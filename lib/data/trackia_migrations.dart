part of 'sqlite_workout_repository.dart';

/// v5 only adds tables. Legacy workouts and activities keep their IDs, values,
/// foreign keys, and v3 backup representation unchanged.
Future<void> _createTrackiaV5(Database db) async {
  await db.execute('''CREATE TABLE trackia_spaces (
    id TEXT NOT NULL, profile_id TEXT NOT NULL, name TEXT NOT NULL,
    revision INTEGER NOT NULL CHECK(revision > 0),
    PRIMARY KEY(profile_id, id))''');
  await db.execute(
    '''CREATE TABLE trackia_legacy_workout_scope (
    workout_id TEXT PRIMARY KEY REFERENCES workouts(id) ON DELETE CASCADE,
    profile_id TEXT NOT NULL, space_id TEXT NOT NULL,
    FOREIGN KEY(profile_id, space_id) REFERENCES trackia_spaces(profile_id, id))''',
  );
  await db.execute(
    '''CREATE TABLE trackia_legacy_activity_scope (
    activity_id TEXT PRIMARY KEY REFERENCES activities(id) ON DELETE CASCADE,
    profile_id TEXT NOT NULL, space_id TEXT NOT NULL,
    FOREIGN KEY(profile_id, space_id) REFERENCES trackia_spaces(profile_id, id))''',
  );
}

