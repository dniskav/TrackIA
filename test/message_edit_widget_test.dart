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

/// Editar un mensaje: guardar solo, guardar y enviar al modelo, cancelar.
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
    dir = await Directory.systemTemp.createTemp('trackia-edit-');
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

  Future<List<Map<String, dynamic>>> open(WidgetTester tester) async {
    final bodies = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: AssistantChatScreen(
          controller: controller,
          chatStore: repo.chats,
          client: AiClient(
            transport: (_, __, body) async {
              bodies.add(body);
              return {
                'choices': [
                  {
                    'message': {'content': 'Respuesta ${bodies.length}'},
                  },
                ],
              };
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
    return bodies;
  }

  Future<void> say(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('assistant-input')), text);
    await tester.tap(find.byTooltip('Enviar'));
    await realIo(tester);
  }

  Future<void> openEditor(
    WidgetTester tester,
    String text,
    String edited,
  ) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar'));
    await realIo(tester);
    expect(find.byKey(const Key('edit-message-input')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('edit-message-input')), edited);
  }

  Future<void> expectVersion2(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Historial'));
    await realIo(tester);
    expect(find.textContaining('Versión 2 · actual'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await realIo(tester, 10);
  }

  testWidgets('Guardar solo guarda la revisión 2 sin enviar ni fallar', (
    tester,
  ) async {
    final bodies = await open(tester);
    await say(tester, 'Hola original');
    expect(bodies, hasLength(1));
    await openEditor(tester, 'Hola original', 'Hola corregido');
    await tester.tap(find.byKey(const Key('save-edit-message')));
    await realIo(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(bodies, hasLength(1));
    expect(find.text('Hola corregido'), findsOneWidget);
    await expectVersion2(tester);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Guardar y enviar manda el texto editado y limpia el contexto', (
    tester,
  ) async {
    final bodies = await open(tester);
    await say(tester, 'Hola original');
    await say(tester, 'Segundo mensaje');
    expect(bodies, hasLength(2));
    await tester.pump(const Duration(milliseconds: 600));
    await openEditor(tester, 'Hola original', 'Hola corregido');
    await tester.tap(find.byKey(const Key('save-send-edit-message')));
    await realIo(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(bodies, hasLength(3));
    // El mensaje de sistema (contexto de la app) no es historial de chat.
    final sent = [
      for (final m in bodies.last['messages'] as List)
        if ((m as Map)['role'] != 'system') m['content'],
    ];
    expect(sent, ['Hola corregido']);
    expect(sent.join(), isNot(contains('Hola original')));
    expect(sent.join(), isNot(contains('Respuesta 1')));
    expect(sent.join(), isNot(contains('Segundo mensaje')));
    // Visible: texto editado, respuesta nueva y aviso; lo obsoleto se retira.
    expect(find.text('Hola corregido'), findsOneWidget);
    expect(find.text('Respuesta 3'), findsOneWidget);
    expect(find.text('Respuesta 1'), findsNothing);
    expect(find.text('Segundo mensaje'), findsNothing);
    expect(
      find.text('Conversación continuada desde el mensaje editado'),
      findsOneWidget,
    );
    await expectVersion2(tester);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Cancelar no cambia nada', (tester) async {
    final bodies = await open(tester);
    await say(tester, 'Hola original');
    await openEditor(tester, 'Hola original', 'Otra cosa');
    await tester.tap(find.byKey(const Key('cancel-edit-message')));
    await realIo(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(bodies, hasLength(1));
    expect(find.text('Hola original'), findsOneWidget);
    expect(find.text('Otra cosa'), findsNothing);
    await tester.tap(find.byTooltip('Historial'));
    await realIo(tester);
    expect(find.textContaining('Versión 2'), findsNothing);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    await close(tester);
  });
}
