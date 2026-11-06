import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/chat_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/message_revision.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Synthetic compatibility checks for the current chat JSON and storage layer.
/// Revision semantics are intentionally pending the T007/T008 implementation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test(
    'legacy message codec preserves an 8000 character body and attachment',
    () {
      final bytes = <int>[0, 1, 2, 253, 254, 255];
      final original = AiMessage(
        'user',
        'x' * 8000,
        attachment: AiAttachment(
          name: 'fixture.png',
          mime: 'image/png',
          bytes: Uint8List.fromList(bytes),
        ),
        recordedAt: DateTime.utc(2026, 11, 5),
      );

      final restored = AiMessage.fromStorage(original.forStorage());
      expect(restored.text, hasLength(8000));
      expect(restored.text, original.text);
      expect(restored.recordedAt, original.recordedAt);
      expect(restored.attachment?.name, 'fixture.png');
      expect(restored.attachment?.mime, 'image/png');
      expect(restored.attachment?.bytes, bytes);
    },
  );

  test(
    'chat store round-trips synthetic opaque IDs, revision metadata and media',
    () async {
      final dir = await Directory.systemTemp.createTemp('message-revision-');
      final repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/test.sqlite',
      );
      final db = await databaseFactoryFfi.openDatabase(
        '${dir.path}/test.sqlite',
      );
      final media = Directory('${dir.path}/media');
      final store = ChatStore(
        db,
        () => DateTime.utc(2026, 11, 5),
        'profile-fixture',
        mediaDirectory: media,
      );
      final state = <String, dynamic>{
        'sessionId': 'chat-fixture-opaque',
        'messages': [
          {
            'id': 'message-fixture-opaque',
            'role': 'user',
            'content': 'texto sintético',
            'currentRevisionId': 'revision-2-fixture',
            'revisions': [
              {
                'id': 'revision-1-fixture',
                'revision': 1,
                'text': 'versión previa',
              },
              {
                'id': 'revision-2-fixture',
                'revision': 2,
                'text': 'texto sintético',
                'supersedesId': 'revision-1-fixture',
              },
            ],
            'attachment': {
              'name': 'fixture.txt',
              'mime': 'text/plain',
              'bytes': base64Encode([70, 73, 88, 84, 85, 82, 69]),
            },
          },
        ],
        'pending': null,
      };

      try {
        await store.saveActive('gymbro', state);
        final loaded = (await store.loadActive('gymbro'))!;
        final message = (loaded['messages'] as List).single as Map;
        expect(message['id'], 'message-fixture-opaque');
        expect(message['currentRevisionId'], 'revision-2-fixture');
        expect(
          jsonEncode(message['revisions']),
          jsonEncode(((state['messages'] as List).first as Map)['revisions']),
        );
        expect(message['attachment']['name'], 'fixture.txt');
        expect(
          message['attachment']['bytes'],
          base64Encode([70, 73, 88, 84, 85, 82, 69]),
        );
        expect((await media.list().toList()), hasLength(1));
      } finally {
        await db.close();
        await repo.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'revision model accepts the 8000 character boundary and rejects invalid text',
    () {
      final revision = MessageRevision(
        id: 'revision-1',
        messageId: 'message-1',
        revision: 1,
        text: 'x' * 8000,
        createdAt: DateTime.utc(2026, 11, 5),
      );
      expect(revision.text, hasLength(8000));
      expect(
        () => MessageRevision(
          id: 'revision-too-long',
          messageId: 'message-1',
          revision: 1,
          text: 'x' * 8001,
          createdAt: DateTime.utc(2026, 11, 5),
        ),
        throwsArgumentError,
      );
      expect(
        () => MessageRevision(
          id: 'revision-empty',
          messageId: 'message-1',
          revision: 1,
          text: '  ',
          createdAt: DateTime.utc(2026, 11, 5),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'message identity stays stable while revisions grow and preserve original',
    () {
      final timestamp = DateTime.utc(2026, 11, 5);
      final original = MessageRevision(
        id: 'revision-opaque-1',
        messageId: 'message-opaque-1',
        revision: 1,
        text: 'haz tres series',
        createdAt: timestamp,
      );
      final edited = MessageRevision(
        id: 'revision-opaque-2',
        messageId: original.messageId,
        revision: original.revision + 1,
        text: 'haz cuatro series',
        createdAt: timestamp.add(const Duration(minutes: 1)),
        supersedesId: original.id,
      );
      final message = Message(
        id: original.messageId,
        profileId: 'profile-fixture',
        companionId: 'companion-fixture',
        chatId: 'chat-fixture',
        createdAt: timestamp,
        currentRevisionId: edited.id,
        attachmentRefs: const ['attachment-opaque-1'],
      );

      expect(message.id, original.messageId);
      expect(message.currentRevisionId, edited.id);
      expect(message.attachmentRefs, ['attachment-opaque-1']);
      expect(edited.revision, greaterThan(original.revision));
      expect(edited.supersedesId, original.id);
      expect(original.text, 'haz tres series');
      expect(original.id, 'revision-opaque-1');
    },
  );

  test(
    'revision number must be positive and message attachment refs are immutable',
    () {
      expect(
        () => MessageRevision(
          id: 'revision-zero',
          messageId: 'message-1',
          revision: 0,
          text: 'texto',
          createdAt: DateTime.utc(2026, 11, 5),
        ),
        throwsArgumentError,
      );

      final refs = ['attachment-1'];
      final message = Message(
        id: 'message-1',
        profileId: 'profile-1',
        companionId: 'companion-1',
        chatId: 'chat-1',
        createdAt: DateTime.utc(2026, 11, 5),
        currentRevisionId: 'revision-1',
        attachmentRefs: refs,
      );
      refs.add('attachment-2');
      expect(message.attachmentRefs, ['attachment-1']);
      expect(
        () => message.attachmentRefs.add('attachment-3'),
        throwsUnsupportedError,
      );
    },
  );
}