/// v6 only adds tables for observations, templates, companion settings,
/// reminders, goals, achievements and chats. Nothing existing is altered.
Future<void> _createTrackiaV6(Database db) async {
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

/// Feature 005 v7 entities. Additive: new tables only; existing rows, columns
/// and IDs stay untouched. Definitions follow the test-provisional schemas of
/// the existing repositories and the effect model in data-model.md.
Future<void> _createTrackiaV7(Database db) async {
  const statements = [
    '''CREATE TABLE message_revision_messages (
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, id TEXT NOT NULL,
      chat_id TEXT NOT NULL, created_at INTEGER NOT NULL, current_revision_id TEXT NOT NULL,
      delivery TEXT NOT NULL, attachment_refs TEXT NOT NULL,
      PRIMARY KEY(profile_id, companion_id, id))''',
    '''CREATE TABLE message_revision_versions (
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, id TEXT NOT NULL,
      message_id TEXT NOT NULL, revision INTEGER NOT NULL, text TEXT NOT NULL,
      created_at INTEGER NOT NULL, supersedes_id TEXT,
      PRIMARY KEY(profile_id, companion_id, id),
      UNIQUE(profile_id, companion_id, message_id, revision),
      FOREIGN KEY(profile_id, companion_id, message_id)
        REFERENCES message_revision_messages(profile_id, companion_id, id))''',
    '''CREATE INDEX message_revision_delivery_queue
      ON message_revision_messages(profile_id, companion_id, chat_id, delivery, created_at, id)''',
    '''CREATE TABLE trackia_companion_memories (
      id TEXT PRIMARY KEY, profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
      content TEXT NOT NULL, source TEXT NOT NULL,
      source_message_id TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
      revision INTEGER NOT NULL, status TEXT NOT NULL)''',
    '''CREATE INDEX companion_memory_listing
      ON trackia_companion_memories(profile_id, companion_id, created_at, id)''',
    '''CREATE TABLE trackia_message_effects (
      id TEXT PRIMARY KEY,
      profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
      message_revision_id TEXT NOT NULL,
      target_type TEXT NOT NULL, target_id TEXT NOT NULL,
      operation_id TEXT NOT NULL UNIQUE, status TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      FOREIGN KEY(profile_id, companion_id, message_revision_id)
        REFERENCES message_revision_versions(profile_id, companion_id, id))''',
    '''CREATE INDEX message_effect_revision
      ON trackia_message_effects(profile_id, companion_id, message_revision_id)''',
  ];
  for (final statement in statements) {
    await db.execute(statement);
  }
}

Future<void> _backupBeforeTrackiaV5(
  Database db,
  String dbPath, [
  String fileName = 'pre-trackia-v4.json',
]) async {
  if (dbPath == inMemoryDatabasePath) return;
  final preferred = File('$dbPath.$fileName');
  // A failed first attempt may have left a valid backup. Keep it and create a
  // second snapshot of the current v4 database instead of blocking startup.
  final target =
      await preferred.exists()
          ? File('${preferred.path}.${DateTime.now().microsecondsSinceEpoch}')
          : preferred;
  final pending = File('${target.path}.tmp');
  final sink = pending.openWrite();
  try {
    sink.write('{"format":"trackia-backup","version":3,"tables":{');
    var firstTable = true;
    for (final table in SqliteWorkoutRepository._backupTables.keys) {
      if (!firstTable) sink.write(',');
      firstTable = false;
      sink.write('${jsonEncode(table)}:[');
      var firstRow = true;
      var lastRowId = -9223372036854775808;
      final hasMedia = table == 'activity_messages';
      final columns = SqliteWorkoutRepository._backupTables[table]!;
      final projected =
          hasMedia
              ? 'rowid AS _backup_rowid, '
                  '${columns.where((column) => column != 'attachment').map((column) => '"$column"').join(', ')}, '
                  '(attachment IS NOT NULL) AS _backup_has_attachment'
              : 'rowid AS _backup_rowid, *';
      while (true) {
        // Never put attachment into Android's CursorWindow: one image can exceed
        // its per-row capacity even when the query is limited to one row.
        final rows = await db.rawQuery(
          'SELECT $projected FROM "$table" '
          'WHERE rowid > ? ORDER BY rowid LIMIT 4',
          [lastRowId],
        );
        if (rows.isEmpty) break;
        for (final row in rows) {
          lastRowId = row['_backup_rowid'] as int;
          if (!firstRow) sink.write(',');
          firstRow = false;
          if (!hasMedia) {
            sink.write(
              jsonEncode(
                Map<String, Object?>.from(row)..remove('_backup_rowid'),
              ),
            );
          } else {
            sink.write('{');
            for (var index = 0; index < columns.length; index++) {
              final column = columns[index];
              if (index != 0) sink.write(',');
              sink.write('${jsonEncode(column)}:');
              if (column != 'attachment') {
                sink.write(jsonEncode(row[column]));
                continue;
              }
              if (row['_backup_has_attachment'] != 1) {
                sink.write('null');
                continue;
              }
              sink.write('"');
              for (var offset = 1; ; offset += 64 * 1024) {
                final fragment =
                    (await db.rawQuery(
                          'SELECT substr(attachment, ?, ?) AS fragment '
                          'FROM activity_messages WHERE rowid = ?',
                          [offset, 64 * 1024, lastRowId],
                        )).single['fragment']
                        as String;
                if (fragment.isEmpty) break;
                final encoded = jsonEncode(fragment);
                sink.write(encoded.substring(1, encoded.length - 1));
                if (fragment.runes.length < 64 * 1024) break;
              }
              sink.write('"');
            }
            sink.write('}');
          }
        }
        await sink.flush();
      }
      sink.write(']');
    }
    sink.write('}}');
    await sink.flush();
    await sink.close();
    await pending.rename(target.path);
  } catch (_) {
    await sink.close();
    if (await pending.exists()) await pending.delete();
    rethrow;
  }
}

Future<void> _ensureTrackiaDefaultSpace(Database db, String profileId) =>
    db.transaction((tx) async {
      final owners = await tx.query('trackia_spaces', columns: ['profile_id']);
      if (owners.any((row) => row['profile_id'] != profileId)) {
        throw const ValidationException(
          'La base de datos pertenece a otro perfil; no se han movido datos.',
        );
      }
      await tx.insert('trackia_spaces', {
        'id': 'gym',
        'profile_id': profileId,
        'name': 'Gimnasio',
        'revision': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await _backfillTrackiaLegacyScope(tx, profileId);
    });

Future<void> _backfillTrackiaLegacyScope(
  DatabaseExecutor tx,
  String profileId,
) async {
  await tx.rawInsert(
    '''INSERT OR IGNORE INTO trackia_legacy_workout_scope
       (workout_id, profile_id, space_id)
       SELECT id, ?, 'gym' FROM workouts''',
    [profileId],
  );
  await tx.rawInsert(
    '''INSERT OR IGNORE INTO trackia_legacy_activity_scope
       (activity_id, profile_id, space_id)
       SELECT id, ?, 'gym' FROM activities''',
    [profileId],
  );
}

/// Experimental logical recovery snapshot. Call only when no migration is in
/// progress. Cooperating ChatStore writers and media GC in this isolate share
/// its lock. Other isolates, processes and direct file access must be stopped.
/// Published as one directory only after verification. Secure storage, including
/// unmigrated legacy chats, is excluded. Never call from a transaction or
/// migration callback: this can deadlock against a ChatStore writer.
///
/// SQL copies run inside SQLite, avoiding CursorWindow limits for large blobs.
/// Unsupported schema objects fail closed rather than silently disappearing.
Future<Directory> createExperimentalRecoverySnapshot(
  Database db,
  Directory destination, {
  Directory? mediaDirectory,
}) {
  final media =
      mediaDirectory ?? Directory(p.join(p.dirname(db.path), 'trackia_media'));
  return ChatStore.withMediaLock(
    media,
    () => _createExperimentalRecoverySnapshot(db, destination, media),
  );
}

Future<Directory> _createExperimentalRecoverySnapshot(
  Database db,
  Directory destination,
  Directory media,
) async {
  if (await destination.exists()) {
    throw StateError('Recovery snapshot already exists: ${destination.path}');
  }
  final pending = Directory('${destination.path}.pending');
  if (await pending.exists()) {
    throw StateError('Incomplete recovery snapshot exists: ${pending.path}');
  }
  await pending.create(recursive: true);
  final output = p.join(pending.path, 'database.sqlite');
  var attached = false;
  try {
    await db.execute('ATTACH DATABASE ? AS recovery', [output]);
    attached = true;
    late final List<Map<String, Object?>> objects;
    String quote(String name) => '"${name.replaceAll('"', '""')}"';
    await db.transaction((tx) async {
      objects = await tx.rawQuery(
        "SELECT type, name, sql FROM main.sqlite_master "
        "WHERE name NOT LIKE 'sqlite_%' AND sql IS NOT NULL ORDER BY type, name",
      );
      for (final object in objects) {
        if (object['type'] != 'table') continue;
        final sql = object['sql'] as String;
        final start = sql.indexOf('(');
        if (start < 0 ||
            RegExp(r'^CREATE\s+VIRTUAL', caseSensitive: false).hasMatch(sql)) {
          throw StateError('Unsupported recovery schema: ${object['name']}');
        }
        final name = quote(object['name'] as String);
        await tx.execute('CREATE TABLE recovery.$name ${sql.substring(start)}');
      }
      await tx.execute('PRAGMA defer_foreign_keys = ON');
      for (final object in objects) {
        if (object['type'] != 'table') continue;
        final name = quote(object['name'] as String);
        final sql = object['sql'] as String;
        if (RegExp(
          r'\bWITHOUT\s+ROWID\b',
          caseSensitive: false,
        ).hasMatch(sql)) {
          await tx.execute(
            'INSERT INTO recovery.$name SELECT * FROM main.$name',
          );
          continue;
        }
        final columns = await tx.rawQuery('PRAGMA main.table_info($name)');
        final columnNames =
            columns.map((row) => row['name'] as String).toList();
        final lowerNames =
            columnNames.map((name) => name.toLowerCase()).toSet();
        final aliases = [
          'rowid',
          '_rowid_',
          'oid',
        ].where((alias) => !lowerNames.contains(alias));
        if (aliases.isEmpty) throw StateError('Cannot preserve rowid: $name');
        final alias = aliases.first;
        final columnList = columnNames.map(quote).join(', ');
        await tx.execute(
          'INSERT INTO recovery.$name ($alias, $columnList) '
          'SELECT $alias, $columnList FROM main.$name',
        );
      }
      for (final object in objects) {
        if (object['type'] == 'table') continue;
        if (object['type'] != 'index') {
          throw StateError(
            'Unsupported recovery schema object: ${object['name']}',
          );
        }
        final sql = object['sql'] as String;
        final on = RegExp(r'\s+ON\s+', caseSensitive: false).firstMatch(sql);
        if (on == null) throw StateError('Invalid index: ${object['name']}');
        final unique = RegExp(
          r'^CREATE\s+UNIQUE\s+INDEX',
          caseSensitive: false,
        ).hasMatch(sql);
        await tx.execute(
          'CREATE ${unique ? 'UNIQUE ' : ''}INDEX recovery.${quote(object['name'] as String)}${sql.substring(on.start)}',
        );
      }
      final sequence = await tx.rawQuery(
        "SELECT name FROM main.sqlite_master WHERE name = 'sqlite_sequence'",
      );
      if (sequence.isNotEmpty) {
        await tx.execute('DELETE FROM recovery.sqlite_sequence');
        await tx.execute(
          'INSERT INTO recovery.sqlite_sequence SELECT * FROM main.sqlite_sequence',
        );
      }
      final version = await tx.rawQuery('PRAGMA main.user_version');
      await tx.execute(
        'PRAGMA recovery.user_version = ${version.single.values.single as int}',
      );
    });
    final outputMedia = Directory(p.join(pending.path, 'trackia_media'));
    await outputMedia.create();
    final references = <String>{};
    for (final table in const ['trackia_chats', 'trackia_chat_archives']) {
      if (!objects.any((o) => o['type'] == 'table' && o['name'] == table)) {
        continue;
      }
      int? lastRowId;
      while (true) {
        final rows = await db.rawQuery(
          'SELECT rowid AS recovery_rowid, length(payload) AS payload_length '
          'FROM recovery.${quote(table)} '
          '${lastRowId == null ? '' : 'WHERE rowid > ? '}ORDER BY rowid LIMIT 1',
          lastRowId == null ? [] : [lastRowId],
        );
        if (rows.isEmpty) break;
        lastRowId = rows.single['recovery_rowid'] as int;
        final length = rows.single['payload_length'] as int;
        final scanner = _RecoveryMediaScanner(references);
        for (var offset = 1; offset <= length; offset += 65536) {
          final fragment = await db.rawQuery(
            'SELECT substr(payload, ?, ?) AS fragment '
            'FROM recovery.${quote(table)} WHERE rowid = ?',
            [offset, 65536, lastRowId],
          );
          scanner.add(fragment.single['fragment'] as String);
        }
        scanner.finish();
      }
    }
    for (final hash in references) {
      final source = File(p.join(media.path, hash));
      final target = File(p.join(outputMedia.path, hash));
      await source.copy(target.path);
      if ((await sha256.bind(target.openRead()).first).toString() != hash) {
        throw StateError('Corrupt recovery attachment: $hash');
      }
    }
    final integrity = await db.rawQuery('PRAGMA recovery.integrity_check');
    if (integrity.length != 1 || integrity.single.values.single != 'ok') {
      throw StateError('Recovery snapshot failed integrity check');
    }

    await db.execute('DETACH DATABASE recovery');
    attached = false;
    return await pending.rename(destination.path);
  } catch (_) {
    if (attached) {
      try {
        await db.execute('DETACH DATABASE recovery');
      } catch (_) {}
    }
    if (await pending.exists()) await pending.delete(recursive: true);
    rethrow;
  }
}

/// Recovery copy for the TrackIA v7 upgrade. Publishes a verified logical
/// snapshot as `<dbPath>.pre-trackia-v7.sqlite` and merges its chat media into
/// `<dbPath>.pre-trackia-v7.media`, so the backup restores on its own like the
/// experimental folder snapshot does.
///
/// Must be called with a dedicated open handle before openDatabase applies the
/// version bump: SQLite cannot ATTACH inside sqflite's upgrade transaction, so
/// this never runs inside a transaction, migration callback or an active
/// ChatStore writer. Never call on the in-memory database path.
///
/// The first valid copy is kept: a retry after an interrupted upgrade writes a
/// timestamped sibling instead of overwriting it. The only crash residues are
/// staging directories and equal verified media files, which later attempts
/// clean or overwrite; a backup without complete media fails loudly on load.
Future<void> createTrackiaV7Backup(Database db, String dbPath) async {
  if (dbPath == inMemoryDatabasePath) return;
  final preferred = File('$dbPath.pre-trackia-v7.sqlite');
  // Interrupted attempts can leave staging directories with old names or
  // timestamped names: they were never verified and never published, so any
  // of them is crash residue and starting clean is always safe.
  final parent = Directory(p.dirname(dbPath));
  await for (final entry in parent.list()) {
    final name = p.basename(entry.path);
    if (name.contains('.pre-trackia-v7') && name.endsWith('.snapshot')) {
      await entry.delete(recursive: true);
    }
  }
  final target =
      await preferred.exists()
          ? File('${preferred.path}.${DateTime.now().microsecondsSinceEpoch}')
          : preferred;
  final staging = Directory('${target.path}.snapshot');
  final mediaTarget = Directory('$dbPath.pre-trackia-v7.media');
  if (await staging.exists()) {
    // Crash residue from an interrupted attempt: its content was never
    // verified and never published, so starting clean is always safe.
    await staging.delete(recursive: true);
  }
  await createExperimentalRecoverySnapshot(db, staging);
  try {
    final mediaSource = Directory(p.join(staging.path, 'trackia_media'));
    // Media first, database last: if the process dies in the middle, either
    // the old state is untouched or the published database already has every
    // media file it references beside it.
    await mediaTarget.create(recursive: true);
    await for (final entry in mediaSource.list()) {
      if (entry is! File) {
        throw StateError('Unexpected recovery media entry: ${entry.path}');
      }
      final name = p.basename(entry.path);
      await entry.copy(p.join(mediaTarget.path, name));
    }
    await File(p.join(staging.path, 'database.sqlite')).rename(target.path);
  } catch (_) {
    try {
      await staging.delete(recursive: true);
    } catch (_) {}
    // The staged database was never renamed away; already merged media only
    // carries equal verified content, so no incomplete copy is left behind.
    rethrow;
  }
  await staging.delete(recursive: true);
}

/// Scans string tokens incrementally and recognizes the same attachment shape
/// as ChatStore: an object with string name, mime and media fields.
class _RecoveryMediaScanner {
  _RecoveryMediaScanner(this.references);
  final Set<String> references;
  final _frames = <_RecoveryJsonFrame>[];
  var _inside = false;
  var _escape = false;
  var _overflow = false;
  var _token = StringBuffer();
  var _tokenLength = 0;

  void add(String chunk) {
    for (final unit in chunk.codeUnits) {
      if (_inside) {
        if (unit == 34 && !_escape) {
          _inside = false;
          final value =
              _overflow ? null : jsonDecode('"${_token.toString()}"') as String;
          if (_frames.isNotEmpty) {
            final frame = _frames.last;
            if (frame.object && frame.expectKey) {
              frame.key = value;
              frame.expectKey = false;
            } else {
              frame.recordString(value, _overflow);
            }
          }
          continue;
        }
        if (++_tokenLength <= 256) {
          _token.writeCharCode(unit);
        } else {
          _overflow = true;
        }
        if (_escape) {
          _escape = false;
        } else if (unit == 92) {
          _escape = true;
        }
      } else if (unit == 34) {
        _inside = true;
        _escape = false;
        _overflow = false;
        _tokenLength = 0;
        _token = StringBuffer();
      } else if (unit == 123 || unit == 91) {
        if (_frames.isNotEmpty) _frames.last.recordOther();
        _frames.add(_RecoveryJsonFrame(unit == 123));
      } else if (unit == 125 || unit == 93) {
        if (_frames.isEmpty || _frames.last.object != (unit == 125)) {
          throw const FormatException('Invalid chat payload');
        }
        final frame = _frames.removeLast();
        if (frame.object && frame.name && frame.mime && frame.mediaString) {
          final hash = frame.media;
          if (hash == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
            throw const FormatException('Invalid recovery media reference');
          }
          references.add(hash);
        }
      } else if (unit == 44) {
        if (_frames.isNotEmpty && _frames.last.object) {
          _frames.last.expectKey = true;
        }
      } else if (unit != 58 &&
          unit != 32 &&
          unit != 9 &&
          unit != 10 &&
          unit != 13) {
        if (_frames.isNotEmpty) _frames.last.recordOther();
      }
    }
  }

  void finish() {
    if (_inside || _frames.isNotEmpty) {
      throw const FormatException('Incomplete chat payload');
    }
  }
}

class _RecoveryJsonFrame {
  _RecoveryJsonFrame(this.object) : expectKey = object;
  final bool object;
  bool expectKey;
  String? key;
  bool name = false;
  bool mime = false;
  bool mediaString = false;
  String? media;

  void recordString(String? value, bool overflow) {
    if (!object || expectKey) return;
    if (key == 'name') name = true;
    if (key == 'mime') mime = true;
    if (key == 'media') {
      mediaString = true;
      media = overflow ? null : value;
    }
    key = null;
  }

  void recordOther() {
    if (!object || expectKey) return;
    if (key == 'name') name = false;
    if (key == 'mime') mime = false;
    if (key == 'media') {
      mediaString = false;
      media = null;
    }
    key = null;
  }
}
