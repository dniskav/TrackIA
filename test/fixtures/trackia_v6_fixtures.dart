import 'package:sqflite/sqflite.dart';

import 'trackia_legacy_fixtures.dart';

/// Tables added by the v6 migration, in dependency-safe drop order.
const trackiaV6Tables = [
  'trackia_achievement_unlocks',
  'trackia_achievements',
  'trackia_goals',
  'trackia_reminders',
  'trackia_companion_settings',
  'trackia_activity_templates',
  'trackia_observations',
  'trackia_chat_archives',
  'trackia_chats',
];

/// Synthetic v5 database: the legacy fixture plus the empty v5 scope tables.
/// Re-opening it with the current repository must upgrade it additively.
class TrackiaV5Fixture {
  static Future<TrackiaLegacyFixture> create({
    required DatabaseFactory factory,
    required String path,
  }) async {
    final legacy = await TrackiaLegacyFixture.create(
      factory: factory,
      path: path,
    );
    final db = await factory.openDatabase(path);
    try {
      await db.execute('''CREATE TABLE trackia_spaces (
        id TEXT NOT NULL, profile_id TEXT NOT NULL, name TEXT NOT NULL,
        revision INTEGER NOT NULL CHECK(revision > 0),
        PRIMARY KEY(profile_id, id))''');
      await db.execute('''CREATE TABLE trackia_legacy_workout_scope (
        workout_id TEXT PRIMARY KEY REFERENCES workouts(id) ON DELETE CASCADE,
        profile_id TEXT NOT NULL, space_id TEXT NOT NULL,
        FOREIGN KEY(profile_id, space_id) REFERENCES trackia_spaces(profile_id, id))''');
      await db.execute('''CREATE TABLE trackia_legacy_activity_scope (
        activity_id TEXT PRIMARY KEY REFERENCES activities(id) ON DELETE CASCADE,
        profile_id TEXT NOT NULL, space_id TEXT NOT NULL,
        FOREIGN KEY(profile_id, space_id) REFERENCES trackia_spaces(profile_id, id))''');
      await db.setVersion(5);
    } finally {
      await db.close();
    }
    return legacy;
  }
}

/// Pre-004 chat state as stored in secure storage: one active chat and one
/// archive per companion, plus a tiny attachment (base64 of `PNGDATA`).
class LegacyChatFixture {
  static const profileId = 'local';
  static const companionId = 'gymbro';
  static const archiveId = 'archive-1';
  static const attachmentBase64 = 'UE5HREFUQQ==';

  static Map<String, dynamic> chat() => {
    'sessionId': 'session-1',
    'messages': [
      {'role': 'user', 'content': 'Hola'},
      {
        'role': 'assistant',
        'content': 'Preparado.',
        'attachment': {
          'name': 'nota.png',
          'mime': 'image/png',
          'data': attachmentBase64,
        },
      },
    ],
    'archives': <Object>[],
    'archivedActivityMessageIds': <String>[],
    'carryForward': '',
  };

  static Map<String, dynamic> archive() => {
    'id': archiveId,
    'messages': [
      {'role': 'user', 'content': 'Mensaje archivado'},
    ],
  };
}
