import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trackia/data/chat_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('experimental snapshot restores WAL and media on Android', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp(
        'trackia-android-snapshot-',
      );
      Database? db;
      Database? restored;
      try {
        db = await openDatabase(
          '${dir.path}/source.sqlite',
          singleInstance: false,
        );
        await db.execute(
          'CREATE TABLE trackia_chats (profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, payload TEXT NOT NULL, updated_at INTEGER NOT NULL, PRIMARY KEY(profile_id, companion_id))',
        );
        await db.execute(
          'CREATE TABLE trackia_chat_archives (id TEXT PRIMARY KEY, profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, payload TEXT NOT NULL, created_at INTEGER NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE synthetic (id INTEGER PRIMARY KEY, value TEXT NOT NULL)',
        );
        await db.execute('CREATE INDEX synthetic_value ON synthetic(value)');
        await db.setVersion(6);
        final mode = await db.rawQuery('PRAGMA journal_mode=WAL');
        expect(mode.single.values.single.toString().toLowerCase(), 'wal');
        await db.insert('synthetic', {'id': 42, 'value': 'wal-data'});
        final bytes = Uint8List.fromList(
          List.generate(3 * 1024 * 1024, (i) => i % 251),
        );
        final chat = {
          'messages': [
            {
              'role': 'user',
              'content': 'synthetic',
              'attachment': {
                'name': 'large.bin',
                'mime': 'application/octet-stream',
                'bytes': base64Encode(bytes),
              },
            },
          ],
        };
        final archive = {'id': 'archive', 'messages': <Object>[]};
        final store = ChatStore(db, DateTime.now, 'local');
        await store.saveArchiveAndActive('companion', 'archive', archive, chat);
        final snapshot = await createExperimentalRecoverySnapshot(
          db,
          Directory('${dir.path}/snapshot'),
        );
        restored = await openDatabase(
          '${snapshot.path}/database.sqlite',
          singleInstance: false,
        );
        expect(await restored.getVersion(), 6);
        expect(
          (await restored.rawQuery(
            'PRAGMA integrity_check',
          )).single.values.single,
          'ok',
        );
        expect((await restored.query('synthetic')).single['value'], 'wal-data');
        expect(
          (await restored.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='index' AND name='synthetic_value'",
          )).length,
          1,
        );
        final copy = ChatStore(
          restored,
          DateTime.now,
          'local',
          mediaDirectory: Directory('${snapshot.path}/trackia_media'),
        );
        expect(await copy.loadActive('companion'), chat);
        expect(await copy.loadArchive('companion', 'archive'), archive);
        final sourceMedia = File(
          '${dir.path}/trackia_media/${ChatStore.hashOf(bytes)}',
        );
        await sourceMedia.writeAsString('damaged');
        await expectLater(
          createExperimentalRecoverySnapshot(
            db,
            Directory('${dir.path}/failed'),
          ),
          throwsStateError,
        );
        expect(await Directory('${dir.path}/failed').exists(), isFalse);
        expect(await Directory('${dir.path}/failed.pending').exists(), isFalse);
      } finally {
        await restored?.close();
        await db?.close();
        await dir.delete(recursive: true);
      }
    });
  });
}
