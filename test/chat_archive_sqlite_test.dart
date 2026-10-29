import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/data/ai_client.dart';
import 'package:gymia/data/chat_archive_store.dart';
import 'package:gymia/data/chat_store.dart';
import 'package:gymia/domain/workout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixtures/trackia_v6_fixtures.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';

/// The same guarantees as test/chat_archive_store_test.dart, on the SQLite store.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late String path;
  late SqliteWorkoutRepository repo;
  final opened = <Database>[];

  final messages = [
    AiMessage(
      'user',
      'Original 👋',
      attachment: AiAttachment(
        name: 'photo.png',
        mime: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    ).forStorage(),
    const AiMessage('assistant', 'Respuesta original').forStorage(),
  ];
  final state = {
    'sessionId': 'old-session',
    'messages': messages,
    'pending': null,
  };

  Future<ChatStore> chats({String profile = 'local'}) async {
    final db = await databaseFactoryFfi.openDatabase(path);
    opened.add(db);
    return ChatStore(db, () => DateTime(2026, 10, 29), profile);
  }

  Future<ChatArchiveStore> archiveStore(
    ChatStore store, {
    String profile = 'local',
    String companion = 'gymbro',
  }) async {
    final archive = ChatArchiveStore(
      profileId: profile,
      companionId: companion,
      chats: store,
    );
    await store.saveActive(companion, state);
    return archive;
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('trackia-archive-sqlite-');
    path = '${dir.path}/test.sqlite';
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: path,
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

  Future<Map<String, dynamic>> doArchive(ChatArchiveStore store) =>
      store.archive(
        state: state,
        transcript: messages,
        activityMessageIds: ['activity-message'],
        title: 'Prueba',
        summary: 'Resumen',
        reason: 'manual',
        automatic: false,
      );

  test(
    'archive is complete, rotates the session and keeps the attachment',
    () async {
      final store = await chats();
      final archive = await archiveStore(store);
      final next = await doArchive(archive);

      expect(next['sessionId'], isNot('old-session'));
      expect(next['messages'], isEmpty);
      expect(next['carryForward'], 'Resumen');
      final id = ChatArchiveStore.index(next).single['id'] as String;

      // The active chat in the database is the new one.
      expect(
        (await store.loadActive('gymbro'))!['sessionId'],
        next['sessionId'],
      );
      final read = await archive.read(id);
      expect(read['messages'], messages);
      expect(read['activityMessageIds'], ['activity-message']);
      expect(read['sourceSessionId'], 'old-session');
      expect(
        (read['messages'] as List).first['attachment']['bytes'],
        base64Encode([1, 2, 3]),
      );
    },
  );

  test('another profile or companion cannot read the archive', () async {
    final store = await chats();
    final archive = await archiveStore(store);
    final id =
        ChatArchiveStore.index(await doArchive(archive)).single['id'] as String;
    final other = await chats(profile: 'otro');
    await expectLater(
      ChatArchiveStore(profileId: 'otro', chats: other).read(id),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      ChatArchiveStore(
        profileId: 'local',
        companionId: 'enfoque',
        chats: store,
      ).read(id),
      throwsA(isA<ValidationException>()),
    );
  });

  test('a failure between archive and active chat changes nothing', () async {
    final store = await chats();
    final archive = await archiveStore(store);
    store.debugStep = (step) {
      if (step == 'archive') throw StateError('disk full');
    };
    await expectLater(doArchive(archive), throwsA(isA<StateError>()));
    store.debugStep = null;

    final active = (await store.loadActive('gymbro'))!;
    expect(active['sessionId'], 'old-session');
    expect(active['messages'], messages);
    expect(await opened.first.query('trackia_chat_archives'), isEmpty);
    // And archiving can simply be retried.
    final next = await doArchive(archive);
    expect(ChatArchiveStore.index(next), hasLength(1));
  });

  test(
    'archiving refuses a chat that changed or has a pending message',
    () async {
      final store = await chats();
      final archive = await archiveStore(store);
      await expectLater(
        archive.archive(
          state: {...state, 'pending': 'sin responder'},
          transcript: messages,
          activityMessageIds: const [],
          title: 't',
          summary: 's',
          reason: 'r',
          automatic: false,
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        archive.archive(
          state: {...state, 'sessionId': 'otra'},
          transcript: messages,
          activityMessageIds: const [],
          title: 't',
          summary: 's',
          reason: 'r',
          automatic: false,
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test('excerpt pages through an archive stored in SQLite', () async {
    final store = await chats();
    final archive = await archiveStore(store);
    final id =
        ChatArchiveStore.index(await doArchive(archive)).single['id'] as String;
    final page = await archive.excerpt(id);
    expect(page['totalMessages'], 2);
    expect(page['hasMore'], isFalse);
    expect((page['messages'] as List).map((m) => m['content']), [
      'Original 👋',
      'Respuesta original',
    ]);
  });

  test(
    'an archive of the old keys still opens before it is migrated',
    () async {
      final store = await chats();
      final archive = ChatArchiveStore(profileId: 'local', chats: store);
      final old = {
        ...LegacyChatFixture.chat(),
        'archives': [
          {'id': LegacyChatFixture.archiveId},
        ],
      };
      FlutterSecureStorage.setMockInitialValues({
        archive.activeKey: jsonEncode(old),
        'gymia.ai.archive.v1.${LegacyChatFixture.archiveId}': jsonEncode(
          LegacyChatFixture.archive(),
        ),
      });
      final read = await archive.read(LegacyChatFixture.archiveId);
      expect(read['id'], LegacyChatFixture.archiveId);
    },
  );
}
