import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/chat_store.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixtures/trackia_v6_fixtures.dart';

/// FR-040 / SC-007: chats leave secure storage in two verified phases.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  const storage = FlutterSecureStorage();
  late Directory dir;
  late String path;
  late SqliteWorkoutRepository repo;
  late Directory media;
  final opened = <Database>[];
  final now = DateTime(2026, 10, 29, 9);

  final chatKey = companionStorageKey(
    'gymia.ai.chat.v1',
    LegacyChatFixture.profileId,
    LegacyChatFixture.companionId,
  );
  final archiveKey = companionStorageKey(
    'gymia.ai.archive.v1.${LegacyChatFixture.archiveId}',
    LegacyChatFixture.profileId,
    LegacyChatFixture.companionId,
  );

  /// A chat state like the one the app writes: the index lists the archive.
  Map<String, dynamic> legacyChat({String companion = 'gymbro'}) => {
    ...LegacyChatFixture.chat(),
    'archives': [
      {
        'id': LegacyChatFixture.archiveId,
        'title': 'Antiguo',
        'messageCount': 1,
      },
    ],
  };

  Future<ChatStore> store({
    String profile = LegacyChatFixture.profileId,
  }) async {
    final db = await databaseFactoryFfi.openDatabase(path);
    opened.add(db);
    return ChatStore(db, () => now, profile, mediaDirectory: media);
  }

  Future<void> seed({
    String profile = LegacyChatFixture.profileId,
    String companion = LegacyChatFixture.companionId,
    Map<String, dynamic>? chat,
    bool withArchive = true,
  }) async {
    final key = companionStorageKey('gymia.ai.chat.v1', profile, companion);
    final aKey = companionStorageKey(
      'gymia.ai.archive.v1.${LegacyChatFixture.archiveId}',
      profile,
      companion,
    );
    await storage.write(key: key, value: jsonEncode(chat ?? legacyChat()));
    if (withArchive) {
      await storage.write(
        key: aKey,
        value: jsonEncode(LegacyChatFixture.archive()),
      );
    }
  }

  Future<List<File>> mediaFiles() async => media.existsSync()
      ? media
            .listSync()
            .whereType<File>()
            .where((f) => !f.path.endsWith('.tmp'))
            .toList()
      : [];

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('trackia-chat-store-');
    path = '${dir.path}/test.sqlite';
    media = Directory('${dir.path}/trackia_media');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: path,
      clock: () => now,
    );
  });
  tearDown(() async {
    for (final db in opened) {
      await db.close();
    }
    opened.clear();
    await repo.close();
    await dir.delete(recursive: true);
  });

  final pngBytes = base64Decode(LegacyChatFixture.attachmentBase64);

  group('phase 1: copy and verify', () {
    test(
      'copies chat and archive, keeps order, verifies, leaves legacy keys',
      () async {
        await seed();
        final chats = await store();
        final result = await chats.migrate(storage, 'gymbro');
        expect(result.ok, isTrue);
        expect(result.chats, 1);
        expect(result.archives, 1);

        final info = (await chats.info('gymbro'))!;
        expect(info.verified, isTrue);
        expect(info.legacyKey, chatKey);

        final loaded = (await chats.loadActive('gymbro'))!;
        expect(jsonEncode(loaded), jsonEncode(legacyChat()));
        expect((loaded['messages'] as List).map((m) => (m as Map)['content']), [
          'Hola',
          'Preparado.',
        ]);
        final archive = (await chats.loadArchive(
          'gymbro',
          LegacyChatFixture.archiveId,
        ))!;
        expect(jsonEncode(archive), jsonEncode(LegacyChatFixture.archive()));

        // Phase 1 never deletes anything.
        expect(await storage.read(key: chatKey), isNotNull);
        expect(await storage.read(key: archiveKey), isNotNull);
      },
    );

    test(
      'attachments leave the JSON and are stored once by their hash',
      () async {
        final shared = {
          ...legacyChat(),
          'messages': [
            for (var i = 0; i < 3; i++)
              {
                'role': 'user',
                'content': 'foto $i',
                'attachment': {
                  'name': 'n$i.png',
                  'mime': 'image/png',
                  'bytes': LegacyChatFixture.attachmentBase64,
                },
              },
            {
              'role': 'user',
              'content': 'otra',
              'attachment': {
                'name': 'b.png',
                'mime': 'image/png',
                'bytes': base64Encode([9, 8, 7]),
              },
            },
          ],
        };
        await seed(chat: shared);
        final chats = await store();
        await chats.migrate(storage, 'gymbro');

        final names = (await mediaFiles())
            .map((f) => f.uri.pathSegments.last)
            .toSet();
        expect(names, {
          sha256.convert(pngBytes).toString(),
          sha256.convert([9, 8, 7]).toString(),
        });
        expect(
          await File('${media.path}/${sha256.convert(pngBytes)}').readAsBytes(),
          pngBytes,
        );
        // The stored row no longer carries the bytes.
        final db = opened.first;
        final row = (await db.query('trackia_chats')).single;
        expect(
          row['payload'] as String,
          isNot(contains(LegacyChatFixture.attachmentBase64)),
        );
        expect(
          row['payload'] as String,
          contains(sha256.convert(pngBytes).toString()),
        );
        // Reading puts them back exactly as the app expects them.
        final loaded = (await chats.loadActive('gymbro'))!;
        expect(jsonEncode(loaded), jsonEncode(shared));
      },
    );

    test(
      'a failure midway keeps the legacy chat and the retry is idempotent',
      () async {
        await seed();
        var chats = await store();
        chats.debugStep = (step) {
          if (step == 'row') throw StateError('disco lleno');
        };
        final failed = await chats.migrate(storage, 'gymbro');
        expect(failed.ok, isFalse);
        expect(await chats.info('gymbro'), isNull);
        expect(await storage.read(key: chatKey), isNotNull);
        // The media written before the failure is harmless and content-addressed.
        expect((await mediaFiles()), hasLength(1));

        chats = await store();
        expect((await chats.migrate(storage, 'gymbro')).ok, isTrue);
        expect((await chats.migrate(storage, 'gymbro')).ok, isTrue);
        expect(await opened.last.query('trackia_chats'), hasLength(1));
        expect(await opened.last.query('trackia_chat_archives'), hasLength(1));
        expect(await mediaFiles(), hasLength(1));
        expect((await chats.info('gymbro'))!.verified, isTrue);
      },
    );

    test('a copy that does not verify is never marked verified', () async {
      await seed();
      final chats = await store();
      chats.debugStep = (step) {
        // The attachment disappears between writing and verifying.
        if (step == 'verify') {
          for (final f in media.listSync()) {
            f.deleteSync();
          }
        }
      };
      final result = await chats.migrate(storage, 'gymbro');
      expect(result.ok, isFalse);
      expect((await chats.info('gymbro'))?.verified ?? false, isFalse);
      expect(await storage.read(key: chatKey), isNotNull);
      // Nothing may delete the legacy key of an unverified row.
      expect(await (await store()).finishMigration(storage, 'gymbro'), 0);
      expect(await storage.read(key: chatKey), isNotNull);
    });

    test('a corrupt legacy chat is reported, not lost', () async {
      await storage.write(key: chatKey, value: '{no es json');
      final chats = await store();
      final result = await chats.migrate(storage, 'gymbro');
      expect(result.ok, isFalse);
      expect(await storage.read(key: chatKey), '{no es json');
      expect(await opened.first.query('trackia_chats'), isEmpty);
    });

    test('with nothing to migrate it does nothing', () async {
      final chats = await store();
      final result = await chats.migrate(storage, 'gymbro');
      expect(result.ok, isTrue);
      expect([result.chats, result.archives], [0, 0]);
      expect(await chats.readActive(storage, 'gymbro'), isNull);
    });

    test('an archive missing from storage does not block the chat', () async {
      await seed(withArchive: false);
      final chats = await store();
      final result = await chats.migrate(storage, 'gymbro');
      expect(result.ok, isTrue);
      expect(result.archives, 0);
      expect(
        await chats.loadArchive('gymbro', LegacyChatFixture.archiveId),
        isNull,
      );
      expect(await chats.loadActive('gymbro'), isNotNull);
    });
  });

  group('phase 2: delete the old keys', () {
    test('only on the next launch, and only verified ones', () async {
      await seed();
      await seed(companion: 'enfoque');
      final launch1 = await store();
      // Opening migrates but must not delete in the same run.
      expect(await launch1.readActive(storage, 'gymbro'), isNotNull);
      expect(await launch1.readActive(storage, 'gymbro'), isNotNull);
      expect(await storage.read(key: chatKey), isNotNull);

      final launch2 = await store();
      expect(await launch2.readActive(storage, 'gymbro'), isNotNull);
      expect(await storage.read(key: chatKey), isNull);
      expect(await storage.read(key: archiveKey), isNull);
      // «enfoque» was never opened, so its legacy keys are untouched.
      expect(
        await storage.read(
          key: companionStorageKey('gymia.ai.chat.v1', 'local', 'enfoque'),
        ),
        isNotNull,
      );
      // And the data is still there from SQLite.
      final loaded = (await launch2.loadActive('gymbro'))!;
      expect(jsonEncode(loaded), jsonEncode(legacyChat()));
      expect((await launch2.info('gymbro'))!.legacyKey, isNull);
    });

    test('finishing twice deletes nothing more', () async {
      await seed();
      await (await store()).migrate(storage, 'gymbro');
      final next = await store();
      expect(await next.finishMigration(storage, 'gymbro'), 2);
      expect(await next.finishMigration(storage, 'gymbro'), 0);
    });
  });

  group('reading and writing', () {
    test(
      'SQLite wins over the legacy key; the legacy key is the fallback',
      () async {
        await seed();
        final chats = await store();
        // No row yet: the legacy content is returned (and migrated).
        final first = (await chats.readActive(storage, 'gymbro'))!;
        expect(first['sessionId'], 'session-1');
        // A newer version in SQLite is what is read from then on.
        await chats.saveActive('gymbro', {...first, 'sessionId': 'session-2'});
        expect(
          (await chats.readActive(storage, 'gymbro'))!['sessionId'],
          'session-2',
        );
      },
    );

    test(
      'a failed migration still lets the chat open from the old key',
      () async {
        await seed();
        final chats = await store();
        chats.debugStep = (step) {
          if (step == 'row') throw StateError('boom');
        };
        final state = (await chats.readActive(storage, 'gymbro'))!;
        expect(state['sessionId'], 'session-1');
      },
    );

    test(
      'saving after migration never writes the secure storage again',
      () async {
        final chats = await store();
        await chats.saveActive('gymbro', {
          'sessionId': 's',
          'messages': <Object>[],
        });
        expect(await storage.read(key: chatKey), isNull);
        expect((await chats.loadActive('gymbro'))!['sessionId'], 's');
      },
    );

    test('archiving writes archive and active chat together', () async {
      final chats = await store();
      await chats.saveArchiveAndActive(
        'gymbro',
        'a1',
        {
          'id': 'a1',
          'messages': [
            {'role': 'user', 'content': 'x'},
          ],
        },
        {'sessionId': 'nueva', 'messages': <Object>[]},
      );
      expect((await chats.loadActive('gymbro'))!['sessionId'], 'nueva');
      expect((await chats.loadArchive('gymbro', 'a1'))!['id'], 'a1');
    });

    test('an archive id that is not safe is refused', () async {
      final chats = await store();
      await expectLater(
        chats.loadArchive('gymbro', '../x'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('isolation', () {
    test('profiles and companions never see each other\'s chats', () async {
      await seed(profile: 'local');
      await seed(
        profile: 'otro',
        chat: {...legacyChat(), 'sessionId': 'de-otro'},
      );
      await seed(
        companion: 'enfoque',
        chat: {...legacyChat(), 'sessionId': 'enfoque'},
      );
      final mine = await store();
      final theirs = await store(profile: 'otro');
      await mine.migrate(storage, 'gymbro');
      await mine.migrate(storage, 'enfoque');
      await theirs.migrate(storage, 'gymbro');

      expect((await mine.loadActive('gymbro'))!['sessionId'], 'session-1');
      expect((await theirs.loadActive('gymbro'))!['sessionId'], 'de-otro');
      expect((await mine.loadActive('enfoque'))!['sessionId'], 'enfoque');
      expect(await theirs.loadActive('enfoque'), isNull);
      // An archive id of another profile or companion is not readable.
      expect(
        await theirs.loadArchive('enfoque', LegacyChatFixture.archiveId),
        isNull,
      );
      expect(
        await mine.loadArchive('calma', LegacyChatFixture.archiveId),
        isNull,
      );
    });

    test(
      'deleting a companion removes its chats and only its orphan files',
      () async {
        await seed();
        final other = {
          ...legacyChat(),
          'messages': [
            {
              'role': 'user',
              'content': 'solo mío',
              'attachment': {
                'name': 'u.png',
                'mime': 'image/png',
                'bytes': base64Encode([5, 5, 5]),
              },
            },
          ],
        };
        await seed(companion: 'enfoque', chat: other);
        final chats = await store();
        await chats.migrate(storage, 'gymbro');
        await chats.migrate(storage, 'enfoque');
        expect(await mediaFiles(), hasLength(2));

        await chats.deleteCompanion('enfoque');
        expect(await chats.loadActive('enfoque'), isNull);
        expect(await chats.gcMedia(), 1);
        expect(await mediaFiles(), hasLength(1));
        // The other companion keeps its attachment.
        expect(
          jsonEncode((await chats.loadActive('gymbro'))!),
          jsonEncode(legacyChat()),
        );
      },
    );
  });

  test('the media directory is created on demand', () async {
    expect(media.existsSync(), isFalse);
    final chats = await store();
    await chats.saveActive('gymbro', {
      'messages': [
        {
          'role': 'user',
          'content': 'x',
          'attachment': {
            'name': 'a.png',
            'mime': 'image/png',
            'bytes': base64Encode(Uint8List.fromList([1, 2, 3])),
          },
        },
      ],
    });
    expect(media.existsSync(), isTrue);
    expect(await mediaFiles(), hasLength(1));
  });
}
