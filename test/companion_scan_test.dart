import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/application/companion_creation.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/ui/companion_scan.dart';
import 'package:trackia/ui/theme.dart';

import 'fixtures/companion_package_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late CompanionStore store;
  var scannersBuilt = 0;
  final now = DateTime(2026, 10, 29, 9);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    scannersBuilt = 0;
    dir = await Directory.systemTemp.createTemp('trackia-scan-');
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

  /// Fake camera: a button per event it can emit.
  Widget fakeScanner(
    BuildContext context,
    ValueChanged<String> onCode,
    ValueChanged<Object> onError,
  ) {
    scannersBuilt++;
    return Column(
      children: [
        TextButton(
          key: const Key('fake-valid'),
          onPressed: () => onCode(typicalPackage().encode()),
          child: const Text('valido'),
        ),
        TextButton(
          key: const Key('fake-junk'),
          onPressed: () => onCode('esto no es un paquete'),
          child: const Text('basura'),
        ),
        TextButton(
          key: const Key('fake-denied'),
          onPressed: () => onError(
            const MobileScannerException(
              errorCode: MobileScannerErrorCode.permissionDenied,
            ),
          ),
          child: const Text('denegado'),
        ),
        TextButton(
          key: const Key('fake-broken'),
          onPressed: () => onError(
            const MobileScannerException(
              errorCode: MobileScannerErrorCode.genericError,
            ),
          ),
          child: const Text('roto'),
        ),
      ],
    );
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: Builder(
          builder: (context) => TextButton(
            key: const Key('scan'),
            onPressed: () => scanAndImportCompanion(
              context,
              store: store,
              creation: CompanionCreation(
                store: store,
                progress: repo.progress,
                templates: repo.templates,
              ),
              scannerBuilder: fakeScanner,
            ),
            child: const Text('escanear'),
          ),
        ),
      ),
    );
    expect(scannersBuilt, 0, reason: 'nada de cámara antes de pulsar');
    await tester.tap(find.byKey(const Key('scan')));
    await tester.pumpAndSettle();
  }

  const builtIn = {'gymbro', 'enfoque', 'calma', 'diario'};
  Future<List<Companion>> saved(WidgetTester tester) async =>
      (await tester.runAsync(() => store.load()))!
          .where((c) => !builtIn.contains(c.id))
          .toList();

  testWidgets('QR válido: abre la vista previa con los campos del paquete', (
    tester,
  ) async {
    await open(tester);
    expect(scannersBuilt, greaterThan(0));
    expect(find.text('Escanear acompañante'), findsOneWidget);
    expect(find.byKey(const Key('scan-frame')), findsOneWidget);
    await tester.tap(find.byKey(const Key('fake-valid')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-external-notice')), findsOneWidget);
    final name = tester.widget<TextField>(find.byKey(const Key('import-name')));
    expect(name.controller!.text, 'Lectura');
    expect(find.byKey(const Key('import-activity')), findsOneWidget);
    expect(await saved(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('código que no es paquete: error del importador, nada guardado', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('fake-junk')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-error')), findsOneWidget);
    expect(find.byKey(const Key('import-save')), findsNothing);
    expect(await saved(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permiso denegado: mensaje y alternativa por archivo o texto', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('fake-denied')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan-error')), findsOneWidget);
    expect(find.textContaining('permiso'), findsOneWidget);
    await tester.tap(find.byKey(const Key('scan-use-file')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-paste')), findsOneWidget);
    expect(find.byKey(const Key('import-external-notice')), findsNothing);
    final paste = tester.widget<TextField>(find.byKey(const Key('import-paste')));
    expect(paste.controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin cámara u otro error: mensaje distinto del de permiso', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('fake-broken')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan-error')), findsOneWidget);
    expect(find.textContaining('No se pudo usar la cámara'), findsOneWidget);
    expect(find.byKey(const Key('scan-use-file')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detecciones repetidas se ignoran', (tester) async {
    await open(tester);
    final button = tester.widget<TextButton>(find.byKey(const Key('fake-valid')));
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-name')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
