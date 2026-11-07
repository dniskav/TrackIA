import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/assistant_blocks.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/ui/assistant_chat.dart';
import 'package:trackia/ui/activity_builder.dart';
import 'package:trackia/ui/activity_focus.dart';
import 'package:trackia/ui/theme.dart';
import 'package:trackia/ui/timer_ring.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController c;
  late DateTime now;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await const AiSettingsStore().save(
      const AiConfig(
        service: AiService.custom,
        protocol: AiProtocol.chatCompletions,
        baseUrl: 'https://example.test/v1',
        model: 'test',
        apiKey: 'test-key',
      ),
    );
    await const AiSettingsStore().markVerified(
      (await const AiSettingsStore().load())!,
    );
    now = DateTime(2026, 10, 8, 10);
    dir = await Directory.systemTemp.createTemp('gymia-focus-ui-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    c = WorkoutController(repo, clock: () => now);
    await repo.prepareActivity(
      ActivityDefinition(
        name: 'Pec Fly',
        restSeconds: 120,
        targetSets: 4,
        fields: const [
          {'key': 'weight_kg', 'label': 'Peso', 'unit': 'kg'},
          {'key': 'reps', 'label': 'Reps', 'unit': ''},
          {'key': 'failure', 'label': 'Fallo', 'unit': ''},
        ],
      ),
    );
    await repo.startInterval((await repo.loadActivities()).single.id);
    now = now.add(const Duration(seconds: 30));
    await repo.stopInterval((await repo.loadActivities()).single.id);
    await c.refresh();
  });
  tearDown(() async {
    c.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });
  Future<void> show(
    WidgetTester tester, {
    AiClient? client,
    Companion? companion,
    Locale locale = const Locale('es'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: gymTheme,
        home: AssistantChatScreen(
          controller: c,
          client: client,
          companion: companion,
          availability: AiAvailability(
            catalog: AiModelCatalog(
              transport:
                  (_, __) async => {
                    'data': [
                      {'id': 'test'},
                    ],
                  },
            ),
          ),
          focusMode: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  Future<void> showActivityControls(
    WidgetTester tester, {
    required Locale locale,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ActivityFocusControls(controller: c, flushInput: () async {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!done() && DateTime.now().isBefore(deadline)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(done(), isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tap(WidgetTester tester, Key key) =>
      tester.runAsync(() => tester.tap(find.byKey(key)));
  Future<void> disposeScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Drain both real SQLite completions and fake-frame continuations from the
    // final autosave before closing the database in tearDown.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
  }

  for (final localeCase in [
    (
      locale: const Locale('en'),
      title: 'Rest in progress',
      prompt:
          'Do you also want to change the notice that is already scheduled?',
      keep: 'Keep notice',
      change: 'Change notice',
    ),
    (
      locale: const Locale('ar'),
      title: 'استراحة جارية',
      prompt: 'هل تريد تغيير التنبيه المجدول بالفعل أيضًا؟',
      keep: 'الاحتفاظ بالتنبيه',
      change: 'تغيير التنبيه',
    ),
  ]) {
    testWidgets(
      '${localeCase.locale.languageCode} rest notice prompt is localized',
      (tester) async {
        final activityId = c.focus!.id;
        await tester.runAsync(() async {
          await repo.startInterval(activityId);
          now = now.add(const Duration(seconds: 30));
          await repo.stopInterval(activityId);
          await c.refresh();
        });
        expect(c.focus!.restEndsAt!.isAfter(now), isTrue);
        await showActivityControls(tester, locale: localeCase.locale);
        await tester.ensureVisible(find.byKey(const Key('activity-rest')));
        await tester.tap(find.byKey(const Key('activity-rest')));
        await tester.pumpAndSettle();
        expect(find.byType(ActivityRestDialog), findsOneWidget);
        await tester.enterText(find.byType(TextField).last, '90');
        await tester.tap(find.byType(FilledButton).last);
        await tester.pumpAndSettle();
        expect(find.text(localeCase.title), findsOneWidget);
        expect(find.text(localeCase.prompt), findsOneWidget);
        expect(find.text(localeCase.keep), findsOneWidget);
        expect(find.text(localeCase.change), findsOneWidget);
        await tester.tap(find.text(localeCase.keep));
        await waitFor(tester, () => c.focus!.definition.restSeconds == 90);
        await disposeScreen(tester);
      },
    );
  }

  testWidgets('Arabic chat localizes composer and retains RTL app direction', (
    tester,
  ) async {
    await show(tester, locale: const Locale('ar'));
    expect(find.byTooltip('إرسال'), findsOneWidget);
    expect(find.text('اكتب رسالتك أو أمْلِها…'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('assistant-input'))),
      ),
      TextDirection.rtl,
    );
    await disposeScreen(tester);
  });

  testWidgets(
    'one primary control saves result locally and rest never gates restart',
    (tester) async {
      await show(tester);
      expect(find.text('Iniciar'), findsOneWidget);
      expect(find.text('1/4 series · Descanso'), findsOneWidget);
      expect(find.text('Añadir serie'), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
      now = now.add(const Duration(seconds: 100));
      await tap(tester, const Key('activity-start-stop'));
      await waitFor(tester, () => c.focus!.running != null && !c.busy);
      expect(c.focus!.messages, isEmpty);
      expect(c.focus!.restEndsAt, isNull);
      expect(find.text('Parar'), findsOneWidget);
      expect(find.text('Serie 2 de 4'), findsOneWidget);
      now = now.add(const Duration(seconds: 30));
      await tester.enterText(find.byType(TextField), '60k 13r f');
      await tester.pump();
      expect(find.text('Parar'), findsOneWidget);
      await tap(tester, const Key('activity-start-stop'));
      await waitFor(
        tester,
        () =>
            c.focus!.running == null && !c.busy && c.focus!.messages.isNotEmpty,
      );
      expect(c.focus!.restEndsAt, now.add(const Duration(seconds: 120)));
      expect(c.focus!.messages.single.text, '60k 13r f');
      expect(c.focus!.messages.single.intervalId, c.focus!.intervals.last.id);
      await disposeScreen(tester);
    },
  );

  testWidgets('cycle controls stay separate from completed series', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await repo.finishActivity((await repo.loadActivities()).single.id, now);
      await repo.prepareActivity(
        ActivityDefinition(name: 'Pomodoro', targetCycles: 4, restSeconds: 300),
      );
      await c.refresh();
    });
    await show(tester);
    expect(find.text('Ciclos 0/4'), findsOneWidget);
    await tap(tester, const Key('cycle-increment'));
    await waitFor(tester, () => c.focus!.definition.completedCycles == 1);
    expect(find.text('Ciclos 1/4'), findsOneWidget);
    expect(c.focus!.intervals, isEmpty);
    await disposeScreen(tester);
  });

  testWidgets(
    'small phone hides Iniciar while composing and keeps input visible',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await show(tester);
      await tester.enterText(find.byType(TextField), 'Me molestó el hombro');
      expect(find.byType(ListView), findsOneWidget);
      await tester.pump();
      expect(find.byKey(const Key('activity-start-stop')), findsNothing);
      final input = tester.getRect(find.byType(TextField));
      expect(input.bottom, lessThanOrEqualTo(340));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 350));
      await waitFor(tester, () => !c.busy);
      await disposeScreen(tester);
      expect(
        (await tester.runAsync(() => repo.loadActivities()))!.single.draft,
        'Me molestó el hombro',
      );
    },
  );
  testWidgets(
    'chat focus and pending draft hide Iniciar until communication ends',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await show(tester);
      final start = find.byKey(const Key('activity-start-stop'));
      final input = find.byKey(const Key('assistant-input'));
      expect(start, findsOneWidget);
      await tester.showKeyboard(input);
      await tester.pump();
      expect(start, findsNothing);
      await tester.enterText(input, '60k 13r f');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(start, findsNothing); // Draft still awaiting Send.
      expect(c.focus!.running, isNull);
      await tester.enterText(input, '');
      await tester.pump();
      expect(start, findsNothing); // Focus alone is enough.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(
        start,
        findsOneWidget,
      ); // Back/dismissing the keyboard ends editing.
      expect(c.focus!.running, isNull);
      await disposeScreen(tester);
    },
  );

  testWidgets('dictation hides Iniciar and restores it when cancelled', (
    tester,
  ) async {
    const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => switch (call.method) {
            'initialize' => true,
            'locales' => ['es_ES:Español'],
            'listen' => true,
            'stop' || 'cancel' => null,
            _ => null,
          },
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await show(tester);
    expect(find.text('Iniciar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('assistant-talk')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activity-start-stop')), findsNothing);
    expect(find.byTooltip('Terminar dictado'), findsOneWidget);
    expect(c.focus!.running, isNull);
    await tester.tap(find.byKey(const Key('assistant-talk')));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar'), findsOneWidget);
    expect(c.focus!.running, isNull);
    await tester.pump(
      const Duration(seconds: 3),
    ); // Drain the recognizer final-result timeout.
    await disposeScreen(tester);
  });

  testWidgets(
    'unambiguous shorthand uses local receipt and never calls the LLM',
    (tester) async {
      var calls = 0;
      await const AiSettingsStore().save(
        const AiConfig(
          service: AiService.custom,
          protocol: AiProtocol.chatCompletions,
          baseUrl: 'https://example.test/v1',
          model: 'test',
          apiKey: 'test-key',
        ),
      );
      await show(
        tester,
        client: AiClient(
          transport: (_, __, ___) async {
            calls++;
            throw StateError('No model is needed');
          },
        ),
      );
      await tester.enterText(find.byType(TextField), '60k13rf');
      await tester.runAsync(() => tester.tap(find.byTooltip('Enviar')));
      await waitFor(tester, () => c.focus!.messages.length == 2);
      expect(c.focus!.messages.first.metrics['reps'], 13);
      expect(c.focus!.messages.last.role, 'assistant');
      expect(calls, 0);
      expect(find.textContaining('60 kg × 13 · fallo · fin'), findsOneWidget);
      await disposeScreen(tester);
      await show(tester);
      expect(find.textContaining('60 kg × 13 · fallo · fin'), findsOneWidget);
      expect(calls, 0);
      await disposeScreen(tester);
    },
  );
  testWidgets(
    'opening keyboard preserves composer focus and receives the complete text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await show(tester);
      await tester.showKeyboard(find.byKey(const Key('assistant-input')));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: 'Pr'),
      );
      await tester.pump();
      tester.view.viewInsets = FakeViewPadding(bottom: 300);
      await tester.pump();
      expect(tester.testTextInput.hasAnyClients, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: 'Prueba completa'),
      );
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('assistant-input')))
            .controller!
            .text,
        'Prueba completa',
      );
      expect(tester.takeException(), isNull);
      await disposeScreen(tester);
    },
  );

  testWidgets(
    'delayed LLM interpretation stays with original activity after Terminar',
    (tester) async {
      final answer = Completer<Map<String, dynamic>>();
      var called = false;
      await const AiSettingsStore().save(
        const AiConfig(
          service: AiService.custom,
          protocol: AiProtocol.chatCompletions,
          baseUrl: 'https://example.test/v1',
          model: 'test',
          apiKey: 'test-key',
        ),
      );
      await show(
        tester,
        client: AiClient(
          transport: (_, __, body) async {
            called = true;
            return answer.future;
          },
        ),
      );
      final original = c.focus!.id;
      await tester.enterText(
        find.byType(TextField),
        'Hoy me molestó la rodilla',
      );
      await tester.runAsync(() => tester.tap(find.byTooltip('Enviar')));
      await waitFor(tester, () => called && c.focus!.messages.isNotEmpty);
      await tap(tester, const Key('finish-activity'));
      for (var i = 0; i < 30 && find.text('Guardar').evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => tester.tap(find.text('Guardar')));
      await waitFor(tester, () => c.focus == null && !c.busy);
      await tester.runAsync(() async {
        await repo.prepareActivity(
          ActivityDefinition(name: 'Fútbol', repeated: false, restSeconds: 0),
        );
        await c.refresh();
        answer.complete({
          'choices': [
            {
              'message': {
                'content': 'Conservaré esa observación junto al Pec Fly.',
              },
            },
          ],
        });
      });
      await waitFor(
        tester,
        () =>
            c.activities.singleWhere((a) => a.id == original).messages.length ==
            2,
      );
      expect(c.focus!.definition.name, 'Fútbol');
      expect(c.focus!.messages, isEmpty);
      expect(
        c.activities.singleWhere((a) => a.id == original).messages.first.text,
        'Hoy me molestó la rodilla',
      );
      await disposeScreen(tester);
    },
  );
  testWidgets(
    'LLM prepares flexible activity automatically; only Iniciar starts timing',
    (tester) async {
      await tester.runAsync(() async {
        await repo.finishActivity(c.focus!.id, now);
        await c.refresh();
      });
      await const AiSettingsStore().save(
        const AiConfig(
          service: AiService.custom,
          protocol: AiProtocol.chatCompletions,
          baseUrl: 'https://example.test/v1',
          model: 'test',
          apiKey: 'test-key',
        ),
      );
      await show(
        tester,
        client: AiClient(
          transport:
              (_, __, body) async => {
                'choices': [
                  {
                    'message': {
                      'content':
                          'Prepararemos fútbol.\n```gymia-activity\n{"name":"Fútbol","repeated":false,"restSeconds":0,"fields":[{"key":"goals","label":"Goles","unit":""}],"instructions":"Consultar notas de rodilla anteriores"}\n```',
                    },
                  },
                ],
              },
        ),
      );
      await tester.enterText(find.byType(TextField), 'Voy a jugar fútbol');
      await tester.runAsync(() => tester.tap(find.byTooltip('Enviar')));
      await waitFor(tester, () => c.focus != null && !c.busy);
      expect(c.focus!.definition.name, 'Fútbol');
      expect(c.focus!.definition.fields.single['key'], 'goals');
      expect(c.focus!.intervals, isEmpty);
      await tap(tester, const Key('activity-start-stop'));
      await waitFor(tester, () => c.focus!.running != null && !c.busy);
      expect(find.text('Parar'), findsOneWidget);
      await disposeScreen(tester);
    },
  );
  testWidgets('Enfoque proposals create activities owned by Enfoque', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await repo.finishActivity(c.focus!.id, now);
      await c.refresh();
    });
    await show(
      tester,
      companion: Companion.suggestions.firstWhere((p) => p.id == 'enfoque'),
      client: AiClient(
        transport:
            (_, __, ___) async => {
              'choices': [
                {
                  'message': {
                    'content':
                        'Preparemos un pomodoro.\n```gymia-activity\n{"name":"Pomodoro","repeated":true,"restSeconds":300,"targetCycles":4,"fields":[],"instructions":"Trabajar con pausas"}\n```',
                  },
                },
              ],
            },
      ),
    );
    await tester.enterText(find.byType(TextField), 'Pomodoro de 25 minutos');
    await tester.runAsync(() => tester.tap(find.byTooltip('Enviar')));
    await waitFor(tester, () => c.focus?.definition.name == 'Pomodoro');
    expect(c.focus!.definition.companionId, 'enfoque');
    expect(c.focus!.definition.targetCycles, 4);
    await disposeScreen(tester);
  });
  testWidgets('canceling change keeps prepared activity and its footer', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await repo.finishActivity(c.focus!.id, now);
      await repo.prepareActivity(
        ActivityDefinition(name: 'Chest Press · prueba'),
      );
      await c.refresh();
    });
    await show(tester);
    final id = c.focus!.id;
    await tap(tester, const Key('change-activity'));
    for (
      var i = 0;
      i < 100 && find.byType(ActivityChooser).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.byType(ActivityChooser), findsOneWidget);
    expect(c.focus!.id, id);
    await tester.runAsync(() async {
      Navigator.of(tester.element(find.byType(ActivityChooser))).pop();
    });
    await tester.pumpAndSettle();
    expect(c.focus!.id, id);
    expect(find.byKey(const Key('activity-start-stop')), findsOneWidget);
    await tap(tester, const Key('rename-activity'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('activity-name-input')),
      'Prueba renombrada',
    );
    await tester.runAsync(() => tester.tap(find.text('Guardar nombre')));
    await waitFor(
      tester,
      () => c.focus!.definition.name == 'Prueba renombrada',
    );
    expect(c.focus!.id, id);
    expect(c.focus!.intervals, isEmpty);
    await disposeScreen(tester);
  });

  testWidgets('new preparation does not inherit an expired finished rest', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await repo.finishActivity(c.focus!.id, now);
      now = now.add(const Duration(seconds: 121));
      await repo.prepareActivity(
        ActivityDefinition(name: 'Nueva actividad', restSeconds: 180),
      );
      await c.refresh();
    });
    await show(tester);
    expect(find.text('180s'), findsOneWidget);
    expect(find.text('0:00 · 120s'), findsNothing);
    await disposeScreen(tester);
  });

  testWidgets(
    'idle bar offers a new activity and the prepared panel shows Iniciar',
    (tester) async {
      await tester.runAsync(() async {
        await repo.finishActivity(c.focus!.id, now);
        now = now.add(const Duration(seconds: 121));
        await c.refresh();
      });
      await show(tester);
      expect(find.text('Sin actividad'), findsOneWidget);
      expect(find.text('Registra una cuando quieras'), findsOneWidget);
      expect(find.text('Finalizar día'), findsOneWidget);
      expect(find.byKey(const Key('new-activity')), findsOneWidget);
      expect(find.byKey(const Key('activity-start-stop')), findsNothing);
      expect(find.text('Esperando actividad'), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('new-activity')))
            .onPressed,
        isNotNull,
      );
      await tester.runAsync(() async {
        await repo.prepareActivity(ActivityDefinition(name: 'Chest Press'));
        await c.refresh();
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('new-activity')), findsNothing);
      expect(find.text('Chest Press'), findsOneWidget);
      expect(find.text('Iniciar'), findsOneWidget);
      expect(find.byKey(const Key('finish-activity')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('activity-start-stop')))
            .onPressed,
        isNotNull,
      );
      await disposeScreen(tester);
    },
  );

  testWidgets('a new activity can be created from the idle bar without AI', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.runAsync(() async {
      await repo.finishActivity(c.focus!.id, now);
      now = now.add(const Duration(seconds: 121));
      await c.refresh();
    });
    await show(tester);
    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('new-activity')),
    );
    expect(button.onPressed, isNotNull);
    await tap(tester, const Key('new-activity'));
    // choose() flushes the draft through the real database first.
    for (
      var i = 0;
      i < 100 && find.byType(ActivityChooser).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(ActivityChooser), findsOneWidget);
    await disposeScreen(tester);
  });

  testWidgets(
    'Iniciar is teal, Parar is crimson and a running tramo shows the ring',
    (tester) async {
      await show(tester);
      Color? fill() => tester
          .widget<FilledButton>(find.byKey(const Key('activity-start-stop')))
          .style!
          .backgroundColor!
          .resolve({});
      expect(fill(), brandTeal);
      expect(find.byType(TimerRing), findsNothing);
      now = now.add(const Duration(seconds: 100));
      await tap(tester, const Key('activity-start-stop'));
      await waitFor(tester, () => c.focus!.running != null && !c.busy);
      expect(fill(), brandCrimson);
      final ring = tester.widget<TimerRing>(find.byType(TimerRing));
      expect(
        ring.total,
        isNull,
        reason: 'Pec Fly no tiene duración: cronómetro',
      );
      expect(find.text('Parar'), findsOneWidget);
      await disposeScreen(tester);
    },
  );

  testWidgets('a timed tramo counts down inside the ring', (tester) async {
    await tester.runAsync(() async {
      await repo.finishActivity(c.focus!.id, now);
      await repo.prepareActivity(
        ActivityDefinition(
          name: 'Pomodoro',
          activitySeconds: 1500,
          restSeconds: 300,
        ),
      );
      await c.refresh();
    });
    await show(tester);
    await tap(tester, const Key('activity-start-stop'));
    await waitFor(tester, () => c.focus!.running != null && !c.busy);
    now = now.add(const Duration(minutes: 10, seconds: 55));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final ring = tester.widget<TimerRing>(find.byType(TimerRing));
    expect(ring.total, const Duration(minutes: 25));
    expect(ring.elapsed, greaterThanOrEqualTo(const Duration(minutes: 10)));
    expect(find.text('14:05'), findsOneWidget);
    await disposeScreen(tester);
  });

  testWidgets(
    'local target editor updates objective without deleting progress',
    (tester) async {
      await show(tester);
      await tap(tester, const Key('edit-activity-target'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '2');
      await tester.tap(find.text('Guardar'));
      await waitFor(
        tester,
        () => c.focus!.definition.targetSets == 2 && !c.busy,
      );
      expect(c.focus!.intervals.where((i) => i.endedAt != null), hasLength(1));
      await disposeScreen(tester);
    },
  );

  for (final localeCase in [
    (
      locale: const Locale('en'),
      title: 'Set target',
      label: 'Sets (empty to clear)',
    ),
    (
      locale: const Locale('ar'),
      title: 'العدد المستهدف للمجموعات',
      label: 'المجموعات (اتركه فارغًا للإزالة)',
    ),
  ]) {
    testWidgets(
      '${localeCase.locale.languageCode} local target editor is localized',
      (tester) async {
        await showActivityControls(tester, locale: localeCase.locale);
        await tester.tap(find.byKey(const Key('edit-activity-target')));
        await tester.pumpAndSettle();
        expect(find.text(localeCase.title), findsOneWidget);
        expect(find.text(localeCase.label), findsOneWidget);
        await tester.tap(
          find.text(
            localeCase.locale.languageCode == 'en' ? 'Cancel' : 'إلغاء',
          ),
        );
        await tester.pumpAndSettle();
        await disposeScreen(tester);
      },
    );
  }

  testWidgets('chat target proposal requires confirmation and saves once', (
    tester,
  ) async {
    await show(
      tester,
      client: AiClient(
        transport:
            (_, __, ___) async => {
              'choices': [
                {
                  'message': {
                    'content':
                        'Propongo ajustarlo.\n```trackia-activity-target\n{"targetSets": 3}\n```',
                  },
                },
              ],
            },
      ),
    );
    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Cambia a tres series',
    );
    await tester.runAsync(() => tester.tap(find.byTooltip('Enviar')));
    await waitFor(
      tester,
      () => find.text('Cambiar objetivo de series').evaluate().isNotEmpty,
    );
    expect(c.focus!.definition.targetSets, 4);
    await tester.tap(find.text('Cambiar'));
    await waitFor(tester, () => c.focus!.definition.targetSets == 3 && !c.busy);
    expect(c.focus!.intervals.where((i) => i.endedAt != null), hasLength(1));
    await disposeScreen(tester);
  });

  testWidgets('chat target proposal quotes the revision from the context', (
    tester,
  ) async {
    String? sentRevision;
    await show(
      tester,
      client: AiClient(
        transport: (_, __, body) async {
          final system = [
            for (final m in body['messages'] as List)
              if ((m as Map)['role'] == 'system') m['content'],
          ].join('\n');
          sentRevision =
              RegExp(r'"expectedRevision":"([0-9a-f]{8})"')
                  .firstMatch(system)
                  ?.group(1);
          return {
            'choices': [
              {
                'message': {
                  'content':
                      'Propongo ajustarlo.\n```trackia-activity-target\n{"targetSets": 3, "expectedRevision": "$sentRevision"}\n```',
                },
              },
            ],
          };
        },
      ),
    );
    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Cambia a tres series',
    );
    await tester.runAsync(() => tester.tap(find.byTooltip('Enviar')));
    await waitFor(
      tester,
      () => find.text('Cambiar objetivo de series').evaluate().isNotEmpty,
    );
    expect(sentRevision, activityRevision(c.focus!.definition));
    await tester.tap(find.text('Cambiar'));
    await waitFor(tester, () => c.focus!.definition.targetSets == 3 && !c.busy);
    await disposeScreen(tester);
  });

  testWidgets('chat target proposal with an obsolete revision is rejected', (
    tester,
  ) async {
    await show(
      tester,
      client: AiClient(
        transport:
            (_, __, ___) async => {
              'choices': [
                {
                  'message': {
                    'content':
                        'Propongo ajustarlo.\n```trackia-activity-target\n{"targetSets": 3, "expectedRevision": "00000000"}\n```',
                  },
                },
              ],
            },
      ),
    );
    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Cambia a tres series',
    );
    await tester.runAsync(() => tester.tap(find.byTooltip('Enviar')));
    await waitFor(
      tester,
      () => find.text(staleTargetText).evaluate().isNotEmpty,
    );
    expect(find.text('Cambiar objetivo de series'), findsNothing);
    expect(c.focus!.definition.targetSets, 4);
    await disposeScreen(tester);
  });

  for (final localeCase in [
    (
      locale: const Locale('en'),
      title: 'Change set target',
      prompt: 'Do you want to set the target to 3 sets?',
      cancel: 'Cancel',
      confirm: 'Change',
    ),
    (
      locale: const Locale('ar'),
      title: 'تغيير العدد المستهدف للمجموعات',
      prompt: 'هل تريد تحديد الهدف بـ 3 مجموعات؟',
      cancel: 'إلغاء',
      confirm: 'تغيير',
    ),
  ]) {
    testWidgets(
      '${localeCase.locale.languageCode} chat target confirmation is localized',
      (tester) async {
        await show(
          tester,
          locale: localeCase.locale,
          client: AiClient(
            transport:
                (_, __, ___) async => {
                  'choices': [
                    {
                      'message': {
                        'content':
                            '```trackia-activity-target\n{"targetSets":3}\n```',
                      },
                    },
                  ],
                },
          ),
        );
        await tester.enterText(
          find.byKey(const Key('assistant-input')),
          'Change the set target',
        );
        await tester.tap(
          find.byTooltip(
            localeCase.locale.languageCode == 'en' ? 'Send' : 'إرسال',
          ),
        );
        await waitFor(
          tester,
          () => find.text(localeCase.title).evaluate().isNotEmpty,
        );
        expect(find.text(localeCase.prompt), findsOneWidget);
        expect(find.text(localeCase.cancel), findsOneWidget);
        expect(find.text(localeCase.confirm), findsOneWidget);
        await tester.tap(find.text(localeCase.cancel));
        await waitFor(tester, () => !c.busy);
        expect(c.focus!.definition.targetSets, 4);
        await disposeScreen(tester);
      },
    );
  }

  testWidgets('stale chat target is rejected after a local edit', (
    tester,
  ) async {
    final reply = Completer<Map<String, dynamic>>();
    var requested = false;
    await show(
      tester,
      client: AiClient(
        transport: (_, __, ___) async {
          requested = true;
          return reply.future;
        },
      ),
    );
    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Cambia a tres series',
    );
    await tester.runAsync(() => tester.tap(find.byTooltip('Enviar')));
    await waitFor(tester, () => requested);
    await tester.runAsync(() async {
      await repo.renameActivity(c.focus!.id, 'Otro nombre');
      await c.refresh();
      reply.complete({
        'choices': [
          {
            'message': {
              'content': '```trackia-activity-target\n{"targetSets":3}\n```',
            },
          },
        ],
      });
    });
    await waitFor(
      tester,
      () => find.text('Cambiar objetivo de series').evaluate().isNotEmpty,
    );
    await tester.tap(find.text('Cambiar'));
    await waitFor(
      tester,
      () =>
          find
              .textContaining('No se cambió el objetivo. La actividad')
              .evaluate()
              .isNotEmpty,
    );
    expect(c.focus!.definition.targetSets, 4);
    expect(c.focus!.definition.name, 'Otro nombre');
    await disposeScreen(tester);
  });

  for (final otherKind in [
    'goal',
    'achievement',
    'reminder-copy',
    'archive',
    'recall',
  ]) {
    testWidgets('chat rejects target mixed with $otherKind', (tester) async {
      var calls = 0;
      await show(
        tester,
        client: AiClient(
          transport: (_, __, ___) async {
            calls++;
            return {
              'choices': [
                {
                  'message': {
                    'content':
                        '```trackia-activity-target\n{"targetSets":3}\n```\n```trackia-$otherKind\n{}\n```',
                  },
                },
              ],
            };
          },
        ),
      );
      await tester.enterText(
        find.byKey(const Key('assistant-input')),
        'Cambia a tres series',
      );
      await tester.runAsync(() => tester.tap(find.byTooltip('Enviar')));
      await waitFor(
        tester,
        () => !c.busy && calls > 0 && c.focus!.messages.length >= 2,
      );
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(find.text('Cambiar objetivo de series'), findsNothing);
      expect(c.focus!.definition.targetSets, 4);
      expect(calls, 1);
      await disposeScreen(tester);
    });
  }

  testWidgets('chat rejects a series target for continuous activity', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await repo.finishActivity(c.focus!.id, now);
      await repo.prepareActivity(
        ActivityDefinition(name: 'Correr', repeated: false),
      );
      await c.refresh();
    });
    await show(
      tester,
      client: AiClient(
        transport:
            (_, __, ___) async => {
              'choices': [
                {
                  'message': {
                    'content':
                        '```trackia-activity-target\n{"targetSets":3}\n```',
                  },
                },
              ],
            },
      ),
    );
    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Cambia a tres series',
    );
    await tester.runAsync(() => tester.tap(find.byTooltip('Enviar')));
    await waitFor(tester, () => !c.busy && c.focus!.messages.length >= 2);
    expect(find.text('Cambiar objetivo de series'), findsNothing);
    expect(c.focus!.definition.targetSets, isNull);
    await disposeScreen(tester);
  });

  for (final updateNotice in [false, true]) {
    testWidgets(
      'rest edit ${updateNotice ? 'updates' : 'preserves'} the active notice after confirmation',
      (tester) async {
        final originalEnd = c.focus!.restEndsAt!;
        await show(tester);
        await tap(tester, const Key('activity-rest'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, '180');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        await waitFor(
          tester,
          () => find.text('Descanso en curso').evaluate().isNotEmpty,
        );
        await tester.tap(
          find.text(updateNotice ? 'Cambiar aviso' : 'Conservar aviso'),
        );
        await tester.pump();
        await waitFor(
          tester,
          () => c.focus!.definition.restSeconds == 180 && !c.busy,
        );
        expect(
          c.focus!.restEndsAt,
          originalEnd.add(Duration(seconds: updateNotice ? 60 : 0)),
        );
        expect(c.focus!.intervals.single.restSeconds, 120);
        await disposeScreen(tester);
      },
    );
  }

  testWidgets('with notices off the panel offers to turn them on', (
    tester,
  ) async {
    var enabled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: Scaffold(
          body: ActivityFocusControls(
            controller: c,
            flushInput: () async {},
            noticesOff: true,
            onEnableNotices: () => enabled = true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Avisos desactivados'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notices-enable')));
    expect(enabled, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  group('choosing or creating an activity', () {
    Future<void> openChooser(WidgetTester tester) async {
      await tester.runAsync(() async {
        await repo.finishActivity(c.focus!.id, now);
        now = now.add(const Duration(seconds: 121));
        await c.refresh();
      });
      await show(tester);
      await tap(tester, const Key('new-activity'));
      for (
        var i = 0;
        i < 100 && find.byType(ActivityChooser).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // The builder sits on top of the chooser sheet; calling the real handlers
    // avoids hit-testing through stacked routes.
    void pressSubmit(WidgetTester tester) {
      tester
          .widget<FilledButton>(find.byKey(const Key('builder-submit')))
          .onPressed!();
    }

    void toggleSave(WidgetTester tester, bool value) {
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('builder-save')))
          .onChanged!(value);
    }

    Future<void> revealBuilder(WidgetTester tester, String key) async {
      await tester.scrollUntilVisible(
        find.byKey(Key(key)),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }

    Future<void> waitUntil(WidgetTester tester, bool Function() done) async {
      for (var i = 0; i < 200 && !done(); i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(done(), isTrue);
    }

    testWidgets(
      'the chooser lists your saved activities of this companion first',
      (tester) async {
        await tester.runAsync(() async {
          await repo.templates.save(
            companionId: 'gymbro',
            definition: ActivityDefinition(
              name: 'Estiramientos',
              repeated: false,
              restSeconds: 0,
            ),
          );
          await repo.templates.save(
            companionId: 'calma',
            definition: ActivityDefinition(
              name: 'Respirar',
              repeated: false,
              restSeconds: 0,
              companionId: 'calma',
            ),
          );
        });
        await openChooser(tester);
        expect(find.text('Tus actividades'), findsOneWidget);
        expect(find.text('Estiramientos'), findsOneWidget);
        expect(find.text('Respirar'), findsNothing);
      },
    );

    testWidgets('choosing a saved activity prepares it', (tester) async {
      await tester.runAsync(
        () => repo.templates.save(
          companionId: 'gymbro',
          definition: ActivityDefinition(
            name: 'Estiramientos',
            repeated: false,
            restSeconds: 0,
          ),
        ),
      );
      await openChooser(tester);
      await tester.tap(find.text('Estiramientos'));
      await waitUntil(
        tester,
        () => c.focus?.definition.name == 'Estiramientos',
      );
      expect(c.focus!.intervals, isEmpty);
      await disposeScreen(tester);
    });

    testWidgets('Nueva actividad opens the builder and preparing saves it', (
      tester,
    ) async {
      await openChooser(tester);
      await tester.tap(find.text('Nueva actividad').last);
      await tester.pumpAndSettle();
      expect(find.byType(ActivityBuilder), findsOneWidget);
      await tester.enterText(find.byKey(const Key('builder-name')), 'Leer');
      await revealBuilder(tester, 'builder-submit');
      pressSubmit(tester);
      await waitUntil(tester, () => c.focus?.definition.name == 'Leer');
      expect(c.focus!.definition.companionId, 'gymbro');
      final saved =
          (await tester.runAsync(
            () => repo.templates.list(companionId: 'gymbro'),
          ))!;
      expect(saved.map((t) => t.definition.name), ['Leer']);
      expect(saved.single.instant, isFalse);
      await disposeScreen(tester);
    });

    testWidgets(
      'unchecking «Guardar en tus actividades» keeps it out of the list',
      (tester) async {
        await openChooser(tester);
        await tester.tap(find.text('Nueva actividad').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('builder-name')),
          'Solo hoy',
        );
        await revealBuilder(tester, 'builder-save');
        toggleSave(tester, false);
        await tester.pump();
        await revealBuilder(tester, 'builder-submit');
        pressSubmit(tester);
        await waitUntil(tester, () => c.focus?.definition.name == 'Solo hoy');
        final saved =
            (await tester.runAsync(
              () => repo.templates.list(companionId: 'gymbro'),
            ))!;
        expect(saved, isEmpty);
        await disposeScreen(tester);
      },
    );

    testWidgets('leaving the builder with Atrás changes nothing', (
      tester,
    ) async {
      await openChooser(tester);
      await tester.tap(find.text('Nueva actividad').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(c.focus, isNull);
      await disposeScreen(tester);
    });
  });

  group('segment names', () {
    Future<void> prepareAndStart(
      WidgetTester tester,
      ActivityDefinition definition,
    ) async {
      await tester.runAsync(() async {
        await repo.finishActivity(c.focus!.id, now);
        now = now.add(const Duration(seconds: 121));
        await repo.prepareActivity(definition);
        await c.refresh();
      });
      await show(tester);
      await tap(tester, const Key('activity-start-stop'));
      await waitFor(tester, () => c.focus!.running != null && !c.busy);
    }

    testWidgets('a custom name is used while running and while resting', (
      tester,
    ) async {
      await prepareAndStart(
        tester,
        ActivityDefinition(
          name: 'Pomodoro',
          targetSets: 4,
          activitySeconds: 1500,
          segmentSingular: 'pomodoro',
          segmentPlural: 'pomodoros',
        ),
      );
      expect(find.text('Pomodoro 1 de 4'), findsOneWidget);
      expect(find.text('Serie 1 de 4'), findsNothing);
      await tap(tester, const Key('activity-start-stop'));
      await waitFor(tester, () => c.focus!.running == null && !c.busy);
      expect(find.text('1/4 pomodoros · Descanso'), findsOneWidget);
      await disposeScreen(tester);
    });

    testWidgets('without names GymBro keeps «serie» and the others «tramo»', (
      tester,
    ) async {
      await prepareAndStart(
        tester,
        ActivityDefinition(name: 'Fuerza', targetSets: 3),
      );
      expect(find.text('Serie 1 de 3'), findsOneWidget);
      await disposeScreen(tester);
    });

    testWidgets('another companion without names says «tramo»', (tester) async {
      await tester.runAsync(() async {
        await repo.finishActivity(c.focus!.id, now);
        await repo.prepareActivity(
          ActivityDefinition(
            name: 'Pomodoro',
            targetSets: 2,
            companionId: 'enfoque',
          ),
        );
        await c.refresh();
      });
      await show(tester, companion: Companion.suggestions[1]);
      await tap(tester, const Key('activity-start-stop'));
      await waitFor(tester, () => c.focus!.running != null && !c.busy);
      expect(find.text('Tramo 1 de 2'), findsOneWidget);
      await disposeScreen(tester);
    });
  });

  group('quick counters', () {
    final reading = ActivityDefinition(
      name: 'Leer',
      repeated: false,
      restSeconds: 0,
      fields: const [
        {'key': 'pages', 'label': 'Páginas', 'unit': 'págs', 'type': 'number'},
        {
          'key': 'best',
          'label': 'Mejor marca',
          'unit': '',
          'type': 'number',
          'aggregate': 'max',
        },
        {'key': 'book', 'label': 'Libro', 'unit': '', 'type': 'text'},
        {'key': 'goals', 'label': 'Goles', 'unit': '', 'type': 'number'},
      ],
    );

    Future<void> prepare(WidgetTester tester, {bool start = true}) async {
      await tester.runAsync(() async {
        await repo.finishActivity(c.focus!.id, now);
        now = now.add(const Duration(seconds: 121));
        await repo.prepareActivity(reading);
        await c.refresh();
      });
      await show(tester);
      if (start) {
        await tap(tester, const Key('activity-start-stop'));
        await waitFor(tester, () => c.focus!.running != null && !c.busy);
      }
    }

    Future<void> press(WidgetTester tester, String key, [int times = 1]) async {
      for (var i = 0; i < times; i++) {
        tester.widget<IconButton>(find.byKey(Key(key))).onPressed!();
        await tester.pump();
      }
    }

    Future<void> waitMessages(WidgetTester tester, int count) async {
      await waitFor(tester, () => c.focus!.messages.length >= count && !c.busy);
    }

    testWidgets(
      'only numeric fields that add up get a counter, and only once started',
      (tester) async {
        await prepare(tester, start: false);
        expect(find.byKey(const Key('counter-pages')), findsNothing);
        await tap(tester, const Key('activity-start-stop'));
        await waitFor(tester, () => c.focus!.running != null && !c.busy);
        expect(find.byKey(const Key('counter-pages')), findsOneWidget);
        expect(find.byKey(const Key('counter-goals')), findsOneWidget);
        expect(
          find.byKey(const Key('counter-best')),
          findsNothing,
          reason: 'mejor marca no suma',
        );
        expect(
          find.byKey(const Key('counter-book')),
          findsNothing,
          reason: 'texto',
        );
        await disposeScreen(tester);
      },
    );

    testWidgets('18 taps become one message when the tramo stops', (
      tester,
    ) async {
      await prepare(tester);
      await press(tester, 'counter-inc-pages', 18);
      expect(
        tester.widget<Text>(find.byKey(const Key('counter-pages'))).data,
        '18',
      );
      expect(c.focus!.messages, isEmpty, reason: 'aún no se guarda');
      await tap(tester, const Key('activity-start-stop'));
      await waitMessages(tester, 1);
      final m = c.focus!.messages.single;
      expect(m.text, 'Páginas: +18');
      expect(m.metrics, {'pages': 18});
      expect(m.intervalId, c.focus!.intervals.last.id);
      expect(m.role, 'user');
      await disposeScreen(tester);
    });

    testWidgets(
      'three seconds without taps saves the burst; the next burst is separate',
      (tester) async {
        await prepare(tester);
        await press(tester, 'counter-inc-pages', 5);
        await tester.pump(const Duration(seconds: 3));
        await waitMessages(tester, 1);
        expect(c.focus!.messages.single.metrics, {'pages': 5});
        expect(
          tester.widget<Text>(find.byKey(const Key('counter-pages'))).data,
          '5',
          reason: 'se muestra lo ya guardado más lo pendiente',
        );
        await press(tester, 'counter-inc-pages', 3);
        expect(
          tester.widget<Text>(find.byKey(const Key('counter-pages'))).data,
          '8',
        );
        await tester.pump(const Duration(seconds: 3));
        await waitMessages(tester, 2);
        final totals =
            c.focus!.messages.map((m) => m.metrics['pages']).toList();
        expect(totals, [
          5,
          3,
        ], reason: 'cada mensaje es una cantidad, no un total');
        await disposeScreen(tester);
      },
    );

    testWidgets('taps keep postponing the save', (tester) async {
      await prepare(tester);
      await press(tester, 'counter-inc-pages');
      await tester.pump(const Duration(seconds: 2));
      await press(tester, 'counter-inc-pages');
      await tester.pump(const Duration(seconds: 2));
      expect(c.focus!.messages, isEmpty);
      await tester.pump(const Duration(seconds: 2));
      await waitMessages(tester, 1);
      expect(c.focus!.messages.single.metrics, {'pages': 2});
      await disposeScreen(tester);
    });

    testWidgets('minus only takes back pending taps', (tester) async {
      await prepare(tester);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('counter-dec-pages')))
            .onPressed,
        isNull,
      );
      await press(tester, 'counter-inc-pages', 3);
      await press(tester, 'counter-dec-pages');
      expect(
        tester.widget<Text>(find.byKey(const Key('counter-pages'))).data,
        '2',
      );
      await tester.pump(const Duration(seconds: 3));
      await waitMessages(tester, 1);
      expect(c.focus!.messages.single.metrics, {'pages': 2});
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('counter-dec-pages')))
            .onPressed,
        isNull,
      );
      await disposeScreen(tester);
    });

    testWidgets('several counters in one burst share a single message', (
      tester,
    ) async {
      await prepare(tester);
      await press(tester, 'counter-inc-pages', 4);
      await press(tester, 'counter-inc-goals', 2);
      await tap(tester, const Key('activity-start-stop'));
      await waitMessages(tester, 1);
      expect(c.focus!.messages, hasLength(1));
      expect(c.focus!.messages.single.metrics, {'pages': 4, 'goals': 2});
      expect(c.focus!.messages.single.text, 'Páginas: +4 · Goles: +2');
      await disposeScreen(tester);
    });

    testWidgets('counters also work during the rest and without AI', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});
      await prepare(tester);
      await tap(tester, const Key('activity-start-stop'));
      await waitFor(tester, () => c.focus!.running == null && !c.busy);
      await press(tester, 'counter-inc-pages', 2);
      await tester.pump(const Duration(seconds: 3));
      await waitMessages(tester, 1);
      expect(c.focus!.messages.single.metrics, {'pages': 2});
      expect(c.focus!.messages.single.intervalId, c.focus!.intervals.last.id);
      await disposeScreen(tester);
    });

    testWidgets('Terminar saves what is still pending', (tester) async {
      await prepare(tester);
      await tap(tester, const Key('activity-start-stop'));
      await waitFor(tester, () => c.focus!.running == null && !c.busy);
      await press(tester, 'counter-inc-pages', 6);
      await tap(tester, const Key('finish-activity'));
      for (var i = 0; i < 40 && find.text('Guardar').evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      final saved = (await tester.runAsync(
        () => repo.loadActivities(),
      ))!.expand((a) => a.messages).where((m) => m.metrics['pages'] == 6);
      expect(saved, hasLength(1));
      await disposeScreen(tester);
    });
  });
}
