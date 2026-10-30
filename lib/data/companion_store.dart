import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/companion.dart';
import '../domain/user_profile.dart';

/// GymBro retains the pre-companion keys so existing chats and Sheets survive.
String companionStorageKey(String base, String profileId, String companionId) =>
    companionId == 'gymbro'
        ? profileStorageKey(base, profileId)
        : profileStorageKey('$base.companion.$companionId', profileId);

class CompanionStore {
  const CompanionStore({
    required this.profileId,
    this.storage = const FlutterSecureStorage(),
  });
  final String profileId;
  final FlutterSecureStorage storage;
  String get key => profileStorageKey('trackia.companions.v1', profileId);

  Future<List<Companion>> load() async {
    final raw = await storage.read(key: key);
    if (raw == null) {
      final defaults = Companion.suggestions;
      await save(defaults);
      return defaults;
    }
    return [
      for (final row in jsonDecode(raw) as List)
        Companion.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  }

  Future<void> save(List<Companion> companions) async {
    if (companions.map((p) => p.id).toSet().length != companions.length) {
      throw const FormatException(
        'Hay identificadores de acompañante duplicados.',
      );
    }
    await storage.write(
      key: key,
      value: jsonEncode(companions.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> upsert(Companion companion) async {
    final items = await load();
    final index = items.indexWhere((item) => item.id == companion.id);
    if (index < 0) {
      items.add(companion);
    } else {
      items[index] = companion;
    }
    await save(items);
  }

  Future<void> delete(String id) async {
    final items = await load();
    await save(items.where((item) => item.id != id).toList());
    final chatKey = companionStorageKey('trackia.ai.chat.v1', profileId, id);
    final raw = await storage.read(key: chatKey);
    if (raw != null) {
      final state = jsonDecode(raw) as Map<String, dynamic>;
      for (final row in state['archives'] as List? ?? []) {
        final archiveId = (row as Map)['id'];
        if (archiveId is String &&
            RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(archiveId)) {
          await storage.delete(
            key: companionStorageKey(
              'trackia.ai.archive.v1.$archiveId',
              profileId,
              id,
            ),
          );
        }
      }
    }
    for (final base in [
      'trackia.ai.chat.v1',
      'trackia.sheet.context.v1',
      'trackia.sheet.connection.v1',
      'trackia.sheet.creation.v1',
      'trackia.sheet.jobs.v1',
    ]) {
      await storage.delete(key: companionStorageKey(base, profileId, id));
    }
  }
}
