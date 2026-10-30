import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// The app was called GymIA: its secure-storage keys started with `gymia.`
/// and its databases were `gymia.sqlite` / `gymia-<profile>.sqlite`. They
/// are now `trackia.*` and `trackia*.sqlite`. Both migrations copy first,
/// verify, and never delete what they could not verify.

const _oldKeyPrefix = 'gymia.';
const _newKeyPrefix = 'trackia.';

class KeyRenameReport {
  const KeyRenameReport({
    this.copied = 0,
    this.alreadyThere = 0,
    this.conflicts = 0,
    this.failed = 0,
  });

  /// Keys written under the new name and removed from the old one.
  final int copied;

  /// Old keys whose new copy already held the same value: only the old one was removed.
  final int alreadyThere;

  /// The new key holds a different value: both stay and the new one wins.
  final int conflicts;

  /// The copy could not be written or verified: the old key stays untouched.
  final int failed;
}

/// Moves every `gymia.*` entry to `trackia.*`. Safe to run on every start.
/// It never throws: a storage that cannot be read just leaves the old keys.
Future<KeyRenameReport> migrateStorageKeys({
  FlutterSecureStorage storage = const FlutterSecureStorage(),
}) async {
  var copied = 0, alreadyThere = 0, conflicts = 0, failed = 0;
  try {
    // A snapshot: the storage may hand back a live map that the writes change.
    final all = Map<String, String>.of(await storage.readAll());
    for (final entry in all.entries) {
      if (!entry.key.startsWith(_oldKeyPrefix)) continue;
      final newKey = _newKeyPrefix + entry.key.substring(_oldKeyPrefix.length);
      try {
        final existing = all[newKey];
        if (existing == null) {
          await storage.write(key: newKey, value: entry.value);
          if (await storage.read(key: newKey) != entry.value) {
            failed++;
            continue;
          }
          await storage.delete(key: entry.key);
          copied++;
        } else if (existing == entry.value) {
          await storage.delete(key: entry.key);
          alreadyThere++;
        } else {
          conflicts++;
        }
      } catch (error) {
        failed++;
        debugPrint('Storage key rename failed: ${error.runtimeType}');
      }
    }
  } catch (error) {
    debugPrint('Storage keys not readable: ${error.runtimeType}');
  }
  return KeyRenameReport(
    copied: copied,
    alreadyThere: alreadyThere,
    conflicts: conflicts,
    failed: failed,
  );
}

/// The database file name for a profile.
String databaseFileName(String profileId) =>
    profileId == 'local' ? 'trackia.sqlite' : 'trackia-$profileId.sqlite';

/// The name the same profile's database had before the rename.
String legacyDatabaseFileName(String profileId) =>
    profileId == 'local' ? 'gymia.sqlite' : 'gymia-$profileId.sqlite';

/// Makes `trackia*.sqlite` out of `gymia*.sqlite` when only the old one
/// exists. The old file is kept as the backup and is never opened again.
/// Returns `true` when the new file now exists.
Future<bool> migrateDatabaseFile(
  String directory,
  String profileId, {
  Future<void> Function(String path)? beforeCopy,
}) async {
  final target = File(p.join(directory, databaseFileName(profileId)));
  final source = File(p.join(directory, legacyDatabaseFileName(profileId)));
  if (await target.exists()) return true;
  if (!await source.exists()) return false;
  final temporary = File('${target.path}.copying');
  try {
    // A write-ahead log would hold changes the main file does not have yet.
    await beforeCopy?.call(source.path);
    for (final suffix in ['-wal', '-shm', '-journal']) {
      if (await File(source.path + suffix).exists()) {
        debugPrint('Database rename skipped: ${source.path}$suffix is pending');
        return false;
      }
    }
    if (await temporary.exists()) await temporary.delete();
    await source.copy(temporary.path);
    if (await temporary.length() != await source.length()) {
      await temporary.delete();
      return false;
    }
    await temporary.rename(target.path);
    return true;
  } catch (error) {
    debugPrint('Database rename failed: ${error.runtimeType}');
    try {
      if (await temporary.exists()) await temporary.delete();
    } catch (_) {}
    return false;
  }
}

/// Folds a write-ahead log into the main file so a plain copy is complete.
Future<void> checkpointDatabase(String path, {DatabaseFactory? factory}) async {
  final f = factory ?? databaseFactory;
  final db = await f.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  try {
    await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
  } finally {
    await db.close();
  }
}

/// The path to open for this profile. After the rename it is `trackia*.sqlite`;
/// if the copy could not be made, the old file keeps being used so the person
/// never meets an empty database.
Future<String> resolveDatabasePath(
  String directory,
  String profileId, {
  DatabaseFactory? factory,
}) async {
  final migrated = await migrateDatabaseFile(
    directory,
    profileId,
    beforeCopy: (path) => checkpointDatabase(path, factory: factory),
  );
  final legacy = p.join(directory, legacyDatabaseFileName(profileId));
  if (!migrated && await File(legacy).exists()) return legacy;
  return p.join(directory, databaseFileName(profileId));
}
