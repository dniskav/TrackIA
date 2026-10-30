import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/application/companion_creation.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/ui/companion_creator.dart';
import 'package:trackia/ui/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/real_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late CompanionStore store;
  late AiAvailability availability;
  late List<String> replies;
  late List<Map<String, dynamic>> requests;
  Companion? created;
  var openedAiSettings = 0;
  final now = DateTime(2026, 10, 29, 9);
  const config = AiConfig(
    service: AiService.custom,
    protocol: AiProtocol.chatCompletions,
    baseUrl: 'https://example.test/v1',
    model: 'test',
    apiKey: 'fake-key',
  );

  String proposal(Map<String, Object?> json) =>
      'Te propongo esto.\n```trackia-companion\n${jsonEncode(json)}\n```';

  final reading = <String, Object?>{
    'name': 'Lectura',
    'description': 'Leer cada día',
    'icon': 'book',
    'color': 'violet',
    'mode': 'game',
    'activity': {
      'name': 'Leer',
      'repeated': false,
      'restSeconds': 0,
      'fields': [
        {
          'key': 'paginas',
          'label': 'Páginas',
          'unit': '',
          'type': 'number',
          'aggregate': 'sum',
        },
      ],
    },
    'goal': {
      'metric': {
        'source': 'field',
        'field': 'paginas',
        'aggregate': 'sum',
        'per': 'day',
      },
      'period': 'day',
      'target': 20,
      'minimum': 5,
    },
    'reminder': {
      'days': ['mon', 'tue', 'wed', 'thu', 'fri'],
      'start': '21:00',
      'end': '23:00',
      'lastCall': '22:30',
      'tone': 'cheer',
    },
  };

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    created = null;
    openedAiSettings = 0;
    replies = [];
    requests = [];
    dir = await Directory.systemTemp.createTemp('trackia-creator-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    store = const CompanionStore(profileId: 'local');
    availability = AiAvailability(
      catalog: AiModelCatalog(
        transport: (_, __) async => {
          'data': [
            {'id': 'test'},
          ],
        },
      ),
    );
  });
  tearDown(() async {
    availability.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<void> connectAi(WidgetTester tester) async {
    await tester.runAsync(() async {
      await const AiSettingsStore().save(config);
      await const AiSettingsStore().markVerified(config);
      await availability.check(acceptRecentVerification: true);
    });
  }

  AiClient client() => AiClient(
    transport: (_, __, body) async {
      requests.add(body);
      return {
        'choices': [
          {
            'message': {'content': replies.removeAt(0)},
          },
        ],
      };
    },
  );

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () async {
              created = await Navigator.of(context).push<Companion>(
                MaterialPageRoute(
                  builder: (_) => CompanionCreatorScreen(
                    store: store,
                    progress: repo.progress,
                    templates: repo.templates,
                    availability: availability,
                    aiStore: const AiSettingsStore(),
                    client: client(),
                    onOpenAiSettings: () => openedAiSettings++,
                  ),
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await realIo(tester, 6);
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> say(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('creator-input')), text);
    await tester.tap(find.byKey(const Key('creator-send')));
    await realIo(tester, 12);
  }

  Future<void> goAssisted(WidgetTester tester) async {
    await connectAi(tester);
    await open(tester);
    await tester.tap(find.byKey(const Key('creator-ai')));
    await realIo(tester, 6);
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> nothingCreated(WidgetTester tester) async {
    expect(created, isNull);
    expect(
      (await tester.runAsync(() => store.load()))!.map((c) => c.id),
      isNot(contains('lectura')),
    );
    expect(
      await tester.runAsync(() => repo.progress.reminderFor('lectura')),
      isNull,
    );
    expect(
      await tester.runAsync(() => repo.progress.activeGoal('lectura')),
      isNull,
    );
    expect(
      await tester.runAsync(() => repo.templates.list(companionId: 'lectura')),
      isEmpty,
    );
  }

  group('the choice', () {
    testWidgets('without a verified AI it explains and points to Ajustes', (
      tester,
    ) async {
      await open(tester);
      expect(
        find.text('Necesitas conectar y verificar un proveedor de IA.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('creator-ai')));
      await tester.pump();
      // The AI path stays closed.
      expect(find.byKey(const Key('creator-input')), findsNothing);
      await tester.tap(find.byKey(const Key('creator-open-ai-settings')));
      expect(openedAiSettings, 1);
      expect(find.byKey(const Key('creator-manual')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with a verified AI both ways are open', (tester) async {
      await connectAi(tester);
      await open(tester);
      expect(find.byKey(const Key('creator-open-ai-settings')), findsNothing);
      await tester.tap(find.byKey(const Key('creator-ai')));
      await realIo(tester, 4);
      expect(find.byKey(const Key('creator-greeting')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('with the AI', () {
    testWidgets('a valid block shows the sheet and Crear creates everything', (
      tester,
    ) async {
      replies = [proposal(reading)];
      await goAssisted(tester);
      await say(tester, 'Quiero leer cada día');

      // The conversation never sends the greeting, and the AI gets the script.
      expect((requests.single['messages'] as List).first['role'], 'system');
      expect(
        (requests.single['messages'] as List)[1]['content'],
        'Quiero leer cada día',
      );
      expect(
        requests.single['messages'][0]['content'],
        contains('Haz como máximo tres preguntas breves'),
      );
      expect(find.text('Te propongo esto.'), findsOneWidget);
      expect(find.textContaining('trackia-companion'), findsNothing);

      expect(find.byKey(const Key('creator-preview')), findsOneWidget);
      expect(find.text('Lectura'), findsWidgets);
      expect(find.text('Qué anotas: Leer (Páginas)'), findsOneWidget);
      expect(find.text('Meta: 20 páginas al día (mínimo 5)'), findsOneWidget);
      expect(find.text('Nivel: Juego completo'), findsOneWidget);
      expect(
        find.text(
          'Aviso: De lunes a viernes, 21:00–23:00 · última llamada 22:30',
        ),
        findsOneWidget,
      );
      await nothingCreated(tester); // nothing is saved until the user decides

      await tester.tap(find.byKey(const Key('creator-create')));
      await realIo(tester, 40);
      expect(created?.id, 'lectura');
      final progress = repo.progress;
      expect(
        (await tester.runAsync(() => progress.settings('lectura')))!.mode,
        'game',
      );
      expect(
        (await tester.runAsync(() => progress.activeGoal('lectura')))!.target,
        20,
      );
      expect(
        (await tester.runAsync(() => progress.reminderFor('lectura')))!.tone,
        'cheer',
      );
      expect(
        (await tester.runAsync(
          () => repo.templates.list(companionId: 'lectura'),
        ))!.single.definition.name,
        'Leer',
      );
      expect(
        (await tester.runAsync(() => progress.achievements('lectura')))!,
        isNotEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an invalid block creates nothing and says so', (tester) async {
      replies = [
        proposal({...reading, 'origin': 'assistant'}), // a key it may not bring
      ];
      await goAssisted(tester);
      await say(tester, 'Hazlo');
      expect(find.text('Te propongo esto.'), findsOneWidget);
      expect(
        find.text('La propuesta no es válida y no se aplicó.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('creator-preview')), findsNothing);
      await nothingCreated(tester);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('two blocks are both ignored', (tester) async {
      replies = [
        '${proposal(reading)}\n${proposal({...reading, 'name': 'Otra'})}',
      ];
      await goAssisted(tester);
      await say(tester, 'Hazlo');
      expect(find.byKey(const Key('creator-preview')), findsNothing);
      expect(
        find.text('La propuesta no es válida y no se aplicó.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a reply without a block is just conversation', (tester) async {
      replies = ['¿Qué quieres seguir?'];
      await goAssisted(tester);
      await say(tester, 'Hola');
      expect(find.text('¿Qué quieres seguir?'), findsOneWidget);
      expect(find.byKey(const Key('creator-preview')), findsNothing);
      expect(find.byKey(const Key('creator-ai-error')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Descartar closes the sheet and the talk goes on', (
      tester,
    ) async {
      replies = [proposal(reading), '¿Algo más?'];
      await goAssisted(tester);
      await say(tester, 'Hazlo');
      await tester.tap(find.byKey(const Key('creator-discard')));
      await tester.pump();
      expect(find.byKey(const Key('creator-preview')), findsNothing);
      await say(tester, 'Mejor otra cosa');
      // system, user, assistant, user: the greeting is never sent.
      expect(requests.last['messages'].length, 4);
      await nothingCreated(tester);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Editar opens the builder filled and keeps the changes', (
      tester,
    ) async {
      replies = [proposal(reading)];
      await goAssisted(tester);
      await say(tester, 'Hazlo');
      await tester.tap(find.byKey(const Key('creator-edit')));
      await realIo(tester, 4);
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('builder-name')))
            .controller!
            .text,
        'Lectura',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('builder-description')))
            .controller!
            .text,
        'Leer cada día',
      );
      expect(
        tester
            .widget<RadioListTile<String>>(find.byKey(const Key('level-game')))
            .value,
        'game',
      );
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('builder-remind')))
            .value,
        isTrue,
      );
      expect(find.byKey(const Key('builder-activity')), findsOneWidget);
      expect(find.byKey(const Key('builder-goal')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('builder-name')),
        'Mis lecturas',
      );
      await tester.ensureVisible(find.byKey(const Key('level-goals')));
      await tester.tap(find.byKey(const Key('level-goals')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('builder-remove-goal')));
      await tester.tap(find.byKey(const Key('builder-remove-goal')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('builder-submit')));
      await tester.tap(find.byKey(const Key('builder-submit')));
      await realIo(tester, 4);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('creator-preview')), findsOneWidget);
      expect(find.text('Mis lecturas'), findsWidgets);
      expect(find.text('Nivel: Metas y rachas'), findsOneWidget);
      expect(find.text('Meta: sin meta'), findsOneWidget);
      await tester.tap(find.byKey(const Key('creator-create')));
      await realIo(tester, 40);
      expect(created?.name, 'Mis lecturas');
      expect(created?.id, 'mis-lecturas');
      final settings = (await tester.runAsync(
        () => repo.progress.settings('mis-lecturas'),
      ))!;
      expect([settings.mode, settings.achievementsEnabled], ['game', false]);
      expect(
        await tester.runAsync(() => repo.progress.activeGoal('mis-lecturas')),
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('each level is shown with its own words', (tester) async {
      for (final entry in {
        'reminder': 'Solo recordatorio',
        'goals': 'Metas y rachas',
        'game': 'Juego completo',
      }.entries) {
        replies = [
          proposal({'name': 'X', 'mode': entry.key}),
        ];
        requests.clear();
        await goAssisted(tester);
        await say(tester, 'Hola');
        expect(
          find.text('Nivel: ${entry.value}'),
          findsOneWidget,
          reason: entry.key,
        );
        await tester.pumpWidget(const SizedBox());
        await realIo(tester, 2);
      }
    });

    testWidgets('the conversation is not saved in any chat', (tester) async {
      replies = [proposal(reading)];
      await goAssisted(tester);
      await say(tester, 'Hazlo');
      expect(
        await tester.runAsync(() => repo.chats.loadActive('gymbro')),
        isNull,
      );
      expect(
        await tester.runAsync(() => repo.chats.loadActive('lectura')),
        isNull,
      );
      expect(
        await tester.runAsync(() => const FlutterSecureStorage().readAll()),
        isNot(contains('trackia.ai.chat.v1')),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a failure while creating undoes everything and says so', (
      tester,
    ) async {
      replies = [proposal(reading)];
      await connectAi(tester);
      final creation =
          CompanionCreation(
              store: store,
              progress: repo.progress,
              templates: repo.templates,
            )
            ..debugStep = (s) {
              if (s == 'reminder') throw StateError('boom');
            };
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: gymTheme,
          home: CompanionAssistedScreen(
            creation: creation,
            aiStore: const AiSettingsStore(),
            client: client(),
          ),
        ),
      );
      await say(tester, 'Hazlo');
      await tester.tap(find.byKey(const Key('creator-create')));
      await realIo(tester, 40);
      expect(
        find.text('No se pudo crear el acompañante. No se guardó nada.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('creator-preview')), findsOneWidget);
      await nothingCreated(tester);
      expect(
        await tester.runAsync(() => repo.progress.achievements('lectura')),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('by hand', () {
    Future<void> goManual(WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('creator-manual')));
      await realIo(tester, 4);
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('a companion with its level and reminder is created', (
      tester,
    ) async {
      await goManual(tester);
      await tester.enterText(find.byKey(const Key('builder-name')), 'Agua');
      await tester.enterText(
        find.byKey(const Key('builder-description')),
        'Beber más',
      );
      await tester.tap(find.byKey(const Key('builder-icon-water')));
      await tester.tap(find.byKey(const Key('builder-color-green')));
      await tester.ensureVisible(find.byKey(const Key('level-goals')));
      await tester.tap(find.byKey(const Key('level-goals')));
      await tester.ensureVisible(find.byKey(const Key('builder-remind')));
      await tester.tap(find.byKey(const Key('builder-remind')));
      await tester.pump();
      await tester.tap(find.text('Motivador'));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('builder-submit')));
      await tester.tap(find.byKey(const Key('builder-submit')));
      await realIo(tester, 40);

      expect(created?.id, 'agua');
      expect(
        [created?.icon, created?.color, created?.description],
        ['water', 'green', 'Beber más'],
      );
      final settings = (await tester.runAsync(
        () => repo.progress.settings('agua'),
      ))!;
      expect([settings.mode, settings.achievementsEnabled], ['game', false]);
      final reminder = (await tester.runAsync(
        () => repo.progress.reminderFor('agua'),
      ))!;
      expect(
        [
          reminder.days,
          reminder.windowStartMin,
          reminder.windowEndMin,
          reminder.tone,
        ],
        [127, 1200, 1320, 'cheer'],
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'the lowest level without a reminder saves only the companion',
      (tester) async {
        await goManual(tester);
        await tester.enterText(
          find.byKey(const Key('builder-name')),
          'Diario 2',
        );
        await tester.ensureVisible(find.byKey(const Key('builder-submit')));
        await tester.tap(find.byKey(const Key('builder-submit')));
        await realIo(tester, 40);
        expect(created?.id, 'diario-2');
        expect(
          (await tester.runAsync(
            () => repo.progress.settings('diario-2'),
          ))!.mode,
          'reminder',
        );
        expect(
          await tester.runAsync(() => repo.progress.reminderFor('diario-2')),
          isNull,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('an empty name or no days is refused in Spanish', (
      tester,
    ) async {
      await goManual(tester);
      await tester.ensureVisible(find.byKey(const Key('builder-submit')));
      await tester.tap(find.byKey(const Key('builder-submit')));
      await tester.pump();
      expect(
        find.text('Escribe un nombre de entre 1 y 40 caracteres.'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('builder-name')), 'Algo');
      await tester.ensureVisible(find.byKey(const Key('builder-remind')));
      await tester.tap(find.byKey(const Key('builder-remind')));
      await tester.pump();
      for (var i = 0; i < 7; i++) {
        await tester.ensureVisible(find.byKey(Key('builder-day-$i')));
        await tester.tap(find.byKey(Key('builder-day-$i')));
      }
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('builder-submit')));
      await tester.tap(find.byKey(const Key('builder-submit')));
      await tester.pump();
      expect(find.text('Elige al menos un día de la semana.'), findsOneWidget);
      expect(created, isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
