import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/application/progress_engine.dart';
import 'package:gymia/data/progress_repository.dart';
import 'package:gymia/domain/progress.dart';
import 'package:gymia/domain/activity.dart';
import 'package:gymia/domain/workout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late String path;
  late SqliteWorkoutRepository repo;
  late ProgressRepository progress;
  var now = DateTime(2026, 10, 29, 9);

  setUp(() async {
    now = DateTime(2026, 10, 29, 9);
    dir = await Directory.systemTemp.createTemp('trackia-progress-');
    path = '${dir.path}/test.sqlite';
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: path,
      clock: () => now,
    );
    progress = repo.progress;
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  group('settings', () {
    test('an existing companion defaults to reminder mode', () async {
      final s = await progress.settings('gymbro');
      expect(s.mode, 'reminder');
      expect(s.game, isFalse);
      expect(s.freeDaysPerWeek, 1);
      expect(s.revision, 0);
    });

    test('saving keeps the choices and bumps the revision', () async {
      await progress.saveSettings(
        (await progress.settings('lectura')).copyWith(
          mode: 'game',
          achievementsEnabled: false,
          freeDaysPerWeek: 2,
        ),
      );
      var s = await progress.settings('lectura');
      expect(s.game, isTrue);
      expect(s.achievementsEnabled, isFalse);
      expect(s.goalsEnabled, isTrue);
      expect(s.freeDaysPerWeek, 2);
      expect(s.revision, 1);
      await progress.saveSettings(s.copyWith(cheersEnabled: false));
      s = await progress.settings('lectura');
      expect(s.cheersEnabled, isFalse);
      expect(s.revision, 2);
    });

    test('invalid settings are rejected in Spanish', () async {
      final base = await progress.settings('lectura');
      await expectLater(
        progress.saveSettings(base.copyWith(mode: 'otro')),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        progress.saveSettings(base.copyWith(freeDaysPerWeek: 4)),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        progress.settings('no válido!'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('reminders', () {
    test('one reminder per companion; saving again replaces it', () async {
      final first = await progress.saveReminder(
        companionId: 'lectura',
        days: 127,
        windowStartMin: 21 * 60,
        windowEndMin: 23 * 60,
        lastCallMin: 22 * 60 + 30,
        tone: 'cheer',
        minimum: {'metric': 'paginas', 'value': 5},
      );
      expect(first.minimum, {'metric': 'paginas', 'value': 5});
      final second = await progress.saveReminder(
        companionId: 'lectura',
        days: 31,
        windowStartMin: 20 * 60,
        windowEndMin: 22 * 60,
      );
      expect(second.id, first.id);
      expect(second.revision, 2);
      expect(second.lastCallMin, isNull);
      expect(second.minimum, isNull);
      expect(await progress.activeReminders(), hasLength(1));
      expect((await progress.reminderFor('lectura'))!.days, 31);
      expect(await progress.reminderFor('enfoque'), isNull);
    });

    test('the data-model validations are enforced', () async {
      Future<void> bad({
        int days = 127,
        int start = 600,
        int end = 700,
        int? last,
        String tone = 'neutral',
        Map<String, Object?>? minimum,
      }) => expectLater(
        progress.saveReminder(
          companionId: 'lectura',
          days: days,
          windowStartMin: start,
          windowEndMin: end,
          lastCallMin: last,
          tone: tone,
          minimum: minimum,
        ),
        throwsA(isA<ValidationException>()),
      );
      await bad(days: 0);
      await bad(days: 128);
      await bad(start: 700, end: 700);
      await bad(start: 800, end: 700);
      await bad(end: 1441);
      await bad(last: 600); // not strictly after the start
      await bad(last: 700); // not strictly before the end
      await bad(tone: 'loud');
      await bad(minimum: {'metric': 'paginas', 'value': 0});
      await bad(minimum: {'value': 3});
      expect(await progress.activeReminders(), isEmpty);
    });

    test('pausing and resuming; saving lifts a pause', () async {
      await progress.saveReminder(
        companionId: 'lectura',
        days: 127,
        windowStartMin: 600,
        windowEndMin: 700,
      );
      await progress.setPaused('lectura', paused: true);
      expect((await progress.reminderFor('lectura'))!.pausedAt, now);
      await progress.setPaused('lectura', paused: false);
      expect((await progress.reminderFor('lectura'))!.paused, isFalse);
      await progress.setPaused('lectura', paused: true);
      await progress.saveReminder(
        companionId: 'lectura',
        days: 127,
        windowStartMin: 600,
        windowEndMin: 700,
      );
      expect((await progress.reminderFor('lectura'))!.paused, isFalse);
    });

    test('a switched-off reminder is not active', () async {
      await progress.saveReminder(
        companionId: 'lectura',
        days: 127,
        windowStartMin: 600,
        windowEndMin: 700,
        enabled: false,
      );
      expect(await progress.activeReminders(), isEmpty);
      expect(await progress.reminderFor('lectura'), isNotNull);
    });
  });

  test('profiles never see each other\'s settings or reminders', () async {
    final db = await databaseFactoryFfi.openDatabase(path);
    addTearDown(db.close);
    final other = ProgressRepository(db, () => now, 'otro');
    await progress.saveSettings(
      (await progress.settings('lectura')).copyWith(mode: 'game'),
    );
    await progress.saveReminder(
      companionId: 'lectura',
      days: 127,
      windowStartMin: 600,
      windowEndMin: 700,
    );
    expect((await other.settings('lectura')).mode, 'reminder');
    expect(await other.reminderFor('lectura'), isNull);
    await other.deleteCompanion('lectura');
    expect((await progress.settings('lectura')).mode, 'game');
    expect(await progress.reminderFor('lectura'), isNotNull);
  });

  test(
    'deleting a companion removes its settings and reminders only',
    () async {
      final definition = ActivityDefinition(
        name: 'Leer',
        repeated: false,
        restSeconds: 0,
        companionId: 'lectura',
      );
      final activityId = await repo.prepareActivity(definition);
      await repo.observations.record(
        companionId: 'lectura',
        definition: definition,
        original: 'Leí un rato',
      );
      await repo.templates.save(companionId: 'lectura', definition: definition);
      await progress.saveSettings(
        (await progress.settings('lectura')).copyWith(mode: 'game'),
      );
      await progress.saveReminder(
        companionId: 'lectura',
        days: 127,
        windowStartMin: 600,
        windowEndMin: 700,
      );
      await progress.saveReminder(
        companionId: 'enfoque',
        days: 127,
        windowStartMin: 600,
        windowEndMin: 700,
      );

      await progress.deleteCompanion('lectura');

      expect(await progress.reminderFor('lectura'), isNull);
      expect((await progress.settings('lectura')).revision, 0);
      expect(await repo.templates.list(companionId: 'lectura'), isEmpty);
      // The user's records stay.
      expect(
        (await repo.loadActivities()).map((a) => a.id),
        contains(activityId),
      );
      expect(
        await repo.observations.list(companionId: 'lectura'),
        hasLength(1),
      );
      // Another companion is untouched.
      expect(await progress.reminderFor('enfoque'), isNotNull);
    },
  );

  test('session days come from point records and ended segments', () async {
    final definition = ActivityDefinition(
      name: 'Leer',
      repeated: false,
      restSeconds: 0,
      companionId: 'lectura',
    );
    await repo.observations.record(
      companionId: 'lectura',
      definition: definition,
      original: 'Hoy',
    );
    now = DateTime(2026, 10, 30, 9);
    final id = await repo.prepareActivity(definition);
    await repo.startInterval(id);
    now = now.add(const Duration(minutes: 10));
    await repo.stopInterval(id);
    // Another companion's day does not count.
    await repo.observations.record(
      companionId: 'enfoque',
      definition: ActivityDefinition(
        name: 'Foco',
        repeated: false,
        restSeconds: 0,
        companionId: 'enfoque',
      ),
      original: 'Otro',
    );
    expect(await progress.sessionDays('lectura'), {'2026-10-29', '2026-10-30'});
    expect(await progress.sessionDays('enfoque'), {'2026-10-30'});
  });

  group('goals', () {
    GoalRule goal(double target, {double? minimum}) => GoalRule(
      metric: Metric(
        source: 'field',
        field: 'paginas',
        aggregate: 'sum',
        per: 'day',
      ),
      period: 'day',
      target: target,
      minimum: minimum,
    );

    test(
      'a companion has one active goal; a new one archives the old',
      () async {
        expect(await progress.activeGoal('lectura'), isNull);
        await progress.saveGoal('lectura', goal(20, minimum: 5));
        var saved = (await progress.activeGoal('lectura'))!;
        expect([saved.target, saved.minimum, saved.period], [20, 5, 'day']);
        expect(saved.metric.field, 'paginas');
        now = now.add(const Duration(minutes: 1));
        await progress.saveGoal('lectura', goal(30));
        saved = (await progress.activeGoal('lectura'))!;
        expect([saved.target, saved.minimum], [30, null]);
        await progress.clearGoal('lectura');
        expect(await progress.activeGoal('lectura'), isNull);
        // The companion next door never sees it.
        await progress.saveGoal('lectura', goal(20));
        expect(await progress.activeGoal('enfoque'), isNull);
      },
    );

    test('an unknown origin is rejected', () async {
      await expectLater(
        progress.saveGoal('lectura', goal(20), origin: 'magia'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('achievements', () {
    final family = generateAchievements(
      companionName: 'Lectura',
      fields: const [
        {
          'key': 'paginas',
          'label': 'Páginas',
          'unit': '',
          'type': 'number',
          'aggregate': 'sum',
        },
      ],
    );

    test('generated achievements are saved once, never duplicated', () async {
      expect(
        await progress.ensureAchievements('lectura', family),
        family.length,
      );
      expect(await progress.ensureAchievements('lectura', family), 0);
      final saved = await progress.achievements('lectura');
      expect(saved, hasLength(family.length));
      expect(saved.every((a) => !a.unlocked), isTrue);
      expect(saved.first.title, 'Primera vez');
      // Another companion has its own copy.
      expect(
        await progress.ensureAchievements('enfoque', family),
        family.length,
      );
    });

    test('an achievement unlocks once and keeps its first value', () async {
      await progress.ensureAchievements('lectura', family);
      final first = (await progress.achievements('lectura')).first;
      await progress.recordUnlocks([
        NewUnlock(first, 1),
      ], sourceActivityId: 'act-1');
      await progress.recordUnlocks([NewUnlock(first, 9)]);
      final unlocked = (await progress.achievements('lectura')).first.unlock!;
      expect(unlocked.value, 1);
      expect(unlocked.sourceActivityId, 'act-1');
      expect(unlocked.unlockedAt, now);
    });

    test('titles can be edited; the rule stays', () async {
      await progress.ensureAchievements('lectura', family);
      final first = (await progress.achievements('lectura')).first;
      await progress.renameAchievement(first.id, '  ¡Empecé!  ');
      final renamed = (await progress.achievements('lectura')).first;
      expect(renamed.title, '¡Empecé!');
      expect(renamed.ruleHash, first.ruleHash);
      await expectLater(
        progress.renameAchievement(first.id, '   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('deleting the companion removes achievements and unlocks', () async {
      await progress.ensureAchievements('lectura', family);
      final first = (await progress.achievements('lectura')).first;
      await progress.recordUnlocks([NewUnlock(first, 1)]);
      await progress.deleteCompanion('lectura');
      expect(await progress.achievements('lectura'), isEmpty);
      final rows = await repo.progress.achievements('lectura');
      expect(rows, isEmpty);
    });
  });

  group('data for the engine', () {
    final reading = ActivityDefinition(
      name: 'Leer',
      repeated: false,
      restSeconds: 0,
      companionId: 'lectura',
      fields: const [
        {
          'key': 'paginas',
          'label': 'Páginas',
          'unit': '',
          'type': 'number',
          'aggregate': 'sum',
        },
        {'key': 'notas', 'label': 'Notas', 'unit': ''},
      ],
    );

    test('a finished activity gives time, a session and its values', () async {
      final id = await repo.prepareActivity(reading);
      await repo.startInterval(id);
      now = now.add(const Duration(minutes: 10));
      await repo.stopInterval(id);
      await repo.recordActivityMessage(
        id,
        '18 páginas',
        metrics: {'paginas': 18, 'notas': 'bien'},
      );
      await repo.finishActivity(id, now);
      final data = await progress.loadData('lectura');
      expect(data.sessions.single.seconds, 600);
      expect(data.sessions.single.day, '2026-10-29');
      expect(data.typedFields, {'paginas'});
      expect(
        metricValue(
          Metric(
            source: 'field',
            field: 'paginas',
            aggregate: 'sum',
            per: 'total',
          ),
          data,
          at: '2026-10-29',
        ),
        18,
      );
      // The untyped legacy field is loaded but never counted.
      expect(
        metricValue(
          Metric(
            source: 'field',
            field: 'notas',
            aggregate: 'distinct',
            per: 'total',
          ),
          data,
          at: '2026-10-29',
        ),
        0,
      );
    });

    test(
      'an activity in progress counts from its first ended segment',
      () async {
        final id = await repo.prepareActivity(reading);
        expect((await progress.loadData('lectura')).sessions, isEmpty);
        await repo.startInterval(id);
        now = now.add(const Duration(minutes: 5));
        await repo.stopInterval(id);
        final data = await progress.loadData('lectura');
        expect(data.sessions.single.seconds, 300);
      },
    );

    test('only the latest revision of a point record counts', () async {
      final record = await repo.observations.record(
        companionId: 'lectura',
        definition: reading,
        original: '10 páginas',
        values: {'paginas': 10},
      );
      await repo.observations.correct(record.id, values: {'paginas': 12});
      final data = await progress.loadData('lectura');
      expect(data.sessions, hasLength(1));
      expect(data.values.map((v) => v.value), [12]);
    });

    test('another companion\'s records are left out', () async {
      await repo.observations.record(
        companionId: 'lectura',
        definition: reading,
        original: 'Hoy',
      );
      final other = ActivityDefinition(
        name: 'Foco',
        repeated: false,
        restSeconds: 0,
        companionId: 'enfoque',
      );
      await repo.prepareActivity(other);
      await repo.observations.record(
        companionId: 'enfoque',
        definition: other,
        original: 'Otro',
      );
      expect((await progress.loadData('lectura')).sessions, hasLength(1));
      expect((await progress.loadData('enfoque')).sessions, hasLength(1));
      expect((await progress.loadData('calma')).sessions, isEmpty);
    });
  });
}
