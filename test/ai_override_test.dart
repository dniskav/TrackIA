import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/data/ai_settings_store.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/domain/ai_config.dart';
import 'package:gymia/domain/workout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;

  const defaults = AiConfig(
    service: AiService.openai,
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-default',
    protocol: AiProtocol.responses,
    apiKey: 'sk-profile-secret',
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('trackia-ai-override-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => DateTime(2026, 10, 29, 9),
    );
    await const AiSettingsStore().save(defaults);
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  AiSettingsStore storeFor(String companionId) => AiSettingsStore(
    exception: () async =>
        (await repo.progress.settings(companionId)).aiOverride,
  );

  test('without an exception the profile default is used', () async {
    final config = await storeFor('gymbro').load();
    expect(config?.model, 'gpt-default');
    expect(config?.apiKey, 'sk-profile-secret');
  });

  test(
    'with an exception the companion model is used, the key is the profile\'s',
    () async {
      final settings = await repo.progress.settings('gymbro');
      await repo.progress.saveSettings(
        settings.copyWith(
          aiOverride: AiOverride(
            service: AiService.openai,
            model: 'gpt-ligero',
          ),
        ),
      );
      final config = await storeFor('gymbro').load();
      expect(config?.model, 'gpt-ligero');
      expect(config?.apiKey, 'sk-profile-secret');
      // Another companion keeps the default; the stored default is untouched.
      expect((await storeFor('enfoque').load())?.model, 'gpt-default');
      expect((await const AiSettingsStore().load())?.model, 'gpt-default');
      expect((await storeFor('gymbro').loadDefault())?.model, 'gpt-default');
    },
  );

  test('the exception can be cleared', () async {
    final base = await repo.progress.settings('gymbro');
    await repo.progress.saveSettings(
      base.copyWith(
        aiOverride: AiOverride(service: AiService.openai, model: 'gpt-ligero'),
      ),
    );
    await repo.progress.saveSettings(
      (await repo.progress.settings('gymbro')).copyWith(clearAiOverride: true),
    );
    expect((await repo.progress.settings('gymbro')).aiOverride, isNull);
    expect((await storeFor('gymbro').load())?.model, 'gpt-default');
  });

  test(
    'an exception for another provider is ignored: no credentials for it',
    () async {
      await repo.progress.saveSettings(
        (await repo.progress.settings('gymbro')).copyWith(
          aiOverride: AiOverride(service: AiService.gemini, model: 'gemini-x'),
        ),
      );
      final config = await storeFor('gymbro').load();
      expect(config?.service, AiService.openai);
      expect(config?.model, 'gpt-default');
    },
  );

  test('the database stores only provider and model, never a key', () async {
    await repo.progress.saveSettings(
      (await repo.progress.settings('gymbro')).copyWith(
        aiOverride: AiOverride(service: AiService.openai, model: 'gpt-ligero'),
      ),
    );
    final db = await databaseFactoryFfi.openDatabase('${dir.path}/test.sqlite');
    final rows = await db.query(
      'trackia_companion_settings',
      columns: ['ai_override'],
    );
    await db.close();
    expect(
      rows.single['ai_override'],
      '{"provider":"openai","modelId":"gpt-ligero"}',
    );
    expect(rows.single['ai_override'].toString(), isNot(contains('sk-')));
  });

  test('a value with a key, or a bad model, is rejected', () {
    expect(
      () => AiOverride.fromJson({
        'provider': 'openai',
        'modelId': 'gpt-x',
        'apiKey': 'sk-leak',
      }),
      throwsFormatException,
    );
    expect(
      () => AiOverride(service: AiService.openai, model: 'dos palabras'),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => AiOverride(service: AiService.openai, model: '  '),
      throwsA(isA<ValidationException>()),
    );
  });

  test('the protocol follows the companion model on OpenCode', () async {
    const opencode = AiConfig(
      service: AiService.opencodeGo,
      baseUrl: 'https://opencode.ai/zen/go/v1',
      model: 'opencode-go/glm-5.3',
      protocol: AiProtocol.chatCompletions,
      apiKey: 'k',
    );
    final tuned = opencode.withOverride(
      AiOverride(service: AiService.opencodeGo, model: 'claude-haiku'),
    );
    expect(tuned.protocol, AiProtocol.anthropic);
    expect(tuned.apiKey, 'k');
  });
}
