import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/feature_scope.dart';
import 'package:trackia/data/message_revision_repository.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/message_revision.dart';
import 'package:trackia/ui/assistant_chat.dart';

import 'helpers/real_io.dart';

/// T011: cola ordenada de pendientes, sin truncar y con envío al chat de origen.
/// Un mensaje queda `pending` cuando se guarda pero no hay proveedor
/// configurado en el momento de enviar (nunca se envía solo después).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController controller;
  const config = AiConfig(
    service: AiService.custom,
    protocol: AiProtocol.chatCompletions,
    baseUrl: 'https://example.test/v1',
    model: 'test',
    apiKey: 'fake-key',
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await const AiSettingsStore().save(config);
    await const AiSettingsStore().markVerified(config);
    dir = await Directory.systemTemp.createTemp('trackia-queue-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
    );
    controller = WorkoutController(repo);
  });
  tearDown(() async {
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<void> openScreen(
    WidgetTester tester,
    List<Map<String, dynamic>> bodies, {
    Companion? companion,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: AssistantChatScreen(
          key: UniqueKey(),
          controller: controller,
          chatStore: repo.chats,
          companion: companion,
          client: AiClient(
            transport: (_, __, body) async {
              bodies.add(body);
              return {
                'choices': [
                  {
                    'message': {'content': 'Respuesta ${bodies.length}'},
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
  }

  Future<void> say(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('assistant-input')), text);
    await tester.tap(find.byTooltip('Enviar'));
    await realIo(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await realIo(tester, 10);
  }

  Future<void> withoutProvider(Future<void> Function() body) async {
    FlutterSecureStorage.setMockInitialValues({});
    await body();
    FlutterSecureStorage.setMockInitialValues({});
    await const AiSettingsStore().save(config);
    await const AiSettingsStore().markVerified(config);
  }

  List<String> userTurns(Map<String, dynamic> body) => [
    for (final m in body['messages'] as List)
      if ((m as Map)['role'] == 'user') m['content'] as String,
  ];

  Future<MessageRevisionRepository> queueOf(
    WidgetTester tester,
    String companionId,
  ) async {
    final result = await tester.runAsync(
      () => MessageRevisionRepository.fromChatStore(
        repo.chats,
        FeatureScope(profileId: controller.profileId, companionId: companionId),
      ),
    );
    return result!;
  }

  testWidgets('varios pendientes se envían en orden de creación', (
    tester,
  ) async {
    final bodies = <Map<String, dynamic>>[];
    await openScreen(tester, bodies);
    await withoutProvider(() async {
      await say(tester, 'uno');
      await say(tester, 'dos');
      await say(tester, 'tres');
    });
    expect(bodies, isEmpty);

    final queue = await queueOf(tester, 'gymbro');
    final chatIds = await tester.runAsync(() async {
      final json = await repo.chats.loadActive('gymbro');
      return json?['sessionId'] as String?;
    });
    expect(chatIds, isNotNull);
    final items = (await tester.runAsync(() => queue.queue(chatIds!)))!;
    expect([for (final i in items) i.revision.text], ['uno', 'dos', 'tres']);
    expect(
      items.every((i) => i.message.delivery == MessageDelivery.pending),
      isTrue,
    );
    for (var i = 1; i < items.length; i++) {
      expect(
        items[i].message.createdAt.isBefore(items[i - 1].message.createdAt),
        isFalse,
      );
    }

    // Reenviar en orden: cada envío lleva los anteriores sin resolver y no
    // adelanta los posteriores.
    for (final (index, text) in ['uno', 'dos', 'tres'].indexed) {
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text(text).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.refresh).last);
      await realIo(tester);
      expect(bodies, hasLength(index + 1));
    }
    expect(userTurns(bodies[0]), ['uno']);
    expect(userTurns(bodies[1]), ['uno', 'dos']);
    expect(userTurns(bodies[2]), ['uno', 'dos', 'tres']);
    await close(tester);
  });

  testWidgets('un mensaje largo llega íntegro, enviado y pendiente', (
    tester,
  ) async {
    final long = List.generate(7900, (i) => 'abcdefghij'[i % 10]).join();
    final bodies = <Map<String, dynamic>>[];
    await openScreen(tester, bodies);
    await say(tester, long);
    expect(bodies, hasLength(1));
    expect(userTurns(bodies.single).last, long);
    expect(userTurns(bodies.single).last.length, 7900);

    // Pendiente largo: va completo en el contexto del siguiente envío.
    final pendingLong = '${long.substring(0, 7899)}Z';
    await withoutProvider(() => say(tester, pendingLong));
    expect(bodies, hasLength(1));
    await say(tester, 'corto');
    expect(bodies, hasLength(2));
    final turns = userTurns(bodies.last);
    expect(turns, contains(pendingLong));
    expect(turns.firstWhere((t) => t.length > 7000).length, greaterThan(7000));
    expect(turns.last, 'corto');
    await close(tester);
  });

  testWidgets('un pendiente se envía a su compañero y chat de origen', (
    tester,
  ) async {
    final a = Companion(
      id: 'compa-a',
      name: 'Alfa',
      description: 'A',
      prompt: 'Eres A.',
    );
    final b = Companion(
      id: 'compa-b',
      name: 'Beta',
      description: 'B',
      prompt: 'Eres B.',
    );
    final bodies = <Map<String, dynamic>>[];
    await openScreen(tester, bodies, companion: a);
    await withoutProvider(() => say(tester, 'solo para A'));
    expect(bodies, isEmpty);
    await close(tester);

    // El usuario cambia de compañero: B no ve ni envía lo pendiente de A.
    await openScreen(tester, bodies, companion: b);
    expect(find.text('solo para A'), findsNothing);
    await say(tester, 'hola B');
    expect(bodies, hasLength(1));
    expect(userTurns(bodies.single), ['hola B']);
    await close(tester);

    // Al volver a A, Reenviar lo manda con el contexto de A y lo resuelve allí.
    await openScreen(tester, bodies, companion: a);
    expect(find.text('solo para A'), findsOneWidget);
    await tester.tap(find.text('solo para A'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reenviar'));
    await realIo(tester);
    expect(bodies, hasLength(2));
    expect(userTurns(bodies.last), ['solo para A']);
    final system = [
      for (final m in bodies.last['messages'] as List)
        if ((m as Map)['role'] == 'system') m['content'],
    ].join('\n');
    expect(system, contains('Eres A.'));
    expect(system, isNot(contains('Eres B.')));

    final repoA = await queueOf(tester, 'compa-a');
    final repoB = await queueOf(tester, 'compa-b');
    final json = await tester.runAsync(() => repo.chats.loadActive('compa-a'));
    final chatA = json!['sessionId'] as String;
    final all = (await tester.runAsync(() => repoA.chatMessages(chatA)))!;
    expect(all.single.revision.text, 'solo para A');
    expect(all.single.message.chatId, chatA);
    expect(all.single.message.delivery, MessageDelivery.answered);
    expect((await tester.runAsync(() => repoA.queue(chatA)))!, isEmpty);
    expect((await tester.runAsync(() => repoB.queue(chatA)))!, isEmpty);
    await close(tester);
  });
}
