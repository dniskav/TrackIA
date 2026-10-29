import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/activity.dart';
import '../domain/space.dart';
import '../domain/workout.dart';

/// A saved activity definition the user can start again: their own
/// activities, plus point-record shapes (`instant`) like «Beber agua».
class ActivityTemplate {
  const ActivityTemplate({
    required this.id,
    required this.companionId,
    required this.definition,
    required this.instant,
    required this.origin,
    required this.createdAt,
    this.archivedAt,
  });

  final String id, companionId, origin;
  final ActivityDefinition definition;
  final bool instant;
  final DateTime createdAt;
  final DateTime? archivedAt;
  bool get archived => archivedAt != null;
}

/// `trackia_activity_templates`, scoped to the repository's profile.
class ActivityTemplateRepository {
  ActivityTemplateRepository(this._db, this._now, this.profileId);

  static const origins = {'user', 'assistant', 'template'};
  static const _uuid = Uuid();

  final Database _db;
  final DateTime Function() _now;
  final String profileId;

  /// Saves [definition] for [companionId]. Saving an activity that is already
  /// saved (same key, same kind) updates it instead of adding a duplicate; an
  /// archived one is never reused.
  Future<ActivityTemplate> save({
    required String companionId,
    required ActivityDefinition definition,
    bool instant = false,
    String origin = 'user',
  }) => _db.transaction((tx) async {
    if (validTrackiaId(companionId) != definition.companionId ||
        !origins.contains(origin)) {
      throw const ValidationException('No se puede guardar esta actividad.');
    }
    final json = jsonEncode(definition.toJson());
    final existing =
        (await tx.query(
          'trackia_activity_templates',
          where:
              'profile_id = ? AND companion_id = ? AND instant = ? AND archived_at IS NULL',
          whereArgs: [profileId, companionId, instant ? 1 : 0],
        )).where((row) => _read(row).definition.activityKey == definition.activityKey)
            .firstOrNull;
    if (existing != null) {
      await tx.update(
        'trackia_activity_templates',
        {'definition': json, 'origin': origin},
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
      return _read({...existing, 'definition': json, 'origin': origin});
    }
    final row = {
      'id': _uuid.v4(),
      'profile_id': profileId,
      'companion_id': companionId,
      'definition': json,
      'instant': instant ? 1 : 0,
      'origin': origin,
      'created_at': _now().millisecondsSinceEpoch,
      'archived_at': null,
    };
    await tx.insert('trackia_activity_templates', row);
    return _read(row);
  });

  Future<List<ActivityTemplate>> list({
    required String companionId,
    bool includeArchived = false,
  }) async {
    final rows = await _db.query(
      'trackia_activity_templates',
      where:
          'profile_id = ? AND companion_id = ?'
          '${includeArchived ? '' : ' AND archived_at IS NULL'}',
      whereArgs: [profileId, companionId],
      orderBy: 'created_at, rowid',
    );
    return rows.map(_read).toList();
  }

  Future<void> archive(String id) async {
    final changed = await _db.update(
      'trackia_activity_templates',
      {'archived_at': _now().millisecondsSinceEpoch},
      where: 'id = ? AND profile_id = ? AND archived_at IS NULL',
      whereArgs: [id, profileId],
    );
    if (changed == 0) {
      throw const ValidationException('No se encuentra la actividad guardada.');
    }
  }

  ActivityTemplate _read(Map<String, Object?> row) => ActivityTemplate(
    id: row['id'] as String,
    companionId: row['companion_id'] as String,
    definition: ActivityDefinition.fromJson(
      jsonDecode(row['definition'] as String) as Map<String, dynamic>,
    ),
    instant: row['instant'] == 1,
    origin: row['origin'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    archivedAt:
        row['archived_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['archived_at'] as int),
  );
}
