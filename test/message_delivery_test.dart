import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/application/message_delivery.dart';
import 'package:trackia/data/feature_scope.dart';
import 'package:trackia/data/message_revision_repository.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/message_effect.dart';
import 'package:trackia/domain/message_revision.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String path;
  late Database? database;
  final scope = FeatureScope(
    profileId: 'profile-a',
    companionId: 'companion-a',
  );
  final instant = DateTime.utc(2026, 11, 6, 10);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('trackia-delivery-');
    path = '${directory.path}/delivery.sqlite';
    final migrated = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: path,
      profileId: scope.profileId,
    );
    await migrated.close();
    database = null;
  });

  tearDown(() async {
    await database?.close();
    await directory.delete(recursive: true);
  });

  Future<MessageRevisionRepository> reopen() async {
    await database?.close();
    database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    return MessageRevisionRepository(database!, scope);
  }

  Future<void> create(
    MessageRevisionRepository repo,
    String id, {
    String? chatId,
    String? companionId,
    DateTime? createdAt,
    String? text,
    List<String> attachments = const [],
  }) async {
    final revisionId = 'revision-$id';
    final message = Message(
      id: id,
      profileId: scope.profileId,
      companionId: companionId ?? scope.companionId,
      chatId: chatId ?? 'chat-a',
      createdAt: createdAt ?? instant,
      currentRevisionId: revisionId,
      attachmentRefs: attachments,
    );
    final target = companionId == null || companionId == scope.companionId
        ? repo
        : MessageRevisionRepository(
            database!,
            FeatureScope(
              profileId: scope.profileId,
              companionId: companionId,
            ),
          );
    await target.create(
      message,
      MessageRevision(
        id: revisionId,
        messageId: id,
        revision: 1,
        text: text ?? 'texto $id',
        createdAt: createdAt ?? instant,
      ),
    );
  }

  test('pending queue survives reopen in stable order with origin and media', () async {
    var repo = await reopen();
    await create(
      repo,
      'message-b',
      createdAt: instant,
      attachments: const ['sha256-fixture-b'],
    );
    await create(repo, 'message-a', createdAt: instant);
    await create(
      repo,
      'message-later',
      chatId: 'chat-b',
      createdAt: instant.add(const Duration(seconds: 1)),
    );
    await create(
      repo,
      'message-a',
      companionId: 'companion-b',
      text: 'otro acompañante',
    );

    repo = await reopen();
    final queue = await repo.queue('chat-a');
    expect(queue.map((item) => item.message.id), ['message-a', 'message-b']);
    expect(queue.map((item) => item.message.chatId), ['chat-a', 'chat-a']);
    expect(
      queue.map((item) => item.message.companionId),
      [scope.companionId, scope.companionId],
    );
    expect(queue.last.message.attachmentRefs, ['sha256-fixture-b']);
    expect(queue.map((item) => item.revision.text), ['texto message-a', 'texto message-b']);
  });

  test('answer and late answer are idempotent for the same message ID', () async {
    var repo = await reopen();
    await create(repo, 'message-a');
    await create(repo, 'message-late');
    var attempt = await repo.beginAttempt(
      'message-a',
      expectedRevisionId: 'revision-message-a',
    );
    expect(attempt, isNotNull);
    expect(
      await repo.recordAnswer(
        'message-a',
        expectedRevisionId: 'revision-message-a',
      ),
      MessageAnswerStatus.recorded,
    );
    expect(
      await repo.recordAnswer(
        'message-a',
        expectedRevisionId: 'revision-message-a',
      ),
      MessageAnswerStatus.duplicate,
    );

    attempt = await repo.beginAttempt(
      'message-late',
      expectedRevisionId: 'revision-message-late',
    );
    expect(attempt!.message.delivery, MessageDelivery.sending);
    repo = await reopen();
    final delivery = MessageDeliveryService(repo);
    expect(await delivery.openScope(chatId: 'chat-a'), 1);
    expect(
      await repo.recordAnswer(
        'message-late',
        expectedRevisionId: 'revision-message-late',
      ),
      MessageAnswerStatus.recorded,
    );
    expect(
      await repo.recordAnswer(
        'message-late',
        expectedRevisionId: 'revision-message-late',
      ),
      MessageAnswerStatus.duplicate,
    );
    expect((await repo.load('message-a'))!.message.delivery, MessageDelivery.answered);
    expect((await repo.load('message-late'))!.message.delivery, MessageDelivery.answered);
  });

  test('confirmed rejection retries but interrupted sending never auto dispatches', () async {
    var repo = await reopen();
    await create(repo, 'message-failed');
    await create(repo, 'message-interrupted');
    await repo.beginAttempt(
      'message-failed',
      expectedRevisionId: 'revision-message-failed',
    );
    expect(
      await repo.recordFailure(
        'message-failed',
        expectedRevisionId: 'revision-message-failed',
        acceptanceKnown: true,
      ),
      MessageDelivery.failed,
    );
    await repo.beginAttempt(
      'message-interrupted',
      expectedRevisionId: 'revision-message-interrupted',
    );

    repo = await reopen();
    var transportCalls = 0;
    final delivery = MessageDeliveryService(repo);
    expect(await delivery.openScope(chatId: 'chat-a'), 1);
    final queue = await delivery.pending('chat-a');
    expect(queue.map((item) => item.message.id), ['message-failed']);
    expect(
      (await repo.load('message-interrupted'))!.message.delivery,
      MessageDelivery.uncertain,
    );
    expect(
      await repo.beginAttempt(
        'message-interrupted',
        expectedRevisionId: 'revision-message-interrupted',
      ),
      isNull,
    );
    // Opening and reading the queue have no transport callback to invoke.
    expect(transportCalls, 0);

    final retry = await repo.beginAttempt(
      'message-failed',
      expectedRevisionId: 'revision-message-failed',
    );
    expect(retry, isNotNull);
    repo = await reopen();
    expect(
      (await repo.load('message-failed'))!.message.delivery,
      MessageDelivery.sending,
    );
  });

  test('edit preserves original and an old response cannot settle new revision', () async {
    var repo = await reopen();
    await create(repo, 'message-a', text: 'original');
    await repo.beginAttempt('message-a', expectedRevisionId: 'revision-message-a');
    await repo.append(
      'message-a',
      expectedRevisionId: 'revision-message-a',
      revision: MessageRevision(
        id: 'revision-message-a-2',
        messageId: 'message-a',
        revision: 2,
        text: 'corregido',
        createdAt: instant.add(const Duration(minutes: 1)),
        supersedesId: 'revision-message-a',
      ),
    );
    expect(
      await repo.recordAnswer(
        'message-a',
        expectedRevisionId: 'revision-message-a',
      ),
      MessageAnswerStatus.superseded,
    );

    repo = await reopen();
    final loaded = (await repo.load('message-a'))!;
    expect(loaded.message.currentRevisionId, 'revision-message-a-2');
    expect(loaded.message.delivery, MessageDelivery.pending);
    expect(loaded.revisions.map((revision) => revision.text), ['original', 'corregido']);
    expect(loaded.revisions.last.supersedesId, 'revision-message-a');
  });

  test('confirmed effect is not repeated and uncertain effect needs reconciliation', () async {
    var repo = await reopen();
    await create(repo, 'message-a');
    final effect = EffectLink(
      id: 'effect-a',
      profileId: scope.profileId,
      companionId: scope.companionId,
      messageRevisionId: 'revision-message-a',
      targetType: 'activity',
      targetId: 'activity-a',
      operationId: 'operation-a',
      createdAt: instant,
    );
    await repo.linkEffect(effect);
    expect(await repo.confirmEffect('operation-a'), isTrue);

    repo = await reopen();
    expect(await repo.confirmEffect('operation-a'), isFalse);
    expect(await repo.markEffectUncertain('operation-a'), isFalse);
    expect((await repo.effectByOperation('operation-a'))!.status, EffectStatus.confirmed);

    await repo.linkEffect(
      EffectLink(
        id: 'effect-b',
        profileId: scope.profileId,
        companionId: scope.companionId,
        messageRevisionId: 'revision-message-a',
        targetType: 'activity',
        targetId: 'activity-a',
        operationId: 'operation-b',
        createdAt: instant,
      ),
    );
    await repo.markEffectUncertain('operation-b');
    await expectLater(
      repo.confirmEffect('operation-b'),
      throwsStateError,
    );
    expect(
      await repo.confirmEffect('operation-b', reconciled: true),
      isTrue,
    );
    expect((await repo.effectByOperation('operation-b'))!.status, EffectStatus.confirmed);
  });
}
