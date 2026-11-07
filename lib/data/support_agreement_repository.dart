import 'package:sqflite/sqflite.dart';

import '../domain/support_agreement.dart';
import '../domain/workout.dart';
import 'feature_scope.dart';

/// Persistencia de los acuerdos de apoyo (feature 005, US5).
///
/// Las tablas son aditivas y se crean con IF NOT EXISTS (sin subir la versión
/// de la base ni tocar tablas existentes). Todo se consulta con perfil y
/// acompañante. Las revisiones y los eventos son inmutables: se añaden, nunca
/// se reescriben (también lo impiden disparadores en la propia base).
class SupportAgreementRepository {
  SupportAgreementRepository(this._db, this.scope);

  final Database _db;
  final FeatureScope scope;
  Future<void>? _ready;

  Future<void> _ensure() => _ready ??= _create();

  Future<void> _create() async {
    await _db.execute('''CREATE TABLE IF NOT EXISTS trackia_support_agreements (
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, id TEXT NOT NULL,
      objective TEXT NOT NULL, unit TEXT, target REAL, duration_seconds INTEGER,
      reminder TEXT, status TEXT NOT NULL, revision INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      PRIMARY KEY (profile_id, companion_id, id))''');
    await _db.execute('''CREATE TABLE IF NOT EXISTS
    trackia_support_agreement_revisions (
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, id TEXT NOT NULL,
      agreement_id TEXT NOT NULL, revision INTEGER NOT NULL,
      objective TEXT NOT NULL, unit TEXT, target REAL, duration_seconds INTEGER,
      reminder TEXT, status TEXT NOT NULL, created_at INTEGER NOT NULL,
      PRIMARY KEY (profile_id, companion_id, id),
      UNIQUE (profile_id, companion_id, agreement_id, revision))''');
    await _db.execute('''CREATE TABLE IF NOT EXISTS
    trackia_support_agreement_events (
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, id TEXT NOT NULL,
      agreement_id TEXT NOT NULL, occurred_at INTEGER NOT NULL,
      amount REAL, note TEXT,
      PRIMARY KEY (profile_id, companion_id, id))''');
    for (final table in const [
      'trackia_support_agreement_revisions',
      'trackia_support_agreement_events',
    ]) {
      await _db.execute('''CREATE TRIGGER IF NOT EXISTS ${table}_no_update
        BEFORE UPDATE ON $table
        BEGIN SELECT RAISE(ABORT, 'inmutable'); END''');
      await _db.execute('''CREATE TRIGGER IF NOT EXISTS ${table}_no_delete
        BEFORE DELETE ON $table
        BEGIN SELECT RAISE(ABORT, 'inmutable'); END''');
    }
  }

  /// Guarda el acuerdo: crea o actualiza su estado actual y añade las
  /// revisiones y eventos nuevos. Una revisión o evento ya guardado no puede
  /// cambiar; un acuerdo con revisión menor que la guardada se rechaza.
  Future<void> save(SupportAgreement agreement) async {
    FeatureScopeValidator.requireScope(
      requested: scope,
      stored: FeatureScope(
        profileId: agreement.profileId,
        companionId: agreement.companionId,
      ),
    );
    await _ensure();
    await _db.transaction((tx) async {
      final existing = await tx.query(
        'trackia_support_agreements',
        columns: ['revision', 'status'],
        where: 'profile_id = ? AND companion_id = ? AND id = ?',
        whereArgs: [scope.profileId, scope.companionId, agreement.id],
      );
      if (existing.isNotEmpty) {
        final stored = existing.single['revision']! as int;
        if (stored > agreement.revision) {
          throw const ValidationException(
            'El acuerdo guardado es más reciente que el recibido.',
          );
        }
        if (existing.single['status'] == SupportAgreementStatus.completed.name &&
            stored == agreement.revision &&
            agreement.status != SupportAgreementStatus.completed) {
          throw const ValidationException('Un acuerdo finalizado es inmutable.');
        }
      }
      final row = _agreementRow(agreement);
      if (existing.isEmpty) {
        await tx.insert('trackia_support_agreements', row);
      } else {
        await tx.update(
          'trackia_support_agreements',
          row,
          where: 'profile_id = ? AND companion_id = ? AND id = ?',
          whereArgs: [scope.profileId, scope.companionId, agreement.id],
        );
      }
      for (final revision in agreement.revisions) {
        await _insertImmutable(
          tx,
          'trackia_support_agreement_revisions',
          _revisionRow(revision),
        );
      }
      for (final event in agreement.events) {
        await _insertImmutable(
          tx,
          'trackia_support_agreement_events',
          _eventRow(event),
        );
      }
    });
  }

  Future<SupportAgreement?> get(String id) async {
    await _ensure();
    final rows = await _db.query(
      'trackia_support_agreements',
      where: 'profile_id = ? AND companion_id = ? AND id = ?',
      whereArgs: [scope.profileId, scope.companionId, id],
    );
    if (rows.isEmpty) return null;
    return _load(_db, rows.single);
  }

