import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/application/companion_creation.dart';
import 'package:trackia/application/sheet_automation.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/profile_store.dart';
import 'package:trackia/data/sheet_context_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/sheet_context.dart';
import 'package:trackia/domain/user_profile.dart';
import 'package:trackia/ui/assistant_chat.dart';
import 'package:trackia/ui/companion_settings.dart';

import 'helpers/real_io.dart';
import 'sheet_sync_test.dart' show syncSnapshot;

/// T063: un acompañante importado pide confirmación antes de editar la hoja
/// o preparar una actividad; uno propio actúa como siempre.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  const identity = UserProfile(
    subject: 'destination',
    email: 'dest@example.test',
  );
  const config = AiConfig(
    service: AiService.custom,
    protocol: AiProtocol.chatCompletions,
    baseUrl: 'https://example.test/v1',
    model: 'test',
    apiKey: 'fake-key',
  );
  const sheetEdit =
      '```trackia-sheet-edit\n{"summary":"Corregir carga","writes":[{"cell":"C2","expected":"55","value":60}]}\n```';
  const activityBlock =
      '```trackia-activity\n{"name":"Press banca","repeated":true,"restSeconds":75,"targetSets":4,"fields":[]}\n```';

  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController controller;
  late Map<String, dynamic> snapshot;
  final calls = <MethodCall>[];
  var answer = '';

  Companion companion(String origin) => Companion(
    id: 'gymbro',
    name: 'GymBro',
    description: '',
    prompt: 'Estilo cercano',
    origin: origin,
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'trackia.sheet.destination.v1': jsonEncode(identity.toJson()),
    });
    await ProfileStore.instance.load();
    await const AiSettingsStore().save(config);
    await const AiSettingsStore().markVerified(config);
    calls.clear();
    dir = await Directory.systemTemp.createTemp('trackia-trust-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
    );
    controller = WorkoutController(repo);
    await controller.refresh();
    snapshot =
        jsonDecode(
              jsonEncode({
                ...syncSnapshot(
                  rows: [
                    ['Fecha', 'Ejercicio', 'Carga'],
                    ['21/10/2026', 'Press', '55'],
                  ],
                  occupied: ['0:0', '0:1', '0:2', '1:0', '1:1', '1:2'],
                ),
                'entered': {
                  '1:2': {'numberValue': 55},
                },
              }),
            )
            as Map<String, dynamic>;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ProfileStore.channel, (call) async {
          calls.add(call);
          final args = call.arguments as Map? ?? {};
          switch (call.method) {
            case 'authorizeWrite':
              return true;
            case 'clearSheetToken':
              return null;
            case 'syncSnapshot':
              return snapshot;
            case 'syncStatus':
              return {'synced': false};
            case 'writeWorkout':
              for (final raw in args['writes'] as List) {
                final cell = raw as Map;
                final row = cell['row'] as int, column = cell['column'] as int;
                final value = cell['value'];
                (snapshot['entered'] as Map)['$row:$column'] = {
                  'numberValue': value,
                };
                ((snapshot['rows'] as List)[row] as List)[column] =
                    value.toString();
              }
              return {'synced': true};
          }
          throw StateError('Unexpected Google operation: ${call.method}');
        });
    final sheet = SheetContext(
      id: 'file',
      name: 'Progreso',
      title: 'Resumen 2026',
      loadedAt: DateTime(2026, 10, 1),
      rows: const [
        ['Fecha', 'Ejercicio', 'Carga'],
      ],
    );
    final automation = SheetAutomation(controller);
    automation.service.identity = identity;
    await automation.service.bind(
      sheet,
      snapshot,
      allowOverwrite: true,
      instructions: 'Usar la tabla existente',
    );
    await SheetContextStore().save(sheet);
  });
  tearDown(() async {
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ProfileStore.channel, null);
  });

  Future<void> open(
    WidgetTester tester,
    String origin, {
    bool focusMode = false,
  }) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await realIo(tester, 10);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: AssistantChatScreen(
          controller: controller,
          chatStore: repo.chats,
          focusMode: focusMode,
          companion: companion(origin),
          client: AiClient(
            transport: (_, __, body) async => {
              'choices': [
                {
                  'message': {'content': answer},
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
    await realIo(tester);
  }

  Future<void> say(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('assistant-input')), text);
    await tester.tap(find.byTooltip('Enviar'));
    await realIo(tester);
  }

  Iterable<MethodCall> writes() => calls.where((c) => c.method == 'writeWorkout');

  group('trackia-sheet-edit', () {
    setUp(() => answer = sheetEdit);

    testWidgets('importado: muestra celdas y Cancelar no escribe', (
      tester,
    ) async {
      await open(tester, 'imported');
      await say(tester, 'Sube la carga a 60');
      expect(find.byKey(const Key('imported-action-dialog')), findsOneWidget);
      expect(
        find.textContaining('Este acompañante es importado'),
        findsOneWidget,
      );
      expect(find.textContaining('Progreso'), findsWidgets);
      expect(find.textContaining('C2'), findsOneWidget);
      expect(find.textContaining('55'), findsOneWidget);
      expect(find.textContaining('60'), findsWidgets);
      await tester.tap(find.byKey(const Key('imported-action-cancel')));
      await realIo(tester);
      expect(writes(), isEmpty);
      expect(find.textContaining('Acción cancelada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('importado: Confirmar escribe', (tester) async {
      await open(tester, 'imported');
      await say(tester, 'Sube la carga a 60');
      await tester.tap(find.byKey(const Key('imported-action-confirm')));
      await realIo(tester);
      expect(writes(), hasLength(1));
      expect((snapshot['entered'] as Map)['1:2'], {'numberValue': 60});
      expect(tester.takeException(), isNull);
    });

    testWidgets('propio: sin diálogo, escribe como antes', (tester) async {
      await open(tester, 'user');
      await say(tester, 'Sube la carga a 60');
      expect(find.byKey(const Key('imported-action-dialog')), findsNothing);
      expect(writes(), hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('trackia-activity', () {
    setUp(() => answer = activityBlock);

    testWidgets('importado: Cancelar no crea la actividad', (tester) async {
      await open(tester, 'imported', focusMode: true);
      await say(tester, 'Prepara press banca');
      expect(find.byKey(const Key('imported-action-dialog')), findsOneWidget);
      expect(find.textContaining('Press banca'), findsWidgets);
      expect(find.text('Descanso: 75 s'), findsOneWidget);
      await tester.tap(find.byKey(const Key('imported-action-cancel')));
      await realIo(tester);
      expect(controller.activities, isEmpty);
      expect(find.textContaining('Acción cancelada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('importado: Confirmar prepara la actividad', (tester) async {
      await open(tester, 'imported', focusMode: true);
      await say(tester, 'Prepara press banca');
      await tester.tap(find.byKey(const Key('imported-action-confirm')));
      await realIo(tester);
      expect(controller.activities, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('propio: sin diálogo, prepara como antes', (tester) async {
      await open(tester, 'user', focusMode: true);
      await say(tester, 'Prepara press banca');
      expect(find.byKey(const Key('imported-action-dialog')), findsNothing);
      expect(controller.activities, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('modelo', () {
    test('Companion JSON es retrocompatible', () {
      final own = companion('user');
      expect(own.toJson().containsKey('origin'), isFalse);
      final legacy = Companion.fromJson({
        'id': 'x',
        'name': 'X',
        'prompt': 'p',
      });
      expect(legacy.origin, 'user');
      final imported = companion('imported');
      expect(imported.toJson()['origin'], 'imported');
      final back = Companion.fromJson(imported.toJson());
      expect(back.isImported, isTrue);
      expect(back.copyWith(name: 'Otro').origin, 'imported');
      expect(imported.copyWith(origin: 'user').origin, 'user');
      expect(() => companion('raro'), throwsFormatException);
    });

    test('CompanionCreation: borrador externo queda importado', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const store = CompanionStore(profileId: 'local');
      final creation = CompanionCreation(
        store: store,
        progress: repo.progress,
      );
      final external = await creation.create(
        const CompanionDraft(name: 'Externo', origin: 'external'),
      );
      expect(external.origin, 'imported');
      final own = await creation.create(const CompanionDraft(name: 'Propio'));
      expect(own.origin, 'user');
      final loaded = await store.load();
      expect(loaded.firstWhere((c) => c.id == external.id).isImported, isTrue);
    });
  });

  group('ajustes', () {
    Future<void> settings(WidgetTester tester, Companion c) async {
      const store = CompanionStore(profileId: 'local');
      await store.upsert(c);
      await tester.pumpWidget(
        MaterialApp(
          home: CompanionSettingsScreen(
            progress: repo.progress,
            store: store,
            companion: c,
          ),
        ),
      );
      await realIo(tester);
    }

    testWidgets('propio: sin fila de confianza', (tester) async {
      await settings(tester, companion('user'));
      expect(find.byKey(const Key('trust-companion')), findsNothing);
    });

    testWidgets('importado: el interruptor lo pasa a propio', (tester) async {
      await settings(tester, companion('imported'));
      await tester.scrollUntilVisible(
        find.byKey(const Key('trust-companion')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('trust-companion')));
      await realIo(tester, 10);
      await tester.tap(find.byKey(const Key('trust-companion-confirm')));
      await realIo(tester);
      expect(find.byKey(const Key('trust-companion')), findsNothing);
      final loaded = await const CompanionStore(profileId: 'local').load();
      expect(loaded.firstWhere((c) => c.id == 'gymbro').origin, 'user');
      expect(tester.takeException(), isNull);
    });
  });
}
