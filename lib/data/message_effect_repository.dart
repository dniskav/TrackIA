import 'package:sqflite/sqflite.dart';

import '../domain/message_effect.dart';
import '../domain/space.dart';
import '../domain/workout.dart';
import 'feature_scope.dart';
import 'message_revision_repository.dart';

/// Registry of the real operations each message caused.
///
/// Rows live in `trackia_message_effects` (v7). The readable summary and the
/// correction mark go in the additive table `trackia_message_effect_notes`,
/// created with IF NOT EXISTS: no existing table or column changes, so the
/// database version and every ID stay as they are.
class MessageEffectRepository {
  MessageEffectRepository(this._db, this.scope);

  /// Shares the connection of the delivery repository.
  factory MessageEffectRepository.on(MessageRevisionRepository revisions) =>
      MessageEffectRepository(revisions.database, revisions.scope);

  final Database _db;
  final FeatureScope scope;
  Future<void>? _ready;

  Future<void> _ensure() => _ready ??= _db.execute('''CREATE TABLE IF NOT EXISTS
    trackia_message_effect_notes (
      effect_id TEXT PRIMARY KEY, summary TEXT NOT NULL DEFAULT '',
      reverted_at INTEGER)''');

  static const _select = '''SELECT e.id, e.message_revision_id, e.target_type,
    e.target_id, e.operation_id, e.status, e.created_at, v.message_id,
    COALESCE(n.summary, '') AS summary, n.reverted_at
    FROM trackia_message_effects e
    JOIN message_revision_versions v ON v.profile_id = e.profile_id
      AND v.companion_id = e.companion_id AND v.id = e.message_revision_id
    LEFT JOIN trackia_message_effect_notes n ON n.effect_id = e.id
    WHERE e.profile_id = ? AND e.companion_id = ?''';

  /// Registers an applied effect. Returns false, changing nothing, when an
  /// effect with the same idempotency key already exists in this scope.
  Future<bool> record(MessageEffect effect) async {
    FeatureScopeValidator.requireScope(
      requested: scope,
      stored: FeatureScope(
        profileId: effect.profileId,
        companionId: effect.companionId,
      ),
    );
    await _ensure();
    return _db.transaction((tx) async {
      final existing = await tx.query(
        'trackia_message_effects',
        columns: ['id'],
        where: 'profile_id = ? AND companion_id = ? AND operation_id = ?',
        whereArgs: [scope.profileId, scope.companionId, effect.operationKey],
      );
      if (existing.isNotEmpty) return false;
      final revision = await tx.rawQuery(
        '''SELECT message_id FROM message_revision_versions
        WHERE profile_id = ? AND companion_id = ? AND id = ?''',
        [scope.profileId, scope.companionId, effect.revisionId],
      );
      if (revision.isEmpty ||
          revision.single['message_id'] != effect.messageId) {
        throw const ValidationException(
          'La revisión del efecto no pertenece al mensaje.',
        );
      }
      await tx.insert('trackia_message_effects', {
        'id': effect.id,
        'profile_id': scope.profileId,
        'companion_id': scope.companionId,
        'message_revision_id': effect.revisionId,
        'target_type': effect.kind,
        'target_id': effect.targetId,
        'operation_id': effect.operationKey,
        'status': effect.status.name,
        'created_at': effect.createdAt.millisecondsSinceEpoch,
      });
      await tx.insert('trackia_message_effect_notes', {
        'effect_id': effect.id,
        'summary': effect.summary,
      });
      return true;
    });
  }

  /// Whether this idempotency key was already applied in this scope.
  Future<bool> isApplied(String operationKey) async {
    validTrackiaId(operationKey);
    final rows = await _db.query(
      'trackia_message_effects',
      columns: ['status'],
      where: 'profile_id = ? AND companion_id = ? AND operation_id = ?',
      whereArgs: [scope.profileId, scope.companionId, operationKey],
    );
    return rows.isNotEmpty;
  }

