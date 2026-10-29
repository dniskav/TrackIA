import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/data/companion_store.dart';
import 'package:gymia/data/sheet_context_store.dart';
import 'package:gymia/data/sheet_sync_service.dart';
import 'package:gymia/domain/companion.dart';
import 'package:gymia/domain/sheet_context.dart';
import 'package:gymia/ui/theme.dart';

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

  group('icon and color', () {
    test('the four suggestions each have their own icon and color', () {
      final byId = {for (final c in Companion.suggestions) c.id: c};
      expect((byId['gymbro']!.icon, byId['gymbro']!.color), ('barbell', 'orange'));
      expect((byId['enfoque']!.icon, byId['enfoque']!.color), ('hourglass', 'teal'));
      expect((byId['calma']!.icon, byId['calma']!.color), ('leaf', 'green'));
      expect((byId['diario']!.icon, byId['diario']!.color), ('notebook', 'amber'));
    });

    test('a custom companion defaults to sparkles and teal', () {
      final own = Companion.custom(name: 'Lectura', prompt: 'Ayúdame a leer.');
      expect((own.icon, own.color), ('sparkles', 'teal'));
    });

    test('JSON saved before this change loads with defaults and keeps its data', () {
      final old = {
        'id': 'gymbro',
        'name': 'GymBro',
        'description': 'Entrenamiento',
        'prompt': 'Acompáñame.',
      };
      final loaded = Companion.fromJson(old);
      expect((loaded.icon, loaded.color), ('barbell', 'orange'));
      final again = Companion.fromJson(
        jsonDecode(jsonEncode(loaded.toJson())) as Map<String, dynamic>,
      );
      expect(again.toJson(), loaded.toJson());
      expect(again.name, 'GymBro');
      expect(again.prompt, 'Acompáñame.');
    });

    test('an explicit choice is kept and copyWith can change it', () {
      final own = Companion(
        id: 'ciclismo',
        name: 'Ciclismo',
        description: '',
        prompt: 'Registra mis rutas.',
        icon: 'bike',
        color: 'violet',
      );
      expect((own.icon, own.color), ('bike', 'violet'));
      expect(Companion.fromJson(own.toJson()).icon, 'bike');
      final changed = own.copyWith(icon: 'run', color: 'crimson');
      expect((changed.icon, changed.color), ('run', 'crimson'));
      expect(changed.name, 'Ciclismo');
      expect(own.copyWith(name: 'Otro').icon, 'bike');
    });

    test('unknown icon or color IDs are rejected', () {
      Companion build({String? icon, String? color}) => Companion(
        id: 'x1',
        name: 'X',
        description: '',
        prompt: 'p',
        icon: icon,
        color: color,
      );
      expect(() => build(icon: 'rocket'), throwsFormatException);
      expect(() => build(color: 'pink'), throwsFormatException);
      expect(
        () => Companion.fromJson({
          'id': 'x1',
          'name': 'X',
          'prompt': 'p',
          'icon': 'nope',
        }),
        throwsFormatException,
      );
    });

    test('the allowed IDs match the contract and the theme palette', () {
      expect(Companion.iconIds, hasLength(16));
      expect(Companion.colorIds, trackiaCompanionColors.keys.toSet());
    });
  });
}
