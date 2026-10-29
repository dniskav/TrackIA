import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/application/ai_availability.dart';
import 'package:gymia/application/workout_controller.dart';
import 'package:gymia/data/ai_client.dart';
import 'package:gymia/data/ai_model_catalog.dart';
import 'package:gymia/data/ai_settings_store.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/domain/ai_config.dart';
import 'package:gymia/domain/companion.dart';
import 'package:gymia/ui/assistant_chat.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Golden files pin the exact system prompt so moving or extending the context
/// builder cannot change it by accident. Regenerate deliberately with
/// `flutter test --dart-define=UPDATE_GOLDEN=true test/assistant_context_test.dart`.
const _update = bool.fromEnvironment('UPDATE_GOLDEN');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController controller;
  const config = AiConfig(
    service: AiService.opencodeGo,
    baseUrl: 'https://opencode.ai/zen/go/v1',
    model: 'test-model',
    protocol: AiProtocol.chatCompletions,
    apiKey: 'test-secret',
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('trackia-context-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
    );
    controller = WorkoutController(repo, clock: () => DateTime(2026, 10, 29, 9));
    await controller.refresh();
    await const AiSettingsStore().save(config);
    await const AiSettingsStore().markVerified(config);
  });
  tearDown(() async {
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<String> systemPrompt(
    WidgetTester tester, {
    required bool focusMode,
    Companion? companion,
  }) async {
    final payloads = <Map<String, dynamic>>[];
    final client = AiClient(
      transport: (_, __, body) async {
        payloads.add(body);
        return {
          'choices': [
            {
              'message': {'content': 'Hola'},
            },
          ],
        };
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AssistantChatScreen(
          controller: controller,
          client: client,
          focusMode: focusMode,
          companion: companion,
          availability: AiAvailability(
            catalog: AiModelCatalog(
              transport:
                  (_, __) async => {
                    'data': [
                      {'id': 'test-model'},
                    ],
                  },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Mensaje de prueba',
    );
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(payloads, hasLength(1));
    return payloads.single['messages'][0]['content'] as String;
  }

  void matchesGolden(String name, String actual) {
    final file = File('test/fixtures/assistant_context_$name.txt');
    if (_update) {
      file.writeAsStringSync(actual);
      return;
    }
    expect(file.existsSync(), isTrue, reason: 'Falta ${file.path}');
    expect(actual, file.readAsStringSync());
  }

  testWidgets('GymBro conversation context is unchanged', (tester) async {
    matchesGolden(
      'gymbro',
      await systemPrompt(tester, focusMode: false),
    );
  });

  testWidgets('GymBro focus context is unchanged', (tester) async {
    matchesGolden(
      'gymbro_focus',
      await systemPrompt(tester, focusMode: true),
    );
  });

  testWidgets('custom companion context is unchanged', (tester) async {
    matchesGolden(
      'custom_focus',
      await systemPrompt(
        tester,
        focusMode: true,
        companion: Companion(
          id: 'lectura',
          name: 'Lectura',
          description: 'Hábito de leer',
          prompt: 'Ayúdame a leer cada día.',
        ),
      ),
    );
  });
}
