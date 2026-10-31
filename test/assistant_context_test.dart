import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/application/progress_service.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/assistant_blocks.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/progress.dart';
import 'package:trackia/application/assistant_context.dart';
import 'package:trackia/ui/assistant_chat.dart';
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
    controller = WorkoutController(
      repo,
      clock: () => DateTime(2026, 10, 29, 9),
    );
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
              transport: (_, __) async => {
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
    matchesGolden('gymbro', await systemPrompt(tester, focusMode: false));
  });

  testWidgets('GymBro focus context is unchanged', (tester) async {
    matchesGolden('gymbro_focus', await systemPrompt(tester, focusMode: true));
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

  testWidgets('an empty prompt uses the neutral instructions (FR-016)', (
    tester,
  ) async {
    final prompt = await systemPrompt(
      tester,
      focusMode: true,
      companion: Companion(
        id: 'silencio',
        name: 'Silencio',
        description: '',
        prompt: '',
      ),
    );
    expect(
      prompt,
      contains(
        'Acompaña al usuario con un tono cercano y claro. Ayúdale a registrar lo que hace sin inventar datos.',
      ),
    );
  });

  group('edit events (FR-024)', () {
    Future<(List<Map<String, dynamic>>, Map<String, dynamic>)> send(
      WidgetTester tester,
    ) async {
      final key = companionStorageKey(
        'trackia.ai.chat.v1',
        controller.profileId,
        'gymbro',
      );
      FlutterSecureStorage.setMockInitialValues({
        key: jsonEncode({
          'sessionId': 's1',
          'messages': [
            {'role': 'user', 'content': 'Hola'},
            {'role': 'assistant', 'content': 'Buenas'},
            {'role': 'event', 'content': 'Cambiaste el descanso a 120 s'},
          ],
          'pending': null,
          'archives': <Object>[],
          'archivedActivityMessageIds': <Object>[],
          'carryForward': '',
        }),
      });
      await const AiSettingsStore().save(config);
      await const AiSettingsStore().markVerified(config);
      final payloads = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AssistantChatScreen(
            controller: controller,
            client: AiClient(
              transport: (_, __, body) async {
                payloads.add(body);
                return {
                  'choices': [
                    {
                      'message': {'content': 'Hecho'},
                    },
                  ],
                };
              },
            ),
            availability: AiAvailability(
              catalog: AiModelCatalog(
                transport: (_, __) async => {
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
      expect(find.byKey(const Key('event-line')), findsOneWidget);
      expect(find.text('Cambiaste el descanso a 120 s'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('assistant-input')),
        'Siguiente',
      );
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(payloads, hasLength(1));
      final messages = (payloads.single['messages'] as List)
          .cast<Map<String, dynamic>>();
      return (messages, payloads.single);
    }

    testWidgets('an event is shown but never sent as a message', (
      tester,
    ) async {
      final (messages, _) = await send(tester);
      expect(messages.map((m) => m['role']), isNot(contains('event')));
      expect(
        messages.skip(1).map((m) => m['content']).join(' '),
        isNot(contains('Cambiaste el descanso')),
      );
    });

    testWidgets('recent events are summarised in the context', (tester) async {
      final (messages, _) = await send(tester);
      expect(
        messages.first['content'],
        contains('Cambiaste el descanso a 120 s'),
      );
      expect(messages.first['content'], contains('Cambios recientes'));
    });
  });

  group('progress (FR-032)', () {
    const instruction =
        'No afirmes que el usuario desbloqueó un logro o cumplió una meta: la app lo calcula y te lo indica en el contexto.';

    Future<String> systemWithProgress(WidgetTester tester) async {
      final payloads = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AssistantChatScreen(
            controller: controller,
            progressService: ProgressService(
              progress: controller.progress!,
              clock: () => DateTime(2026, 10, 29, 9),
            ),
            client: AiClient(
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
            ),
            availability: AiAvailability(
              catalog: AiModelCatalog(
                transport: (_, __) async => {
                  'data': [
                    {'id': 'test-model'},
                  ],
                },
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.enterText(
        find.byKey(const Key('assistant-input')),
        'Mensaje',
      );
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();
      expect(payloads, hasLength(1));
      return payloads.single['messages'][0]['content'] as String;
    }

    testWidgets('game mode adds the calculated state as data', (tester) async {
      await tester.runAsync(() async {
        final progress = controller.progress!;
        await progress.saveSettings(
          (await progress.settings('gymbro')).copyWith(mode: 'game'),
        );
        await progress.saveGoal(
          'gymbro',
          GoalRule(metric: Metric.sessions('day'), period: 'day', target: 2),
        );
        await repo.observations.record(
          companionId: 'gymbro',
          definition: ActivityDefinition(
            name: 'Algo',
            repeated: false,
            restSeconds: 0,
          ),
          original: 'Hoy',
          // The progress clock is fixed, so the observation must not use the real one.
          observedAt: DateTime(2026, 10, 29, 9),
        );
      });
      final prompt = await systemWithProgress(tester);
      expect(prompt, contains(instruction));
      expect(prompt, contains('Estado de progreso calculado por la app'));
      expect(prompt, contains('"mode":"game"'));
      // One session does not reach a goal of two, so the day is not done yet.
      expect(prompt, contains('"currentStreak":0'));
      expect(prompt, contains('"value":1.0,"target":2.0'));
      expect(prompt, contains('"met":false'));
      expect(prompt, contains('"unlockedToday":[]'));
    });

    testWidgets('outside game mode only the fixed instruction is added', (
      tester,
    ) async {
      final prompt = await systemWithProgress(tester);
      expect(prompt, contains(instruction));
      expect(prompt, isNot(contains('Estado de progreso')));
    });

    testWidgets('every golden context carries the fixed instruction', (
      tester,
    ) async {
      for (final name in ['gymbro', 'gymbro_focus', 'custom_focus']) {
        expect(
          File('test/fixtures/assistant_context_$name.txt').readAsStringSync(),
          contains(instruction),
        );
      }
    });
  });

  group('blocks the AI may use', () {
    test('a proposal built from the prompt examples is accepted', () {
      final text = buildCompanionCreationContext();
      const reminder =
          '{"days":["mon","tue","wed","thu","fri","sat","sun"],"start":"18:00","end":"19:00","tone":"cheer"}';
      expect(text, contains(reminder));
      final proposal = parseCompanionBlock(
        '```trackia-companion\n{"name":"Lectura","mode":"game","goal":'
        '{"metric":{"source":"time","per":"day"},"period":"day","target":20},'
        '"reminder":$reminder}\n```',
      );
      expect(proposal, isNotNull);
      expect(proposal!.reminder!.startMin, 18 * 60);
    });

    test('the goal examples in the creation prompt pass the real validator', () {
      final text = buildCompanionCreationContext();
      for (final example in [
        '{"metric":{"source":"time","per":"day"},"period":"day","target":20}',
        '{"metric":{"source":"sessions","per":"day"},"period":"day","target":1}',
      ]) {
        expect(text, contains(example));
        expect(GoalRule.tryParse(jsonDecode(example)), isNotNull);
      }
    });

    test('creating a companion gets the exact script and the block format', () {
      final text = buildCompanionCreationContext();
      expect(
        text,
        contains(
          'Ayuda a crear un acompañante de seguimiento. Haz como máximo tres preguntas breves, de una en una: qué quiere seguir, con qué frecuencia y si quiere aviso. Después ofrece estos tres niveles con una línea cada uno: Solo recordatorio; Metas y rachas (recomendado); Juego completo con logros. Cuando el usuario elija, responde con un único bloque trackia-companion. No inventes datos del usuario.',
        ),
      );
      expect(text, contains('trackia-companion'));
      for (final key in [
        'name',
        'mode',
        'description',
        'prompt',
        'icon',
        'color',
        'activity',
        'goal',
        'reminder',
      ]) {
        expect(text, contains(key));
      }
      for (final id in Companion.iconIds.followedBy(Companion.colorIds)) {
        expect(text, contains(id));
      }
      // The other blocks are not described where they are not accepted.
      expect(text, isNot(contains('trackia-achievement')));
      expect(text, isNot(contains('gymia-activity')));
    });

    test('game mode describes goal, achievement and reminder texts', () {
      for (final kind in [
        'trackia-goal',
        'trackia-achievement',
        'trackia-reminder-copy',
      ]) {
        expect(gameBlocksInstructions, contains(kind));
      }
      expect(gameBlocksInstructions, contains('{dias}'));
      expect(
        gameBlocksInstructions,
        contains('la app lo muestra como tarjeta'),
      );
    });

    test('the golden contexts never mention them (reminder mode)', () {
      for (final name in ['gymbro', 'gymbro_focus', 'custom_focus']) {
        final golden = File(
          'test/fixtures/assistant_context_$name.txt',
        ).readAsStringSync();
        expect(golden, isNot(contains('trackia-goal')));
        expect(golden, isNot(contains('trackia-companion')));
      }
    });
  });
}
