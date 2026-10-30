import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/ui/companion_creator.dart';
import 'package:trackia/ui/theme.dart';

/// R8 of specs/004-trackia-experience/quickstart.md on Android: with a verified
/// AI, «Crear acompañante → Con ayuda de la IA» shows a sheet and Crear saves
/// the companion, its settings, activity, goal, reminder and achievements. The
/// AI's reply is canned; the database, secure storage and UI are real.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a companion is created from an AI proposal', (tester) async {
    const config = AiConfig(
      service: AiService.custom,
      protocol: AiProtocol.chatCompletions,
      baseUrl: 'https://example.test/v1',
      model: 'test',
      apiKey: 'fake-key',
    );
    final proposal = {
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
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp('trackia-r8-'),
    );
    final repo = await tester.runAsync(
      () => SqliteWorkoutRepository.open(path: '${dir!.path}/r8.sqlite'),
    );
    const store = CompanionStore(profileId: 'local');
    final availability = AiAvailability(
      catalog: AiModelCatalog(
        transport: (_, __) async => {
          'data': [
            {'id': 'test'},
          ],
        },
      ),
    );
    await tester.runAsync(() async {
      await const AiSettingsStore().save(config);
      await const AiSettingsStore().markVerified(config);
      await availability.check(acceptRecentVerification: true);
    });
    expect(availability.ready, isTrue);

    Companion? created;
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open'),
                onPressed: () async {
                  created = await Navigator.of(context).push<Companion>(
                    MaterialPageRoute(
                      builder: (_) => CompanionCreatorScreen(
                        store: store,
                        progress: repo!.progress,
                        templates: repo.templates,
                        availability: availability,
                        aiStore: const AiSettingsStore(),
                        client: AiClient(
                          transport: (_, __, ___) async => {
                            'choices': [
                              {
                                'message': {
                                  'content':
                                      'Te propongo esto.\n```trackia-companion\n${jsonEncode(proposal)}\n```',
                                },
                              },
                            ],
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Crear acompañante'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 4)),
    ); // capture: choice
    await tester.tap(find.byKey(const Key('creator-ai')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('creator-input')),
      'Quiero leer cada día',
    );
    await tester.tap(find.byKey(const Key('creator-send')));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const Key('creator-preview')), findsOneWidget);
    expect(find.text('Nivel: Juego completo'), findsOneWidget);
    expect(find.text('Meta: 20 páginas al día (mínimo 5)'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 5)),
    ); // capture: sheet

    await tester.tap(find.byKey(const Key('creator-create')));
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(created?.id, 'lectura');
    await tester.runAsync(() async {
      expect((await store.load()).map((c) => c.id), contains('lectura'));
      expect((await repo!.progress.settings('lectura')).game, isTrue);
      expect((await repo.progress.activeGoal('lectura'))!.target, 20);
      expect(
        (await repo.progress.reminderFor('lectura'))!.lastCallMin,
        22 * 60 + 30,
      );
      expect(
        (await repo.templates.list(
          companionId: 'lectura',
        )).single.definition.name,
        'Leer',
      );
      expect(
        (await repo.progress.achievements('lectura')).length,
        greaterThan(10),
      );
      await repo.progress.deleteCompanion('lectura');
      await store.delete('lectura');
      await repo.close();
      await dir!.delete(recursive: true);
    });
    availability.dispose();
  });
}
