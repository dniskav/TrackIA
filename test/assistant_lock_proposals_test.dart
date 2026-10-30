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
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/ui/assistant_chat.dart';

/// Deja correr la E/S real (sqflite, transporte) mientras se bombean fotogramas
/// hasta que se cumple [done]; `pumpAndSettle` no sirve con la barra de progreso.
Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!done() && DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(done(), isTrue, reason: 'la condición se cumplió a tiempo');
}

/// FR-023: lo fijado a mano no se aplica solo; aparece como propuesta
/// «Aplicar/Ignorar» y solo el toque del usuario la aplica.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController controller;
  final now = DateTime(2026, 10, 29, 9);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await const AiSettingsStore().save(
      const AiConfig(
        service: AiService.custom,
        protocol: AiProtocol.chatCompletions,
        baseUrl: 'https://example.test/v1',
        model: 'test',
        apiKey: 'fake-key',
      ),
    );
    await const AiSettingsStore().markVerified(
      (await const AiSettingsStore().load())!,
    );
    dir = await Directory.systemTemp.createTemp('gymia-proposals-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    controller = WorkoutController(repo, clock: () => now);
    await controller.refresh();
  });

  tearDown(() async {
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });

  testWidgets(
    'a locked rest shows the proposal card and only Aplicar changes it',
    (tester) async {
      final activityId = (await tester.runAsync(() async {
        final id = await repo.prepareActivity(
          ActivityDefinition(name: 'Sentadilla', restSeconds: 120),
        );
        await repo.setActivityRest(id, 120);
        await controller.refresh();
        return id;
      }))!;

      await tester.pumpWidget(
        MaterialApp(
          home: AssistantChatScreen(
            controller: controller,
            availability: AiAvailability(
              catalog: AiModelCatalog(
                transport: (_, __) async => {
                  'data': [
                    {'id': 'test'},
                  ],
                },
              ),
            ),
            client: AiClient(
              transport: (_, __, ___) async {
                final content = '```gymia-timing\n{"restSeconds": 150}\n```';
                return {
                  'choices': [
                    {
                      'message': {'content': content},
                    },
                  ],
                };
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'sube el descanso');
      await tester.runAsync(() => tester.tap(find.byIcon(Icons.send)));
      await settleUntil(
        tester,
        () => find.byKey(const Key('proposal-card')).evaluate().isNotEmpty,
      );

      // No se aplicó solo: sigue en 120 s y aparece la tarjeta.
      final activity = (await tester.runAsync(
        () => repo.loadActivities(),
      ))!.singleWhere((a) => a.id == activityId);
      expect(activity.definition.restSeconds, 120);
      expect(activity.definition.userSet, contains('restSeconds'));
      expect(find.byKey(const Key('proposal-card')), findsOneWidget);
      expect(find.text('Descanso: 120 s → 150 s'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('proposal-apply')));
      });
      await settleUntil(
        tester,
        () => find.byKey(const Key('proposal-card')).evaluate().isEmpty,
      );
      final applied = (await tester.runAsync(
        () => repo.loadActivities(),
      ))!.singleWhere((a) => a.id == activityId);
      expect(applied.definition.restSeconds, 150);
      expect(find.byKey(const Key('proposal-card')), findsNothing);
    },
  );
}
