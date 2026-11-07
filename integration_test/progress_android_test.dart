import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trackia/application/progress_service.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/progress.dart';
import 'package:trackia/ui/activity_summary.dart';
import 'package:trackia/ui/progress_screen.dart';
import 'package:trackia/ui/theme.dart';

/// R7 of specs/004-trackia-experience/quickstart.md: «Leer» in game mode, a
/// goal of 20 pages a day with a minimum of 5 and one free day a week, over
/// four days with a controlled clock. Real SQLite and UI on Android; no AI.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('four days of reading: goal, minimum, free day and unlocks', (
    tester,
  ) async {
    final dir = await Directory.systemTemp.createTemp('trackia-r7-');
    var now = DateTime(2026, 10, 26, 20); // Monday
    final repo = await SqliteWorkoutRepository.open(
      path: '${dir.path}/r7.sqlite',
      clock: () => now,
    );
    final service = ProgressService(progress: repo.progress, clock: () => now);
    final fields = <Map<String, Object>>[
      {
        'key': 'paginas',
        'label': 'Páginas',
        'unit': '',
        'type': 'number',
        'aggregate': 'sum',
      },
    ];
    final lectura = Companion(
      id: 'lectura',
      name: 'Lectura',
      description: '',
      prompt: '',
    );

    Future<ProgressDelta> read(int pages) async {
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
      now = now.add(const Duration(minutes: 20));
      await repo.stopInterval(id);
      await repo.recordActivityMessage(
        id,
        '$pages páginas',
        metrics: {'paginas': pages},
      );
      await repo.finishActivity(id, now);
      return service.afterChange(
        'lectura',
        companionName: 'Lectura',
        fields: fields,
        activityId: id,
      );
    }

    List<String> titles(ProgressDelta d) => [
      for (final a in d.unlocked) a.title,
    ];

    late ProgressDelta day1, day2, day4;
    await tester.runAsync(() async {
      final settings = await repo.progress.settings('lectura');
      await repo.progress.saveSettings(
        settings.copyWith(mode: 'game', freeDaysPerWeek: 1),
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
      day1 = await read(25); // Mon 26: goal met
      now = DateTime(2026, 10, 27, 20);
      day2 = await read(5); // Tue 27: only the minimum
      now = DateTime(2026, 10, 29, 20); // Wed 28 is the free day
      day4 = await read(100); // Thu 29
    });

    expect(titles(day1), ['Primera vez', '10 páginas']);
    expect(day2.unlocked, isEmpty);
    // Three sessions of 20 min also add up to one hour.
    expect(titles(day4).toSet(), {
      '1 h en Lectura',
      'Racha de 3 días',
      '100 páginas',
    });
    expect(day4.records.map((r) => r.label), contains('Récord de páginas'));

    final state = (await tester.runAsync(() => service.state('lectura')))!;
    expect(state.streak.current, 3);
    expect(state.streak.freeDaysUsedThisWeek, 1);
    expect(state.doneDays, {'2026-10-26', '2026-10-27', '2026-10-29'});

    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open-summary'),
                onPressed: () => showActivitySummary(
                  context,
                  name: 'Leer',
                  duration: const Duration(minutes: 20),
                  delta: day4,
                ),
                child: const Text('Ver resumen'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-summary')));
    await tester.pumpAndSettle();
    expect(find.text('Sesión terminada'), findsOneWidget);
    expect(find.text('Leer · 20 min'), findsOneWidget);
    expect(find.text('100 páginas'), findsOneWidget);
    expect(find.text('Racha de 3 días'), findsOneWidget);
    // Time to capture it from outside: adb exec-out screencap -p > resumen.png
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 6)),
    );
    await tester.tap(find.byKey(const Key('summary-close')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: ProgressScreen(service: service, companion: lectura),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Racha actual (días): 3'), findsOneWidget);
    expect(find.byKey(const Key('day-2026-10-26-done')), findsOneWidget);
    expect(find.byKey(const Key('day-2026-10-28-open')), findsOneWidget);
    expect(find.byKey(const Key('goal-text')), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 6)),
    );

    await tester.pumpWidget(const SizedBox());
    await repo.close();
    await dir.delete(recursive: true);
  });
}
