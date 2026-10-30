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
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/ui/assistant_chat.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/real_io.dart';

/// FR-036: in game mode, `trackia-goal`, `trackia-achievement` and
/// `trackia-reminder-copy` become cards; only the user's tap saves, and an
/// achievement is never unlocked by adding it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController controller;
  late ProgressService service;
  late String reply;
  var remindersChanged = 0;
  final now = DateTime(2026, 10, 29, 9);
  const config = AiConfig(
    service: AiService.custom,
    protocol: AiProtocol.chatCompletions,
    baseUrl: 'https://example.test/v1',
    model: 'test',
    apiKey: 'fake-key',
  );

  String block(String kind, Object json) =>
      'Mira.\n```trackia-$kind\n${jsonEncode(json)}\n```';

  final goal = {
    'metric': {'source': 'sessions', 'per': 'day'},
    'period': 'day',
    'target': 2,
  };
  final achievement = {
    'title': 'Diez sesiones',
    'rule': {
      'kind': 'threshold',
      'metric': {'source': 'sessions', 'per': 'total'},
      'threshold': 1,
    },
  };

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    remindersChanged = 0;
    await const AiSettingsStore().save(config);
    await const AiSettingsStore().markVerified(config);
    dir = await Directory.systemTemp.createTemp('trackia-game-blocks-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    controller = WorkoutController(repo, clock: () => now);
    service = ProgressService(progress: repo.progress, clock: () => now);
  });
  tearDown(() async {
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<void> gameMode(WidgetTester tester) => tester.runAsync(
    () async => repo.progress.saveSettings(
      (await repo.progress.settings('gymbro')).copyWith(mode: 'game'),
    ),
  );

  Future<void> ask(WidgetTester tester, String text) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AssistantChatScreen(
          controller: controller,
          progressService: service,
          onRemindersChanged: () => remindersChanged++,
          client: AiClient(
            transport: (_, __, body) async => {
              'choices': [
                {
                  'message': {'content': reply},
                },
              ],
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
    await realIo(tester, 30);
    await tester.enterText(find.byKey(const Key('assistant-input')), text);
    await tester.tap(find.byTooltip('Enviar'));
    await realIo(tester, 60);
  }

  const rejected = 'La propuesta no es válida y no se aplicó.';

  testWidgets('a goal becomes a card and only Añadir saves it', (tester) async {
    await gameMode(tester);
    reply = block('goal', goal);
    await ask(tester, 'Ponme una meta');
    expect(find.byKey(const Key('game-proposal-goal')), findsOneWidget);
    expect(find.text('Meta propuesta: 2 sesiones al día'), findsOneWidget);
    // Nothing is saved until the user decides.
    expect(
      await tester.runAsync(() => repo.progress.activeGoal('gymbro')),
      isNull,
    );

    await tester.tap(find.byKey(const Key('game-add-goal')));
    await realIo(tester, 40);
    final saved = (await tester.runAsync(
      () => repo.progress.activeGoal('gymbro'),
    ))!;
    expect([saved.target, saved.period], [2, 'day']);
    expect(find.byKey(const Key('game-proposal-goal')), findsNothing);
    expect(find.text('Meta añadida. La verás en tu progreso.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Ignorar drops the card and saves nothing', (tester) async {
    await gameMode(tester);
    reply = block('goal', goal);
    await ask(tester, 'Ponme una meta');
    await tester.tap(find.byKey(const Key('game-ignore-goal')));
    await tester.pump();
    expect(find.byKey(const Key('game-proposal-goal')), findsNothing);
    expect(
      await tester.runAsync(() => repo.progress.activeGoal('gymbro')),
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an achievement is added as a rule and never unlocked', (
    tester,
  ) async {
    await gameMode(tester);
    // The data already satisfies the rule (one session), yet adding must not unlock.
    await tester.runAsync(
      () => repo.observations.record(
        companionId: 'gymbro',
        definition: ActivityDefinition(
          name: 'Algo',
          repeated: false,
          restSeconds: 0,
        ),
        original: 'Hecho',
      ),
    );
    reply = block('achievement', achievement);
    await ask(tester, 'Un logro');
    expect(find.text('Logro propuesto: Diez sesiones'), findsOneWidget);
    expect(find.text('Sesiones ≥ 1 sesión en total'), findsOneWidget);
    expect(
      await tester.runAsync(() => repo.progress.achievements('gymbro')),
      isEmpty,
    );

    await tester.tap(find.byKey(const Key('game-add-achievement')));
    await realIo(tester, 40);
    final saved = (await tester.runAsync(
      () => repo.progress.achievements('gymbro'),
    ))!;
    expect(saved.single.title, 'Diez sesiones');
    expect(saved.single.origin, 'assistant');
    expect(saved.single.unlocked, isFalse);
    expect(find.text('Logro añadido: Diez sesiones.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'reminder texts show real examples and are kept on the companion',
    (tester) async {
      await gameMode(tester);
      reply = block('reminder-copy', {
        'windowStart': ['{nombre}: ¡a por ello!'],
        'lastCall': ['Aún puedes hoy.'],
      });
      await ask(tester, 'Textos');
      expect(find.byKey(const Key('game-proposal-copy')), findsOneWidget);
      expect(find.text('GymBro: ¡a por ello!'), findsOneWidget);
      expect(find.text('Aún puedes hoy.'), findsOneWidget);
      expect(
        (await tester.runAsync(
          () => const CompanionStore(profileId: 'local').load(),
        ))!.first.reminderCopy,
        isNull,
      );

      await tester.tap(find.byKey(const Key('game-add-copy')));
      await realIo(tester, 40);
      final gymbro = (await tester.runAsync(
        () => const CompanionStore(profileId: 'local').load(),
      ))!.firstWhere((c) => c.id == 'gymbro');
      expect(gymbro.reminderCopy!.windowStart, ['{nombre}: ¡a por ello!']);
      expect(gymbro.reminderCopy!.lastCall, ['Aún puedes hoy.']);
      expect(gymbro.reminderCopy!.inactive, isEmpty);
      expect(remindersChanged, 1);
      expect(find.text('Textos de recordatorio guardados.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('an invalid block leaves the reply, shows no card and says so', (
    tester,
  ) async {
    await gameMode(tester);
    reply = block('goal', {...goal, 'origin': 'assistant'});
    await ask(tester, 'Meta');
    expect(find.text(rejected), findsOneWidget);
    expect(find.byKey(const Key('game-proposal-goal')), findsNothing);
    expect(
      await tester.runAsync(() => repo.progress.activeGoal('gymbro')),
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an activity the companion does not have is rejected', (
    tester,
  ) async {
    await gameMode(tester);
    reply = block('goal', {...goal, 'activityKey': 'fantasma'});
    await ask(tester, 'Meta');
    expect(find.text(rejected), findsOneWidget);
    expect(find.byKey(const Key('game-proposal-goal')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('two blocks of the same kind are both ignored', (tester) async {
    await gameMode(tester);
    reply = '${block('goal', goal)}\n${block('goal', {...goal, 'target': 3})}';
    await ask(tester, 'Meta');
    expect(find.text(rejected), findsOneWidget);
    expect(find.byKey(const Key('game-proposal-goal')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('one reply can carry a goal and an achievement', (tester) async {
    await gameMode(tester);
    reply = '${block('goal', goal)}\n${block('achievement', achievement)}';
    await ask(tester, 'Todo');
    expect(find.byKey(const Key('game-proposal-goal')), findsOneWidget);
    expect(find.byKey(const Key('game-proposal-achievement')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('outside game mode the blocks are ignored, not even rejected', (
    tester,
  ) async {
    reply = block('goal', goal);
    await ask(tester, 'Meta');
    expect(find.byKey(const Key('game-proposal-goal')), findsNothing);
    expect(find.text(rejected), findsNothing);
    expect(
      await tester.runAsync(() => repo.progress.activeGoal('gymbro')),
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
