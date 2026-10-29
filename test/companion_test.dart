import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/data/companion_store.dart';
import 'package:gymia/data/sheet_context_store.dart';
import 'package:gymia/data/sheet_sync_service.dart';
import 'package:gymia/domain/companion.dart';
import 'package:gymia/domain/sheet_context.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'suggested companions can be edited and deleted without reseeding',
    () async {
      const store = CompanionStore(profileId: 'local');
      final defaults = await store.load();
      expect(
        defaults.map((item) => item.name),
        containsAll(['GymBro', 'Enfoque', 'Calma', 'Diario']),
      );
      final changed = defaults.first.copyWith(
        name: 'Mi entrenador',
        prompt: 'Ayúdame con mis ejercicios.',
      );
      await store.upsert(changed);
      expect((await store.load()).first.name, 'Mi entrenador');
      final own = Companion.custom(
        name: 'Basket',
        prompt: 'Controla mis cuartos.',
      );
      await store.upsert(own);
      expect((await store.load()).last.id, own.id);
      await store.delete('gymbro');
      expect((await store.load()).any((item) => item.id == 'gymbro'), isFalse);
      for (final item in await store.load()) {
        await store.delete(item.id);
      }
      expect(await store.load(), isEmpty);
    },
  );

  test(
    'GymBro keeps legacy keys; other companions keep Sheets separate',
    () async {
      expect(
        companionStorageKey('gymia.ai.chat.v1', 'local', 'gymbro'),
        'gymia.ai.chat.v1',
      );
      expect(
        SheetSyncService(profileId: 'local').connectionKey,
        'gymia.sheet.connection.v1',
      );
      final other = SheetSyncService(profileId: 'local', companionId: 'calma');
      expect(other.connectionKey, isNot('gymia.sheet.connection.v1'));

      final gym = SheetContextStore(profileId: 'local');
      final calm = SheetContextStore(profileId: 'local', companionId: 'calma');
      SheetContext sheet(String id) => SheetContext(
        id: id,
        name: id,
        title: 'Registro',
        loadedAt: DateTime(2026),
        rows: [
          [id],
        ],
      );
      await gym.save(sheet('gym'));
      await calm.save(sheet('calma'));
      expect((await gym.load())!.id, 'gym');
      expect((await calm.load())!.id, 'calma');
      await calm.delete();
      expect((await gym.load())!.id, 'gym');
    },
  );

  test(
    'deleting one companion removes only its local chat and destination',
    () async {
      const storage = FlutterSecureStorage();
      const store = CompanionStore(profileId: 'local');
      await store.load();
      final gymChat = companionStorageKey(
        'gymia.ai.chat.v1',
        'local',
        'gymbro',
      );
      final calmChat = companionStorageKey(
        'gymia.ai.chat.v1',
        'local',
        'calma',
      );
      await storage.write(key: gymChat, value: jsonEncode({'messages': []}));
      await storage.write(key: calmChat, value: jsonEncode({'messages': []}));
      await storage.write(
        key:
            SheetSyncService(
              profileId: 'local',
              companionId: 'calma',
            ).connectionKey,
        value: jsonEncode({'id': 'sheet-calma'}),
      );
      await store.delete('calma');
      expect(await storage.read(key: calmChat), isNull);
      expect(
        await SheetSyncService(
          profileId: 'local',
          companionId: 'calma',
        ).connection(),
        isNull,
      );
      expect(await storage.read(key: gymChat), isNotNull);
    },
  );
}
