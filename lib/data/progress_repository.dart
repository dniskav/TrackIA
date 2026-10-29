import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../application/progress_engine.dart';
import '../domain/ai_config.dart';
import '../domain/observation.dart';
import '../domain/progress.dart';
import '../domain/reminder.dart';
import '../domain/space.dart';
import '../domain/workout.dart';

/// How a companion is used: only reminders, or also goals, streaks and
/// achievements (data-model §3, FR-026).
class CompanionSettings {
  const CompanionSettings({
    required this.companionId,
    this.mode = 'reminder',
    this.goalsEnabled = true,
    this.streaksEnabled = true,
    this.achievementsEnabled = true,
    this.cheersEnabled = true,
    this.freeDaysPerWeek = 1,
    this.dismissedSuggestions = const [],
    this.aiOverride,
    this.revision = 0,
  });

  static const modes = {'reminder', 'game'};

  final String companionId, mode;
  final bool goalsEnabled, streaksEnabled, achievementsEnabled, cheersEnabled;
  final int freeDaysPerWeek;
  final List<String> dismissedSuggestions;

  /// US11: this companion's model instead of the profile's; `null` = default.
  final AiOverride? aiOverride;

  /// 0 while nothing has been saved: the defaults of an existing companion.
  final int revision;

  bool get game => mode == 'game';

  CompanionSettings copyWith({
    String? mode,
    bool? goalsEnabled,
    bool? streaksEnabled,
    bool? achievementsEnabled,
    bool? cheersEnabled,
    int? freeDaysPerWeek,
    List<String>? dismissedSuggestions,
    AiOverride? aiOverride,
    bool clearAiOverride = false,
  }) => CompanionSettings(
    companionId: companionId,
    mode: mode ?? this.mode,
    goalsEnabled: goalsEnabled ?? this.goalsEnabled,
    streaksEnabled: streaksEnabled ?? this.streaksEnabled,
    achievementsEnabled: achievementsEnabled ?? this.achievementsEnabled,
    cheersEnabled: cheersEnabled ?? this.cheersEnabled,
    freeDaysPerWeek: freeDaysPerWeek ?? this.freeDaysPerWeek,
    dismissedSuggestions: dismissedSuggestions ?? this.dismissedSuggestions,
    aiOverride: clearAiOverride ? null : aiOverride ?? this.aiOverride,
    revision: revision,
  );
}

/// `trackia_companion_settings` and `trackia_reminders`, scoped to one
/// profile: another profile's rows are never read or changed from here.
class ProgressRepository {
  ProgressRepository(this._db, this._now, this.profileId);

  static const _uuid = Uuid();

  final Database _db;
  final DateTime Function() _now;
  final String profileId;

  static String _scope(String companionId) => validTrackiaId(companionId);

  // --- Companion settings ---------------------------------------------------

  /// The saved settings, or the defaults (mode `reminder`) when none exist.
  Future<CompanionSettings> settings(String companionId) async {
    final rows = await _db.query(
      'trackia_companion_settings',
      where: 'profile_id = ? AND companion_id = ?',
      whereArgs: [profileId, _scope(companionId)],
    );
    return rows.isEmpty
        ? CompanionSettings(companionId: companionId)
        : _readSettings(rows.single);
  }

