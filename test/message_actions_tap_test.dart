import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/ui/assistant_chat.dart';

import 'helpers/real_io.dart';

/// Las acciones de un mensaje respondido están ocultas hasta tocar su texto.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController controller;
  const config = AiConfig(
    service: AiService.custom,
    protocol: AiProtocol.chatCompletions,
    baseUrl: 'https://example.test/v1',
    model: 'test',
    apiKey: 'fake-key',
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await const AiSettingsStore().save(config);
    await const AiSettingsStore().markVerified(config);
    dir = await Directory.systemTemp.createTemp('trackia-actions-tap-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
    );
    controller = WorkoutController(repo);
  });
  tearDown(() async {
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });

  testWidgets('tocar el texto muestra y oculta las acciones del mensaje', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AssistantChatScreen(
          controller: controller,
          chatStore: repo.chats,
          client: AiClient(
            transport: (_, __, ___) async => {
              'choices': [
                {
                  'message': {'content': 'Entendido'},
                },
              ],
            },
          ),
          availability: AiAvailability(
            catalog: AiModelCatalog(
              transport: (_, __) async => {
                'data': [
                  {'id': 'test'},
                ],
              },
            ),
          ),
        ),
      ),
    );
    await realIo(tester);
    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Hola TrackIA',
    );
    await tester.tap(find.byTooltip('Enviar'));
    await realIo(tester);
    expect(find.text('Entendido'), findsOneWidget);

    final edit = find.byWidgetPredicate(
      (w) => w.key.toString().startsWith("[<'edit-message-"),
    );
    final history = find.byWidgetPredicate(
      (w) => w.key.toString().startsWith("[<'history-message-"),
    );
    final resend = find.byWidgetPredicate(
      (w) => w.key.toString().startsWith("[<'resend-message-"),
    );
    final state = find.byWidgetPredicate(
      (w) => w.key.toString().startsWith("[<'delivery-state-"),
    );

    // 1) Respondido: nada visible.
    expect(edit, findsNothing);
    expect(history, findsNothing);
    expect(resend, findsNothing);
    expect(state, findsNothing);

    // 2) Un toque en el texto muestra los iconos.
    await tester.tap(find.text('Hola TrackIA'));
    await tester.pumpAndSettle();
    expect(edit, findsOneWidget);
    expect(history, findsOneWidget);
    expect(resend, findsOneWidget);
    expect(state, findsOneWidget);
    expect(find.byTooltip('Editar'), findsOneWidget);
    expect(find.byTooltip('Historial'), findsOneWidget);
    expect(find.byTooltip('Reenviar'), findsOneWidget);
    expect(find.text('Respondido'), findsOneWidget);

    // 3) Un segundo toque los oculta (fuera de la ventana de doble toque).
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Hola TrackIA'));
    await tester.pumpAndSettle();
    expect(edit, findsNothing);
    expect(history, findsNothing);
    expect(resend, findsNothing);
    expect(find.byTooltip('Editar'), findsNothing);
  });
}
