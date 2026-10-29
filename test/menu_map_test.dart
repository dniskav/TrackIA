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
import 'package:gymia/ui/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Every entry of the old side drawer and app bar must still be reachable
/// (specs/004-trackia-experience/plan.md → «Mapa de menús»).
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
    await const AiSettingsStore().save(config);
    await const AiSettingsStore().markVerified(config);
    dir = await Directory.systemTemp.createTemp('trackia-menu-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/db.sqlite',
    );
    controller = WorkoutController(repo);
    await controller.refresh();
  });

  tearDown(() async {
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });

  Companion? switched;
  var trainingOpened = 0;

  Future<void> openChat(
    WidgetTester tester, {
    Companion? companion,
    bool focusMode = true,
  }) async {
    switched = null;
    trainingOpened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => AssistantChatScreen(
                                  controller: controller,
                                  client: AiClient(
                                    transport: (_, __, ___) async => {},
                                  ),
                                  companion: companion,
                                  focusMode: focusMode,
                                  onTraining: () => trainingOpened++,
                                  onData: () async {},
                                  onSwitchCompanion: (c) => switched = c,
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
                        ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    // Not pumpAndSettle: the panel loads saved activities asynchronously.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('chat-menu')));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String key) =>
      tester.widget<PopupMenuItem<String>>(find.byKey(Key(key))).enabled;

  testWidgets('the chat has no side drawer and a back button instead', (
    tester,
  ) async {
    await openChat(tester);
    final scaffold = tester.state<ScaffoldState>(
      find.descendant(
        of: find.byType(AssistantChatScreen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.hasDrawer, isFalse);
    expect(find.byType(DrawerButton), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatScreen), findsNothing);
  });

  testWidgets('the title shows the companion and opens a switcher', (
    tester,
  ) async {
    await openChat(tester, companion: Companion.suggestions[1]);
    expect(find.text('Enfoque'), findsWidgets);
    expect(find.byKey(const Key('companion-switcher')), findsOneWidget);
    await tester.tap(find.byKey(const Key('companion-switcher')));
    await tester.pumpAndSettle();
    for (final name in ['GymBro', 'Enfoque', 'Calma', 'Diario']) {
      expect(find.byKey(Key('switch-to-${name.toLowerCase()}')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('switch-to-calma')));
    await tester.pumpAndSettle();
    expect(switched?.id, 'calma');
  });

  testWidgets('choosing the current companion just closes the switcher', (
    tester,
  ) async {
    await openChat(tester, companion: Companion.suggestions[1]);
    await tester.tap(find.byKey(const Key('companion-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-to-enfoque')));
    await tester.pumpAndSettle();
    expect(switched, isNull);
    expect(find.byKey(const Key('switch-to-calma')), findsNothing);
  });

  testWidgets('the ⋮ menu keeps the companion actions of the old drawer', (
    tester,
  ) async {
    await openChat(tester, companion: Companion.suggestions.first);
    await openMenu(tester);
    for (final entry in {
      'menu-training': 'Rutinas e historial',
      'menu-sheet-sync': 'Enviar a Google Sheets',
      'archive-chat': 'Archivar chat',
      'menu-archives': 'Chats archivados',
      'menu-sheet': 'Hoja cargada',
    }.entries) {
      expect(find.byKey(Key(entry.key)), findsOneWidget, reason: entry.value);
      expect(
        find.descendant(
          of: find.byKey(Key(entry.key)),
          matching: find.text(entry.value),
        ),
        findsOneWidget,
      );
    }
    expect(enabled(tester, 'archive-chat'), isFalse, reason: 'chat vacío');
    expect(enabled(tester, 'menu-training'), isTrue);
    expect(find.byKey(const Key('menu-close-day')), findsNothing);
    expect(find.byKey(const Key('menu-recover')), findsNothing);
  });

  testWidgets('Rutinas e historial calls the training callback', (tester) async {
    await openChat(tester, companion: Companion.suggestions.first);
    await openMenu(tester);
    await tester.tap(find.byKey(const Key('menu-training')));
    await tester.pumpAndSettle();
    expect(trainingOpened, 1);
  });

  testWidgets('Finalizar día appears only for GymBro with an open session', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await repo.start('Sesión de prueba');
      await controller.refresh();
    });
    await openChat(tester, companion: Companion.suggestions.first);
    await openMenu(tester);
    expect(find.byKey(const Key('menu-close-day')), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openChat(tester, companion: Companion.suggestions[1]);
    await openMenu(tester);
    expect(find.byKey(const Key('menu-close-day')), findsNothing);
  });

  testWidgets('what moved to Ajustes is no longer in the chat menu', (
    tester,
  ) async {
    await openChat(tester, companion: Companion.suggestions.first);
    await openMenu(tester);
    for (final moved in [
      'Apariencia',
      'Ayuda y bienvenida',
      'Cuenta y datos',
      'Exportar / importar',
      'Configurar IA',
      'Probar notificación ahora',
      'Permitir avisos puntuales',
      'Avisar al iniciar, parar y terminar el descanso',
    ]) {
      expect(find.text(moved), findsNothing, reason: moved);
    }
  });

  testWidgets('the chat outside focus mode keeps its app bar icons', (
    tester,
  ) async {
    await openChat(tester, focusMode: false);
    expect(find.byKey(const Key('chat-menu')), findsNothing);
    expect(find.byKey(const Key('archive-chat')), findsOneWidget);
    expect(find.byTooltip('Chats archivados'), findsOneWidget);
    expect(find.byTooltip('Proveedor de IA'), findsOneWidget);
  });
}
