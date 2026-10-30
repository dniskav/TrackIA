import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/ui/ai_per_companion.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/real_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('trackia-ai-per-companion-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => DateTime(2026, 10, 29, 9),
    );
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AiPerCompanionSection(
                profileId: 'local',
                progress: repo.progress,
              ),
            ],
          ),
        ),
      ),
    );
    await realIo(tester);
  }

  const defaults = AiConfig(
    service: AiService.openai,
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-default',
    protocol: AiProtocol.responses,
    apiKey: 'sk-profile',
  );

  testWidgets('lists each companion as default and saves a model of its own', (
    tester,
  ) async {
    await tester.runAsync(() => const AiSettingsStore().save(defaults));
    await open(tester);
    expect(find.text('Por acompañante'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('ai-override-gymbro')),
        matching: find.text('Por defecto'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('ai-override-gymbro')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const Key('ai-override-model')),
      'gpt-ligero',
    );
    await tester.tap(find.byKey(const Key('ai-override-save')));
    await realIo(tester, 20);

    expect(find.textContaining('gpt-ligero'), findsOneWidget);
    final saved = (await tester.runAsync(
      () => repo.progress.settings('gymbro'),
    ))!.aiOverride;
    expect(saved, AiOverride(service: AiService.openai, model: 'gpt-ligero'));
    // The other companions and the profile default stay as they were.
    final other = (await tester.runAsync(
      () => repo.progress.settings('enfoque'),
    ))!;
    expect(other.aiOverride, isNull);

    await tester.tap(find.byKey(const Key('ai-override-gymbro')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('ai-override-default')));
    await realIo(tester, 20);
    expect(
      (await tester.runAsync(
        () => repo.progress.settings('gymbro'),
      ))!.aiOverride,
      isNull,
    );
    expect(find.textContaining('gpt-ligero'), findsNothing);
  });

  testWidgets('a bad model shows a Spanish error and saves nothing', (
    tester,
  ) async {
    await tester.runAsync(() => const AiSettingsStore().save(defaults));
    await open(tester);
    await tester.tap(find.byKey(const Key('ai-override-calma')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const Key('ai-override-model')),
      'dos palabras',
    );
    await tester.tap(find.byKey(const Key('ai-override-save')));
    await realIo(tester, 20);
    expect(
      find.text('Introduce el identificador exacto del modelo.'),
      findsOneWidget,
    );
    expect(
      (await tester.runAsync(
        () => repo.progress.settings('calma'),
      ))!.aiOverride,
      isNull,
    );
  });

  testWidgets('without a connected provider it explains and stays disabled', (
    tester,
  ) async {
    await open(tester);
    expect(find.textContaining('Conecta primero un proveedor'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ai-override-gymbro')));
    await tester.pump();
    expect(find.byKey(const Key('ai-override-model')), findsNothing);
  });
}
