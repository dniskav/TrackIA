import 'dart:convert';

import '../domain/companion_memory.dart';

/// A portable, credential-free copy of companion memories.
///
/// Snapshots are deliberately scoped to exactly one profile and companion.
/// They contain memory provenance IDs, but never account tokens or connection
/// credentials. Callers must still obtain explicit consent before transfer.
class MemorySnapshot {
  MemorySnapshot({
    required this.profileId,
    required this.companionId,
    required Iterable<CompanionMemory> memories,
  }) : memories = List.unmodifiable(memories) {
    _requireText(profileId, 'profileId');
    _requireText(companionId, 'companionId');
    for (final memory in this.memories) {
      if (memory.profileId != profileId || memory.companionId != companionId) {
        throw const FormatException('El snapshot mezcla ámbitos de memoria.');
      }
    }
  }

  static const int currentVersion = 1;
  final String profileId;
  final String companionId;
  final List<CompanionMemory> memories;

  /// Produces deterministic JSON; records are ordered by ID.
  String toJson() => jsonEncode(toMap());

  Map<String, Object?> toMap() => <String, Object?>{
    'version': currentVersion,
    'profileId': profileId,
    'companionId': companionId,
    'memories':
        memories.map(_memoryToMap).toList()
          ..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String)),
  };

  /// Parses only the v1 schema and rejects data from another requested scope.
  /// Unknown keys are rejected to prevent silently dropping imported data.
  static MemorySnapshot parse(
    String json, {
    required String expectedProfileId,
    required String expectedCompanionId,
  }) {
    _requireText(expectedProfileId, 'expectedProfileId');
    _requireText(expectedCompanionId, 'expectedCompanionId');
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      rethrow;
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El snapshot debe ser un objeto JSON.');
    }
    _requireKeys(decoded, const {
      'version',
      'profileId',
      'companionId',
      'memories',
    }, 'snapshot');
    if (decoded['version'] != currentVersion) {
      throw FormatException(
        'Versión de snapshot no compatible: ${decoded['version']}.',
      );
    }
    final profileId = _string(decoded['profileId'], 'profileId');
    final companionId = _string(decoded['companionId'], 'companionId');
    if (profileId != expectedProfileId || companionId != expectedCompanionId) {
      throw const FormatException(
        'El snapshot pertenece a otro perfil o acompañante.',
      );
    }
    final rawMemories = decoded['memories'];
    if (rawMemories is! List) {
      throw const FormatException('memories debe ser una lista.');
    }
    final memories = rawMemories
        .map((raw) {
          if (raw is! Map<String, dynamic>) {
            throw const FormatException('Cada memoria debe ser un objeto.');
          }
          _requireKeys(raw, const {
            'id',
            'content',
            'source',
            'sourceMessageId',
            'createdAt',
            'updatedAt',
            'revision',
            'status',
          }, 'memory');
          final source = _enumByName(
            MemorySource.values,
            raw['source'],
            'source',
          );
          final status = _enumByName(
            MemoryStatus.values,
            raw['status'],
            'status',
          );
          final sourceMessageId = raw['sourceMessageId'];
          if (sourceMessageId != null && sourceMessageId is! String) {
            throw const FormatException(
              'sourceMessageId debe ser texto o null.',
            );
          }
          final createdAt = _date(raw['createdAt'], 'createdAt');
          final updatedAt = _date(raw['updatedAt'], 'updatedAt');
          final revision = raw['revision'];
          if (revision is! int) {
            throw const FormatException('revision debe ser un entero.');
          }
          try {
            return CompanionMemory(
              id: _string(raw['id'], 'id'),
              profileId: profileId,
              companionId: companionId,
              content: _string(raw['content'], 'content'),
              source: source,
              sourceMessageId: sourceMessageId as String?,
              createdAt: createdAt,
              updatedAt: updatedAt,
              revision: revision,
              status: status,
            );
          } on ArgumentError catch (error) {
            throw FormatException('Memoria inválida: ${error.message}');
          }
        })
        .toList(growable: false);
    return MemorySnapshot(
      profileId: profileId,
      companionId: companionId,
      memories: memories,
    );
  }
}

Map<String, Object?> _memoryToMap(CompanionMemory memory) => <String, Object?>{
  'id': memory.id,
  'content': memory.content,
  'source': memory.source.name,
  'sourceMessageId': memory.sourceMessageId,
  'createdAt': memory.createdAt.toUtc().toIso8601String(),
  'updatedAt': memory.updatedAt.toUtc().toIso8601String(),
  'revision': memory.revision,
  'status': memory.status.name,
};

void _requireKeys(Map<String, dynamic> map, Set<String> expected, String name) {
  if (map.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(map.keys.toSet()).isNotEmpty) {
    throw FormatException('$name contiene claves ausentes o desconocidas.');
  }
}

String _string(Object? value, String name) {
  if (value is! String) throw FormatException('$name debe ser texto.');
  return value;
}

DateTime _date(Object? value, String name) {
  final text = _string(value, name);
  final parsed = DateTime.tryParse(text);
  if (parsed == null || !parsed.toIso8601String().contains('T')) {
    throw FormatException('$name debe ser una fecha ISO-8601 válida.');
  }
  return parsed;
}

T _enumByName<T extends Enum>(List<T> values, Object? value, String name) {
  if (value is! String) throw FormatException('$name debe ser texto.');
  for (final item in values) {
    if (item.name == value) return item;
  }
  throw FormatException('$name no es compatible.');
}

void _requireText(String value, String name) {
  if (value.trim().isEmpty) throw ArgumentError.value(value, name);
}
