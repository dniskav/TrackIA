import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/message_effect.dart';
import '../domain/message_revision.dart';
import '../domain/space.dart';
import '../domain/workout.dart';
import 'chat_store.dart';
import 'feature_scope.dart';
import 'trackia_rename.dart';

/// A message and the immutable revision used by one delivery attempt.
class MessageDeliveryItem {
  const MessageDeliveryItem({required this.message, required this.revision});

  final Message message;
  final MessageRevision revision;
}

enum MessageAnswerStatus { recorded, duplicate, superseded }

/// Transactional persistence on the additive SQLite v7 tables.
///
/// The repository never sends a message or executes an effect. Every attempt
/// is committed as `sending` before a caller starts external work. A response
/// or edit must name the expected revision so late work cannot overwrite a
/// newer correction.
class MessageRevisionRepository {
  MessageRevisionRepository(this._db, this.scope);

  final Database _db;
  final FeatureScope scope;

  /// Uses the same database path and factory as the active [ChatStore].
  ///
  /// Production paths are resolved with the normal TrackIA naming rules. The
  /// single-candidate fallback supports synthetic stores with a custom file
  /// name. sqflite's default single-instance mode returns the already-open
  /// connection, so this does not create a second queue or close app storage.
  static Future<MessageRevisionRepository> fromChatStore(
    ChatStore store,
    FeatureScope scope, {
    DatabaseFactory? factory,
  }) async {
    final f = factory ?? databaseFactory;
    final media = await store.mediaDirectory();
    final directory = p.dirname(media.path);
    var path = await resolveDatabasePath(
      directory,
      scope.profileId,
      factory: f,
    );
    if (!await f.databaseExists(path)) {
      final candidates = <String>[];
      await for (final entry in Directory(directory).list(followLinks: false)) {
        final name = p.basename(entry.path);
        if (entry is File &&
            name.endsWith('.sqlite') &&
            !name.contains('pre-trackia')) {
          candidates.add(entry.path);
        }
      }
      if (candidates.length == 1) path = candidates.single;
    }
    if (!await f.databaseExists(path)) {
      throw StateError('No se encontró la base SQLite del chat activo.');
    }
    final db = await f.openDatabase(
      path,
      options: OpenDatabaseOptions(
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    return MessageRevisionRepository(db, scope);
  }

  Future<void> create(Message message, MessageRevision original) async {
    FeatureScopeValidator.requireScope(
      requested: scope,
      stored: FeatureScope(
        profileId: message.profileId,
        companionId: message.companionId,
      ),
    );
    validTrackiaId(message.id);
    validTrackiaId(message.chatId);
    validTrackiaId(original.id);
    if (original.messageId != message.id ||
        original.id != message.currentRevisionId ||
        original.revision != 1 ||
        original.supersedesId != null ||
        message.delivery != MessageDelivery.pending) {
      throw const ValidationException(
        'La revisión inicial no coincide con el mensaje.',
      );
    }
    await _db.transaction((tx) async {
      await tx.insert('message_revision_messages', {
        'profile_id': scope.profileId,
        'companion_id': scope.companionId,
        'id': message.id,
        'chat_id': message.chatId,
        'created_at': message.createdAt.millisecondsSinceEpoch,
        'current_revision_id': original.id,
        'delivery': message.delivery.name,
        'attachment_refs': jsonEncode(message.attachmentRefs),
      });
      await _insertRevision(tx, original);
    });
  }

  Future<void> append(
    String messageId, {
    required String expectedRevisionId,
    required MessageRevision revision,
  }) async {
    validTrackiaId(messageId);
    validTrackiaId(expectedRevisionId);
    validTrackiaId(revision.id);
    await _db.transaction((tx) async {
      final rows = await _currentRows(tx, messageId);
      if (rows.length != 1 ||
          rows.single['current_revision_id'] != expectedRevisionId) {
        throw const ValidationException(
          'El mensaje cambió o no existe en este ámbito.',
        );
      }
      if (revision.messageId != messageId ||
          revision.supersedesId != expectedRevisionId ||
          revision.revision != (rows.single['revision'] as int) + 1) {
        throw const ValidationException(
          'La revisión nueva no sigue a la versión actual.',
        );
      }
      await _insertRevision(tx, revision);
      final changed = await tx.update(
        'message_revision_messages',
        {
          'current_revision_id': revision.id,
          'delivery': MessageDelivery.pending.name,
        },
        where:
            'profile_id = ? AND companion_id = ? AND id = ? AND current_revision_id = ?',
        whereArgs: [
          scope.profileId,
          scope.companionId,
          messageId,
          expectedRevisionId,
        ],
      );
      if (changed != 1) throw const ValidationException('El mensaje cambió.');
    });
  }

  Future<void> _insertRevision(
    DatabaseExecutor tx,
    MessageRevision revision,
  ) async {
    await tx.insert('message_revision_versions', {
      'profile_id': scope.profileId,
      'companion_id': scope.companionId,
      'id': revision.id,
      'message_id': revision.messageId,
      'revision': revision.revision,
      'text': revision.text,
      'created_at': revision.createdAt.millisecondsSinceEpoch,
      'supersedes_id': revision.supersedesId,
    });
  }

  Future<List<Map<String, Object?>>> _currentRows(
    DatabaseExecutor tx,
    String messageId,
  ) => tx.rawQuery(
    '''SELECT m.current_revision_id, m.delivery, r.revision
    FROM message_revision_messages m JOIN message_revision_versions r
    ON r.profile_id = m.profile_id AND r.companion_id = m.companion_id
    AND r.message_id = m.id AND r.id = m.current_revision_id
    WHERE m.profile_id = ? AND m.companion_id = ? AND m.id = ?''',
    [scope.profileId, scope.companionId, messageId],
  );

  Future<({Message message, List<MessageRevision> revisions})?> load(
    String messageId,
  ) async {
    validTrackiaId(messageId);
    return _db.transaction((tx) => _loadWith(tx, messageId));
  }

  Future<({Message message, List<MessageRevision> revisions})?> _loadWith(
    DatabaseExecutor tx,
    String messageId,
  ) async {
    final rows = await tx.query(
      'message_revision_messages',
      where: 'profile_id = ? AND companion_id = ? AND id = ?',
      whereArgs: [scope.profileId, scope.companionId, messageId],
    );
    if (rows.isEmpty) return null;
    final history = await tx.query(
      'message_revision_versions',
      where: 'profile_id = ? AND companion_id = ? AND message_id = ?',
      whereArgs: [scope.profileId, scope.companionId, messageId],
      orderBy: 'revision',
    );
    return (
      message: _messageFrom(rows.single),
      revisions: history.map(_revisionFrom).toList(growable: false),
    );
  }

  Message _messageFrom(Map<String, Object?> row) => Message(
    id: row['id'] as String,
    profileId: scope.profileId,
    companionId: scope.companionId,
    chatId: row['chat_id'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at'] as int,
      isUtc: true,
    ),
    currentRevisionId: row['current_revision_id'] as String,
    delivery: MessageDelivery.values.byName(row['delivery'] as String),
    attachmentRefs: (jsonDecode(row['attachment_refs'] as String) as List)
        .cast<String>(),
  );

  MessageRevision _revisionFrom(Map<String, Object?> row) => MessageRevision(
    id: row['id'] as String,
    messageId: row['message_id'] as String,
    revision: row['revision'] as int,
    text: row['text'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at'] as int,
      isUtc: true,
    ),
    supersedesId: row['supersedes_id'] as String?,
  );

  Future<MessageDeliveryItem?> loadItem(String messageId) async {
    validTrackiaId(messageId);
    return _db.transaction((tx) async {
      final rows = await tx.query(
        'message_revision_messages',
        columns: ['id'],
        where: 'profile_id = ? AND companion_id = ? AND id = ?',
        whereArgs: [scope.profileId, scope.companionId, messageId],
      );
      if (rows.isEmpty) return null;
      return _itemWith(tx, messageId);
    });
  }

  Future<MessageDeliveryItem> _itemWith(
    DatabaseExecutor tx,
    String messageId,
  ) async {
    final loaded = await _loadWith(tx, messageId);
    if (loaded == null) throw StateError('El mensaje no existe en este ámbito.');
    final revision = loaded.revisions
        .where((item) => item.id == loaded.message.currentRevisionId)
        .single;
    return MessageDeliveryItem(message: loaded.message, revision: revision);
  }

  /// Retryable work only: uncertain and interrupted sends are deliberately
  /// excluded. Date plus opaque ID provides a total, stable order.
  Future<List<MessageDeliveryItem>> queue(String chatId) async {
    validTrackiaId(chatId);
    return _db.transaction((tx) async {
      final ids = await tx.query(
        'message_revision_messages',
        columns: ['id'],
        where:
            "profile_id = ? AND companion_id = ? AND chat_id = ? AND delivery IN ('pending','failed')",
        whereArgs: [scope.profileId, scope.companionId, chatId],
        orderBy: 'created_at, id',
      );
      return [
        for (final row in ids) await _itemWith(tx, row['id'] as String),
      ];
    });
  }

  /// All delivery records for the origin chat, in transcript order.
  Future<List<MessageDeliveryItem>> chatMessages(String chatId) async {
    validTrackiaId(chatId);
    return _db.transaction((tx) async {
      final ids = await tx.query(
        'message_revision_messages',
        columns: ['id'],
        where: 'profile_id = ? AND companion_id = ? AND chat_id = ?',
        whereArgs: [scope.profileId, scope.companionId, chatId],
        orderBy: 'created_at, id',
      );
      return [
        for (final row in ids) await _itemWith(tx, row['id'] as String),
      ];
    });
  }

  Future<MessageDeliveryItem?> beginAttempt(
    String messageId, {
    required String expectedRevisionId,
  }) async {
    validTrackiaId(messageId);
    validTrackiaId(expectedRevisionId);
    return _db.transaction((tx) async {
      final rows = await _currentRows(tx, messageId);
      if (rows.isEmpty) return null;
      final row = rows.single;
      if (row['current_revision_id'] != expectedRevisionId ||
          (row['delivery'] != MessageDelivery.pending.name &&
              row['delivery'] != MessageDelivery.failed.name)) {
        return null;
      }
      final changed = await tx.update(
        'message_revision_messages',
        {'delivery': MessageDelivery.sending.name},
        where:
            "profile_id = ? AND companion_id = ? AND id = ? AND current_revision_id = ? AND delivery IN ('pending','failed')",
        whereArgs: [
          scope.profileId,
          scope.companionId,
          messageId,
          expectedRevisionId,
        ],
      );
      if (changed != 1) return null;
      return _itemWith(tx, messageId);
    });
  }

  Future<MessageAnswerStatus> recordAnswer(
    String messageId, {
    required String expectedRevisionId,
  }) async {
    validTrackiaId(messageId);
    validTrackiaId(expectedRevisionId);
    return _db.transaction((tx) async {
      final rows = await _currentRows(tx, messageId);
      if (rows.isEmpty) {
        throw const ValidationException('El mensaje no existe en este ámbito.');
      }
      final row = rows.single;
      if (row['current_revision_id'] != expectedRevisionId) {
        return MessageAnswerStatus.superseded;
      }
      final state = row['delivery'] as String;
      if (state == MessageDelivery.answered.name) {
        return MessageAnswerStatus.duplicate;
      }
      if (state != MessageDelivery.sending.name &&
          state != MessageDelivery.uncertain.name) {
        throw StateError('No se puede adjuntar una respuesta desde $state.');
      }
      final changed = await tx.update(
        'message_revision_messages',
        {'delivery': MessageDelivery.answered.name},
        where:
            "profile_id = ? AND companion_id = ? AND id = ? AND current_revision_id = ? AND delivery IN ('sending','uncertain')",
        whereArgs: [
          scope.profileId,
          scope.companionId,
          messageId,
          expectedRevisionId,
        ],
      );
      return changed == 1
          ? MessageAnswerStatus.recorded
          : MessageAnswerStatus.duplicate;
    });
  }

  Future<MessageDelivery?> recordFailure(
    String messageId, {
    required String expectedRevisionId,
    required bool acceptanceKnown,
  }) async {
    validTrackiaId(messageId);
    validTrackiaId(expectedRevisionId);
    return _db.transaction((tx) async {
      final rows = await _currentRows(tx, messageId);
      if (rows.isEmpty ||
          rows.single['current_revision_id'] != expectedRevisionId ||
          rows.single['delivery'] != MessageDelivery.sending.name) {
        return null;
      }
      final next = acceptanceKnown
          ? MessageDelivery.failed
          : MessageDelivery.uncertain;
      final changed = await tx.update(
        'message_revision_messages',
        {'delivery': next.name},
        where:
            "profile_id = ? AND companion_id = ? AND id = ? AND current_revision_id = ? AND delivery = 'sending'",
        whereArgs: [
          scope.profileId,
          scope.companionId,
          messageId,
          expectedRevisionId,
        ],
      );
      return changed == 1 ? next : null;
    });
  }

  /// Recovery is a durable state transition, never a dispatch operation.
  Future<int> recoverSending({String? chatId}) {
    if (chatId != null) validTrackiaId(chatId);
    return _db.update(
      'message_revision_messages',
      {'delivery': MessageDelivery.uncertain.name},
      where:
          "profile_id = ? AND companion_id = ? AND delivery = 'sending'${chatId == null ? '' : ' AND chat_id = ?'}",
      whereArgs: [
        scope.profileId,
        scope.companionId,
        if (chatId != null) chatId,
      ],
    );
  }

  Future<void> linkEffect(EffectLink effect) async {
    FeatureScopeValidator.requireScope(
      requested: scope,
      stored: FeatureScope(
        profileId: effect.profileId,
        companionId: effect.companionId,
      ),
    );
    await _db.transaction((tx) async {
      final revisions = await tx.query(
        'message_revision_versions',
        columns: ['id'],
        where: 'profile_id = ? AND companion_id = ? AND id = ?',
        whereArgs: [scope.profileId, scope.companionId, effect.messageRevisionId],
      );
      if (revisions.isEmpty) {
        throw const ValidationException('La revisión del efecto no existe.');
      }
      await tx.insert('trackia_message_effects', {
        'id': effect.id,
        'profile_id': scope.profileId,
        'companion_id': scope.companionId,
        'message_revision_id': effect.messageRevisionId,
        'target_type': effect.targetType,
        'target_id': effect.targetId,
        'operation_id': effect.operationId,
        'status': effect.status.name,
        'created_at': effect.createdAt.millisecondsSinceEpoch,
      });
    });
  }

  Future<EffectLink?> effectByOperation(String operationId) async {
    validTrackiaId(operationId);
    final rows = await _db.query(
      'trackia_message_effects',
      where: 'profile_id = ? AND companion_id = ? AND operation_id = ?',
      whereArgs: [scope.profileId, scope.companionId, operationId],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return EffectLink(
      id: row['id'] as String,
      profileId: scope.profileId,
      companionId: scope.companionId,
      messageRevisionId: row['message_revision_id'] as String,
      targetType: row['target_type'] as String,
      targetId: row['target_id'] as String,
      operationId: operationId,
      status: EffectStatus.values.byName(row['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
        isUtc: true,
      ),
    );
  }

  /// Returns false for an already confirmed operation. An uncertain operation
  /// cannot be repeated unless its destination was reconciled explicitly.
  Future<bool> confirmEffect(
    String operationId, {
    bool reconciled = false,
  }) async {
    validTrackiaId(operationId);
    return _db.transaction((tx) async {
      final rows = await tx.query(
        'trackia_message_effects',
        columns: ['status'],
        where: 'profile_id = ? AND companion_id = ? AND operation_id = ?',
        whereArgs: [scope.profileId, scope.companionId, operationId],
      );
      if (rows.isEmpty) {
        throw const ValidationException('El efecto no existe en este ámbito.');
      }
      final status = EffectStatus.values.byName(rows.single['status'] as String);
      if (status == EffectStatus.confirmed) return false;
      if (status == EffectStatus.superseded) {
        throw StateError('Un efecto sustituido no se puede confirmar.');
      }
      if (status == EffectStatus.uncertain && !reconciled) {
        throw StateError('Un efecto incierto exige reconciliación.');
      }
      final changed = await tx.update(
        'trackia_message_effects',
        {'status': EffectStatus.confirmed.name},
        where:
            "profile_id = ? AND companion_id = ? AND operation_id = ? AND status != 'confirmed'",
        whereArgs: [scope.profileId, scope.companionId, operationId],
      );
      return changed == 1;
    });
  }

  Future<bool> markEffectUncertain(String operationId) async {
    validTrackiaId(operationId);
    final changed = await _db.update(
      'trackia_message_effects',
      {'status': EffectStatus.uncertain.name},
      where:
          "profile_id = ? AND companion_id = ? AND operation_id = ? AND status IN ('proposed','failed')",
      whereArgs: [scope.profileId, scope.companionId, operationId],
    );
    return changed == 1;
  }
}
