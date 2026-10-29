import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/activity.dart';
import '../domain/observation.dart';
import '../domain/space.dart';
import '../domain/workout.dart';

/// Point records (no running clock) in `trackia_observations`. Every query is
/// scoped to the repository's profile, so another profile's rows are never
/// visible or correctable from here.
class ObservationRepository {
  ObservationRepository(this._db, this._now, this.profileId)
    : spaceId = defaultSpaceId;

  /// The space legacy data lives in until spaces become selectable.
  static const defaultSpaceId = 'gym';
  static const _uuid = Uuid();

  final Database _db;
  final DateTime Function() _now;
  final String profileId;
  final String spaceId;

  Future<Observation> record({
    required String companionId,
    required ActivityDefinition definition,
    required String original,
    Map<String, Object> values = const {},
    String provenance = 'user',
    String? templateId,
    DateTime? observedAt,
  }) => _db.transaction((tx) async {
    final text = original.trim();
    if (text.isEmpty ||
        text.length > 8000 ||
        !Observation.provenances.contains(provenance) ||
        validTrackiaId(companionId) != definition.companionId) {
      throw const ValidationException('No se puede guardar este registro.');
    }
    final checked = validateFieldValues(definition, values);
    final when = observedAt ?? _now();
    final recorded = _now();
    final row = {
      'id': _uuid.v4(),
      'profile_id': profileId,
      'space_id': spaceId,
      'companion_id': companionId,
      'run_id': null,
      'template_id': templateId,
      'definition_snapshot': jsonEncode(definition.toJson()),
      'original': text,
      'values_json': jsonEncode(checked),
      'provenance': provenance,
      'revision': 1,
      'supersedes_id': null,
      'observed_at': when.millisecondsSinceEpoch,
      'recorded_at': recorded.millisecondsSinceEpoch,
      'local_day': Observation.dayOf(when),
    };
    await tx.insert('trackia_observations', row);
    return _read(row);
  });

  /// Adds a revision with corrected [values]. The original text and the first
  /// revision stay exactly as they were. Only the latest revision can be
  /// corrected.
  Future<Observation> correct(
    String id, {
    required Map<String, Object> values,
  }) => _db.transaction((tx) async {
    final current = await _latest(tx, id);
    if (current == null) {
      throw const ValidationException('No se encuentra el registro.');
    }
    final definition = ActivityDefinition.fromJson(
      jsonDecode(current['definition_snapshot'] as String)
          as Map<String, dynamic>,
    );
    final checked = validateFieldValues(definition, values);
    final row = {
      ...current,
      'id': _uuid.v4(),
      'values_json': jsonEncode(checked),
      'revision': (current['revision'] as int) + 1,
      'supersedes_id': current['id'],
      'recorded_at': _now().millisecondsSinceEpoch,
    };
    await tx.insert('trackia_observations', row);
    return _read(row);
  });

  /// Records of one companion, oldest first. By default only the latest
  /// revision of each record counts.
  Future<List<Observation>> list({
    required String companionId,
    String? day,
    bool includeSuperseded = false,
  }) async {
    final rows = await _db.query(
      'trackia_observations',
      where:
          'profile_id = ? AND companion_id = ?'
          '${day == null ? '' : ' AND local_day = ?'}'
          '${includeSuperseded ? '' : ' AND id NOT IN (SELECT supersedes_id FROM trackia_observations WHERE supersedes_id IS NOT NULL)'}',
      whereArgs: [profileId, companionId, ?day],
      orderBy: 'observed_at, revision, recorded_at, rowid',
    );
    return rows.map(_read).toList();
  }

  /// Every revision of the record that [id] belongs to, first to last.
  Future<List<Observation>> history(String id) async {
    final chain = <Map<String, Object?>>[];
    Map<String, Object?>? row = await _row(_db, id);
    while (row != null) {
      chain.add(row);
      final previous = row['supersedes_id'] as String?;
      row = previous == null ? null : await _row(_db, previous);
    }
    return chain.reversed.map(_read).toList();
  }

  Future<Map<String, Object?>?> _row(DatabaseExecutor db, String id) async {
    final rows = await db.query(
      'trackia_observations',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
    return rows.firstOrNull;
  }

  /// The row for [id] if nothing supersedes it yet.
  Future<Map<String, Object?>?> _latest(DatabaseExecutor db, String id) async {
    final row = await _row(db, id);
    if (row == null) return null;
    final newer = await db.query(
      'trackia_observations',
      where: 'supersedes_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return newer.isEmpty ? row : null;
  }

  Observation _read(Map<String, Object?> row) => Observation(
    id: row['id'] as String,
    profileId: row['profile_id'] as String,
    spaceId: row['space_id'] as String,
    companionId: row['companion_id'] as String,
    runId: row['run_id'] as String?,
    templateId: row['template_id'] as String?,
    definition: ActivityDefinition.fromJson(
      jsonDecode(row['definition_snapshot'] as String) as Map<String, dynamic>,
    ),
    original: row['original'] as String,
    values: Map<String, Object>.from(
      jsonDecode(row['values_json'] as String) as Map,
    ),
    provenance: row['provenance'] as String,
    revision: row['revision'] as int,
    supersedesId: row['supersedes_id'] as String?,
    observedAt: DateTime.fromMillisecondsSinceEpoch(row['observed_at'] as int),
    recordedAt: DateTime.fromMillisecondsSinceEpoch(row['recorded_at'] as int),
    localDay: row['local_day'] as String,
  );
}
