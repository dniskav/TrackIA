import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/workout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixtures/trackia_legacy_fixtures.dart';

void main() {
  sqfliteFfiInit();
  test(
    'v4 upgrade backs up originals and creates one scoped gym space',
    () async {
      final dir = await Directory.systemTemp.createTemp('trackia-upgrade-');
      final path = '${dir.path}/legacy.sqlite';
      try {
        final fixture = await TrackiaLegacyFixture.create(
          factory: databaseFactoryFfi,
          path: path,
        );
        final dbBefore = await databaseFactoryFfi.openDatabase(path);
        expect(await dbBefore.getVersion(), 4);
        await dbBefore.close();

        var repo = await SqliteWorkoutRepository.open(
          factory: databaseFactoryFfi,
          path: path,
          profileId: 'local',
        );
        expect((await repo.load()).single.id, fixture.workoutId);
        expect(
          (await repo.load()).single.exercises.single.id,
          fixture.exerciseId,
        );
        expect(
          (await repo.load()).single.exercises.single.sets.single.id,
          fixture.setId,
        );
        expect(
          (await repo.loadActivities()).single.messages.single.text,
          fixture.original,
        );
        await repo.close();

        final saved = await File('$path.pre-trackia-v4.json').readAsString();
        expect(jsonDecode(saved), jsonDecode(fixture.backupV3));
        final dbAfter = await databaseFactoryFfi.openDatabase(path);
        expect(await dbAfter.getVersion(), 8);
        expect(
          await dbAfter.query(
            'trackia_spaces',
            where: 'profile_id = ?',
            whereArgs: ['local'],
          ),
          hasLength(1),
        );
        await dbAfter.close();

        repo = await SqliteWorkoutRepository.open(
          factory: databaseFactoryFfi,
          path: path,
          profileId: 'local',
        );
        await repo.close();
        final repeated = await databaseFactoryFfi.openDatabase(path);
        expect(await repeated.query('trackia_spaces'), hasLength(1));
        await repeated.close();

        final restoredPath = '${dir.path}/restored.sqlite';
        final restored = await SqliteWorkoutRepository.open(
          factory: databaseFactoryFfi,
          path: restoredPath,
        );
        await restored.restoreBackupJson(saved);
        expect((await restored.load()).single.id, fixture.workoutId);
        expect(
          (await restored.loadActivities()).single.messages.single.text,
          fixture.original,
        );
        await restored.close();
        final restoredDb = await databaseFactoryFfi.openDatabase(restoredPath);
        expect(
          await restoredDb.query('trackia_legacy_workout_scope'),
          hasLength(1),
        );
        expect(
          await restoredDb.query('trackia_legacy_activity_scope'),
          hasLength(1),
        );
        await restoredDb.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test('profile ownership is recorded in its own database', () async {
    final dir = await Directory.systemTemp.createTemp('trackia-profile-');
    try {
      for (final id in ['local', 'google_abc']) {
        final path = '${dir.path}/$id.sqlite';
        final repo = await SqliteWorkoutRepository.open(
          factory: databaseFactoryFfi,
          path: path,
          profileId: id,
        );
        await repo.close();
        final db = await databaseFactoryFfi.openDatabase(path);
        final rows = await db.query('trackia_spaces');
        expect(rows, hasLength(1));
        expect(rows.single['profile_id'], id);
        await db.close();
        await expectLater(
          SqliteWorkoutRepository.open(
            factory: databaseFactoryFfi,
            path: path,
            profileId: '${id}_other',
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test(
    'v4 upgrade accepts a history with more than 20 MB of attachments',
    () async {
      final dir = await Directory.systemTemp.createTemp('trackia-large-v4-');
      final path = '${dir.path}/legacy.sqlite';
      try {
        final fixture = await TrackiaLegacyFixture.create(
          factory: databaseFactoryFfi,
          path: path,
        );
        final db = await databaseFactoryFfi.openDatabase(path);
        final attachment = jsonEncode({
          'name': 'fixture.png',
          'mime': 'image/png',
          'base64': base64Encode(Uint8List(3 * 1024 * 1024)),
        });
        for (var index = 0; index < 6; index++) {
          await db.insert('activity_messages', {
            'id': 'media-$index',
            'activity_id': fixture.activityId,
            'interval_id': null,
            'text': 'Adjunto sintético $index',
            'role': 'user',
            'recorded_at': 1000 + index,
            'metrics': '{}',
            'attachment': attachment,
            'attachment_name': 'fixture.png',
            'attachment_mime': 'image/png',
          });
        }
        await db.close();

        final repo = await SqliteWorkoutRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        expect((await repo.loadActivities()).single.messages, hasLength(7));
        await repo.close();
        expect(
          await File('$path.pre-trackia-v4.json').length(),
          greaterThan(20 * 1024 * 1024),
        );
        final backup =
            jsonDecode(await File('$path.pre-trackia-v4.json').readAsString())
                as Map<String, dynamic>;
        final tables = backup['tables'] as Map<String, dynamic>;
        final messages = tables['activity_messages'] as List<dynamic>;
        expect(messages, hasLength(7));
        expect(
          (messages.cast<Map<String, dynamic>>().firstWhere(
            (message) => message['id'] == 'media-0',
          ))['attachment'],
          attachment,
        );
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test('v8 adds the activity revision: backup first, IDs kept, counter grows', () async {
    final dir = await Directory.systemTemp.createTemp('trackia-v8-');
    final path = '${dir.path}/v7.sqlite';
    try {
      // A real v7 database: current schema without the v8 column.
      var repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final activityId = await repo.prepareActivity(
        ActivityDefinition(name: 'Press', targetSets: 3),
      );
      final workoutId = (await repo.loadActivities()).single.workoutId;
      await repo.close();
      var db = await databaseFactoryFfi.openDatabase(path);
      await db.execute('ALTER TABLE activities DROP COLUMN revision');
      await db.setVersion(7);
      await db.close();
      expect(File('$path.pre-trackia-v8.sqlite').existsSync(), isFalse);

      repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final migrated = (await repo.loadActivities()).single;
      expect(migrated.id, activityId);
      expect(migrated.workoutId, workoutId);
      expect(migrated.revision, 1);
      await repo.setActivityTarget(
        activityId,
        5,
        expected: migrated.definition,
        expectedRevision: 1,
      );
      expect((await repo.loadActivities()).single.revision, 2);
      await repo.close();

      // The backup was taken before the change: v7 schema, original ID.
      final backup = File('$path.pre-trackia-v8.sqlite');
      expect(backup.existsSync(), isTrue);
      final old = await databaseFactoryFfi.openDatabase(backup.path);
      expect(await old.getVersion(), 7);
      final cols = await old.rawQuery('PRAGMA table_info(activities)');
      expect(cols.map((c) => c['name']), isNot(contains('revision')));
      final rows = await old.query('activities');
      expect(rows.single['id'], activityId);
      expect(rows.single['definition'], contains('"targetSets":3'));
      await old.close();

      db = await databaseFactoryFfi.openDatabase(path);
      expect(await db.getVersion(), 8);
      await db.close();
      // Reopening a v8 database is a no-op: no new backup, revision kept.
      repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      expect((await repo.loadActivities()).single.revision, 2);
      await repo.close();
      expect(
        dir.listSync().where((f) => f.path.contains('pre-trackia-v8.sqlite')),
        hasLength(1),
      );
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('upgrade from an old v4 base starts every activity at revision 1', () async {
    final dir = await Directory.systemTemp.createTemp('trackia-v8-old-');
    final path = '${dir.path}/legacy.sqlite';
    try {
      final fixture = await TrackiaLegacyFixture.create(
        factory: databaseFactoryFfi,
        path: path,
      );
      final repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final activity = (await repo.loadActivities()).single;
      expect(activity.id, fixture.activityId);
      expect(activity.revision, 1);
      await repo.close();
      // Only the original v4 -> v7 recovery copy exists, not a v8 one.
      expect(File('$path.pre-trackia-v7.sqlite').existsSync(), isTrue);
      expect(File('$path.pre-trackia-v8.sqlite').existsSync(), isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
