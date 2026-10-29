import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/application/ai_availability.dart';
import 'package:gymia/data/ai_model_catalog.dart';
import 'package:gymia/data/progress_repository.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/domain/companion.dart';
import 'package:gymia/ui/companions.dart';
import 'package:gymia/ui/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late ProgressRepository progress;
  late int changes;
  Companion? settingsFor;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    changes = 0;
    settingsFor = null;
    dir = await Directory.systemTemp.createTemp('trackia-pause-card-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => DateTime(2026, 10, 29, 9),
    );
    progress = repo.progress;
  });
  tearDown(() async {
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

  Future<void> show(WidgetTester tester, {bool withSettings = true}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: CompanionDashboard(
          profileId: 'local',
          progress: progress,
          availability: AiAvailability(
            catalog: AiModelCatalog(transport: (_, __) async => {'data': []}),
          ),
          onOpen: (_) {},
          onCompanionSettings: withSettings ? (c) => settingsFor = c : null,
          onRemindersChanged: () => changes++,
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> pauseReminder(WidgetTester tester, String companionId) =>
      tester.runAsync(() async {
        await progress.saveReminder(
          companionId: companionId,
          days: 127,
          windowStartMin: 600,
          windowEndMin: 700,
        );
        await progress.setPaused(companionId, paused: true);
      });

  testWidgets('only a paused companion shows «Recordatorios en pausa»', (
    tester,
  ) async {
    await pauseReminder(tester, 'gymbro');
    await tester.runAsync(
      () => progress.saveReminder(
        companionId: 'enfoque',
        days: 127,
        windowStartMin: 600,
        windowEndMin: 700,
      ),
    );
    await show(tester);
    expect(find.byKey(const Key('paused-gymbro')), findsOneWidget);
    expect(find.text('Recordatorios en pausa'), findsOneWidget);
    expect(find.byKey(const Key('paused-enfoque')), findsNothing);
    expect(find.byKey(const Key('paused-calma')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('«Reanudar» resumes the reminder and tells the phone', (
    tester,
  ) async {
    await pauseReminder(tester, 'gymbro');
    await show(tester);
    await tester.tap(find.byKey(const Key('resume-gymbro')));
    await settle(tester);
    expect(find.byKey(const Key('paused-gymbro')), findsNothing);
    expect(
      (await tester.runAsync(() => progress.reminderFor('gymbro')))!.paused,
      isFalse,
    );
    expect(changes, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('«Modo y avisos» is in the card menu only when it can open', (
    tester,
  ) async {
    await show(tester, withSettings: false);
    await tester.tap(find.byTooltip('Opciones de GymBro'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-companion-settings')), findsNothing);
    await tester.pumpWidget(const SizedBox());

    await show(tester);
    await tester.tap(find.byTooltip('Opciones de GymBro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modo y avisos'));
    await tester.pumpAndSettle();
    expect(settingsFor?.id, 'gymbro');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('deleting a companion removes its reminder and tells the phone', (
    tester,
  ) async {
    await tester.runAsync(
      () => progress.saveReminder(
        companionId: 'gymbro',
        days: 127,
        windowStartMin: 600,
        windowEndMin: 700,
      ),
    );
    await show(tester);
    await tester.tap(find.byTooltip('Opciones de GymBro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar').last);
    await settle(tester);
    expect(find.byKey(const Key('companion-gymbro')), findsNothing);
    expect(await tester.runAsync(() => progress.reminderFor('gymbro')), isNull);
    expect(changes, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
