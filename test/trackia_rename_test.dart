import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/data/trackia_rename.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('secure storage keys', () {
    const storage = FlutterSecureStorage();
    final config = const AiConfig(
      service: AiService.openai,
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-x',
      protocol: AiProtocol.responses,
      apiKey: 'sk-old-secret',
    );

    test(
      'every gymia.* key becomes trackia.* with its value and the app reads it',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'gymia.ai.config.v1': '{"service":"openai"}',
          'gymia.ai.config.v1.profile.ana': 'ana-config',
          'gymia.ai.chat.v1.companion.gymbro': 'chat',
          'gymia.sheet.jobs.v1': 'jobs',
          'gymia.profiles.v1': 'profiles',
          'gymia.appearance.v1': 'dark',
          'gymia.welcome.auto_show.v1': 'false',
          'gymia.chatgpt.accounts.v1': 'accounts',
          'otra.cosa': 'intacta',
        });
        final report = await migrateStorageKeys();
        expect(report.copied, 8);
        expect(report.failed, 0);
        final all = await storage.readAll();
        expect(all.keys.where((k) => k.startsWith('gymia.')), isEmpty);
        expect(all['trackia.ai.config.v1.profile.ana'], 'ana-config');
        expect(all['trackia.ai.chat.v1.companion.gymbro'], 'chat');
        expect(all['trackia.profiles.v1'], 'profiles');
        expect(all['trackia.welcome.auto_show.v1'], 'false');
        expect(all['otra.cosa'], 'intacta');
      },
    );

    test('a saved AI setup keeps working after the rename', () async {
      FlutterSecureStorage.setMockInitialValues({});
      await const FlutterSecureStorage().write(
        key: 'gymia.ai.config.v1',
        value:
            '{"service":"openai","baseUrl":"https://api.openai.com/v1","model":"gpt-x","protocol":"responses","apiKey":"sk-old-secret"}',
      );
      await migrateStorageKeys();
      final loaded = await const AiSettingsStore().load();
      expect(loaded?.apiKey, config.apiKey);
      expect(loaded?.model, 'gpt-x');
    });

    test('running again changes nothing and does not duplicate', () async {
      FlutterSecureStorage.setMockInitialValues({'gymia.ai.chat.v1': 'chat'});
      await migrateStorageKeys();
      final again = await migrateStorageKeys();
      expect(again.copied + again.alreadyThere + again.conflicts, 0);
      expect(await storage.readAll(), {'trackia.ai.chat.v1': 'chat'});
    });

    test(
      'an interrupted rename (both keys, same value) removes only the old one',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'gymia.ai.chat.v1': 'chat',
          'trackia.ai.chat.v1': 'chat',
        });
        final report = await migrateStorageKeys();
        expect(report.alreadyThere, 1);
        expect(await storage.readAll(), {'trackia.ai.chat.v1': 'chat'});
      },
    );

    test(
      'when the new key differs, the new one wins and the old one stays',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'gymia.ai.chat.v1': 'viejo',
          'trackia.ai.chat.v1': 'nuevo',
        });
        final report = await migrateStorageKeys();
        expect(report.conflicts, 1);
        final all = await storage.readAll();
        expect(all['trackia.ai.chat.v1'], 'nuevo');
        expect(all['gymia.ai.chat.v1'], 'viejo');
      },
    );
  });

  group('database file', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('trackia-rename-');
    });
    tearDown(() => dir.delete(recursive: true));

    Future<String> legacyDatabase(String name) async {
      final path = '${dir.path}/$name';
      final repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      await repo.close();
      return path;
    }

    test(
      'gymia.sqlite is copied to trackia.sqlite and kept as the backup',
      () async {
        final old = await legacyDatabase('gymia.sqlite');
        final path = await resolveDatabasePath(
          dir.path,
          'local',
          factory: databaseFactoryFfi,
        );
        expect(path, '${dir.path}/trackia.sqlite');
        expect(File(path).readAsBytesSync(), File(old).readAsBytesSync());
        expect(File(old).existsSync(), isTrue);
        final repo = await SqliteWorkoutRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        expect(repo, isNotNull);
        await repo.close();
      },
    );

    test('another profile keeps its own name and ids', () async {
      final old = await legacyDatabase('gymia-ana.sqlite');
      final path = await resolveDatabasePath(
        dir.path,
        'ana',
        factory: databaseFactoryFfi,
      );
      expect(path, '${dir.path}/trackia-ana.sqlite');
      expect(File(path).readAsBytesSync(), File(old).readAsBytesSync());
    });

    test('resolving again does not copy over the new database', () async {
      await legacyDatabase('gymia.sqlite');
      final path = await resolveDatabasePath(
        dir.path,
        'local',
        factory: databaseFactoryFfi,
      );
      File(path).writeAsStringSync('cambios nuevos');
      await resolveDatabasePath(dir.path, 'local', factory: databaseFactoryFfi);
      expect(File(path).readAsStringSync(), 'cambios nuevos');
    });

    test('a fresh install uses the new name and creates no old file', () async {
      final path = await resolveDatabasePath(
        dir.path,
        'local',
        factory: databaseFactoryFfi,
      );
      expect(path, '${dir.path}/trackia.sqlite');
      expect(File('${dir.path}/gymia.sqlite').existsSync(), isFalse);
    });

    test(
      'an empty journal left by a clean close does not stop the rename',
      () async {
        await legacyDatabase('gymia.sqlite');
        File('${dir.path}/gymia.sqlite-journal').writeAsBytesSync([]);
        expect(await migrateDatabaseFile(dir.path, 'local'), isTrue);
        expect(File('${dir.path}/trackia.sqlite').existsSync(), isTrue);
      },
    );

    test(
      'a pending journal keeps the old file in use instead of an empty database',
      () async {
        await legacyDatabase('gymia.sqlite');
        File('${dir.path}/gymia.sqlite-wal').writeAsStringSync('pendiente');
        final copied = await migrateDatabaseFile(dir.path, 'local');
        expect(copied, isFalse);
        expect(File('${dir.path}/trackia.sqlite').existsSync(), isFalse);
      },
    );
  });
}
