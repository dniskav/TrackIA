import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixtures/trackia_v6_fixtures.dart';

Future<Set<String>> _tables(String path) async {
  final db = await databaseFactoryFfi.openDatabase(path);
  try {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    return rows.map((r) => r['name'] as String).toSet();
  } finally {
    await db.close();
  }
}

void main() {
  sqfliteFfiInit();

  test('v5 upgrade adds the v6 tables, keeps every ID and backs up first', () async {
    final dir = await Directory.systemTemp.createTemp('trackia-v6-');
    final path = '${dir.path}/legacy.sqlite';
    try {
      final fixture = await TrackiaV5Fixture.create(
        factory: databaseFactoryFfi,
        path: path,
      );
      final before = await databaseFactoryFfi.openDatabase(path);
      expect(await before.getVersion(), 5);
      await before.close();
      expect(await _tables(path), isNot(contains('trackia_goals')));

      var repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: path,
        profileId: 'local',
      );
      expect((await repo.load()).single.id, fixture.workoutId);
      expect(
        (await repo.load()).single.exercises.single.sets.single.id,
        fixture.setId,
      );
      expect(
        (await repo.loadActivities()).single.messages.single.text,
        fixture.original,
      );
      await repo.close();

      final after = await databaseFactoryFfi.openDatabase(path);
      expect(await after.getVersion(), 6);
      await after.close();
      expect(await _tables(path), containsAll(trackiaV6Tables));

      final saved = await File('$path.pre-trackia-v6.json').readAsString();
      expect(jsonDecode(saved), jsonDecode(fixture.backupV3));

      repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: path,
        profileId: 'local',
      );
      expect((await repo.load()).single.id, fixture.workoutId);
      await repo.close();
      expect(
        Directory(dir.path)
            .listSync()
            .where((f) => f.path.contains('pre-trackia-v6'))
            .length,
        1,
        reason: 'abrir otra vez no debe crear otro respaldo',
      );

      final restoredPath = '${dir.path}/restored.sqlite';
      final restored = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: restoredPath,
      );
      await restored.restoreBackupJson(saved);
      expect((await restored.load()).single.id, fixture.workoutId);
      await restored.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('a new database is created directly at v6 with every table', () async {
    final dir = await Directory.systemTemp.createTemp('trackia-v6-new-');
    final path = '${dir.path}/fresh.sqlite';
    try {
      final repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      await repo.close();
      final db = await databaseFactoryFfi.openDatabase(path);
      expect(await db.getVersion(), 6);
      await db.close();
      expect(await _tables(path), containsAll(trackiaV6Tables));
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('v6 tables keep chat rows isolated by profile and companion', () async {
    final dir = await Directory.systemTemp.createTemp('trackia-v6-iso-');
    final path = '${dir.path}/iso.sqlite';
    try {
      final repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      await repo.close();
      final db = await databaseFactoryFfi.openDatabase(path);
      await db.insert('trackia_chats', {
        'profile_id': 'local',
        'companion_id': 'gymbro',
        'payload': '{}',
        'updated_at': 1,
      });
      await db.insert('trackia_chats', {
        'profile_id': 'local',
        'companion_id': 'enfoque',
        'payload': '{}',
        'updated_at': 1,
      });
      await expectLater(
        db.insert('trackia_chats', {
          'profile_id': 'local',
          'companion_id': 'gymbro',
          'payload': '{}',
          'updated_at': 2,
        }),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('trackia_chats'), hasLength(2));
      await db.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
