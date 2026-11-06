import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/companion_memory.dart';

/// Persistence for memories. Every read and mutation is constrained to the
/// repository profile; callers must also provide the companion scope.
///
/// The injected executor lets callers use either a database or transaction.
class CompanionMemoryRepository {
  CompanionMemoryRepository(this._db, {required this.profileId}) {
    if (profileId.trim().isEmpty) {
      throw ArgumentError.value(profileId, 'profileId');
    }
  }

  static const table = 'trackia_companion_memories';
  static const _uuid = Uuid();
  final DatabaseExecutor _db;
  final String profileId;

  Future<CompanionMemory> create({
    required String companionId,
    required String content,
    required MemorySource source,
    String? sourceMessageId,
    MemoryStatus status = MemoryStatus.active,
    DateTime? at,
    String? id,
  }) async {
    final when = at ?? DateTime.now();
    final memory = CompanionMemory(
      id: id ?? _uuid.v4(),
      profileId: profileId,
      companionId: companionId,
      content: content,
      source: source,
      sourceMessageId: sourceMessageId,
      createdAt: when,
      updatedAt: when,
      status: status,
    );
    await _db.insert(table, _values(memory));
    return memory;
  }

  Future<CompanionMemory?> get(String id, {required String companionId}) async {
    final rows = await _db.query(
      table,
      where: 'id = ? AND profile_id = ? AND companion_id = ?',
      whereArgs: [id, profileId, companionId],
      limit: 1,
    );
    return rows.isEmpty ? null : _read(rows.first);
  }

  Future<List<CompanionMemory>> list({
    required String companionId,
    bool includeDeleted = false,
  }) async {
    final rows = await _db.query(
      table,
      where:
          'profile_id = ? AND companion_id = ?${includeDeleted ? '' : " AND status != 'deleted'"}',
      whereArgs: [profileId, companionId],
      orderBy: 'created_at, id',
    );
    return rows.map(_read).toList(growable: false);
  }

  Future<CompanionMemory?> revise(
    String id, {
    required String companionId,
    required DateTime at,
    String? content,
    MemoryStatus? status,
  }) async {
    final current = await get(id, companionId: companionId);
    if (current == null) return null;
    final next = current.revise(at: at, content: content, status: status);
    if (next.revision != current.revision) {
      await _db.update(
        table,
        _values(next),
        where: 'id = ? AND profile_id = ? AND companion_id = ?',
        whereArgs: [id, profileId, companionId],
      );
    }
    return next;
  }

  Future<CompanionMemory?> confirm(
    String id, {
    required String companionId,
    required DateTime at,
  }) =>
      revise(id, companionId: companionId, at: at, status: MemoryStatus.active);

  Future<CompanionMemory?> delete(
    String id, {
    required String companionId,
    required DateTime at,
  }) => revise(
    id,
    companionId: companionId,
    at: at,
    status: MemoryStatus.deleted,
  );

  Future<MemoryContextSelection> select({
    required String companionId,
    Iterable<String>? relevantMemoryIds,
    Iterable<String>? referenceCandidateIds,
  }) async => MemoryContextSelection.select(
    candidates: await list(companionId: companionId),
    profileId: profileId,
    companionId: companionId,
    relevantMemoryIds: relevantMemoryIds,
    referenceCandidateIds: referenceCandidateIds,
  );

  Map<String, Object?> _values(CompanionMemory m) => {
    'id': m.id,
    'profile_id': m.profileId,
    'companion_id': m.companionId,
    'content': m.content,
    'source': _sourceToDb(m.source),
    'source_message_id': m.sourceMessageId,
    'created_at': m.createdAt.millisecondsSinceEpoch,
    'updated_at': m.updatedAt.millisecondsSinceEpoch,
    'revision': m.revision,
    'status': _statusToDb(m.status),
  };

  CompanionMemory _read(Map<String, Object?> row) => CompanionMemory(
    id: row['id'] as String,
    profileId: row['profile_id'] as String,
    companionId: row['companion_id'] as String,
    content: row['content'] as String,
    source: _sourceFromDb(row['source'] as String),
    sourceMessageId: row['source_message_id'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    revision: row['revision'] as int,
    status: _statusFromDb(row['status'] as String),
  );

  static String _sourceToDb(MemorySource v) => switch (v) {
    MemorySource.explicit => 'explicit',
    MemorySource.inferred => 'inferred',
    MemorySource.userEdited => 'user_edited',
  };
  static MemorySource _sourceFromDb(String v) => switch (v) {
    'explicit' => MemorySource.explicit,
    'inferred' => MemorySource.inferred,
    'user_edited' => MemorySource.userEdited,
    _ => throw FormatException('Unknown memory source: $v'),
  };
  static String _statusToDb(MemoryStatus v) => switch (v) {
    MemoryStatus.active => 'active',
    MemoryStatus.pendingConfirmation => 'pending_confirmation',
    MemoryStatus.deleted => 'deleted',
  };
  static MemoryStatus _statusFromDb(String v) => switch (v) {
    'active' => MemoryStatus.active,
    'pending_confirmation' => MemoryStatus.pendingConfirmation,
    'deleted' => MemoryStatus.deleted,
    _ => throw FormatException('Unknown memory status: $v'),
  };
}
