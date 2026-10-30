import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/space.dart';
import 'companion_store.dart';

/// What a migration pass did.
class ChatMigrationResult {
  const ChatMigrationResult({
    required this.ok,
    this.chats = 0,
    this.archives = 0,
    this.error,
  });

  final bool ok;
  final int chats, archives;
  final String? error;
}

class ChatRowInfo {
  const ChatRowInfo({required this.verified, required this.legacyKey});

  /// The copy made from the old secure-storage key was checked.
  final bool verified;

  /// The old key still waiting to be deleted, if any.
  final String? legacyKey;
}

/// Chats and chat archives in SQLite (`trackia_chats`, `trackia_chat_archives`),
/// with attachments as files named by their SHA-256 (research D12, FR-040).
///
/// The JSON the app works with is unchanged: attachments appear inline as
/// `{name, mime, bytes}`. In the database they are `{name, mime, media, size}`.
///
/// Moving from the old secure-storage keys happens in two idempotent phases:
/// 1. copy to SQLite and files, read it back and compare with the original;
///    only then mark it verified. The old keys are not touched.
/// 2. on a later launch, delete only the old keys of verified copies.
/// Until phase 2 runs, reading prefers SQLite and falls back to the old key.
class ChatStore {
  ChatStore(this._db, this._now, this.profileId, {Directory? mediaDirectory})
    : _mediaDirectory = mediaDirectory {
    validTrackiaId(profileId);
  }

  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  static final _mediaRef = RegExp(r'"media":"([0-9a-f]{64})"');

  final Database _db;
  final DateTime Function() _now;
  final String profileId;
  Directory? _mediaDirectory;

  /// Test hook called at `media`, `row`, `verify` and `archive`; it may throw.
  void Function(String step)? debugStep;

  final _verifiedThisRun = <String>{};

  String _chatKey(String companionId) =>
      companionStorageKey('trackia.ai.chat.v1', profileId, companionId);
  String _archiveKey(String companionId, String id) =>
      companionStorageKey('trackia.ai.archive.v1.$id', profileId, companionId);
  String _archiveRowId(String companionId, String id) =>
      '$profileId:$companionId:$id';

  String _id(String companionId) => validTrackiaId(companionId);

  String _checkedArchiveId(String id) {
    if (!_safeId.hasMatch(id)) {
      throw const FormatException('Archivo no válido.');
    }
    return id;
  }

  /// Where attachments live: `trackia_media` next to the database, so they
  /// are private to the app and move together with it. (research D12 named the
  /// application support folder; this needs no plugin and works the same.)
  Future<Directory> mediaDirectory() async => _mediaDirectory ??= Directory(
    p.join(p.dirname(_db.path), 'trackia_media'),
  );

  static String hashOf(List<int> bytes) => sha256.convert(bytes).toString();

  // --- attachments ----------------------------------------------------------

  static bool _isAttachment(Map node) =>
      node['bytes'] is String &&
      node['mime'] is String &&
      node['name'] is String;

  static bool _isReference(Map node) =>
      node['media'] is String &&
      node['mime'] is String &&
      node['name'] is String;

  /// Replaces every inline attachment by a reference and collects the bytes.
  static Object? _externalize(Object? node, Map<String, Uint8List> files) {
    if (node is Map) {
      if (_isAttachment(node)) {
        final bytes = base64Decode(node['bytes'] as String);
        final hash = hashOf(bytes);
        files[hash] = bytes;
        return {
          for (final e in node.entries)
            if (e.key != 'bytes') e.key as String: e.value,
          'media': hash,
          'size': bytes.length,
        };
      }
      return {
        for (final e in node.entries)
          e.key as String: _externalize(e.value, files),
      };
    }
    if (node is List) return [for (final e in node) _externalize(e, files)];
    return node;
  }

