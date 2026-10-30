import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/data/trackia_rename.dart';

/// The GymIA → TrackIA rename on a real Android device: keys kept in the
/// Keystore-backed secure storage and a database created under the old name
/// are found under the new ones, nothing lost, and the old file stays as backup.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();

  testWidgets('old keys and gymia.sqlite are picked up by the new names', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final aiJson =
          '{"service":"openai","baseUrl":"https://api.openai.com/v1","model":"gpt-x","protocol":"responses","apiKey":"sk-device-secret"}';
      await storage.write(key: 'gymia.ai.config.v1', value: aiJson);
      await storage.write(key: 'gymia.profiles.v1', value: 'perfiles');
      await storage.delete(key: 'trackia.ai.config.v1');
      await storage.delete(key: 'trackia.profiles.v1');

      final report = await migrateStorageKeys();
      expect(report.failed, 0);
      expect(await storage.read(key: 'gymia.ai.config.v1'), isNull);
      expect(await storage.read(key: 'trackia.profiles.v1'), 'perfiles');
      expect(
        (await const AiSettingsStore().load())?.apiKey,
        'sk-device-secret',
      );
      expect((await migrateStorageKeys()).copied, 0);
      await const AiSettingsStore().delete();
      await storage.delete(key: 'trackia.profiles.v1');

      final directory = await getDatabasesPath();
      final oldPath = p.join(directory, 'gymia-rename-check.sqlite');
      final newPath = p.join(directory, 'trackia-rename-check.sqlite');
      for (final f in [oldPath, newPath]) {
        await deleteDatabase(f);
      }
      final repo = await SqliteWorkoutRepository.open(path: oldPath);
      await repo.close();
      final resolved = await resolveDatabasePath(directory, 'rename-check');
      expect(resolved, newPath);
      expect(File(newPath).readAsBytesSync(), File(oldPath).readAsBytesSync());
      expect(File(oldPath).existsSync(), isTrue);
      final reopened = await SqliteWorkoutRepository.open(path: newPath);
      await reopened.close();
      for (final f in [oldPath, newPath]) {
        await deleteDatabase(f);
      }
    });
  });
}
