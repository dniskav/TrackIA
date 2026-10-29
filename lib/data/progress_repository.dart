import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/observation.dart';
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
    this.revision = 0,
  });

  static const modes = {'reminder', 'game'};

  final String companionId, mode;
  final bool goalsEnabled, streaksEnabled, achievementsEnabled, cheersEnabled;
  final int freeDaysPerWeek;
  final List<String> dismissedSuggestions;

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
  }) => CompanionSettings(
    companionId: companionId,
    mode: mode ?? this.mode,
    goalsEnabled: goalsEnabled ?? this.goalsEnabled,
    streaksEnabled: streaksEnabled ?? this.streaksEnabled,
    achievementsEnabled: achievementsEnabled ?? this.achievementsEnabled,
    cheersEnabled: cheersEnabled ?? this.cheersEnabled,
    freeDaysPerWeek: freeDaysPerWeek ?? this.freeDaysPerWeek,
    dismissedSuggestions: dismissedSuggestions ?? this.dismissedSuggestions,
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
        revision: row['revision'] as int,
      );

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