  /// Every effect of every revision of the message, oldest first.
  Future<List<MessageEffect>> effectsFor(String messageId) async {
    validTrackiaId(messageId);
    await _ensure();
    final rows = await _db.rawQuery(
      '$_select AND v.message_id = ? ORDER BY e.created_at, e.id',
      [scope.profileId, scope.companionId, messageId],
    );
    return rows.map(_from).toList(growable: false);
  }

  Future<List<MessageEffect>> effectsForRevision(String revisionId) async {
    validTrackiaId(revisionId);
    await _ensure();
    final rows = await _db.rawQuery(
      '$_select AND e.message_revision_id = ? ORDER BY e.created_at, e.id',
      [scope.profileId, scope.companionId, revisionId],
    );
    return rows.map(_from).toList(growable: false);
  }

  /// Marks an effect as corrected or reverted. The row is kept for history.
  /// Returns false when it does not exist or was already marked.
  Future<bool> markReverted(String effectId, {DateTime? at}) async {
    validTrackiaId(effectId);
    await _ensure();
    return _db.transaction((tx) async {
      final changed = await tx.update(
        'trackia_message_effects',
        {'status': EffectStatus.superseded.name},
        where:
            "profile_id = ? AND companion_id = ? AND id = ? AND status != 'superseded'",
        whereArgs: [scope.profileId, scope.companionId, effectId],
      );
      if (changed != 1) return false;
      await tx.insert('trackia_message_effect_notes', {
        'effect_id': effectId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await tx.update(
        'trackia_message_effect_notes',
        {'reverted_at': (at ?? DateTime.now()).toUtc().millisecondsSinceEpoch},
        where: 'effect_id = ?',
        whereArgs: [effectId],
      );
      return true;
    });
  }

  /// Text for the model about what earlier answers to [messageId] already did.
  /// Empty when nothing was applied. Proposals never count as applied.
  Future<String> appliedEffectsSummary(String messageId) async {
    final effects = await effectsFor(messageId);
    final done = <String>[];
    final uncertain = <String>[];
    final reverted = <String>[];
    for (final e in effects) {
      final text = effectSummaryText(e);
      switch (e.status) {
        case EffectStatus.confirmed:
          done.add(text);
        case EffectStatus.uncertain:
          uncertain.add(text);
        case EffectStatus.superseded:
          reverted.add(text);
        case EffectStatus.proposed || EffectStatus.failed:
          break;
      }
    }
    if (done.isEmpty && uncertain.isEmpty && reverted.isEmpty) return '';
    final parts = <String>[
      if (done.isNotEmpty)
        'Efectos ya aplicados por la respuesta anterior: ${done.join('; ')}.',
      if (uncertain.isNotEmpty)
        'Con resultado incierto (no los repitas sin comprobar): ${uncertain.join('; ')}.',
      if (reverted.isNotEmpty)
        'Corregidos o revertidos después: ${reverted.join('; ')}.',
    ];
    return parts.join(' ');
  }

  MessageEffect _from(Map<String, Object?> row) => MessageEffect(
    id: row['id'] as String,
    profileId: scope.profileId,
    companionId: scope.companionId,
    messageId: row['message_id'] as String,
    revisionId: row['message_revision_id'] as String,
    kind: row['target_type'] as String,
    targetId: row['target_id'] as String,
    operationKey: row['operation_id'] as String,
    summary: row['summary'] as String,
    status: EffectStatus.values.byName(row['status'] as String),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row['created_at'] as int,
      isUtc: true,
    ),
  );
}

/// The effect's summary, or a generic Spanish text when none was stored.
String effectSummaryText(MessageEffect e) {
  if (e.summary.isNotEmpty) return e.summary;
  return switch (e.kind) {
    'activity' => 'Preparé una actividad',
    'target' => 'Cambié el objetivo de series',
    'timing' => 'Cambié los tiempos de la actividad',
    'goal' => 'Añadí una meta',
    'achievement' => 'Añadí un logro',
    'reminder-copy' => 'Guardé textos de recordatorio',
    'sheet-edit' => 'Edité Google Sheets',
    'observation' => 'Registré un dato',
    'memory' => 'Guardé una memoria',
    _ => 'Apliqué un cambio (${e.kind})',
  };
}
