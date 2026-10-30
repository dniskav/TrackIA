import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../domain/workout.dart';
import 'chat_store.dart';
import 'companion_store.dart';

/// Immutable archive first, then one atomic active-chat/index replacement.
/// If either write fails the active conversation is retained and can be retried.
class ChatArchiveStore {
  const ChatArchiveStore({
    required this.profileId,
    this.companionId = 'gymbro',
    this.storage = const FlutterSecureStorage(),
    this.chats,
  });
  final String profileId;

  /// Where chats live now (SQLite and files, FR-040). Without it the old
  /// secure-storage keys are used, as before.
  final ChatStore? chats;
  final String companionId;
  final FlutterSecureStorage storage;
  String get activeKey =>
      companionStorageKey('trackia.ai.chat.v1', profileId, companionId);
  String _archiveKey(String id) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id)) {
      throw const FormatException('Archivo no válido.');
    }
    return companionStorageKey(
      'trackia.ai.archive.v1.$id',
      profileId,
      companionId,
    );
  }

  Future<Map<String, dynamic>?> active() async {
    final store = chats;
    if (store != null) return store.readActive(storage, companionId);
    final raw = await storage.read(key: activeKey);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Replaces the active chat.
  Future<void> saveActive(Map<String, dynamic> state) async {
    final store = chats;
    if (store != null) return store.saveActive(companionId, state);
    await storage.write(key: activeKey, value: jsonEncode(state));
  }

  static List<Map<String, dynamic>> index(Map<String, dynamic>? state) => [
    for (final row in state?['archives'] as List? ?? [])
      Map<String, dynamic>.from(row as Map),
  ];

  Future<Map<String, dynamic>> archive({
    required Map<String, dynamic> state,
    required List<Map<String, dynamic>> transcript,
    required List<String> activityMessageIds,
    required String title,
    required String summary,
    required String reason,
    required bool automatic,
  }) async {
    if (transcript.isEmpty || state['pending'] != null) {
      throw const ValidationException(
        'Termina el mensaje pendiente antes de archivar.',
      );
    }
    final current = await active();
    String messageIdentity(dynamic rows) => jsonEncode([
      for (final row in rows as List? ?? [])
        [
          row['role'],
          row['content'],
          row['recordedAt'],
          row['attachment']?['name'],
          row['attachment']?['mime'],
          row['attachment']?['bytes'],
        ],
    ]);
    if (current != null &&
        (current['sessionId'] != state['sessionId'] ||
            current['pending'] != null ||
            messageIdentity(current['messages']) !=
                messageIdentity(state['messages']))) {
      throw const ValidationException(
        'El chat cambió. Vuelve a abrirlo antes de archivar.',
      );
    }
    final id = const Uuid().v4();
    final entry = <String, dynamic>{
      'id': id,
      'title': title.trim().isEmpty
          ? 'Conversación'
          : title.trim().substring(0, title.trim().length.clamp(0, 100)),
      'createdAt': DateTime.now().toIso8601String(),
      'summary': summary,
      'reason': reason,
      'automatic': automatic,
      'messageCount': transcript.length,
    };
    final document = jsonEncode({
      ...entry,
      'messages': transcript,
      'activityMessageIds': activityMessageIds,
      'sourceSessionId': state['sessionId'],
    });
    if (utf8.encode(document).length > 20 * 1024 * 1024) {
      throw const ValidationException(
        'El chat supera 20 MB. No se ha archivado ni borrado.',
      );
    }
    final next = <String, dynamic>{
      ...state,
      'sessionId': const Uuid().v4(),
      'messages': [],
      'pending': null,
      'deferredArchive': null,
      'archives': [...index(state), entry],
      'archivedActivityMessageIds': {
        ...List<String>.from(
          state['archivedActivityMessageIds'] as List? ?? [],
        ),
        ...activityMessageIds,
      }.toList(),
      'carryForward': summary,
    };
    final store = chats;
    if (store != null) {
      // Archive and new active chat change together or not at all.
      await store.saveArchiveAndActive(
        companionId,
        id,
        jsonDecode(document) as Map<String, dynamic>,
        next,
      );
      return next;
    }
    await storage.write(key: _archiveKey(id), value: document);
    await storage.write(key: activeKey, value: jsonEncode(next));
    return next;
  }

  Future<Map<String, dynamic>> read(String id) async {
    final state = await active();
    if (!index(state).any((row) => row['id'] == id)) {
      throw const ValidationException(
        'Este chat no pertenece al perfil activo.',
      );
    }
    final store = chats;
    if (store != null) {
      final stored = await store.readArchive(storage, companionId, id);
      if (stored == null) {
        throw const ValidationException(
          'No se pudo recuperar el chat archivado.',
        );
      }
      return stored;
    }
    final raw = await storage.read(key: _archiveKey(id));
    if (raw == null) {
      throw const ValidationException(
        'No se pudo recuperar el chat archivado.',
      );
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> excerpt(String id, {int start = 0}) async {
    final archive = await read(id);
    final rows = List<Map<String, dynamic>>.from(
      (archive['messages'] as List).map(
        (row) => Map<String, dynamic>.from(row as Map),
      ),
    );
    if (start < 0 || start >= rows.length) {
      throw const ValidationException('La página del archivo no existe.');
    }
    final selected = <Map<String, dynamic>>[];
    var available = 16000;
    for (
      var i = start;
      i < rows.length && selected.length < 20 && available > 0;
      i++
    ) {
      final text = rows[i]['content'] as String;
      final take = text.length.clamp(0, available);
      selected.add({
        'role': rows[i]['role'],
        'content': text.substring(0, take),
        'recordedAt': rows[i]['recordedAt'],
        'contentTruncated': take < text.length,
      });
      available -= take;
    }
    return {
      'id': id,
      'title': archive['title'],
      'start': start,
      'totalMessages': rows.length,
      'messages': selected,
      'hasMore': start + selected.length < rows.length,
      'nextStart': start + selected.length,
    };
  }
}

Map<String, dynamic>? chatDirective(String answer, String kind) {
  final blocks = RegExp(
    '```gymia-$kind\\s*\\n([\\s\\S]*?)```',
  ).allMatches(answer).toList();
  if (blocks.length != 1) return null;
  try {
    final value = jsonDecode(blocks.single.group(1)!) as Map<String, dynamic>;
    if (kind == 'archive') {
      if (value.keys.toSet().difference({
            'title',
            'summary',
            'reason',
          }).isNotEmpty ||
          value['title'] is! String ||
          value['summary'] is! String ||
          value['reason'] is! String ||
          (value['summary'] as String).trim().isEmpty ||
          (value['summary'] as String).length > 2500 ||
          (value['reason'] as String).length > 500 ||
          (value['title'] as String).length > 100) {
        return null;
      }
    } else if (kind == 'recall') {
      if (value.keys.toSet().difference({'id', 'start'}).isNotEmpty ||
          value['id'] is! String ||
          (value['start'] != null &&
              (value['start'] is! int || (value['start'] as int) < 0))) {
        return null;
      }
    } else {
      return null;
    }
    return value;
  } catch (error) {
    debugPrint('Chat archive entry rejected: ${error.runtimeType}');
    return null;
  }
}
