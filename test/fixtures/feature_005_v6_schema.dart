// Synthetic copy of the released v6 schema for migration tests.
import 'package:sqflite/sqflite.dart';

Future<void> createSyntheticV6Tables(Database db) async {
  const statements = [
    '''CREATE TABLE trackia_observations (
      id TEXT PRIMARY KEY,
      profile_id TEXT NOT NULL, space_id TEXT NOT NULL, companion_id TEXT NOT NULL,
      run_id TEXT, template_id TEXT,
      definition_snapshot TEXT NOT NULL,
      original TEXT NOT NULL,
      values_json TEXT NOT NULL,
      provenance TEXT NOT NULL CHECK(provenance IN ('user','assistant','import')),
      revision INTEGER NOT NULL CHECK(revision > 0),
      supersedes_id TEXT REFERENCES trackia_observations(id),
      observed_at INTEGER NOT NULL, recorded_at INTEGER NOT NULL, local_day TEXT NOT NULL,
      FOREIGN KEY(profile_id, space_id) REFERENCES trackia_spaces(profile_id, id))''',
    '''CREATE INDEX observation_companion_day
      ON trackia_observations(profile_id, companion_id, local_day)''',
    '''CREATE TABLE trackia_activity_templates (
      id TEXT PRIMARY KEY,
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
      definition TEXT NOT NULL,
      instant INTEGER NOT NULL CHECK(instant IN (0,1)),
      origin TEXT NOT NULL CHECK(origin IN ('user','assistant','template')),
      created_at INTEGER NOT NULL, archived_at INTEGER)''',
    '''CREATE TABLE trackia_companion_settings (
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
      mode TEXT NOT NULL CHECK(mode IN ('reminder','game')) DEFAULT 'reminder',
      goals_enabled INTEGER NOT NULL DEFAULT 1, streaks_enabled INTEGER NOT NULL DEFAULT 1,
      achievements_enabled INTEGER NOT NULL DEFAULT 1, cheers_enabled INTEGER NOT NULL DEFAULT 1,
      free_days_per_week INTEGER NOT NULL DEFAULT 1 CHECK(free_days_per_week BETWEEN 0 AND 3),
      dismissed_suggestions TEXT NOT NULL DEFAULT '[]',
      ai_override TEXT,
      revision INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL,
      PRIMARY KEY(profile_id, companion_id))''',
    '''CREATE TABLE trackia_reminders (
      id TEXT PRIMARY KEY,
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
      days INTEGER NOT NULL CHECK(days BETWEEN 1 AND 127),
      window_start_min INTEGER NOT NULL CHECK(window_start_min BETWEEN 0 AND 1439),
      window_end_min INTEGER NOT NULL CHECK(window_end_min BETWEEN 1 AND 1440),
      last_call_min INTEGER,
      tone TEXT NOT NULL CHECK(tone IN ('neutral','cheer')) DEFAULT 'neutral',
      minimum TEXT,
      enabled INTEGER NOT NULL DEFAULT 1, paused_at INTEGER,
      revision INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL,
      CHECK(window_start_min < window_end_min))''',
    '''CREATE TABLE trackia_goals (
      id TEXT PRIMARY KEY,
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, activity_key TEXT,
      metric TEXT NOT NULL,
      period TEXT NOT NULL CHECK(period IN ('day','week')),
      target REAL NOT NULL CHECK(target > 0), minimum REAL CHECK(minimum > 0),
      origin TEXT NOT NULL CHECK(origin IN ('user','assistant','template')),
      created_at INTEGER NOT NULL, archived_at INTEGER)''',
    '''CREATE TABLE trackia_achievements (
      id TEXT PRIMARY KEY,
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, activity_key TEXT,
      rule TEXT NOT NULL, rule_hash TEXT NOT NULL,
      title TEXT NOT NULL, icon TEXT NOT NULL,
      origin TEXT NOT NULL CHECK(origin IN ('generated','user','assistant')),
      created_at INTEGER NOT NULL, archived_at INTEGER,
      UNIQUE(profile_id, companion_id, rule_hash))''',
    '''CREATE TABLE trackia_achievement_unlocks (
      id TEXT PRIMARY KEY,
      achievement_id TEXT NOT NULL UNIQUE REFERENCES trackia_achievements(id) ON DELETE CASCADE,
      unlocked_at INTEGER NOT NULL, value REAL NOT NULL,
      source_activity_id TEXT, source_observation_id TEXT)''',
    '''CREATE TABLE trackia_chats (
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
      payload TEXT NOT NULL,
      legacy_key TEXT, verified_at INTEGER, updated_at INTEGER NOT NULL,
      PRIMARY KEY(profile_id, companion_id))''',
    '''CREATE TABLE trackia_chat_archives (
      id TEXT PRIMARY KEY,
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
      payload TEXT NOT NULL, legacy_key TEXT, verified_at INTEGER,
      created_at INTEGER NOT NULL)''',
  ];
  for (final statement in statements) {
    await db.execute(statement);
  }
}
