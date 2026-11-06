import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/assistant_blocks.dart';
import 'package:trackia/domain/block_names.dart';
import 'package:trackia/domain/workout.dart';

/// Synthetic coverage for US2. No personal database, clock, or provider is used.
void main() {
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late DateTime now;

  setUp(() async {
    now = DateTime(2026, 11, 5, 10);
    dir = await Directory.systemTemp.createTemp('gymia-live-edit-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/fixture.sqlite',
      clock: () => now,
    );
  });

  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<String> makeThreeSetActivity() => repo.prepareActivity(
    ActivityDefinition(name: 'Fixture press', targetSets: 3, restSeconds: 120),
  );

  Future<void> completeInterval(String id) async {
    await repo.startInterval(id);
    now = now.add(const Duration(seconds: 30));
    await repo.stopInterval(id);
  }

  test('synthetic fixture reproduces the visible 4 de 3 state', () async {
    final id = await makeThreeSetActivity();
    for (var i = 0; i < 4; i++) {
      await completeInterval(id);
    }

    final activity = (await repo.loadActivities()).single;
    final completed = activity.intervals.where((i) => i.endedAt != null).length;
    expect((completed, activity.definition.targetSets), (4, 3));
    // activity_focus.dart interpolates these two persisted values directly.
    expect('$completed/${activity.definition.targetSets}', '4/3');
  });

  test('renaming leaves synthetic completed intervals intact', () async {
    final id = await makeThreeSetActivity();
    await completeInterval(id);
    final before = (await repo.loadActivities()).single.intervals;

    await repo.renameActivity(id, 'Press fixture renombrado');
    final after = (await repo.loadActivities()).single;

    expect(after.definition.name, 'Press fixture renombrado');
    expect(
      after.intervals.map((i) => (i.id, i.startedAt, i.endedAt)),
      before.map((i) => (i.id, i.startedAt, i.endedAt)),
    );
  });

  test('rest edit preserves active notice and historical interval', () async {
    final id = await makeThreeSetActivity();
    await completeInterval(id);
    final endedAt = now;
    now = now.add(const Duration(seconds: 10));

    await repo.setActivityRest(id, 180);
    final activity = (await repo.loadActivities()).single;

    expect(activity.definition.restSeconds, 180);
    expect(activity.restEndsAt, endedAt.add(const Duration(seconds: 120)));
    expect(activity.intervals.single.restSeconds, 120);
    await repo.setActivityRest(
      id,
      180,
      updateActiveRest: true,
      expectedRestEndsAt: activity.restEndsAt,
    );
    final confirmed = (await repo.loadActivities()).single;
    expect(confirmed.restEndsAt, endedAt.add(const Duration(seconds: 180)));
    expect(confirmed.intervals.single.restSeconds, 120);
  });

  test('stale notice confirmation cannot modify a newer notice', () async {
    final id = await makeThreeSetActivity();
    await completeInterval(id);
    final oldDeadline = (await repo.loadActivities()).single.restEndsAt;
    await repo.startInterval(id);
    now = now.add(const Duration(seconds: 15));
    await repo.stopInterval(id);
    final current = (await repo.loadActivities()).single;
    await expectLater(
      repo.setActivityRest(
        id,
        180,
        updateActiveRest: true,
        expectedRestEndsAt: oldDeadline,
      ),
      throwsA(isA<ValidationException>()),
    );
    final after = (await repo.loadActivities()).single;
    expect(after.restEndsAt, current.restEndsAt);
    expect(after.definition.restSeconds, 120);
    expect(after.intervals.map((i) => i.restSeconds), [120, 120]);
  });

  test('4 de 3 synthetic state persists across repository restart', () async {
    final id = await makeThreeSetActivity();
    for (var i = 0; i < 4; i++) {
      await completeInterval(id);
    }
    await repo.close();
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/fixture.sqlite',
      clock: () => now,
    );

    final activity = (await repo.loadActivities()).single;
    expect(activity.definition.targetSets, 3);
    expect(activity.intervals.where((i) => i.endedAt != null), hasLength(4));
  });

  test('target 3 to 4 preserves history and survives restart', () async {
    final id = await makeThreeSetActivity();
    for (var i = 0; i < 3; i++) {
      await completeInterval(id);
    }
    final before = (await repo.loadActivities()).single;
    await repo.setActivityTarget(id, 4, expected: before.definition);
    await completeInterval(id);
    await repo.close();
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/fixture.sqlite',
      clock: () => now,
    );
    final after = (await repo.loadActivities()).single;
    expect(after.definition.targetSets, 4);
    expect(after.intervals.where((i) => i.endedAt != null), hasLength(4));
    expect(
      after.intervals.take(3).map((i) => i.toJson()),
      before.intervals.map((i) => i.toJson()),
    );
  });

  test(
    'lower target retains progress; invalid and stale writes rejected',
    () async {
      final id = await makeThreeSetActivity();
      for (var i = 0; i < 3; i++) {
        await completeInterval(id);
      }
      final before = (await repo.loadActivities()).single;
      await expectLater(
        repo.setActivityTarget(id, 0, expected: before.definition),
        throwsA(isA<ValidationException>()),
      );
      await repo.setActivityTarget(id, 2, expected: before.definition);
      await expectLater(
        repo.setActivityTarget(id, 4, expected: before.definition),
        throwsA(isA<ValidationException>()),
      );
      final after = (await repo.loadActivities()).single;
      expect(after.definition.targetSets, 2);
      expect(
        after.intervals.map((i) => i.toJson()),
        before.intervals.map((i) => i.toJson()),
      );
    },
  );

  test('continuous activity rejects a series target', () async {
    final id = await repo.prepareActivity(
      ActivityDefinition(name: 'Correr', repeated: false),
    );
    final before = (await repo.loadActivities()).single;
    await expectLater(
      repo.setActivityTarget(id, 3, expected: before.definition),
      throwsA(isA<ValidationException>()),
    );
    expect((await repo.loadActivities()).single.definition.targetSets, isNull);
  });

  test('target proposal accepts one exact typed object', () {
    const valid = '```trackia-activity-target\n{"targetSets":4}\n```';
    expect(parseActivityTargetBlock(valid)?.targetSets, 4);
    expect(hasBlock(valid, 'activity'), isFalse);
    expect(parseActivityTargetBlock('$valid\n$valid'), isNull);
    expect(
      parseActivityTargetBlock(
        '```trackia-activity-target\n{"targetSets":0}\n```',
      ),
      isNull,
    );
    expect(
      parseActivityTargetBlock(
        '```trackia-activity-target\n{"targetSets":4,"name":"x"}\n```',
      ),
      isNull,
    );
    expect(
      parseActivityTargetBlock(
        '```trackia-activity-target\n{"targetSets":null}\n```',
      ),
      isNotNull,
    );
  });
}
