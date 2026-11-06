import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/reminder_scheduler.dart';
import 'package:trackia/data/progress_repository.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/progress.dart';
import 'package:trackia/ui/companion_settings.dart';
import 'package:trackia/ui/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late ProgressRepository progress;
  late int syncCalls;
  late ReminderScheduler scheduler;
  final now = DateTime(2026, 10, 29, 9);
  final lectura = Companion(
    id: 'lectura',
    name: 'Lectura',
    description: '',
    prompt: '',
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    syncCalls = 0;
    dir = await Directory.systemTemp.createTemp('trackia-settings-ui-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    progress = repo.progress;
    scheduler = ReminderScheduler(
      progress: progress,
      companions: () async => [lectura],
      clock: () => now,
      supported: true,
      invoke: (method, args) async {
        if (method == 'sync') syncCalls++;
        return true;
      },
    );
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  bool? popped;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(WidgetTester tester, {AiClient? client, AiSettingsStore? aiStore}) async {
    popped = null;
    // Tall enough that the whole list is built, so every key is findable.
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () async {
                popped = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CompanionSettingsScreen(
                      progress: progress,
                      store: const CompanionStore(profileId: 'local'),
                      companion: lectura,
                      scheduler: scheduler,
                      clock: () => now,
                      aiClient: client,
                      aiStore: aiStore,
                    ),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await settle(tester);
  }

  Future<AiSettingsStore> connectedStore() async {
    const store = AiSettingsStore(profileId: 'local');
    await store.save(const AiConfig(
      service: AiService.custom,
      baseUrl: 'https://provider.invalid/v1',
      model: 'synthetic',
      protocol: AiProtocol.chatCompletions,
      apiKey: 'synthetic-key',
    ));
    return store;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> save(WidgetTester tester) async {
    await tapKey(tester, 'save-settings');
    await settle(tester);
  }

  testWidgets('reminder mode is the default and the game options are hidden', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Modo y avisos · Lectura'), findsOneWidget);
    expect(find.byKey(const Key('game-goals')), findsNothing);
    expect(find.byKey(const Key('window-start')), findsNothing);
    await tapKey(tester, 'mode-game');
    expect(find.byKey(const Key('game-goals')), findsOneWidget);
    expect(find.byKey(const Key('game-streaks')), findsOneWidget);
    expect(find.byKey(const Key('game-achievements')), findsOneWidget);
    expect(find.byKey(const Key('game-cheers')), findsOneWidget);
    expect(find.byKey(const Key('free-days')), findsOneWidget);
    await tapKey(tester, 'mode-reminder');
    expect(find.byKey(const Key('game-goals')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('accepting a synthetic personality draft replaces the editor', (tester) async {
    final aiStore = await connectedStore();
    await open(tester, aiStore: aiStore, client: _DraftClient('Nueva propuesta'));
    await tapKey(tester, 'personality-ai-draft');
    await settle(tester);
    expect(find.text('Nueva propuesta'), findsOneWidget);
    await tester.tap(find.text('Usar propuesta'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('companion-personality'))).controller!.text, 'Nueva propuesta');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling a synthetic personality draft preserves user text', (tester) async {
    final aiStore = await connectedStore();
    await open(tester, aiStore: aiStore, client: _DraftClient('Nueva propuesta'));
    final editor = find.byKey(const Key('companion-personality'));
    await tester.enterText(editor, 'Texto propio');
    await tapKey(tester, 'personality-ai-draft');
    await settle(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(editor).controller!.text, 'Texto propio');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('provider failure is clear and preserves personality text', (tester) async {
    final aiStore = await connectedStore();
    await open(tester, aiStore: aiStore, client: _DraftClient.failure());
    final editor = find.byKey(const Key('companion-personality'));
    await tester.enterText(editor, 'Texto propio');
    await tapKey(tester, 'personality-ai-draft');
    await settle(tester);
    expect(find.byKey(const Key('settings-error')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('settings-error'))).data, contains('No se pudo generar'));
    expect(tester.widget<TextField>(editor).controller!.text, 'Texto propio');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('game mode and its switches are saved', (tester) async {
    await open(tester);
    await tapKey(tester, 'mode-game');
    await tapKey(tester, 'game-achievements');
    await save(tester);
    final saved = (await tester.runAsync(() => progress.settings('lectura')))!;
    expect(saved.game, isTrue);
    expect(saved.achievementsEnabled, isFalse);
    expect(saved.goalsEnabled, isTrue);
    expect(popped, isTrue);
    expect(syncCalls, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a reminder with the defaults is saved and shown in a preview', (
    tester,
  ) async {
    await open(tester);
    await tapKey(tester, 'remind-enabled');
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('22:00'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('preview-start'))).data,
      'Es buen momento para tu actividad.',
    );
    expect(find.byKey(const Key('preview-last-call')), findsNothing);

    await tapKey(tester, 'last-call-enabled');
    expect(
      tester.widget<Text>(find.byKey(const Key('preview-last-call'))).data,
      // Sample week: 1 of 7 done, so six are missing.
      'Te faltan 6 esta semana.',
    );
    await save(tester);

    final reminder = (await tester.runAsync(
      () => progress.reminderFor('lectura'),
    ))!;
    expect(reminder.days, 127);
    expect(reminder.windowStartMin, 20 * 60);
    expect(reminder.windowEndMin, 22 * 60);
    expect(reminder.lastCallMin, 21 * 60 + 30);
    expect(reminder.tone, 'neutral');
    expect(reminder.minimum, isNull);
    expect(syncCalls, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tone, minimum and days change the preview and what is saved', (
    tester,
  ) async {
    await open(tester);
    await tapKey(tester, 'remind-enabled');
    await tapKey(tester, 'last-call-enabled');
    await tester.tap(find.text('Motivador'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('preview-start'))).data,
      'Lectura te espera hoy.',
    );
    await tapKey(tester, 'minimum-enabled');
    await tester.enterText(find.byKey(const Key('minimum-value')), '5');
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('preview-last-call'))).data,
      'Última llamada: con 5 sesiones mantienes tu racha de 3 días.',
    );
    await tapKey(tester, 'day-5'); // Saturday off
    await tapKey(tester, 'day-6'); // Sunday off
    await save(tester);

    final reminder = (await tester.runAsync(
      () => progress.reminderFor('lectura'),
    ))!;
    expect(reminder.days, 0x1F);
    expect(reminder.tone, 'cheer');
    expect(reminder.minimum, {'metric': 'sessions', 'value': 5});
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('invalid choices show a Spanish error and save nothing', (
    tester,
  ) async {
    await open(tester);
    await tapKey(tester, 'remind-enabled');
    await tapKey(tester, 'minimum-enabled');
    await tester.enterText(find.byKey(const Key('minimum-value')), '0');
    await tester.pump();
    await save(tester);
    expect(
      find.text('El mínimo debe ser un número mayor que 0.'),
      findsOneWidget,
    );
    expect(popped, isNull);

    await tester.enterText(find.byKey(const Key('minimum-value')), '2');
    for (var i = 0; i < 7; i++) {
      await tapKey(tester, 'day-$i');
    }
    await save(tester);
    expect(find.text('Elige al menos un día de la semana.'), findsOneWidget);
    expect(
      await tester.runAsync(() => progress.reminderFor('lectura')),
      isNull,
    );
    expect(syncCalls, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('turning the reminder off keeps it stored but inactive', (
    tester,
  ) async {
    await tester.runAsync(
      () => progress.saveReminder(
        companionId: 'lectura',
        days: 127,
        windowStartMin: 600,
        windowEndMin: 700,
      ),
    );
    await open(tester);
    expect(find.text('10:00'), findsOneWidget);
    await tapKey(tester, 'remind-enabled');
    await save(tester);
    expect(await tester.runAsync(() => progress.activeReminders()), isEmpty);
    expect(
      await tester.runAsync(() => progress.reminderFor('lectura')),
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a paused reminder offers «Reanudar»', (tester) async {
    await tester.runAsync(() async {
      await progress.saveReminder(
        companionId: 'lectura',
        days: 127,
        windowStartMin: 600,
        windowEndMin: 700,
      );
      await progress.setPaused('lectura', paused: true);
    });
    await open(tester);
    expect(find.text('Recordatorios en pausa'), findsOneWidget);
    await tapKey(tester, 'resume-reminder');
    await settle(tester);
    expect(find.text('Recordatorios en pausa'), findsNothing);
    expect(
      (await tester.runAsync(() => progress.reminderFor('lectura')))!.paused,
      isFalse,
    );
    expect(syncCalls, 1);
    await tester.pumpWidget(const SizedBox());
  });

  group('goal (game mode)', () {
    Future<void> withPagesField(WidgetTester tester) => tester.runAsync(
      () => repo.templates.save(
        companionId: 'lectura',
        definition: ActivityDefinition(
          name: 'Leer',
          repeated: false,
          restSeconds: 0,
          companionId: 'lectura',
          fields: const [
            {
              'key': 'paginas',
              'label': 'Páginas',
              'unit': '',
              'type': 'number',
              'aggregate': 'sum',
            },
            {'key': 'notas', 'label': 'Notas', 'unit': ''},
          ],
        ),
      ),
    );

    Future<void> pick(WidgetTester tester, String key, String text) async {
      await tapKey(tester, key);
      await tester.tap(find.text(text).last);
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('the goal editor only appears in game mode with goals on', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const Key('goal-enabled')), findsNothing);
      await tapKey(tester, 'mode-game');
      expect(find.byKey(const Key('goal-enabled')), findsOneWidget);
      await tapKey(tester, 'game-goals');
      expect(find.byKey(const Key('goal-enabled')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a daily goal on a typed field is saved with its minimum', (
      tester,
    ) async {
      await withPagesField(tester);
      await open(tester);
      await tapKey(tester, 'mode-game');
      await tapKey(tester, 'goal-enabled');
      await pick(tester, 'goal-metric', 'Páginas');
      await tester.enterText(find.byKey(const Key('goal-target')), '20');
      await tester.enterText(find.byKey(const Key('goal-minimum')), '5');
      await save(tester);

      final goal = (await tester.runAsync(
        () => progress.activeGoal('lectura'),
      ))!;
      expect(goal.metric.toJson(), {
        'source': 'field',
        'field': 'paginas',
        'aggregate': 'sum',
        'per': 'day',
      });
      expect([goal.period, goal.target, goal.minimum], ['day', 20, 5]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('legacy fields cannot be measured; time is typed in minutes', (
      tester,
    ) async {
      await withPagesField(tester);
      await open(tester);
      await tapKey(tester, 'mode-game');
      await tapKey(tester, 'goal-enabled');
      await tapKey(tester, 'goal-metric');
      expect(find.text('Notas'), findsNothing);
      await tester.tap(find.text('Tiempo (minutos)').last);
      await tester.pump(const Duration(milliseconds: 200));
      await pick(tester, 'goal-period', 'a la semana');
      await tester.enterText(find.byKey(const Key('goal-target')), '90');
      await save(tester);

      final goal = (await tester.runAsync(
        () => progress.activeGoal('lectura'),
      ))!;
      expect(goal.metric.source, 'time');
      expect(goal.period, 'week');
      expect(goal.target, 5400); // 90 minutes in seconds
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a saved goal is shown again and can be switched off', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await progress.saveSettings(
          (await progress.settings('lectura')).copyWith(mode: 'game'),
        );
        await progress.saveGoal(
          'lectura',
          GoalRule(metric: Metric.sessions('week'), period: 'week', target: 3),
        );
      });
      await open(tester);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('goal-target')))
            .controller!
            .text,
        '3',
      );
      await tapKey(tester, 'goal-enabled');
      await save(tester);
      expect(
        await tester.runAsync(() => progress.activeGoal('lectura')),
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a bad target or minimum shows an error and saves nothing', (
      tester,
    ) async {
      await open(tester);
      await tapKey(tester, 'mode-game');
      await tapKey(tester, 'goal-enabled');
      await tester.enterText(find.byKey(const Key('goal-target')), '0');
      await save(tester);
      expect(
        find.text('El objetivo debe ser un número mayor que 0.'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const Key('goal-target')), '10');
      await tester.enterText(find.byKey(const Key('goal-minimum')), '20');
      await save(tester);
      expect(
        find.textContaining('el mínimo debe ser mayor que 0'),
        findsOneWidget,
      );
      expect(
        await tester.runAsync(() => progress.activeGoal('lectura')),
        isNull,
      );
      expect(popped, isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('leaving game mode keeps the goal for later', (tester) async {
      await tester.runAsync(() async {
        await progress.saveSettings(
          (await progress.settings('lectura')).copyWith(mode: 'game'),
        );
        await progress.saveGoal(
          'lectura',
          GoalRule(metric: Metric.sessions('day'), period: 'day', target: 1),
        );
      });
      await open(tester);
      await tapKey(tester, 'mode-reminder');
      await save(tester);
      expect(
        await tester.runAsync(() => progress.activeGoal('lectura')),
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
    });
  });
}

class _DraftClient extends AiClient {
  _DraftClient(this.answer) : super();
  _DraftClient.failure() : answer = null, super();
  final String? answer;

  @override
  Future<String> reply(AiConfig config, List<AiMessage> messages, {
    required String system,
    required String sessionId,
    void Function(String text)? onText,
  }) async {
    if (answer == null) throw StateError('synthetic provider failure');
    return answer!;
  }
}