  Future<void> saveSettings(CompanionSettings value) async {
    final companionId = _scope(value.companionId);
    if (!CompanionSettings.modes.contains(value.mode) ||
        value.freeDaysPerWeek < 0 ||
        value.freeDaysPerWeek > 3) {
      throw const ValidationException('Los ajustes no son válidos.');
    }
    await _db.transaction((tx) async {
      final values = {
        'mode': value.mode,
        'goals_enabled': value.goalsEnabled ? 1 : 0,
        'streaks_enabled': value.streaksEnabled ? 1 : 0,
        'achievements_enabled': value.achievementsEnabled ? 1 : 0,
        'cheers_enabled': value.cheersEnabled ? 1 : 0,
        'free_days_per_week': value.freeDaysPerWeek,
        'dismissed_suggestions': jsonEncode(value.dismissedSuggestions),
        'ai_override':
            value.aiOverride == null
                ? null
                : jsonEncode(value.aiOverride!.toJson()),
        'updated_at': _now().millisecondsSinceEpoch,
      };
      final changed = await tx.rawUpdate(
        'UPDATE trackia_companion_settings SET '
        '${values.keys.map((k) => '$k = ?').join(', ')}, revision = revision + 1 '
        'WHERE profile_id = ? AND companion_id = ?',
        [...values.values, profileId, companionId],
      );
      if (changed == 0) {
        await tx.insert('trackia_companion_settings', {
          'profile_id': profileId,
          'companion_id': companionId,
          ...values,
        });
      }
    });
  }

  CompanionSettings _readSettings(Map<String, Object?> row) =>
      CompanionSettings(
        companionId: row['companion_id'] as String,
        mode: row['mode'] as String,
        goalsEnabled: row['goals_enabled'] == 1,
        streaksEnabled: row['streaks_enabled'] == 1,
        achievementsEnabled: row['achievements_enabled'] == 1,
        cheersEnabled: row['cheers_enabled'] == 1,
        freeDaysPerWeek: row['free_days_per_week'] as int,
        dismissedSuggestions: List<String>.from(
          jsonDecode(row['dismissed_suggestions'] as String) as List,
        ),
        aiOverride: _readOverride(row['ai_override']),
        revision: row['revision'] as int,
      );

  /// A damaged value is treated as no exception: the default setup still works.
  static AiOverride? _readOverride(Object? raw) {
    if (raw is! String) return null;
    try {
      return AiOverride.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      debugPrint('AI override unreadable: ${error.runtimeType}');
      return null;
    }
  }

  // --- Reminders ------------------------------------------------------------

  /// The companion's reminder, if it has one (at most one in this delivery).
  Future<Reminder?> reminderFor(String companionId) async {
    final rows = await _db.query(
      'trackia_reminders',
      where: 'profile_id = ? AND companion_id = ?',
      whereArgs: [profileId, _scope(companionId)],
    );
    return rows.isEmpty ? null : _readReminder(rows.first);
  }

  /// Every reminder of the profile that is switched on.
  Future<List<Reminder>> activeReminders() async {
    final rows = await _db.query(
      'trackia_reminders',
      where: 'profile_id = ? AND enabled = 1',
      whereArgs: [profileId],
      orderBy: 'created_at, rowid',
    );
    return rows.map(_readReminder).toList();
  }

