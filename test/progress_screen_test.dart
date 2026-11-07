import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/progress_service.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/progress.dart';
import 'package:trackia/ui/progress_screen.dart';
import 'package:trackia/ui/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late ProgressService service;
  late DateTime now;
  final lectura = Companion(
    id: 'lectura',
    name: 'Lectura',
    description: '',
    prompt: '',
  );
  final fields = <Map<String, Object>>[
    {
      'key': 'paginas',
      'label': 'Páginas',
      'unit': '',
      'type': 'number',
      'aggregate': 'sum',
    },
  ];

  setUp(() async {
    now = DateTime(2026, 10, 29, 20); // Thursday
    dir = await Directory.systemTemp.createTemp('trackia-progress-screen-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    service = ProgressService(progress: repo.progress, clock: () => now);
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  /// A widget that says [label] to the screen reader.
  Finder says(Object label) => find.byWidgetPredicate(
    (w) =>
        w is Semantics &&
        (label is RegExp
            ? label.hasMatch(w.properties.label ?? '')
            : w.properties.label == label),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: ProgressScreen(service: service, companion: lectura),
      ),
    );
    await settle(tester);
  }

  Future<void> read(int pages, int day) async {
    now = DateTime(2026, 10, day, 20);
    final id = await repo.prepareActivity(
      ActivityDefinition(
        name: 'Leer',
        repeated: false,
        restSeconds: 0,
        companionId: 'lectura',
        fields: fields,
      ),
    );
    await repo.startInterval(id);
    now = now.add(const Duration(minutes: 10));
    await repo.stopInterval(id);
    await repo.recordActivityMessage(id, '$pages', metrics: {'paginas': pages});
    await repo.finishActivity(id, now);
    await service.afterChange(
      'lectura',
      companionName: 'Lectura',
      fields: fields,
      activityId: id,
    );
  }

  testWidgets('a companion without data explains how to get started', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Progreso · Lectura'), findsOneWidget);
    expect(find.text('Racha actual (días): 0'), findsOneWidget);
    expect(find.byKey(const Key('goal-card')), findsNothing);
    expect(find.byKey(const Key('achievements-empty')), findsOneWidget);
    expect(find.textContaining('Activa el modo Juego'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'streak, calendar, goal and achievements reflect the saved data',
    (tester) async {
      await tester.runAsync(() async {
        await repo.progress.saveSettings(
          (await repo.progress.settings('lectura')).copyWith(mode: 'game'),
        );
        await repo.progress.saveGoal(
          'lectura',
          GoalRule(
            metric: Metric(
              source: 'field',
              field: 'paginas',
              aggregate: 'sum',
              per: 'day',
            ),
            period: 'day',
            target: 20,
            minimum: 5,
          ),
        );
        await read(25, 26);
        await read(6, 27);
        await read(40, 29);
        now = DateTime(2026, 10, 29, 21);
      });
      await open(tester);

      expect(find.text('Racha actual (días): 3'), findsOneWidget);
      expect(find.textContaining('Mejor racha: 3'), findsOneWidget);
      expect(
        find.textContaining('Días libres esta semana: 1/1'),
        findsOneWidget,
      );

      // Four weeks ending in the current one; 28 was the free day.
      expect(find.byKey(const Key('calendar')), findsOneWidget);
      for (final day in ['2026-10-26', '2026-10-27', '2026-10-29']) {
        expect(find.byKey(Key('day-$day-done')), findsOneWidget);
      }
      expect(find.byKey(const Key('day-2026-10-28-open')), findsOneWidget);
      expect(find.byKey(const Key('day-2026-10-05-open')), findsOneWidget);
      expect(says('29 de octubre: cumplido'), findsOneWidget);
      expect(says('28 de octubre: sin cumplir'), findsOneWidget);
      expect(says('30 de octubre: pendiente'), findsOneWidget);

      expect(find.text('Meta de hoy'), findsOneWidget);
      expect(find.text('40 de 20'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      final unlocked = (await tester.runAsync(
        () => repo.progress.achievements('lectura'),
      ))!.where((a) => a.unlocked).map((a) => a.title).toSet();
      expect(
        unlocked,
        containsAll(['Primera vez', '10 páginas', 'Racha de 3 días']),
      );
      expect(
        find.textContaining('Logros · ${unlocked.length} de'),
        findsOneWidget,
      );
      expect(says('Primera vez, desbloqueado'), findsOneWidget);
      // 10 sessions are far: locked, with its progress said aloud.
      expect(
        says(RegExp('^10 sesiones, bloqueado, \\d+ % de progreso\$')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a weekly goal says it is for the week', (tester) async {
    await tester.runAsync(() async {
      await repo.progress.saveGoal(
        'lectura',
        GoalRule(metric: Metric.sessions('week'), period: 'week', target: 3),
      );
      await read(5, 27);
      now = DateTime(2026, 10, 29, 21);
    });
    await open(tester);
    expect(find.text('Meta de la semana'), findsOneWidget);
    expect(find.text('1 de 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
