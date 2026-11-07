import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/data/feature_scope.dart';
import 'package:trackia/data/message_revision_repository.dart';
import 'package:trackia/domain/message_revision.dart';
import 'package:trackia/domain/workout.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late Database db;
  late MessageRevisionRepository repo;
  final scope = FeatureScope(
    profileId: 'profile-a',
    companionId: 'companion-a',
  );
  final time = DateTime.utc(2026, 11, 5);
  Message message() => Message(
    id: 'message-a',
    profileId: scope.profileId,
    companionId: scope.companionId,
    chatId: 'chat-a',
    createdAt: time,
    currentRevisionId: 'revision-a',
    attachmentRefs: ['media-ref'],
  );
  MessageRevision version(
    String id,
    int number,
    String text, {
    String? previous,
  }) => MessageRevision(
    id: id,
    messageId: 'message-a',
    revision: number,
    text: text,
    createdAt: time,
    supersedesId: previous,
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('trackia-revisions-');
    db = await databaseFactoryFfi.openDatabase('${dir.path}/test.sqlite');
    await db.execute('PRAGMA foreign_keys = ON');
    // Provisional test schema only. No production migration is installed.
    await db.execute('''CREATE TABLE message_revision_messages (
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, id TEXT NOT NULL,
      chat_id TEXT NOT NULL, created_at INTEGER NOT NULL, current_revision_id TEXT NOT NULL,
      delivery TEXT NOT NULL, attachment_refs TEXT NOT NULL,
      PRIMARY KEY(profile_id, companion_id, id))''');
    await db.execute('''CREATE TABLE message_revision_versions (
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, id TEXT NOT NULL,
      message_id TEXT NOT NULL, revision INTEGER NOT NULL, text TEXT NOT NULL,
      created_at INTEGER NOT NULL, supersedes_id TEXT,
      PRIMARY KEY(profile_id, companion_id, id),
      UNIQUE(profile_id, companion_id, message_id, revision),
      FOREIGN KEY(profile_id, companion_id, message_id)
        REFERENCES message_revision_messages(profile_id, companion_id, id))''');
    repo = MessageRevisionRepository(db, scope);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test(
    'persists ordered immutable revisions and attachment references after reopen',
    () async {
      await repo.create(message(), version('revision-a', 1, 'x' * 8000));
      await repo.append(
        'message-a',
        expectedRevisionId: 'revision-a',
        revision: version(
          'revision-b',
          2,
          'corrección',
          previous: 'revision-a',
        ),
      );
      await db.close();
      db = await databaseFactoryFfi.openDatabase('${dir.path}/test.sqlite');
      repo = MessageRevisionRepository(db, scope);
      final loaded = (await repo.load('message-a'))!;
      expect(loaded.message.currentRevisionId, 'revision-b');
      expect(loaded.message.attachmentRefs, ['media-ref']);
      expect(loaded.revisions.map((r) => r.text), ['x' * 8000, 'corrección']);
      expect(loaded.revisions.last.supersedesId, 'revision-a');
    },
  );

  test(
    'stale, invalid and cross-scope updates leave no extra revision',
    () async {
      await repo.create(message(), version('revision-a', 1, 'original'));
      await repo.append(
        'message-a',
        expectedRevisionId: 'revision-a',
        revision: version('revision-b', 2, 'actual', previous: 'revision-a'),
      );
      await expectLater(
        repo.append(
          'message-a',
          expectedRevisionId: 'revision-a',
          revision: version(
            'revision-c',
            2,
            'obsoleta',
            previous: 'revision-a',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.append(
          'message-a',
          expectedRevisionId: 'revision-b',
          revision: version('revision-c', 4, 'salto', previous: 'revision-b'),
        ),
        throwsA(isA<ValidationException>()),
      );
      final other = MessageRevisionRepository(
        db,
        FeatureScope(profileId: 'profile-b', companionId: 'companion-a'),
      );
      expect(await other.load('message-a'), isNull);
      await expectLater(
        other.append(
          'message-a',
          expectedRevisionId: 'revision-b',
          revision: version('revision-c', 3, 'ajeno', previous: 'revision-b'),
        ),
        throwsA(isA<ValidationException>()),
      );
      final loaded = (await repo.load('message-a'))!;
      expect(loaded.message.currentRevisionId, 'revision-b');
      expect(loaded.revisions.map((r) => r.text), ['original', 'actual']);
    },
  );

  test('a duplicate revision id rolls back the current revision', () async {
    await repo.create(message(), version('revision-a', 1, 'original'));
    await expectLater(
      repo.append(
        'message-a',
        expectedRevisionId: 'revision-a',
        revision: version('revision-a', 2, 'duplicado', previous: 'revision-a'),
      ),
      throwsA(anything),
    );
    final loaded = (await repo.load('message-a'))!;
    expect(loaded.message.currentRevisionId, 'revision-a');
    expect(loaded.revisions, hasLength(1));
  });

  test(
    'cancelling an edit (nothing appended) keeps the original and its attachment',
    () async {
      await repo.create(message(), version('revision-a', 1, 'original'));
      // El usuario abre el editor y cancela: no se llama a append().
      final loaded = (await repo.load('message-a'))!;
      expect(loaded.revisions, hasLength(1));
      expect(loaded.revisions.single.text, 'original');
      expect(loaded.message.currentRevisionId, 'revision-a');
      expect(loaded.message.attachmentRefs, ['media-ref']);
      // Un reinicio posterior sigue viendo solo la versión original.
      await db.close();
      db = await databaseFactoryFfi.openDatabase('${dir.path}/test.sqlite');
      repo = MessageRevisionRepository(db, scope);
      expect((await repo.load('message-a'))!.revisions, hasLength(1));
    },
  );
}