  /// Todos los acuerdos del ámbito, del más antiguo al más reciente.
  Future<List<SupportAgreement>> list({SupportAgreementStatus? status}) async {
    await _ensure();
    final rows = await _db.query(
      'trackia_support_agreements',
      where: 'profile_id = ? AND companion_id = ?'
          '${status == null ? '' : ' AND status = ?'}',
      whereArgs: [scope.profileId, scope.companionId, ?status?.name],
      orderBy: 'created_at ASC, id ASC',
    );
    return [for (final row in rows) await _load(_db, row)];
  }

  Future<SupportAgreement> _load(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final id = row['id']! as String;
    final revisions = await db.query(
      'trackia_support_agreement_revisions',
      where: 'profile_id = ? AND companion_id = ? AND agreement_id = ?',
      whereArgs: [scope.profileId, scope.companionId, id],
      orderBy: 'revision ASC',
    );
    final events = await db.query(
      'trackia_support_agreement_events',
      where: 'profile_id = ? AND companion_id = ? AND agreement_id = ?',
      whereArgs: [scope.profileId, scope.companionId, id],
      orderBy: 'occurred_at ASC, id ASC',
    );
    return SupportAgreement(
      id: id,
      profileId: scope.profileId,
      companionId: scope.companionId,
      objective: row['objective']! as String,
      unit: row['unit'] as String?,
      target: (row['target'] as num?)?.toDouble(),
      duration: _duration(row['duration_seconds']),
      reminder: row['reminder'] as String?,
      status: _status(row['status']),
      revision: row['revision']! as int,
      createdAt: _date(row['created_at']),
      revisions: [
        for (final r in revisions)
          SupportAgreementRevision(
            id: r['id']! as String,
            agreementId: id,
            revision: r['revision']! as int,
            objective: r['objective']! as String,
            unit: r['unit'] as String?,
            target: (r['target'] as num?)?.toDouble(),
            duration: _duration(r['duration_seconds']),
            reminder: r['reminder'] as String?,
            status: _status(r['status']),
            createdAt: _date(r['created_at']),
          ),
      ],
      events: [
        for (final e in events)
          SupportAgreementEvent(
            id: e['id']! as String,
            agreementId: id,
            occurredAt: _date(e['occurred_at']),
            amount: (e['amount'] as num?)?.toDouble(),
            note: e['note'] as String?,
          ),
      ],
    );
  }

  /// Inserta la fila; si ya existe debe ser idéntica (idempotente) o falla.
  Future<void> _insertImmutable(
    DatabaseExecutor tx,
    String table,
    Map<String, Object?> row,
  ) async {
    final found = await tx.query(
      table,
      where: 'profile_id = ? AND companion_id = ? AND id = ?',
      whereArgs: [scope.profileId, scope.companionId, row['id']],
    );
    if (found.isEmpty) {
      await tx.insert(table, row);
      return;
    }
    for (final entry in row.entries) {
      if (found.single[entry.key] != entry.value) {
        throw const ValidationException(
          'Una revisión o un evento guardado no puede modificarse.',
        );
      }
    }
  }

  Map<String, Object?> _agreementRow(SupportAgreement a) => {
    'profile_id': scope.profileId,
    'companion_id': scope.companionId,
    'id': a.id,
    'objective': a.objective,
    'unit': a.unit,
    'target': a.target,
    'duration_seconds': a.duration?.inSeconds,
    'reminder': a.reminder,
    'status': a.status.name,
    'revision': a.revision,
    'created_at': a.createdAt.millisecondsSinceEpoch,
  };

  Map<String, Object?> _revisionRow(SupportAgreementRevision r) => {
    'profile_id': scope.profileId,
    'companion_id': scope.companionId,
    'id': r.id,
    'agreement_id': r.agreementId,
    'revision': r.revision,
    'objective': r.objective,
    'unit': r.unit,
    'target': r.target,
    'duration_seconds': r.duration?.inSeconds,
    'reminder': r.reminder,
    'status': r.status.name,
    'created_at': r.createdAt.millisecondsSinceEpoch,
  };

  Map<String, Object?> _eventRow(SupportAgreementEvent e) => {
    'profile_id': scope.profileId,
    'companion_id': scope.companionId,
    'id': e.id,
    'agreement_id': e.agreementId,
    'occurred_at': e.occurredAt.millisecondsSinceEpoch,
    'amount': e.amount,
    'note': e.note,
  };
}

Duration? _duration(Object? seconds) =>
    seconds == null ? null : Duration(seconds: seconds as int);

DateTime _date(Object? ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms! as int, isUtc: true);

SupportAgreementStatus _status(Object? name) =>
    SupportAgreementStatus.values.firstWhere((s) => s.name == name);
