import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/ui/assistant_chat.dart';
import 'package:trackia/ui/theme.dart';

/// FR-023: el panel muestra un candado junto a lo que el usuario fijó a mano y
/// tocarlo lo libera.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController c;
  final now = DateTime(2026, 10, 29, 9);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('gymia-lock-badge-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    c = WorkoutController(repo, clock: () => now);
  });
  tearDown(() async {
    c.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('a hand-set name and rest show a lock that frees on tap', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final id = await repo.prepareActivity(
        ActivityDefinition(name: 'Sentadilla', restSeconds: 60),
      );
      await repo.renameActivity(id, 'Sentadilla búlgara');
      await repo.setActivityRest(id, 75);
      await c.refresh();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: AssistantChatScreen(
          controller: c,
          focusMode: true,
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
    await settle(tester);

    expect(find.byKey(const Key('lock-name')), findsOneWidget);
    expect(find.byKey(const Key('lock-restSeconds')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Fijado por ti. Toca para liberar'),
      findsNWidgets(2),
    );

    await tester.runAsync(
      () => tester.tap(find.byKey(const Key('lock-restSeconds'))),
    );
    await settle(tester);

    expect(find.byKey(const Key('lock-restSeconds')), findsNothing);
    expect(find.byKey(const Key('lock-name')), findsOneWidget);
    final saved = (await tester.runAsync(() => repo.loadActivities()))!.single;
    expect(saved.definition.userSet, ['name']);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  });
}