  Future<Object?> _inflate(Object? node, Directory dir) async {
    if (node is Map) {
      if (_isReference(node)) {
        final hash = node['media'] as String;
        if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
          throw StateError('Referencia de adjunto no válida.');
        }
        final file = File(p.join(dir.path, hash));
        if (!await file.exists()) {
          throw StateError('Falta un adjunto guardado del chat.');
        }
        final bytes = await file.readAsBytes();
        if (hashOf(bytes) != hash) {
          throw StateError('Un adjunto guardado del chat está dañado.');
        }
        return {
          for (final e in node.entries)
            if (e.key != 'media' && e.key != 'size') e.key as String: e.value,
          'bytes': base64Encode(bytes),
        };
      }
      return {
        for (final e in node.entries)
          e.key as String: await _inflate(e.value, dir),
      };
    }
    if (node is List) return [for (final e in node) await _inflate(e, dir)];
    return node;
  }

  Future<void> _writeMedia(Map<String, Uint8List> files) async {
    if (files.isEmpty) return;
    final dir = await mediaDirectory();
    await dir.create(recursive: true);
    for (final entry in files.entries) {
      final target = File(p.join(dir.path, entry.key));
      if (await target.exists() &&
          await target.length() == entry.value.length) {
        continue;
      }
      final temp = File('${target.path}.tmp');
      await temp.writeAsBytes(entry.value, flush: true);
      await temp.rename(target.path);
    }
  }

  // --- reading and writing --------------------------------------------------

  Future<Map<String, dynamic>?> _load(
    String table,
    String where,
    List<Object?> args,
  ) async {
    final rows = await _db.query(table, where: where, whereArgs: args);
    if (rows.isEmpty) return null;
    final payload = jsonDecode(rows.single['payload'] as String);
    final inflated = await _inflate(payload, await mediaDirectory());
    return Map<String, dynamic>.from(inflated as Map);
  }

  /// The active chat as the app uses it, or null if nothing is stored here.
  Future<Map<String, dynamic>?> loadActive(String companionId) => _load(
    'trackia_chats',
    'profile_id = ? AND companion_id = ?',
    [profileId, _id(companionId)],
  );

  Future<Map<String, dynamic>?> loadArchive(
    String companionId,
    String id,
  ) async => _load(
    'trackia_chat_archives',
    'id = ? AND profile_id = ? AND companion_id = ?',
    [
      _archiveRowId(_id(companionId), _checkedArchiveId(id)),
      profileId,
      companionId,
    ],
  );

  Future<ChatRowInfo?> info(String companionId) async {
    final rows = await _db.query(
      'trackia_chats',
      columns: ['legacy_key', 'verified_at'],
      where: 'profile_id = ? AND companion_id = ?',
      whereArgs: [profileId, _id(companionId)],
    );
    if (rows.isEmpty) return null;
    return ChatRowInfo(
      verified: rows.single['verified_at'] != null,
      legacyKey: rows.single['legacy_key'] as String?,
    );
  }

  Future<void> _upsertActive(
    DatabaseExecutor tx,
    String companionId,
    String payload,
  ) async {
    final changed = await tx.update(
      'trackia_chats',
      {'payload': payload, 'updated_at': _now().millisecondsSinceEpoch},
      where: 'profile_id = ? AND companion_id = ?',
      whereArgs: [profileId, companionId],
    );
    if (changed == 0) {
      await tx.insert('trackia_chats', {
        'profile_id': profileId,
        'companion_id': companionId,
        'payload': payload,
        'updated_at': _now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> saveActive(
    String companionId,
    Map<String, dynamic> state,
  ) async {
    final id = _id(companionId);
    final files = <String, Uint8List>{};
    final payload = jsonEncode(_externalize(state, files));
    await _writeMedia(files);
    await _db.transaction((tx) => _upsertActive(tx, id, payload));
  }

  /// Archive and active chat in one transaction: both change or neither does.
  Future<void> saveArchiveAndActive(
    String companionId,
    String archiveId,
    Map<String, dynamic> archive,
    Map<String, dynamic> active,
  ) async {
    final id = _id(companionId);
    final row = _archiveRowId(id, _checkedArchiveId(archiveId));
    final files = <String, Uint8List>{};
    final archivePayload = jsonEncode(_externalize(archive, files));
    final activePayload = jsonEncode(_externalize(active, files));
    await _writeMedia(files);
    await _db.transaction((tx) async {
      await tx.insert('trackia_chat_archives', {
        'id': row,
        'profile_id': profileId,
        'companion_id': id,
        'payload': archivePayload,
        'created_at': _now().millisecondsSinceEpoch,
      });
      debugStep?.call('archive');
      await _upsertActive(tx, id, activePayload);
    });
  }

  /// SQLite first; the old secure-storage key if there is no row. Opening an
  /// old chat migrates it (phase 1) and, on a later launch, finishes (phase 2).
  Future<Map<String, dynamic>?> readActive(
    FlutterSecureStorage storage,
    String companionId,
  ) async {
    final id = _id(companionId);
    final current = await info(id);
    if (current != null && !(current.legacyKey != null && !current.verified)) {
      await finishMigration(storage, id);
      return loadActive(id);
    }
    final raw = await storage.read(key: _chatKey(id));
    if (raw == null) return null;
    final result = await migrate(storage, id);
    if (result.ok) {
      final migrated = await loadActive(id);
      if (migrated != null) return migrated;
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<Map<String, dynamic>?> readArchive(
    FlutterSecureStorage storage,
    String companionId,
    String id,
  ) async {
    final stored = await loadArchive(companionId, id);
    if (stored != null) return stored;
    final raw = await storage.read(key: _archiveKey(_id(companionId), id));
    return raw == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  // --- migration ------------------------------------------------------------

  /// Phase 1: copy the companion's old chat and archives, check the copy, and
  /// only then mark it verified. Never deletes an old key. Safe to repeat.
  Future<ChatMigrationResult> migrate(
    FlutterSecureStorage storage,
    String companionId,
  ) async {
    final id = _id(companionId);
    final chatKey = _chatKey(id);
    try {
      final raw = await storage.read(key: chatKey);
      if (raw == null) return const ChatMigrationResult(ok: true);
      final existing = await info(id);
      if (existing != null && existing.verified) {
        return const ChatMigrationResult(ok: true);
      }
      final state = Map<String, dynamic>.from(jsonDecode(raw) as Map);

      final originals = <String, Map<String, dynamic>>{};
      for (final entry in state['archives'] as List? ?? const []) {
        final archiveId = entry is Map ? entry['id'] : null;
        if (archiveId is! String || !_safeId.hasMatch(archiveId)) continue;
        final archiveRaw = await storage.read(key: _archiveKey(id, archiveId));
        if (archiveRaw == null) continue;
        originals[archiveId] = Map<String, dynamic>.from(
          jsonDecode(archiveRaw) as Map,
        );
      }

      final files = <String, Uint8List>{};
      final chatPayload = jsonEncode(_externalize(state, files));
      final archivePayloads = {
        for (final e in originals.entries)
          e.key: jsonEncode(_externalize(e.value, files)),
      };
      await _writeMedia(files);
      debugStep?.call('media');

      await _db.transaction((tx) async {
        // An incomplete earlier copy is redone, never trusted.
        await tx.delete(
          'trackia_chats',
          where: 'profile_id = ? AND companion_id = ?',
          whereArgs: [profileId, id],
        );
        await tx.insert('trackia_chats', {
          'profile_id': profileId,
          'companion_id': id,
          'payload': chatPayload,
          'legacy_key': chatKey,
          'updated_at': _now().millisecondsSinceEpoch,
        });
        for (final e in archivePayloads.entries) {
          final row = _archiveRowId(id, e.key);
          await tx.delete(
            'trackia_chat_archives',
            where: 'id = ?',
            whereArgs: [row],
          );
          await tx.insert('trackia_chat_archives', {
            'id': row,
            'profile_id': profileId,
            'companion_id': id,
            'payload': e.value,
            'legacy_key': _archiveKey(id, e.key),
            'created_at': _now().millisecondsSinceEpoch,
          });
        }
        debugStep?.call('row');
      });

      try {
        debugStep?.call('verify');
        final copied = await loadActive(id);
        if (jsonEncode(copied) != jsonEncode(state)) {
          throw StateError('La copia del chat no coincide con el original.');
        }
        for (final e in originals.entries) {
          final copy = await loadArchive(id, e.key);
          if (jsonEncode(copy) != jsonEncode(e.value)) {
            throw StateError('La copia de un chat archivado no coincide.');
          }
        }
      } catch (error) {
        // An unverified copy must never be read instead of the original.
        await _db.delete(
          'trackia_chats',
          where: 'profile_id = ? AND companion_id = ?',
          whereArgs: [profileId, id],
        );
        await _db.delete(
          'trackia_chat_archives',
          where:
              'profile_id = ? AND companion_id = ? AND legacy_key IS NOT NULL AND verified_at IS NULL',
          whereArgs: [profileId, id],
        );
        rethrow;
      }

      final at = _now().millisecondsSinceEpoch;
      await _db.update(
        'trackia_chats',
        {'verified_at': at},
        where: 'profile_id = ? AND companion_id = ?',
        whereArgs: [profileId, id],
      );
      await _db.update(
        'trackia_chat_archives',
        {'verified_at': at},
        where: 'profile_id = ? AND companion_id = ? AND legacy_key IS NOT NULL',
        whereArgs: [profileId, id],
      );
      _verifiedThisRun.add(id);
      return ChatMigrationResult(
        ok: true,
        chats: 1,
        archives: originals.length,
      );
    } catch (error) {
      return ChatMigrationResult(ok: false, error: '$error');
    }
  }

  /// Phase 2: delete the old keys of verified copies. It does nothing in the
  /// launch that made the copy, so a bad copy is found before anything is lost.
  /// Returns how many keys were deleted.
  Future<int> finishMigration(
    FlutterSecureStorage storage,
    String companionId,
  ) async {
    final id = _id(companionId);
    if (_verifiedThisRun.contains(id)) return 0;
    var deleted = 0;
    for (final table in const ['trackia_chats', 'trackia_chat_archives']) {
      final rows = await _db.query(
        table,
        where:
            'profile_id = ? AND companion_id = ? AND legacy_key IS NOT NULL AND verified_at IS NOT NULL',
        whereArgs: [profileId, id],
      );
      for (final row in rows) {
        await storage.delete(key: row['legacy_key'] as String);
        await _db.update(
          table,
          {'legacy_key': null},
          where: table == 'trackia_chats'
              ? 'profile_id = ? AND companion_id = ?'
              : 'id = ?',
          whereArgs: table == 'trackia_chats' ? [profileId, id] : [row['id']],
        );
        deleted++;
      }
    }
    return deleted;
  }

  // --- cleanup --------------------------------------------------------------

  Future<void> deleteCompanion(String companionId) async {
    final id = _id(companionId);
    for (final table in const ['trackia_chat_archives', 'trackia_chats']) {
      await _db.delete(
        table,
        where: 'profile_id = ? AND companion_id = ?',
        whereArgs: [profileId, id],
      );
    }
  }

  /// Deletes attachment files that no stored chat or archive refers to (of any
  /// profile). Returns how many were deleted.
  Future<int> gcMedia() async {
    final dir = await mediaDirectory();
    if (!await dir.exists()) return 0;
    final referenced = <String>{};
    for (final table in const ['trackia_chats', 'trackia_chat_archives']) {
      for (final row in await _db.query(table, columns: ['payload'])) {
        for (final m in _mediaRef.allMatches(row['payload'] as String)) {
          referenced.add(m.group(1)!);
        }
      }
    }
    var deleted = 0;
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.endsWith('.tmp') || !referenced.contains(name)) {
        await entity.delete();
        deleted++;
      }
    }
    return deleted;
  }
}
