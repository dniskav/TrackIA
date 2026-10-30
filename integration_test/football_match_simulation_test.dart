import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/ui/assistant_chat.dart';
import 'package:trackia/ui/app.dart';
import 'package:trackia/ui/activity_focus.dart';
import 'package:trackia/ui/companions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('a football match uses a custom companion, halves and match events', (
    tester,
  ) async {
    tester.testTextInput.register();
    final dir = await Directory.systemTemp.createTemp('trackia-football-qa-');
    final profileId = 'qa-football-${DateTime.now().millisecondsSinceEpoch}';
    var now = DateTime.now();
    final repo = await SqliteWorkoutRepository.open(
      path: '${dir.path}/match.sqlite',
      clock: () => now,
    );
    final controller = WorkoutController(
      repo,
      clock: () => now,
      profileId: profileId,
    );
    final store = CompanionStore(profileId: profileId);
    final client = AiClient(
      transport: (_, __, body) async {
        final text = (body['messages'] as List).last['content'] as String;
        final answer = switch (text) {
          'Quiero registrar un partido de fútbol 7: dos tiempos de 25 minutos y 5 de descanso. Juego de delantero.' =>
            'Preparé el partido con dos tiempos de 25 minutos y descanso de 5.\n'
                '```gymia-activity\n'
                '{"name":"Partido de fútbol 7","repeated":true,"activitySeconds":1500,'
                '"restSeconds":300,"targetSets":2,"fields":['
                '{"key":"goals","label":"Goles","unit":""},'
                '{"key":"assists","label":"Asistencias","unit":""},'
                '{"key":"shots_on_target","label":"Tiros a puerta","unit":""}],'
                '"instructions":"Dos tiempos de 25 minutos, descanso de 5. Registrar solo hechos comunicados."}'
                '\n```',
          'Primer tiempo: marqué 1 gol y di 1 asistencia.' =>
            'Anotado: 1 gol y 1 asistencia.\n'
                '```gymia-result\n{"metrics":{"goals":1,"assists":1}}\n```',
          'Segundo tiempo: hice 2 tiros a puerta y acabé cansado.' =>
            'Anoté 2 tiros a puerta y conservo tu nota sobre el cansancio.\n'
                '```gymia-result\n{"metrics":{"shots_on_target":2}}\n```',
          _ => throw StateError('Mensaje inesperado: $text'),
        };
        return {
          'choices': [
            {
              'message': {'content': answer},
            },
          ],
        };
      },
    );
    final availability = AiAvailability(
      store: AiSettingsStore(profileId: profileId),
      catalog: AiModelCatalog(
        transport:
            (_, __) async => {
              'data': [
                {'id': 'qa-model'},
              ],
            },
      ),
    );
    const config = AiConfig(
      service: AiService.custom,
      baseUrl: 'https://example.test/v1',
      model: 'qa-model',
      protocol: AiProtocol.chatCompletions,
      apiKey: 'qa-fixture-not-a-real-key',
    );
    Future<void> until(bool Function() done) async {
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (!done() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(done(), isTrue);
    }

    bool sendEnabled() => tester
        .widgetList<IconButton>(find.byType(IconButton))
        .where((button) => button.tooltip == 'Enviar')
        .any((button) => button.onPressed != null);
    Future<void> send(String text) async {
      await tester.enterText(find.byKey(const Key('assistant-input')), text);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();
      await until(
        () =>
            sendEnabled() &&
            tester
                .widget<TextField>(find.byKey(const Key('assistant-input')))
                .controller!
                .text
                .isEmpty &&
            find.byType(LinearProgressIndicator).evaluate().isEmpty,
      );
    }

    Future<void> pressStartStop() async {
      await tester.tap(find.byKey(const Key('activity-start-stop')));
      await tester.pumpAndSettle();
      await until(() => !controller.busy);
    }

    try {
      await AiSettingsStore(profileId: profileId).save(config);
      await AiSettingsStore(profileId: profileId).markVerified(config);
      await controller.refresh();
      await tester.pumpWidget(
        MaterialApp(
          theme: gymTheme,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder:
                (context) => CompanionDashboard(
                  profileId: profileId,
                  onOpen:
                      (companion) => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => AssistantChatScreen(
                                controller: controller,
                                companion: companion,
                                focusMode: true,
                                client: client,
                                availability: availability,
                              ),
                        ),
                      ),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('companion-create')));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'Cancha');
      await tester.enterText(fields.at(1), 'Partidos, minutos y jugadas');
      await tester.enterText(
        fields.at(2),
        'Acompáñame en partidos de fútbol. Divide el partido en tiempos, '
        'registra solo goles, asistencias y jugadas que te confirme, '
        'y conserva mis observaciones físicas. No inventes estadísticas.',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      final cancha = (await store.load()).singleWhere(
        (c) => c.name == 'Cancha',
      );
      expect(cancha.prompt, contains('No inventes estadísticas'));
      await tester.tap(find.text('Cancha'));
      await tester.pumpAndSettle();
      await until(() => availability.ready && sendEnabled());

      await send(
        'Quiero registrar un partido de fútbol 7: dos tiempos de 25 minutos y 5 de descanso. Juego de delantero.',
      );
      final activity = controller.focus!;
      expect(activity.definition.companionId, cancha.id);
      expect(activity.definition.activitySeconds, 1500);
      expect(activity.definition.restSeconds, 300);
      expect(activity.definition.targetSets, 2);
      expect(
        activity.definition.fields.map((f) => f['key']),
        containsAll(['goals', 'assists', 'shots_on_target']),
      );
      await pressStartStop();
      expect(controller.focus!.running, isNotNull);
      expect(find.textContaining('Tramo 1 de 2'), findsWidgets);
      await send('Primer tiempo: marqué 1 gol y di 1 asistencia.');
      expect(
        controller.focus!.messages.where((m) => m.role == 'user').last.metrics,
        {'goals': 1, 'assists': 1},
      );
      now = now.add(const Duration(minutes: 25));
      await tester.pump(const Duration(milliseconds: 300));
      await pressStartStop();
      expect(
        controller.focus!.restEndsAt!.millisecondsSinceEpoch,
        now.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
      );
      now = now.add(const Duration(minutes: 5));
      await pressStartStop();
      expect(controller.focus!.intervals, hasLength(2));
      await send('Segundo tiempo: hice 2 tiros a puerta y acabé cansado.');
      expect(
        controller.focus!.messages
            .where((m) => m.role == 'user')
            .last
            .metrics['shots_on_target'],
        2,
      );
      now = now.add(const Duration(minutes: 25));
      await pressStartStop();
      await until(() => controller.focus?.running == null && !controller.busy);
      tester.testTextInput.hide();
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('finish-activity')))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('finish-activity')));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityEndDialog), findsOneWidget);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      await until(() => controller.focus == null);
      final finished = controller.activities.singleWhere(
        (a) => a.id == activity.id,
      );
      expect(finished.intervals, hasLength(2));
      expect(
        finished.intervals.first.endedAt!
            .difference(finished.intervals.first.startedAt)
            .inSeconds,
        1500,
      );
      expect(
        finished.intervals.last.endedAt!
            .difference(finished.intervals.last.startedAt)
            .inSeconds,
        1500,
      );
      expect(finished.messages.any((m) => m.text.contains('cansado')), isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await repo.close();
      await dir.delete(recursive: true);
      final storage = const FlutterSecureStorage();
      await storage.delete(key: store.key);
      await AiSettingsStore(profileId: profileId).delete();
      tester.testTextInput.unregister();
    }
  });
}
