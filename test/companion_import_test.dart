import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/application/companion_creation.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/ui/companion_import.dart';
import 'package:trackia/ui/theme.dart';

import 'fixtures/companion_package_fixtures.dart';
import 'helpers/real_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late CompanionStore store;
  Companion? created;
  var closed = false;
  final now = DateTime(2026, 10, 29, 9);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    created = null;
    closed = false;
    dir = await Directory.systemTemp.createTemp('trackia-import-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    store = const CompanionStore(profileId: 'local');
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<void> open(
    WidgetTester tester, {
    Iterable<String> taken = const [],
    Future<List<int>?> Function()? pickFile,
    String? initialText,
  }) async {
    tester.view.physicalSize = const Size(800, 4000);
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
                  builder: (_) => CompanionImportScreen(
                    store: store,
                    creation: CompanionCreation(
                      store: store,
                      progress: repo.progress,
                      templates: repo.templates,
                    ),
                    takenIds: taken,
                    pickFile: pickFile,
                    initialText: initialText,
                  ),
                ),
              );
              closed = true;
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  Future<void> preview(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('import-paste')), text);
    await tester.tap(find.byKey(const Key('import-preview')));
    await tester.pumpAndSettle();
  }

  /// Companions the app brings by default are not part of what is imported.
  const builtIn = {'gymbro', 'enfoque', 'calma', 'diario'};
  Future<List<Companion>> saved(WidgetTester tester) async =>
      (await tester.runAsync(() => store.load()))!
          .where((c) => !builtIn.contains(c.id))
          .toList();

  Future<void> expectRejected(WidgetTester tester, String text) async {
    await open(tester);
    await preview(tester, text);
    expect(find.byKey(const Key('import-error')), findsOneWidget);
    expect(find.byKey(const Key('import-save')), findsNothing);
    expect(find.byKey(const Key('import-external-notice')), findsNothing);
    expect(await saved(tester), isEmpty);
    expect(tester.takeException(), isNull);
  }

  testWidgets('texto válido: vista previa editable con aviso externo', (
    tester,
  ) async {
    await open(tester);
    await preview(tester, typicalPackage().encode());
    expect(find.byKey(const Key('import-external-notice')), findsOneWidget);
    expect(
      find.text('Este contenido viene de fuera: revísalo antes de guardarlo.'),
      findsOneWidget,
    );
    final name = tester.widget<TextField>(find.byKey(const Key('import-name')));
    expect(name.controller!.text, 'Lectura');
    expect(find.byKey(const Key('import-description')), findsOneWidget);
    expect(find.byKey(const Key('import-prompt')), findsOneWidget);
    expect(find.byKey(const Key('import-activity')), findsOneWidget);
    expect(find.text('Sesión de lectura'), findsOneWidget);
    expect(find.text('• Hora de leer un rato.'), findsOneWidget);
    // El paquete declaraba «goals»: se avisa y queda en recordatorio.
    expect(find.byKey(const Key('import-warning-modeReset')), findsOneWidget);
    expect(find.byKey(const Key('import-mode-note')), findsOneWidget);
    expect(await saved(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialText: la vista previa sale directa', (tester) async {
    await open(tester, initialText: typicalPackage().encode());
    expect(find.byKey(const Key('import-external-notice')), findsOneWidget);
    final name = tester.widget<TextField>(find.byKey(const Key('import-name')));
    expect(name.controller!.text, 'Lectura');
    expect(await saved(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialText inválido: error y nada guardado', (tester) async {
    await open(tester, initialText: 'no es un paquete');
    expect(find.byKey(const Key('import-error')), findsOneWidget);
    expect(find.byKey(const Key('import-save')), findsNothing);
    expect(await saved(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editar y guardar crea un acompañante nuevo en recordatorio', (
    tester,
  ) async {
    await open(tester);
    await preview(tester, typicalPackage().encode());
    await tester.enterText(find.byKey(const Key('import-name')), 'Mi lectura');
    await tester.tap(find.byKey(const Key('import-color-green')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('import-save')));
    await tester.tap(find.byKey(const Key('import-save')));
    await realIo(tester, 12);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(created, isNotNull);
    expect(created!.id, 'mi-lectura');
    final all = await saved(tester);
    expect(all.map((c) => c.id), ['mi-lectura']);
    final c = all.single;
    expect(c.name, 'Mi lectura');
    expect(c.color, 'green');
    expect(c.icon, 'book');
    expect(c.reminderCopy!.windowStart, ['Hora de leer un rato.']);
    final settings = await tester.runAsync(
      () => repo.progress.settings('mi-lectura'),
    );
    expect(settings!.mode, 'reminder');
    expect(settings.achievementsEnabled, isFalse);
    expect(
      await tester.runAsync(() => repo.progress.activeGoal('mi-lectura')),
      isNull,
    );
    expect(
      await tester.runAsync(() => repo.progress.reminderFor('mi-lectura')),
      isNull,
    );
    final templates = await tester.runAsync(
      () => repo.templates.list(companionId: 'mi-lectura'),
    );
    expect(templates, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar no guarda nada', (tester) async {
    await open(tester);
    await preview(tester, typicalPackage().encode());
    await tester.ensureVisible(find.byKey(const Key('import-cancel')));
    await tester.tap(find.byKey(const Key('import-cancel')));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(created, isNull);
    expect(await saved(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un archivo elegido da la vista previa', (tester) async {
    final bytes = typicalPackage().encodeBytes();
    await open(tester, pickFile: () async => bytes);
    await tester.tap(find.byKey(const Key('import-pick-file')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-external-notice')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('versión futura: error y nada guardado', (tester) async {
    await expectRejected(tester, hostileFutureVersion());
    expect(
      find.textContaining('versión más nueva'),
      findsOneWidget,
    );
  });

  testWidgets('checksum roto: error y nada guardado', (tester) async {
    await expectRejected(tester, hostileBadChecksum());
    expect(find.textContaining('integridad'), findsOneWidget);
  });

  testWidgets('campo prohibido: error y nada guardado', (tester) async {
    await expectRejected(tester, hostileForbiddenField('apiKey'));
    expect(find.textContaining('nunca debe viajar'), findsOneWidget);
  });

  testWidgets('texto basura: error y nada guardado', (tester) async {
    await expectRejected(tester, 'esto no es un acompañante!!');
  });

  testWidgets('texto vacío: error y nada guardado', (tester) async {
    await expectRejected(tester, '   ');
  });

  testWidgets('paquete hostil: avisa y guarda el texto sin bloques', (
    tester,
  ) async {
    await open(tester);
    await preview(tester, hostileBlocks());
    expect(
      find.byKey(const Key('import-warning-appBlocksRemoved')),
      findsOneWidget,
    );
    final shown = tester
        .widget<TextField>(find.byKey(const Key('import-prompt')))
        .controller!
        .text;
    expect(shown, isNot(contains('trackia-')));
    expect(shown, isNot(contains('gymia-')));
    // Aunque la persona pegue un bloque a mano, no se guarda.
    await tester.enterText(
      find.byKey(const Key('import-prompt')),
      'Estilo.\n```trackia-activity\n{}\n```\nFin',
    );
    await tester.ensureVisible(find.byKey(const Key('import-save')));
    await tester.tap(find.byKey(const Key('import-save')));
    await realIo(tester, 12);
    await tester.pumpAndSettle();
    final c = (await saved(tester)).single;
    expect(c.prompt, isNot(contains('trackia-')));
    expect(c.prompt, contains('Estilo.'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('instrucciones sospechosas se avisan', (tester) async {
    await open(tester);
    await preview(tester, hostileIgnoreRules());
    expect(
      find.byKey(const Key('import-warning-suspiciousInstructions')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('import-warning-modeReset')), findsOneWidget);
    expect(await saved(tester), isEmpty);
  });

  testWidgets('ids ocupados se resuelven al guardar', (tester) async {
    await tester.runAsync(
      () => store.upsert(
        Companion(
          id: 'lectura',
          name: 'Lectura',
          description: '',
          prompt: '',
          icon: 'book',
          color: 'violet',
        ),
      ),
    );
    await open(tester, taken: const ['lectura']);
    await preview(tester, typicalPackage().encode());
    await tester.ensureVisible(find.byKey(const Key('import-save')));
    await tester.tap(find.byKey(const Key('import-save')));
    await realIo(tester, 12);
    await tester.pumpAndSettle();
    expect(created!.id, 'lectura-2');
    expect((await saved(tester)).map((c) => c.id), ['lectura', 'lectura-2']);
    expect(tester.takeException(), isNull);
  });
}