  /// Creates or replaces the companion's reminder. Saving it also lifts a
  /// pause: the user just looked at it.
  Future<Reminder> saveReminder({
    required String companionId,
    required int days,
    required int windowStartMin,
    required int windowEndMin,
    int? lastCallMin,
    String tone = 'neutral',
    Map<String, Object?>? minimum,
    bool enabled = true,
  }) => _db.transaction((tx) async {
    final scoped = _scope(companionId);
    final draft = Reminder(
      id: 'draft',
      companionId: scoped,
      days: days,
      windowStartMin: windowStartMin,
      windowEndMin: windowEndMin,
      lastCallMin: lastCallMin,
      tone: tone,
      minimum: minimum,
      enabled: enabled,
    );
    final existing = await tx.query(
      'trackia_reminders',
      where: 'profile_id = ? AND companion_id = ?',
      whereArgs: [profileId, scoped],
    );
    final values = {
      'days': draft.days,
      'window_start_min': draft.windowStartMin,
      'window_end_min': draft.windowEndMin,
      'last_call_min': draft.lastCallMin,
      'tone': draft.tone,
      'minimum': minimum == null ? null : jsonEncode(minimum),
      'enabled': enabled ? 1 : 0,
      'paused_at': null,
    };
    if (existing.isEmpty) {
      await tx.insert('trackia_reminders', {
        'id': _uuid.v4(),
        'profile_id': profileId,
        'companion_id': scoped,
        'created_at': _now().millisecondsSinceEpoch,
        ...values,
      });
    } else {
      await tx.update(
        'trackia_reminders',
        {
          ...values,
          'revision': (existing.first['revision'] as int) + 1,
          // A reminder saved while paused restarts the 7-day count.
          if (existing.first['paused_at'] != null)
            'created_at': _now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
    return _readReminder(
      (await tx.query(
        'trackia_reminders',
        where: 'profile_id = ? AND companion_id = ?',
        whereArgs: [profileId, scoped],
      )).first,
    );
  });

  Future<void> deleteReminder(String companionId) => _db.delete(
    'trackia_reminders',
    where: 'profile_id = ? AND companion_id = ?',
    whereArgs: [profileId, _scope(companionId)],
  );

  /// Pauses (now) or resumes the companion's reminder. Resuming restarts the
  /// 7-day count (`created_at` is the count's lower bound), so a reminder the
  /// user resumes is not paused again for the same gap.
  Future<void> setPaused(String companionId, {required bool paused}) {
    final now = _now().millisecondsSinceEpoch;
    return _db.update(
      'trackia_reminders',
      {'paused_at': paused ? now : null, if (!paused) 'created_at': now},
      where: 'profile_id = ? AND companion_id = ?',
      whereArgs: [profileId, _scope(companionId)],
    );
  }

  Reminder _readReminder(Map<String, Object?> row) {
    final minimum = row['minimum'] as String?;
    final paused = row['paused_at'] as int?;
    return Reminder(
      id: row['id'] as String,
      companionId: row['companion_id'] as String,
      days: row['days'] as int,
      windowStartMin: row['window_start_min'] as int,
      windowEndMin: row['window_end_min'] as int,
      lastCallMin: row['last_call_min'] as int?,
      tone: row['tone'] as String,
      minimum: minimum == null
          ? null
          : Map<String, Object?>.from(jsonDecode(minimum) as Map),
      enabled: row['enabled'] == 1,
      pausedAt: paused == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(paused),
      revision: row['revision'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  // --- Done days -----------------------------------------------------------

  /// Local days (`YYYY-MM-DD`) with at least one session of [companionId]: an
  /// ended segment or finished activity, or a point record. Until the progress
  /// engine exists (phase 7), a day is «done» when it has one.
  Future<Set<String>> sessionDays(String companionId) async {
    final id = _scope(companionId);
    final days = <String>{};
    for (final row in await _db.query(
      'trackia_observations',
      columns: ['local_day'],
      distinct: true,
      where: 'profile_id = ? AND companion_id = ?',
      whereArgs: [profileId, id],
    )) {
      days.add(row['local_day'] as String);
    }
    final owners = <String, String>{};
    for (final row in await _db.query(
      'activities',
      columns: ['id', 'definition', 'finished_at'],
    )) {
      final definition = jsonDecode(row['definition'] as String) as Map;
      final owner = (definition['companionId'] as String?) ?? 'gymbro';
      if (owner != id) continue;
      owners[row['id'] as String] = owner;
      final finished = row['finished_at'] as int?;
      if (finished != null) {
        days.add(
          Observation.dayOf(DateTime.fromMillisecondsSinceEpoch(finished)),
        );
      }
    }
    if (owners.isNotEmpty) {
      for (final row in await _db.query(
        'activity_intervals',
        columns: ['activity_id', 'ended_at'],
        where: 'ended_at IS NOT NULL',
      )) {
        if (owners.containsKey(row['activity_id'])) {
          days.add(
            Observation.dayOf(
              DateTime.fromMillisecondsSinceEpoch(row['ended_at'] as int),
            ),
          );
        }
      }
    }
    return days;
  }

  // --- Goals ---------------------------------------------------------------

  /// The companion's goal, if it has one (a single active goal in this
  /// delivery).
  Future<GoalRule?> activeGoal(String companionId) async {
    final rows = await _db.query(
      'trackia_goals',
      where: 'profile_id = ? AND companion_id = ? AND archived_at IS NULL',
      whereArgs: [profileId, _scope(companionId)],
      orderBy: 'created_at DESC, rowid DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return GoalRule(
      metric: Metric.fromJson(jsonDecode(row['metric'] as String)),
      period: row['period'] as String,
      target: (row['target'] as num).toDouble(),
      minimum: (row['minimum'] as num?)?.toDouble(),
    );
  }

  /// Replaces the companion's goal; the previous one is archived, not erased.
  Future<void> saveGoal(
    String companionId,
    GoalRule goal, {
    String origin = 'user',
  }) => _db.transaction((tx) async {
    final id = _scope(companionId);
    if (!const {'user', 'assistant', 'template'}.contains(origin)) {
      throw const ValidationException('El origen de la meta no es válido.');
    }
    final now = _now().millisecondsSinceEpoch;
    await tx.update(
      'trackia_goals',
      {'archived_at': now},
      where: 'profile_id = ? AND companion_id = ? AND archived_at IS NULL',
      whereArgs: [profileId, id],
    );
    await tx.insert('trackia_goals', {
      'id': _uuid.v4(),
      'profile_id': profileId,
      'companion_id': id,
      'metric': jsonEncode(goal.metric.toJson()),
      'period': goal.period,
      'target': goal.target,
      'minimum': goal.minimum,
      'origin': origin,
      'created_at': now,
    });
  });

  Future<void> clearGoal(String companionId) => _db.update(
    'trackia_goals',
    {'archived_at': _now().millisecondsSinceEpoch},
    where: 'profile_id = ? AND companion_id = ? AND archived_at IS NULL',
    whereArgs: [profileId, _scope(companionId)],
  );

  // --- Achievements --------------------------------------------------------

  /// Saves the generated achievements that do not exist yet (same rule, same
  /// companion: never a duplicate). Returns how many were new.
  Future<int> ensureAchievements(
    String companionId,
    List<GeneratedAchievement> generated, {
    String origin = 'generated',
  }) => _db.transaction((tx) async {
    final id = _scope(companionId);
    if (!Achievement.origins.contains(origin)) {
      throw const ValidationException('El origen del logro no es válido.');
    }
    var added = 0;
    for (final g in generated) {
      if (!Achievement.icons.contains(g.icon)) continue;
      final inserted = await tx.insert('trackia_achievements', {
        'id': _uuid.v4(),
        'profile_id': profileId,
        'companion_id': id,
        'rule': jsonEncode(g.rule.toJson()),
        'rule_hash': g.ruleHash,
        'title': g.title,
        'icon': g.icon,
        'origin': origin,
        'created_at': _now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      if (inserted > 0) added++;
    }
    return added;
  });

  /// The companion's achievements with their unlock, oldest first.
  Future<List<Achievement>> achievements(String companionId) async {
    final rows = await _db.rawQuery(
      'SELECT a.*, u.unlocked_at AS u_at, u.value AS u_value, '
      'u.source_activity_id AS u_activity, u.source_observation_id AS u_observation '
      'FROM trackia_achievements a '
      'LEFT JOIN trackia_achievement_unlocks u ON u.achievement_id = a.id '
      'WHERE a.profile_id = ? AND a.companion_id = ? AND a.archived_at IS NULL '
      'ORDER BY a.created_at, a.rowid',
      [profileId, _scope(companionId)],
    );
    return rows.map((row) {
      final at = row['u_at'] as int?;
      return Achievement(
        id: row['id'] as String,
        companionId: row['companion_id'] as String,
        activityKey: row['activity_key'] as String?,
        rule: AchievementRule.fromJson(jsonDecode(row['rule'] as String)),
        ruleHash: row['rule_hash'] as String,
        title: row['title'] as String,
        icon: row['icon'] as String,
        origin: row['origin'] as String,
        unlock: at == null
            ? null
            : AchievementUnlock(
                achievementId: row['id'] as String,
                unlockedAt: DateTime.fromMillisecondsSinceEpoch(at),
                value: (row['u_value'] as num).toDouble(),
                sourceActivityId: row['u_activity'] as String?,
                sourceObservationId: row['u_observation'] as String?,
              ),
      );
    }).toList();
  }

  Future<void> renameAchievement(String achievementId, String title) async {
    final clean = title.trim();
    if (clean.isEmpty || clean.length > 80) {
      throw const ValidationException(
        'El título debe tener entre 1 y 80 caracteres.',
      );
    }
    await _db.update(
      'trackia_achievements',
      {'title': clean},
      where: 'id = ? AND profile_id = ?',
      whereArgs: [achievementId, profileId],
    );
  }

  /// Stores unlocks. An achievement unlocks once: a second attempt is ignored.
  Future<void> recordUnlocks(
    List<NewUnlock> unlocks, {
    String? sourceActivityId,
    String? sourceObservationId,
  }) => _db.transaction((tx) async {
    for (final u in unlocks) {
      await tx.insert('trackia_achievement_unlocks', {
        'id': _uuid.v4(),
        'achievement_id': u.achievement.id,
        'unlocked_at': _now().millisecondsSinceEpoch,
        'value': u.value,
        'source_activity_id': sourceActivityId,
        'source_observation_id': sourceObservationId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  });

  /// The typed fields of the companion's saved activities and activity
  /// templates (key, label, unit, type, aggregate…), first occurrence of each
  /// key. What a goal or an achievement can be built on.
  Future<List<Map<String, dynamic>>> typedFields(String companionId) async {
    final id = _scope(companionId);
    final found = <String, Map<String, dynamic>>{};
    void take(String definitionJson) {
      final definition = jsonDecode(definitionJson) as Map;
      if (((definition['companionId'] as String?) ?? 'gymbro') != id) return;
      for (final f in (definition['fields'] as List? ?? const [])) {
        if (f is Map && f['type'] != null && f['key'] is String) {
          found.putIfAbsent(
            f['key'] as String,
            () => Map<String, dynamic>.from(f),
          );
        }
      }
    }

    for (final row in await _db.query(
      'trackia_activity_templates',
      columns: ['definition'],
      where: 'profile_id = ? AND companion_id = ? AND archived_at IS NULL',
      whereArgs: [profileId, id],
      orderBy: 'created_at, rowid',
    )) {
      take(row['definition'] as String);
    }
    for (final row in await _db.query(
      'activities',
      columns: ['definition'],
      orderBy: 'created_at DESC, rowid DESC',
    )) {
      take(row['definition'] as String);
    }
    return found.values.toList();
  }

  // --- Data for the engine -------------------------------------------------

  /// The companion's saved records as the engine reads them: finished or
  /// started activities (time and values) and point records, only the latest
  /// revision of each. An activity counts as a session from its first ended
  /// segment or saved value.
  Future<ProgressData> loadData(String companionId) async {
    final id = _scope(companionId);
    final sessions = <ProgressSession>[];
    final values = <ProgressValue>[];
    final typed = <String>{};

    void typedFrom(Object? fields) {
      for (final f in (fields as List? ?? const [])) {
        if (f is Map && f['type'] != null && f['key'] is String) {
          typed.add(f['key'] as String);
        }
      }
    }

    final owned = <String, Map<String, Object?>>{};
    for (final row in await _db.query(
      'activities',
      columns: ['id', 'definition', 'finished_at'],
    )) {
      final definition = jsonDecode(row['definition'] as String) as Map;
      if (((definition['companionId'] as String?) ?? 'gymbro') != id) continue;
      typedFrom(definition['fields']);
      owned[row['id'] as String] = row;
    }
    if (owned.isNotEmpty) {
      final seconds = <String, int>{};
      final lastEnd = <String, int>{};
      for (final row in await _db.query(
        'activity_intervals',
        columns: ['activity_id', 'started_at', 'ended_at'],
        where: 'ended_at IS NOT NULL',
      )) {
        final activity = row['activity_id'] as String;
        if (!owned.containsKey(activity)) continue;
        final ended = row['ended_at'] as int;
        seconds[activity] =
            (seconds[activity] ?? 0) +
            (ended - (row['started_at'] as int)) ~/ 1000;
        if (ended > (lastEnd[activity] ?? 0)) lastEnd[activity] = ended;
      }
      final firstValue = <String, int>{};
      final byActivity = <String, List<ProgressValue>>{};
      for (final row in await _db.query(
        'activity_messages',
        columns: ['activity_id', 'recorded_at', 'metrics'],
        where: "role = 'user'",
        orderBy: 'recorded_at, rowid',
      )) {
        final activity = row['activity_id'] as String;
        if (!owned.containsKey(activity)) continue;
        final metrics = jsonDecode(row['metrics'] as String);
        if (metrics is! Map || metrics.isEmpty) continue;
        final at = row['recorded_at'] as int;
        firstValue.putIfAbsent(activity, () => at);
        final day = Observation.dayOf(DateTime.fromMillisecondsSinceEpoch(at));
        for (final entry in metrics.entries) {
          final v = entry.value;
          if (entry.key is String && (v is num || v is bool || v is String)) {
            (byActivity[activity] ??= []).add(
              ProgressValue(
                sessionId: activity,
                day: day,
                field: entry.key as String,
                value: v as Object,
              ),
            );
          }
        }
      }
      for (final entry in owned.entries) {
        final activity = entry.key;
        final finished = entry.value['finished_at'] as int?;
        final moment = finished ?? lastEnd[activity] ?? firstValue[activity];
        if (moment == null) continue;
        sessions.add(
          ProgressSession(
            id: activity,
            day: Observation.dayOf(DateTime.fromMillisecondsSinceEpoch(moment)),
            seconds: seconds[activity] ?? 0,
            activityId: activity,
          ),
        );
        values.addAll(byActivity[activity] ?? const []);
      }
    }

    for (final row in await _db.query(
      'trackia_observations',
      where:
          'profile_id = ? AND companion_id = ? AND id NOT IN '
          '(SELECT supersedes_id FROM trackia_observations WHERE supersedes_id IS NOT NULL)',
      whereArgs: [profileId, id],
      orderBy: 'observed_at, revision, rowid',
    )) {
      final observation = row['id'] as String;
      final day = row['local_day'] as String;
      typedFrom(
        (jsonDecode(row['definition_snapshot'] as String) as Map)['fields'],
      );
      sessions.add(
        ProgressSession(id: observation, day: day, observationId: observation),
      );
      final recorded = jsonDecode(row['values_json'] as String);
      if (recorded is Map) {
        for (final entry in recorded.entries) {
          final v = entry.value;
          if (entry.key is String && (v is num || v is bool || v is String)) {
            values.add(
              ProgressValue(
                sessionId: observation,
                day: day,
                field: entry.key as String,
                value: v as Object,
              ),
            );
          }
        }
      }
    }
    sessions.sort((a, b) => a.day.compareTo(b.day));
    return ProgressData(sessions: sessions, values: values, typedFields: typed);
  }

  // --- Cascade -------------------------------------------------------------

  /// Deletes what belongs to a deleted companion (data-model §3). Point
  /// records and activities are kept: they are the user's data.
  Future<void> deleteCompanion(String companionId) => _db.transaction((
    tx,
  ) async {
    final id = _scope(companionId);
    final where = 'profile_id = ? AND companion_id = ?';
    final args = [profileId, id];
    await tx.delete(
      'trackia_achievement_unlocks',
      where:
          'achievement_id IN (SELECT id FROM trackia_achievements WHERE $where)',
      whereArgs: args,
    );
    for (final table in const [
      'trackia_achievements',
      'trackia_goals',
      'trackia_reminders',
      'trackia_companion_settings',
      'trackia_activity_templates',
      'trackia_chats',
      'trackia_chat_archives',
    ]) {
      await tx.delete(table, where: where, whereArgs: args);
    }
  });
}
