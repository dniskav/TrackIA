import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';

/// SC-007 on a real Android device: a chat with a large image kept the old way
/// (Keystore-backed secure storage) is copied to SQLite and files in the first
/// launch and its old keys are deleted in the second, with nothing lost.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();

  testWidgets('an old chat with a 3 MB image migrates in two launches', (
    tester,
  ) async {
    const profile = 'local';
    const companion = 'lectura';
    final chatKey = companionStorageKey('gymia.ai.chat.v1', profile, companion);
    final archiveKey = companionStorageKey(
      'gymia.ai.archive.v1.archivo-1',
      profile,
      companion,
    );
    final bytes = Uint8List.fromList(
      List.generate(3 * 1024 * 1024, (i) => i % 251),
    );
    final image = base64Encode(bytes);
    final chat = {
      'sessionId': 'session-1',
      'messages': [
        {
          'role': 'user',
          'content': 'Mira esto',
          'attachment': {
            'name': 'foto.png',
            'mime': 'image/png',
            'bytes': image,
          },
        },
        {'role': 'assistant', 'content': 'Lo veo'},
      ],
      'archives': [
        {'id': 'archivo-1', 'title': 'Antiguo', 'messageCount': 1},
      ],
      'archivedActivityMessageIds': <String>[],
      'carryForward': '',
    };
    final archive = {
      'id': 'archivo-1',
      'messages': [
        {
          'role': 'user',
          'content': 'Archivado',
          'attachment': {
            'name': 'otra.png',
            'mime': 'image/png',
            'bytes': base64Encode([7, 7, 7]),
          },
        },
      ],
    };

    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp('trackia-chat-mig-'),
    );
    await tester.runAsync(() async {
      await storage.write(key: chatKey, value: jsonEncode(chat));
      await storage.write(key: archiveKey, value: jsonEncode(archive));
      final repo = await SqliteWorkoutRepository.open(
        path: '${dir!.path}/chat.sqlite',
        profileId: profile,
      );

      // First launch: copy and verify; the old keys stay.
      final first = (await repo.chats.readActive(storage, companion))!;
      expect(jsonEncode(first), jsonEncode(chat));
      final info = (await repo.chats.info(companion))!;
      expect(info.verified, isTrue);
      expect(await storage.read(key: chatKey), isNotNull);
      expect(await storage.read(key: archiveKey), isNotNull);
      final media = Directory('${dir.path}/trackia_media');
      final stored = File('${media.path}/${sha256.convert(bytes)}');
      expect(await stored.exists(), isTrue);
      expect(await stored.readAsBytes(), bytes);
      await repo.close();

      // Second launch (a new store, as after restarting the app): phase 2.
      final again = await SqliteWorkoutRepository.open(
        path: '${dir.path}/chat.sqlite',
        profileId: profile,
      );
      final second = (await again.chats.readActive(storage, companion))!;
      expect(jsonEncode(second), jsonEncode(chat));
      expect(await storage.read(key: chatKey), isNull);
      expect(await storage.read(key: archiveKey), isNull);
      final readArchive = (await again.chats.readArchive(
        storage,
        companion,
        'archivo-1',
      ))!;
      expect(jsonEncode(readArchive), jsonEncode(archive));

      // A message saved now goes to SQLite only.
      await again.chats.saveActive(companion, {
        ...second,
        'messages': [
          ...second['messages'] as List,
          {'role': 'user', 'content': 'Nuevo'},
        ],
      });
      expect(await storage.read(key: chatKey), isNull);
      expect(
        ((await again.chats.loadActive(companion))!['messages'] as List).length,
        3,
      );
      await again.close();
      await dir.delete(recursive: true);
    });
  });
}
