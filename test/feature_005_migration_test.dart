import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/data/chat_store.dart';

import 'fixtures/trackia_v6_fixtures.dart';
import 'fixtures/feature_005_v6_schema.dart';

void main() {
  sqfliteFfiInit();

  test(
    'experimental snapshot restores WAL database and chat attachment',
    () async {
      final dir = await Directory.systemTemp.createTemp('trackia-snapshot-');
      final path = '${dir.path}/source.sqlite';
      try {
        await TrackiaV5Fixture.create(factory: databaseFactoryFfi, path: path);
        final db = await databaseFactoryFfi.openDatabase(path);
        await createSyntheticV6Tables(db);
        await db.setVersion(6);
        await db.execute('PRAGMA journal_mode=WAL');
        final store = ChatStore(db, DateTime.now, 'local');
        final chat =
            LegacyChatFixture.chat()
              ..['metadata'] = {
                'media': 'ordinary value',
                'name': 'not an attachment',
              };
        await store.saveArchiveAndActive(
          'gymbro',
          'archive-1',
          LegacyChatFixture.archive(),
          chat,
        );
        await db.rawUpdate('UPDATE trackia_chats SET rowid = ?', [
          -9223372036854775808,
        ]);
        final snapshot = await createExperimentalRecoverySnapshot(
          db,
          Directory('${dir.path}/snapshot'),
        );
        final restored = await databaseFactoryFfi.openDatabase(
          '${snapshot.path}/database.sqlite',
        );
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
        );
        for (final table in tables) {
          final name = table['name'] as String;
          expect(
            await restored.query(name),
            await db.query(name),
            reason: name,
          );
        }
        expect(
          (await restored.rawQuery(
            'SELECT rowid FROM trackia_chats',
          )).single.values.single,
          -9223372036854775808,
        );
        expect(await restored.getVersion(), 6);
        expect(
          (await restored.rawQuery(
            'PRAGMA integrity_check',
          )).single.values.single,
          'ok',
        );
        final restoredStore = ChatStore(
          restored,
          DateTime.now,
          'local',
          mediaDirectory: Directory('${snapshot.path}/trackia_media'),
        );
        expect(await restoredStore.loadActive('gymbro'), chat);
        expect(
          await restoredStore.loadArchive('gymbro', 'archive-1'),
          LegacyChatFixture.archive(),
        );
        await restored.close();
        final media = Directory('${dir.path}/trackia_media');
        final attachment =
            (await media.list().where((e) => e is File).first) as File;
        await attachment.writeAsString('corrupt');
        final failed = Directory('${dir.path}/failed-snapshot');
        await expectLater(
          createExperimentalRecoverySnapshot(db, failed),
          throwsStateError,
        );
        expect(await failed.exists(), isFalse);
        expect(await Directory('${failed.path}.pending').exists(), isFalse);
        await attachment.delete();
        final missing = Directory('${dir.path}/missing-snapshot');
        await expectLater(
          createExperimentalRecoverySnapshot(db, missing),
          throwsA(isA<FileSystemException>()),
        );
        expect(await missing.exists(), isFalse);
        expect(await Directory('${missing.path}.pending').exists(), isFalse);
        expect(await File('${snapshot.path}/database.sqlite').exists(), isTrue);
        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'experimental snapshot handles large payload and external attachment',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'trackia-snapshot-large-',
      );
      final path = '${dir.path}/source.sqlite';
      try {
        await TrackiaV5Fixture.create(factory: databaseFactoryFfi, path: path);
        final db = await databaseFactoryFfi.openDatabase(path);
        await createSyntheticV6Tables(db);
        await db.setVersion(6);
        final bytes = Uint8List.fromList(
          List<int>.generate(4 * 1024 * 1024, (i) => i % 251),
        );
        final chat = <String, dynamic>{
          'padding': 'x' * (3 * 1024 * 1024),
          ...LegacyChatFixture.chat(),
        };
        chat['large'] = {
          'name': 'large.bin',
          'mime': 'application/octet-stream',
          'bytes': base64Encode(bytes),
        };
        final store = ChatStore(db, DateTime.now, 'local');
        await store.saveArchiveAndActive(
          'gymbro',
          'archive-1',
          LegacyChatFixture.archive(),
          chat,
        );
        final firstPosition =
            (await db.rawQuery(
                  'SELECT instr(payload, ?) AS position FROM trackia_chats',
                  ['"media"'],
                )).single['position']
                as int;
        final shift = (65532 - (firstPosition - 1) % 65536) % 65536;
        chat['padding'] = '${chat['padding']}${'x' * shift}';
        await store.saveActive('gymbro', chat);
        final adjustedPosition =
            (await db.rawQuery(
                  'SELECT instr(payload, ?) AS position FROM trackia_chats',
                  ['"media"'],
                )).single['position']
                as int;
        expect((adjustedPosition - 1) % 65536, 65532);
        final snapshot = await createExperimentalRecoverySnapshot(
          db,
          Directory('${dir.path}/snapshot'),
        );
        final restored = await databaseFactoryFfi.openDatabase(
          '${snapshot.path}/database.sqlite',
        );
        final restoredStore = ChatStore(
          restored,
          DateTime.now,
          'local',
          mediaDirectory: Directory('${snapshot.path}/trackia_media'),
        );
        expect(await restoredStore.loadActive('gymbro'), chat);
        final copied = File(
          '${snapshot.path}/trackia_media/${ChatStore.hashOf(bytes)}',
        );
        expect(await copied.length(), bytes.length);
        await copied.writeAsString('broken');
        await expectLater(restoredStore.loadActive('gymbro'), throwsStateError);
        await restored.close();
        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'snapshot, media writer and GC serialize on the shared directory lock',
    () async {
      final dir = await Directory.systemTemp.createTemp('trackia-lock-');
      try {
        final path = '${dir.path}/source.sqlite';
        await TrackiaV5Fixture.create(factory: databaseFactoryFfi, path: path);
        final db = await databaseFactoryFfi.openDatabase(path);
        await createSyntheticV6Tables(db);
        await db.setVersion(6);
        final media = Directory('${dir.path}/trackia_media');
        final store = ChatStore(db, DateTime.now, 'local');
        final before = LegacyChatFixture.chat();
        await store.saveActive('gymbro', before);
        final entered = Completer<void>();
        final release = Completer<void>();
        final blocker = ChatStore.withMediaLock(media, () async {
          entered.complete();
          await release.future;
        });
        await entered.future;
        var snapshotDone = false;
        var writeDone = false;
        var gcDone = false;
        final snapshot = createExperimentalRecoverySnapshot(
          db,
          Directory('${dir.path}/snapshot'),
        ).then((value) {
          snapshotDone = true;
          return value;
        });
        final after = LegacyChatFixture.chat()..['carryForward'] = 'later';
        final write = store
            .saveActive('gymbro', after)
            .then((_) => writeDone = true);
        final gc = store.gcMedia().then((_) => gcDone = true);
        await Future<void>.delayed(Duration.zero);
        expect([snapshotDone, writeDone, gcDone], [false, false, false]);
        release.complete();
        await blocker;
        final folder = await snapshot;
        await write;
        await gc;
        final restored = await databaseFactoryFfi.openDatabase(
          '${folder.path}/database.sqlite',
        );
        final snapshotStore = ChatStore(
          restored,
          DateTime.now,
          'local',
          mediaDirectory: Directory('${folder.path}/trackia_media'),
        );
        expect(await snapshotStore.loadActive('gymbro'), before);
        expect(await store.loadActive('gymbro'), after);
        await restored.close();
        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'v6 snapshot restores all tables and attachment, then upgrade is repeatable',
    () async {
      final dir = await Directory.systemTemp.createTemp('trackia-v7-');
      final path = '${dir.path}/source.sqlite';
      try {
        await TrackiaV5Fixture.create(factory: databaseFactoryFfi, path: path);
        final v6 = await databaseFactoryFfi.openDatabase(path);
        await createSyntheticV6Tables(v6);
        await v6.setVersion(6);
        await v6.insert('trackia_spaces', {
          'id': 'gym',
          'profile_id': 'local',
          'name': 'Gimnasio',
          'revision': 1,
        });
        await v6.execute(
          "INSERT INTO trackia_legacy_workout_scope SELECT id, 'local', 'gym' FROM workouts",
        );
        await v6.execute(
          "INSERT INTO trackia_legacy_activity_scope SELECT id, 'local', 'gym' FROM activities",
        );
        // This fixture must describe the actual pre-upgrade schema.
        expect(await v6.getVersion(), 6);
        await v6.insert('trackia_goals', {
          'id': 'goal-1',
          'profile_id': 'local',
          'companion_id': 'gymbro',
          'metric': 'count',
          'period': 'day',
          'target': 3.0,
          'origin': 'user',
          'created_at': 123,
        });
        final media = Directory('${dir.path}/trackia_media');
        final store = ChatStore(
          v6,
          () => DateTime.fromMillisecondsSinceEpoch(123),
          'local',
          mediaDirectory: media,
        );
        await store.saveArchiveAndActive(
          'gymbro',
          'archive-1',
          LegacyChatFixture.archive(),
          LegacyChatFixture.chat(),
        );
        final names =
            (await v6.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
              )).map((row) => row['name'] as String).toList()
              ..sort();
        final before = <String, List<Map<String, Object?>>>{};
        for (final name in names) {
          before[name] = await v6.query(name);
        }
        await v6.close();

        final migrated = await SqliteWorkoutRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        await migrated.close();
        final current = await databaseFactoryFfi.openDatabase(path);
        expect(await current.getVersion(), 7);
        for (final name in names) {
          expect(await current.query(name), before[name], reason: name);
        }
        await current.close();

        final backup = File('$path.pre-trackia-v7.sqlite');
        expect(await backup.exists(), isTrue);
        final restoredPath = '${dir.path}/restored.sqlite';
        await backup.copy(restoredPath);
        final restored = await databaseFactoryFfi.openDatabase(restoredPath);
        expect(await restored.getVersion(), 6);
        expect(
          (await restored.rawQuery(
            'PRAGMA integrity_check',
          )).single.values.single,
          'ok',
        );
        for (final name in names) {
          expect(
            await restored.query(name),
            before[name],
            reason: 'restore $name',
          );
        }
        // Read from the snapshot's own media copy, not the source directory.
        final restoredStore = ChatStore(
          restored,
          DateTime.now,
          'local',
          mediaDirectory: Directory('$path.pre-trackia-v7.media'),
        );
        expect(
          await restoredStore.loadActive('gymbro'),
          LegacyChatFixture.chat(),
        );
        expect(
          await restoredStore.loadArchive('gymbro', 'archive-1'),
          LegacyChatFixture.archive(),
        );
        await restored.close();
        final repeated = await SqliteWorkoutRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        await repeated.close();
        expect(
          dir.listSync().where((f) => f.path.contains('pre-trackia-v7.sqlite')),
          hasLength(1),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'a failed recovery copy blocks the upgrade and leaves the database unchanged',
    () async {
      final dir = await Directory.systemTemp.createTemp('trackia-v7-fail-');
      final path = '${dir.path}/source.sqlite';
      try {
        await TrackiaV5Fixture.create(factory: databaseFactoryFfi, path: path);
        final db = await databaseFactoryFfi.openDatabase(path);
        await createSyntheticV6Tables(db);
        await db.setVersion(6);
        final chat = LegacyChatFixture.chat();
        await ChatStore(db, DateTime.now, 'local')
            .saveActive('gymbro', chat);
        final chatsBefore = await db.query(
          'trackia_chats',
          where: 'companion_id = ?',
          whereArgs: ['gymbro'],
        );
        expect(chatsBefore, hasLength(1));
        await db.close();

        // A source media file that fails verification must abort the whole
        // upgrade: no backup is published and the database keeps its version.
        final mediaFiles =
            (await Directory('${dir.path}/trackia_media').list()
                    .where((e) => e is File)
                    .toList())
                .cast<File>();
        expect(mediaFiles, hasLength(1));
        await mediaFiles.single.writeAsString('corrupt');
        await expectLater(
          SqliteWorkoutRepository.open(factory: databaseFactoryFfi, path: path),
          throwsStateError,
        );
        expect(await File('$path.pre-trackia-v7.sqlite').exists(), isFalse);
        expect(
          await Directory('$path.pre-trackia-v7.sqlite.snapshot').exists(),
          isFalse,
        );
        final check = await databaseFactoryFfi.openDatabase(path);
        expect(await check.getVersion(), 6);
        expect(
          await check.query(
            'trackia_chats',
            where: 'companion_id = ?',
            whereArgs: ['gymbro'],
          ),
          chatsBefore,
        );
        await check.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'a retry after an interrupted upgrade keeps the first copy and adds a sibling',
    () async {
      final dir = await Directory.systemTemp.createTemp('trackia-v7-retry-');
      final path = '${dir.path}/source.sqlite';
      try {
        await TrackiaV5Fixture.create(factory: databaseFactoryFfi, path: path);
        final db = await databaseFactoryFfi.openDatabase(path);
        await createSyntheticV6Tables(db);
        await db.setVersion(6);
        final chat = LegacyChatFixture.chat();
        final media = Directory('${dir.path}/trackia_media');
        await ChatStore(db, DateTime.now, 'local', mediaDirectory: media)
            .saveArchiveAndActive(
          'gymbro',
          'archive-1',
          LegacyChatFixture.archive(),
          chat,
        );

        await createTrackiaV7Backup(db, path);
        expect(await File('$path.pre-trackia-v7.sqlite').exists(), isTrue);

        // Retry while the upgrade did not finish: the first valid copy stays.
        await createTrackiaV7Backup(db, path);
        final siblings =
            dir.listSync().where((f) => f.path.contains('pre-trackia-v7.sqlite'));
        expect(siblings, hasLength(2));
        expect(
          siblings.every((f) => (f as File).lengthSync() > 0),
          isTrue,
        );
        expect(
          await Directory('$path.pre-trackia-v7.sqlite.snapshot').exists(),
          isFalse,
        );
        final siblingPath = siblings
            .map((f) => f.path)
            .where((p) => p != '$path.pre-trackia-v7.sqlite')
            .single;

        for (final backupPath in ['$path.pre-trackia-v7.sqlite', siblingPath]) {
          final backupDb = await databaseFactoryFfi.openDatabase(backupPath);
          final store = ChatStore(
            backupDb,
            DateTime.now,
            'local',
            mediaDirectory: Directory('$path.pre-trackia-v7.media'),
          );
          expect(await store.loadActive('gymbro'), chat);
          expect(
            await store.loadArchive('gymbro', 'archive-1'),
            LegacyChatFixture.archive(),
          );
          await backupDb.close();
        }

        // Interrupted attempts leave staging residue only: every stale
        // staging directory is cleaned, and published copies are preserved.
        await Directory('$siblingPath.snapshot').create(recursive: true);
        await File('$siblingPath.snapshot/database.sqlite')
            .writeAsString('unverified');
        await createTrackiaV7Backup(db, path);
        expect(
          await Directory('$siblingPath.snapshot').exists(),
          isFalse,
        );
        final survivors =
            dir.listSync().where((f) => f.path.contains('pre-trackia-v7.sqlite'));
        expect(survivors, hasLength(3));
        expect(
          survivors.every((f) => (f as File).lengthSync() > 0),
          isTrue,
        );
        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
