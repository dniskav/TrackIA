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
import 'package:trackia/data/message_effect_repository.dart';
import 'package:trackia/data/message_revision_repository.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/message_effect.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/ui/assistant_chat.dart';

import 'helpers/real_io.dart';

/// Editar un mensaje: guardar solo, guardar y enviar al modelo, cancelar.
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
    dir = await Directory.systemTemp.createTemp('trackia-edit-');
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

  Future<List<Map<String, dynamic>>> open(WidgetTester tester) async {
    final bodies = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: AssistantChatScreen(
          controller: controller,
          chatStore: repo.chats,
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
    return bodies;
  }

  Future<void> say(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('assistant-input')), text);
    await tester.tap(find.byTooltip('Enviar'));
    await realIo(tester);
  }

  Future<void> openEditor(
    WidgetTester tester,
    String text,
    String edited,
  ) async {
    if (find.byTooltip('Editar').evaluate().isEmpty) {
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip('Editar'));
    await realIo(tester);
    expect(find.byKey(const Key('edit-message-input')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('edit-message-input')), edited);
  }

  Future<void> expectVersion2(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Historial'));
    await realIo(tester);
    expect(find.textContaining('Versión 2 · actual'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await realIo(tester, 10);
  }

  Future<void> editAndSend(WidgetTester tester, String from, String to) async {
    await tester.pump(const Duration(milliseconds: 600));
    await openEditor(tester, from, to);
    await tester.tap(find.byKey(const Key('save-send-edit-message')));
    await realIo(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('Guardar solo guarda la revisión 2 sin enviar ni fallar', (
    tester,
  ) async {
    final bodies = await open(tester);
    await say(tester, 'Hola original');
    expect(bodies, hasLength(1));
    await openEditor(tester, 'Hola original', 'Hola corregido');
    await tester.tap(find.byKey(const Key('save-edit-message')));
    await realIo(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(bodies, hasLength(1));
    expect(find.text('Hola corregido'), findsOneWidget);
    await expectVersion2(tester);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  const onlyLast =
      'Solo se puede editar el último mensaje. Escribe una corrección como mensaje nuevo.';

  List<Map> modelTurns(Map<String, dynamic> body) => [
    for (final m in body['messages'] as List)
      if ((m as Map)['role'] != 'system') m,
  ];

  String systemText(Map<String, dynamic> body) => [
    for (final m in body['messages'] as List)
      if ((m as Map)['role'] == 'system') m['content'],
  ].join('\n');

  testWidgets('Solo el último mensaje del usuario se puede editar', (
    tester,
  ) async {
    final bodies = await open(tester);
    await say(tester, 'Primero');
    await say(tester, 'Segundo');
    expect(bodies, hasLength(2));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Primero'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Segundo'));
    await tester.pumpAndSettle();
    final edits = find.byIcon(Icons.edit_outlined);
    expect(edits, findsNWidgets(2));
    final buttons = tester.widgetList<IconButton>(
      find.widgetWithIcon(IconButton, Icons.edit_outlined),
    );
    expect(buttons.first.onPressed, isNull);
    expect(buttons.first.tooltip, onlyLast);
    expect(buttons.last.onPressed, isNotNull);
    expect(buttons.last.tooltip, 'Editar');
    // Al tocar el deshabilitado se muestra el motivo y no se abre el editor.
    await tester.tap(edits.first);
    await tester.pumpAndSettle();
    expect(find.text(onlyLast), findsOneWidget);
    expect(find.byKey(const Key('edit-message-input')), findsNothing);
    // El último sí abre el editor.
    await tester.tap(edits.last);
    await realIo(tester);
    expect(find.byKey(const Key('edit-message-input')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel-edit-message')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Guardar y enviar manda el editado y una nota de edición', (
    tester,
  ) async {
    final bodies = await open(tester);
    await say(tester, 'Hola original');
    expect(bodies, hasLength(1));
    // Un mensaje nuevo no lleva nota de edición.
    expect(systemText(bodies.first), isNot(contains('NOTA DE EDICIÓN')));
    await tester.pump(const Duration(milliseconds: 600));
    await openEditor(tester, 'Hola original', 'Hola corregido');
    await tester.tap(find.byKey(const Key('save-send-edit-message')));
    await realIo(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(bodies, hasLength(2));
    final turns = modelTurns(bodies.last);
    expect([for (final m in turns) m['content']], ['Hola corregido']);
    expect(turns.single['role'], 'user');
    final note = systemText(bodies.last);
    expect(note, contains('NOTA DE EDICIÓN'));
    expect(note, contains('Versión 1 (anterior): «Hola original»'));
    expect(note, contains('Versión 2 (nueva): «Hola corregido»'));
    expect(note, contains('Tu respuesta anterior a la versión 1: «Respuesta 1»'));
    expect(note, contains('pregunta al usuario qué prefiere'));
    expect(note, contains('Nunca repitas un efecto ya aplicado'));
    // Visible: texto editado, respuesta nueva y aviso; lo obsoleto se retira.
    expect(find.text('Hola corregido'), findsOneWidget);
    expect(find.text('Respuesta 2'), findsOneWidget);
    expect(find.text('Respuesta 1'), findsNothing);
    expect(
      find.text('Conversación continuada desde el mensaje editado'),
      findsOneWidget,
    );
    await expectVersion2(tester);
    // Un mensaje nuevo posterior vuelve a ir sin nota.
    await say(tester, 'Otro mensaje');
    expect(bodies, hasLength(3));
    expect(systemText(bodies.last), isNot(contains('NOTA DE EDICIÓN')));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('La nota de edición incluye los efectos ya aplicados', (
    tester,
  ) async {
    final bodies = await open(tester);
    await say(tester, 'Hice 10 flexiones');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final revisions = await MessageRevisionRepository.fromChatStore(
        repo.chats,
        FeatureScope(profileId: controller.profileId, companionId: 'gymbro'),
      );
      final rows = await revisions.database.rawQuery(
        'SELECT id, message_id FROM message_revision_versions',
      );
      await MessageEffectRepository.on(revisions).record(
        MessageEffect(
          id: 'effect-1',
          profileId: controller.profileId,
          companionId: 'gymbro',
          messageId: rows.single['message_id'] as String,
          revisionId: rows.single['id'] as String,
          kind: 'goal',
          targetId: 'goal-1',
          operationKey: 'op-flexiones',
          summary: 'Registré 10 flexiones',
          createdAt: DateTime.utc(2026, 11, 7),
        ),
      );
    });
    await openEditor(tester, 'Hice 10 flexiones', 'Hice 12 flexiones');
    await tester.tap(find.byKey(const Key('save-send-edit-message')));
    await realIo(tester);
    await tester.pumpAndSettle();
    expect(bodies, hasLength(2));
    final note = systemText(bodies.last);
    expect(note, contains('NOTA DE EDICIÓN'));
    expect(note, contains('Registré 10 flexiones'));
    // El resumen de efectos va una sola vez.
    expect('Registré 10 flexiones'.allMatches(note), hasLength(1));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Respuesta verbal sin efecto: no hay efectos que declarar', (
    tester,
  ) async {
    final bodies = await open(tester);
    await say(tester, 'Hice 10 flexiones');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final revisions = await MessageRevisionRepository.fromChatStore(
        repo.chats,
        FeatureScope(profileId: controller.profileId, companionId: 'gymbro'),
      );
      final id = (await revisions.database.rawQuery(
        'SELECT message_id FROM message_revision_versions',
      )).single['message_id'] as String;
      final effects = MessageEffectRepository.on(revisions);
      expect(await effects.effectsFor(id), isEmpty);
      expect(await effects.appliedEffectsSummary(id), '');
    });
    await editAndSend(tester, 'Hice 10 flexiones', 'Hice 12 flexiones');
    final note = systemText(bodies.last);
    expect(note, contains('Efectos ya aplicados: ninguno registrado.'));
    expect(note, isNot(contains('Propuestas SIN confirmar')));
    expect(note, isNot(contains('resultado incierto')));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Operación incierta: el modelo sabe que no se sabe si se aplicó', (
    tester,
  ) async {
    final bodies = await open(tester);
    await say(tester, 'Pon el objetivo en 10 series');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final revisions = await MessageRevisionRepository.fromChatStore(
        repo.chats,
        FeatureScope(profileId: controller.profileId, companionId: 'gymbro'),
      );
      final rows = await revisions.database.rawQuery(
        'SELECT id, message_id FROM message_revision_versions',
      );
      await MessageEffectRepository.on(revisions).record(
        MessageEffect(
          id: 'effect-u',
          profileId: controller.profileId,
          companionId: 'gymbro',
          messageId: rows.single['message_id'] as String,
          revisionId: rows.single['id'] as String,
          kind: 'target',
          targetId: 'act-1',
          operationKey: 'op-incierto',
          summary: 'Fijar el objetivo en 10 series',
          createdAt: DateTime.utc(2026, 11, 7),
          status: EffectStatus.uncertain,
        ),
      );
    });
    await editAndSend(
      tester,
      'Pon el objetivo en 10 series',
      'Pon el objetivo en 12 series',
    );
    final note = systemText(bodies.last);
    expect(
      note,
      contains(
        'Con resultado incierto (no sabes si se aplicaron; no los repitas a ciegas',
      ),
    );
    expect(note, contains('Fijar el objetivo en 10 series'));
    expect(note, isNot(contains('Efectos ya aplicados por la respuesta anterior')));
    expect(note, isNot(contains('ninguno registrado')));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Cancelar no cambia nada', (tester) async {
    final bodies = await open(tester);
    await say(tester, 'Hola original');
    await openEditor(tester, 'Hola original', 'Otra cosa');
    await tester.tap(find.byKey(const Key('cancel-edit-message')));
    await realIo(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(bodies, hasLength(1));
    expect(find.text('Hola original'), findsOneWidget);
    expect(find.text('Otra cosa'), findsNothing);
    await tester.tap(find.byTooltip('Historial'));
    await realIo(tester);
    expect(find.textContaining('Versión 2'), findsNothing);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    await close(tester);
  });

  testWidgets('Editar dos veces seguidas sin reiniciar no rompe la lista', (
    tester,
  ) async {
    final bodies = await open(tester);
    await say(tester, 'Hoy hice 3 series con 60 kg');
    await editAndSend(tester, 'Hoy hice 3 series con 60 kg', 'Hoy hice 3 series con 70 kg');
    expect(tester.takeException(), isNull);
    await editAndSend(tester, 'Hoy hice 3 series con 70 kg', 'Hoy hice 3 series con 80 kg');
    expect(tester.takeException(), isNull);
    expect(bodies, hasLength(3));
    expect(find.text('Hoy hice 3 series con 80 kg'), findsOneWidget);
    // Eventos idénticos consecutivos se colapsan: una sola línea visible.
    expect(
      find.text('Conversación continuada desde el mensaje editado'),
      findsOneWidget,
    );
    expect(find.text('Respuesta 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Editar, reiniciar y volver a editar no rompe la lista', (
    tester,
  ) async {
    var bodies = await open(tester);
    await say(tester, 'Mensaje A');
    await editAndSend(tester, 'Mensaje A', 'Mensaje A corregido');
    expect(tester.takeException(), isNull);
    await say(tester, 'Hoy hice 3 series de press banca con 60 kg');
    await editAndSend(
      tester,
      'Hoy hice 3 series de press banca con 60 kg',
      'Hoy hice 3 series de press banca con 70 kg',
    );
    expect(tester.takeException(), isNull);
    await close(tester);
    bodies = await open(tester);
    expect(tester.takeException(), isNull);
    await editAndSend(
      tester,
      'Hoy hice 3 series de press banca con 70 kg',
      'Hoy hice 3 series de press banca con 80 kg',
    );
    expect(tester.takeException(), isNull);
    expect(bodies, hasLength(1));
    expect(
      find.text('Hoy hice 3 series de press banca con 80 kg'),
      findsOneWidget,
    );
    await close(tester);
  });

  // --- T013/T014: el chat registra propuestas, confirmaciones e inciertos ---
  // El objetivo se propone sobre un mensaje durable ya enviado (reenvío tras
  // editar con la actividad abierta): el primer envío con foco abierto va por
  // la ruta de actividad y no tiene mensaje al que enlazar efectos.

  String targetBlock(int sets) =>
      'Propongo ajustarlo.\n```trackia-activity-target\n{"targetSets": $sets}\n```';

  /// Abre el chat en modo foco, envía [text] (respuesta de texto, sin efecto)
  /// y solo entonces prepara la actividad: así el mensaje es durable.
  Future<MessageEffectRepository> openFocus(
    WidgetTester tester,
    List<String> replies,
    String text,
  ) async {
    var n = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AssistantChatScreen(
          controller: controller,
          chatStore: repo.chats,
          focusMode: true,
          client: AiClient(
            transport: (_, __, body) async => {
              'choices': [
                {
                  'message': {'content': replies[n++ % replies.length]},
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
    await say(tester, text);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      await repo.prepareActivity(
        ActivityDefinition(
          name: 'Pec Fly',
          restSeconds: 120,
          targetSets: 4,
          fields: const [
            {'key': 'reps', 'label': 'Reps', 'unit': ''},
          ],
        ),
      );
      await controller.refresh();
    });
    await realIo(tester, 10);
    return (await tester.runAsync(() async {
      final revisions = await MessageRevisionRepository.fromChatStore(
        repo.chats,
        FeatureScope(profileId: controller.profileId, companionId: 'gymbro'),
      );
      return MessageEffectRepository.on(revisions);
    }))!;
  }

  Future<String> messageId(WidgetTester tester) async =>
      (await tester.runAsync(() async {
        final revisions = await MessageRevisionRepository.fromChatStore(
          repo.chats,
          FeatureScope(profileId: controller.profileId, companionId: 'gymbro'),
        );
        return (await revisions.database.rawQuery(
          'SELECT message_id FROM message_revision_versions',
        )).first['message_id'] as String;
      }))!;

  /// Edita y reenvía; deja el diálogo del modelo abierto (no hay `settle`).
  Future<void> resend(WidgetTester tester, String from, String to) async {
    await tester.pump(const Duration(milliseconds: 600));
    await openEditor(tester, from, to);
    await tester.tap(find.byKey(const Key('save-send-edit-message')));
    await realIo(tester);
  }

  Future<void> confirmTarget(WidgetTester tester) async {
    await tester.tap(find.text('Cambiar'));
    await realIo(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('Objetivo propuesto: queda como propuesta y pasa a confirmado', (
    tester,
  ) async {
    final effects = await openFocus(
      tester,
      ['Respuesta', targetBlock(3)],
      'Pon tres series',
    );
    final id = await messageId(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await openEditor(tester, 'Pon tres series', 'Pon tres series ya');
    await tester.tap(find.byKey(const Key('save-send-edit-message')));
    await realIo(tester);
    expect(find.text('Cambiar objetivo de series'), findsOneWidget);
    // Con el diálogo abierto es solo una propuesta: no es un hecho.
    var list = (await tester.runAsync(() => effects.effectsFor(id)))!;
    expect(list.single.status, EffectStatus.proposed);
    var text = (await tester.runAsync(() => effects.appliedEffectsSummary(id)))!;
    expect(text, contains('Propuestas SIN confirmar'));
    expect(text, isNot(contains('ya aplicados')));
    await confirmTarget(tester);
    list = (await tester.runAsync(() => effects.effectsFor(id)))!;
    expect(list.map((e) => e.status), [EffectStatus.confirmed]);
    expect(controller.focus!.definition.targetSets, 3);
    text = (await tester.runAsync(() => effects.appliedEffectsSummary(id)))!;
    expect(text, contains('ya aplicados'));
    expect(text, isNot(contains('SIN confirmar')));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Objetivo rechazado: la propuesta queda fallida y no cambia nada', (
    tester,
  ) async {
    final effects = await openFocus(
      tester,
      ['Respuesta', targetBlock(3)],
      'Pon tres series',
    );
    final id = await messageId(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await openEditor(tester, 'Pon tres series', 'Pon tres series ya');
    await tester.tap(find.byKey(const Key('save-send-edit-message')));
    await realIo(tester);
    await tester.tap(find.text('Cancelar'));
    await realIo(tester);
    await tester.pumpAndSettle();
    final list = (await tester.runAsync(() => effects.effectsFor(id)))!;
    expect(list.single.status, EffectStatus.failed);
    expect(controller.focus!.definition.targetSets, 4);
    expect((await tester.runAsync(() => effects.appliedEffectsSummary(id)))!, '');
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Varias candidatas: pregunta cuál; una sola: corrige con antes/después', (
    tester,
  ) async {
    final effects = await openFocus(
      tester,
      ['Respuesta', targetBlock(3), targetBlock(5), targetBlock(6)],
      'Pon tres series',
    );
    final id = await messageId(tester);
    await resend(tester, 'Pon tres series', 'Pon tres series ya');
    await confirmTarget(tester);
    expect(controller.focus!.definition.targetSets, 3);
    // Reenvío con otro valor propuesto: hay una sola relación, se corrige.
    await resend(tester, 'Pon tres series ya', 'Pon cinco series');
    expect(find.text('Cambiar objetivo de series'), findsOneWidget);
    await confirmTarget(tester);
    expect(controller.focus!.definition.targetSets, 5);
    var list = (await tester.runAsync(() => effects.effectsFor(id)))!;
    expect(list.map((e) => e.status), [
      EffectStatus.superseded,
      EffectStatus.confirmed,
    ]);
    final text = (await tester.runAsync(() => effects.appliedEffectsSummary(id)))!;
    expect(text, contains('antes: 3 series; ahora: 5 series'));
    // Una segunda relación confirmada del mismo objetivo: no elige solo.
    await tester.runAsync(() async {
      await effects.record(
        MessageEffect(
          id: 'extra-target',
          profileId: controller.profileId,
          companionId: 'gymbro',
          messageId: id,
          revisionId: list.last.revisionId,
          kind: 'target',
          targetId: list.last.targetId,
          operationKey: 'op-extra-target',
          summary: 'Fijé el objetivo en 9 series',
          createdAt: DateTime.utc(2026, 11, 7),
        ),
      );
    });
    await resend(tester, 'Pon cinco series', 'Pon seis series');
    await confirmTarget(tester);
    expect(find.textContaining('dime a cuál te refieres'), findsOneWidget);
    expect(find.textContaining('Fijé el objetivo en 9 series'), findsWidgets);
    expect(controller.focus!.definition.targetSets, 5);
    list = (await tester.runAsync(() => effects.effectsFor(id)))!;
    expect(
      list.where((e) => e.status == EffectStatus.confirmed).length,
      2,
      reason: 'no se corrigió ninguna ni se duplicó',
    );
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Objetivo con error inesperado al guardar: queda incierto y el modelo lo sabe', (
    tester,
  ) async {
    final effects = await openFocus(
      tester,
      ['Respuesta', targetBlock(3), 'Vale'],
      'Pon tres series',
    );
    final id = await messageId(tester);
    await resend(tester, 'Pon tres series', 'Pon tres series ya');
    expect(find.text('Cambiar objetivo de series'), findsOneWidget);
    // Un fallo de almacenamiento que no es una validación (disco, bloqueo...).
    await tester.runAsync(() async {
      final other = await databaseFactoryFfi.openDatabase(
        '${dir.path}/test.sqlite',
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await other.execute(
        "CREATE TRIGGER boom BEFORE UPDATE ON activities BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      await other.close();
    });
    await confirmTarget(tester);
    expect(controller.focus!.definition.targetSets, 4);
    final list = (await tester.runAsync(() => effects.effectsFor(id)))!;
    expect(list.single.status, EffectStatus.uncertain);
    final text = (await tester.runAsync(() => effects.appliedEffectsSummary(id)))!;
    expect(text, contains('Con resultado incierto'));
    expect(text, isNot(contains('ya aplicados')));
    expect(tester.takeException(), isNull);
    await close(tester);
  });
}
