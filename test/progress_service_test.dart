import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/application/progress_service.dart';
import 'package:gymia/application/reminder_scheduler.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/domain/activity.dart';
import 'package:gymia/domain/companion.dart';
import 'package:gymia/domain/progress.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late ProgressService service;
  late DateTime now;

  final fields = <Map<String, Object>>[
    {
      'key': 'paginas',
      'label': 'Páginas',
      'unit': '',
      'type': 'number',
      'aggregate': 'sum',
    },
    {
      'key': 'libro',
      'label': 'Libro',
      'unit': '',
      'type': 'text',
      'aggregate': 'distinct',
    },
  ];

  setUp(() async {
    now = DateTime(2026, 10, 26, 20);
    dir = await Directory.systemTemp.createTemp('trackia-progress-service-');
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

  Future<void> game({bool achievements = true, int free = 1}) async {
    final s = await repo.progress.settings('lectura');
    await repo.progress.saveSettings(
      s.copyWith(
        mode: 'game',
        achievementsEnabled: achievements,
        freeDaysPerWeek: free,
      ),
    );
  }

  /// A finished reading session of [pages] pages and [minutes] minutes.
  Future<String> read(int pages, {int minutes = 10, String? book}) async {
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
    now = now.add(Duration(minutes: minutes));
    await repo.stopInterval(id);
    await repo.recordActivityMessage(
      id,
      '$pages páginas',
      metrics: {'paginas': pages, if (book != null) 'libro': book},
    );
    await repo.finishActivity(id, now);
    return id;
  }

  Future<ProgressDelta> after(String id) => service.afterChange(
    'lectura',
    companionName: 'Lectura',
    fields: fields,
    activityId: id,
  );

  List<String> titles(ProgressDelta d) => [for (final a in d.unlocked) a.title];

  test(
    'game mode: the first session unlocks only what its data reaches',
    () async {
      await game();
      final delta = await after(await read(18, book: 'Dune'));
      expect(titles(delta), ['Primera vez', '10 páginas']);
      // Nothing else was reached: not 100 pages, not 10 sessions, not a streak of 3.
      final all = await repo.progress.achievements('lectura');
      expect(all.where((a) => a.unlocked).map((a) => a.title), titles(delta));
      expect(all.length, greaterThan(10));
    },
  );

  test('saving again unlocks nothing twice', () async {
    await game();
    final id = await read(18);
    await after(id);
    final again = await after(id);
    expect(again.unlocked, isEmpty);
    expect(again.isEmpty, isTrue);
  });

  test(
    'a second session unlocks the next thresholds and not the old ones',
    () async {
      await game();
      await after(await read(18));
      now = DateTime(2026, 10, 27, 20);
      final delta = await after(await read(90));
      // 18 + 90 = 108 pages: 100 is reached now, 10 was already.
      expect(titles(delta), ['100 páginas']);
    },
  );

  test('a streak achievement unlocks on the third consecutive day', () async {
    await game();
    for (var day = 26; day <= 28; day++) {
      now = DateTime(2026, 10, day, 20);
      final delta = await after(await read(5));
      expect(titles(delta).contains('Racha de 3 días'), day == 28);
    }
    final state = await service.state('lectura');
    expect(state.streak.current, 3);
    expect(state.unlockedCount, greaterThanOrEqualTo(2));
  });

  test('reminder mode and switched-off achievements unlock nothing', () async {
    final reminderMode = await after(await read(500));
    expect(reminderMode.unlocked, isEmpty);
    expect(await repo.progress.achievements('lectura'), isEmpty);
    await game(achievements: false);
    now = DateTime(2026, 10, 27, 20);
    expect((await after(await read(500))).unlocked, isEmpty);
    expect(await repo.progress.achievements('lectura'), isEmpty);
  });

  group('records', () {
    test('a first session is not a record', () async {
      await game();
      expect((await after(await read(18))).records, isEmpty);
    });

    test('beating the best session reports pages and time', () async {
      await game();
      await after(await read(18, minutes: 10));
      now = DateTime(2026, 10, 27, 20);
      final delta = await after(await read(30, minutes: 25));
      expect(delta.records.map((r) => r.label), [
        'Sesión más larga',
        'Récord de páginas',
      ]);
      expect(delta.records[0].value, 25);
      expect(delta.records[0].unit, 'min');
      expect(delta.records[1].value, 30);
    });

    test('a smaller session is not a record, even in reminder mode', () async {
      await after(await read(40, minutes: 20));
      now = DateTime(2026, 10, 27, 20);
      expect((await after(await read(10, minutes: 5))).records, isEmpty);
      now = DateTime(2026, 10, 28, 20);
      final delta = await after(await read(50, minutes: 5));
      expect(delta.records.map((r) => r.label), ['Récord de páginas']);
    });
  });

  group('state and done days', () {
    test('a daily goal with a minimum decides which days are done', () async {
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
      await read(25); // Mon 26: goal met
      now = DateTime(2026, 10, 27, 20);
      await read(6); // Tue 27: minimum only
      now = DateTime(2026, 10, 28, 20);
      await read(2); // Wed 28: below the minimum
      now = DateTime(2026, 10, 29, 9);
      expect(await service.doneDays('lectura'), {'2026-10-26', '2026-10-27'});
      final state = await service.state('lectura');
      expect(state.goalProgress!.value, 0);
      expect(state.goalProgress!.met, isFalse);
      // 28 was missed (free day) and today is still open: 27 and 26 count.
      expect(state.streak.current, 2);
      expect(state.goal!.target, 20);
    });

    test('without a goal any record makes a day done', () async {
      await read(1);
      expect(await service.doneDays('lectura'), {'2026-10-26'});
    });

    test('an empty companion has an empty state', () async {
      final state = await service.state('calma');
      expect(state.streak.current, 0);
      expect(state.doneDays, isEmpty);
      expect(state.goal, isNull);
      expect(state.achievements, isEmpty);
      expect(state.settings.mode, 'reminder');
    });
  });

  test('the reminders use the engine\'s done days', () async {
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
      ),
    );
    await repo.progress.saveReminder(
      companionId: 'lectura',
      days: 127,
      windowStartMin: 1260,
      windowEndMin: 1380,
    );
    await read(3); // below the goal: not a done day
    final sent = <String>[];
    final scheduler = ReminderScheduler(
      progress: repo.progress,
      companions: () async => [
        Companion(id: 'lectura', name: 'Lectura', description: '', prompt: ''),
      ],
      clock: () => now,
      supported: true,
      doneDays: service.doneDays,
      invoke: (method, args) async {
        sent.add(args['snapshot'] as String);
        return true;
      },
    );
    await scheduler.sync();
    expect(sent.single, contains('"lastDoneDate":null'));
  });
}
