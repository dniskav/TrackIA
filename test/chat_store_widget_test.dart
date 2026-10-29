import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/application/ai_availability.dart';
import 'package:gymia/application/workout_controller.dart';
import 'package:gymia/data/ai_client.dart';
import 'package:gymia/data/ai_model_catalog.dart';
import 'package:gymia/data/ai_settings_store.dart';
import 'package:gymia/data/chat_store.dart';
import 'package:gymia/data/companion_store.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/domain/ai_config.dart';
import 'package:gymia/ui/assistant_chat.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixtures/trackia_v6_fixtures.dart';
import 'helpers/real_io.dart';

/// The chat on the real store: it opens an old chat from secure storage,
/// migrates it, and keeps saving to SQLite (FR-040).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  const storage = FlutterSecureStorage();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController controller;
  final now = DateTime(2026, 10, 29, 9);
  const config = AiConfig(
    service: AiService.custom,
    protocol: AiProtocol.chatCompletions,
    baseUrl: 'https://example.test/v1',
    model: 'test',
    apiKey: 'fake-key',
  );
  final legacyKey = companionStorageKey(
    'gymia.ai.chat.v1',
    LegacyChatFixture.profileId,
    LegacyChatFixture.companionId,
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      legacyKey: jsonEncode(LegacyChatFixture.chat()),
    });
    await const AiSettingsStore().save(config);
    await const AiSettingsStore().markVerified(config);
    dir = await Directory.systemTemp.createTemp('trackia-chat-widget-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    controller = WorkoutController(repo, clock: () => now);
  });
  tearDown(() async {
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<List<Map<String, dynamic>>> sent(
    WidgetTester tester, {
    ChatStore? store,
  }) async {
    final bodies = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: AssistantChatScreen(
          controller: controller,
          chatStore: store,
          client: AiClient(
            transport: (_, __, body) async {
              bodies.add(body);
              return {
                'choices': [
                  {
                    'message': {'content': 'Entendido'},
                  },
                ],
              };
            },
          ),
          availability: AiAvailability(
            catalog: AiModelCatalog(
              transport: (_, __) async => {
                'data': [
                  {'id': 'test'},
                ],
              },
            ),
          ),
        ),
      ),
    );
    await realIo(tester);
    return bodies;
  }

  testWidgets('an old chat opens, is migrated and keeps saving to SQLite', (
    tester,
  ) async {
    final store = repo.chats;
    final bodies = await sent(tester, store: store);
    expect(find.text('Hola'), findsOneWidget);
    expect(find.text('Preparado.'), findsOneWidget);

    // Opening copied it and verified it; the old key waits for the next launch.
    final info = (await tester.runAsync(() => store.info('gymbro')))!;
    expect(info.verified, isTrue);
    expect(
      await tester.runAsync(() => storage.read(key: legacyKey)),
      isNotNull,
    );
    final hash = sha256.convert(
      base64Decode(LegacyChatFixture.attachmentBase64),
    );
    expect(File('${dir.path}/trackia_media/$hash').existsSync(), isTrue);

    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Siguiente',
    );
    await tester.tap(find.byTooltip('Enviar'));
    await realIo(tester);
    expect(bodies, hasLength(1));

    final saved = (await tester.runAsync(() => store.loadActive('gymbro')))!;
    final texts = [
      for (final m in saved['messages'] as List) (m as Map)['content'],
    ];
    expect(texts, ['Hola', 'Preparado.', 'Siguiente', 'Entendido']);
    // The attachment of the old chat survived the round trip untouched.
    expect(
      ((saved['messages'] as List)[1] as Map)['attachment']['bytes'],
      LegacyChatFixture.attachmentBase64,
    );
    await tester.pumpWidget(const SizedBox());
    await realIo(tester, 10);
  });

  testWidgets('a new chat is written to SQLite and never to secure storage', (
    tester,
  ) async {
    // No old chat this time; the AI configuration stays.
    await storage.delete(key: legacyKey);
    final store = repo.chats;
    await sent(tester, store: store);
    await tester.enterText(find.byKey(const Key('assistant-input')), 'Primero');
    await tester.tap(find.byTooltip('Enviar'));
    await realIo(tester);
    final saved = (await tester.runAsync(() => store.loadActive('gymbro')))!;
    expect(
      [for (final m in saved['messages'] as List) (m as Map)['content']],
      ['Primero', 'Entendido'],
    );
    expect(await tester.runAsync(() => storage.read(key: legacyKey)), isNull);
    await tester.pumpWidget(const SizedBox());
    await realIo(tester, 10);
  });
}
