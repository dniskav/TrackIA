import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/data/companion_memory_repository.dart';
import 'package:trackia/data/memory_google_drive.dart';
import 'package:trackia/data/memory_snapshot.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/companion_memory.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';
import 'package:trackia/ui/companion_memory.dart';

/// Transporte falso en memoria: sin Google, sin red.
class FakeTransport implements MemoryCloudTransport {
  final docs = <String, String>{};
  int reads = 0, writes = 0, deletes = 0;
  MemoryCloudWriteResult writeResult = MemoryCloudWriteResult.written;
  MemoryCloudDeleteResult deleteResult = MemoryCloudDeleteResult.deleted;

  @override
  Future<MemoryCloudDocument?> read({
    required String accountId,
    required String key,
  }) async {
    reads++;
    final payload = docs['$accountId|$key'];
    return payload == null
        ? null
        : MemoryCloudDocument(accountId: accountId, key: key, payload: payload);
  }

  @override
  Future<MemoryCloudWriteResult> write({
    required String accountId,
    required String key,
    required String payload,
    required int? expectedRevision,
  }) async {
    writes++;
    if (writeResult == MemoryCloudWriteResult.written) {
      docs['$accountId|$key'] = payload;
    }
    return writeResult;
  }

  @override
  Future<MemoryCloudDeleteResult> delete({
    required String accountId,
    required String key,
  }) async {
    deletes++;
    if (deleteResult == MemoryCloudDeleteResult.deleted) {
      docs.removeWhere((k, _) => k == '$accountId|$key');
    }
    return deleteResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late Database db;
  late CompanionMemoryRepository repo;
  late FakeTransport transport;
  final t0 = DateTime.utc(2026, 1, 1, 10);
  final companion = Companion(
    id: 'lectura',
    name: 'Lectura',
    description: '',
    prompt: '',
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('trackia-memory-ui-');
    db = await databaseFactoryFfi.openDatabase('${dir.path}/memory.sqlite');
    await db.execute('''CREATE TABLE trackia_companion_memories (
      id TEXT PRIMARY KEY, profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
      content TEXT NOT NULL, source TEXT NOT NULL,
      source_message_id TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
      revision INTEGER NOT NULL, status TEXT NOT NULL)''');
    repo = CompanionMemoryRepository(db, profileId: 'perfil-a');
    transport = FakeTransport();
    await repo.create(
      companionId: 'lectura',
      content: 'Prefiere leer por la mañana',
      source: MemorySource.explicit,
      at: t0,
      id: 'm1',
    );
    await repo.create(
      companionId: 'lectura',
      content: 'Quizá le gusta la novela negra',
      source: MemorySource.inferred,
      status: MemoryStatus.pendingConfirmation,
      at: t0.add(const Duration(minutes: 1)),
      id: 'm2',
    );
    // Otro acompañante y otro perfil: nunca deben aparecer.
    await repo.create(
      companionId: 'otro',
      content: 'Recuerdo de otro acompañante',
      source: MemorySource.explicit,
      at: t0,
      id: 'x1',
    );
    await CompanionMemoryRepository(db, profileId: 'perfil-b').create(
      companionId: 'lectura',
      content: 'Recuerdo de otro perfil',
      source: MemorySource.explicit,
      at: t0,
      id: 'x2',
    );
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(
    WidgetTester tester, {
    MemoryCloudTransport? withTransport,
    String? account,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompanionMemoryScreen(
          repository: repo,
          companion: companion,
          transport: withTransport,
          accountId: account,
          clock: () => DateTime.utc(2026, 2, 1),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  bool enabled(WidgetTester tester, String key) {
    final w = tester.widget(find.byKey(Key(key)));
    return (w as ButtonStyleButton).onPressed != null;
  }

  // sqflite ffi usa isolates: fuera de runAsync el Future nunca completa.
  Future<List<CompanionMemory>> all(WidgetTester tester) async =>
      (await tester.runAsync(
        () => repo.list(companionId: 'lectura', includeDeleted: true),
      ))!;

  testWidgets('lista solo los recuerdos del perfil y acompañante', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Prefiere leer por la mañana'), findsOneWidget);
    expect(find.text('Quizá le gusta la novela negra'), findsOneWidget);
    expect(find.textContaining('Activo'), findsOneWidget);
    expect(find.textContaining('Pendiente de confirmar'), findsOneWidget);
    expect(find.text('Recuerdo de otro acompañante'), findsNothing);
    expect(find.text('Recuerdo de otro perfil'), findsNothing);
    expect(find.byKey(const Key('memory-confirm-m1')), findsNothing);
    expect(find.byKey(const Key('memory-confirm-m2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editar guarda, valida el límite de 2000 y cancelar no cambia', (
    tester,
  ) async {
    await open(tester);
    await tapKey(tester, 'memory-edit-m1');
    await tester.enterText(find.byKey(const Key('memory-edit-field')), '   ');
    await tapKey(tester, 'memory-edit-save');
    expect(find.text('El recuerdo no puede estar vacío.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('memory-edit-field')),
      'a' * 2001,
    );
    await tapKey(tester, 'memory-edit-save');
    expect(
      find.text('El recuerdo no puede superar 2000 caracteres.'),
      findsOneWidget,
    );
    await tapKey(tester, 'memory-edit-cancel');
    expect((await all(tester)).first.content, 'Prefiere leer por la mañana');

    await tapKey(tester, 'memory-edit-m1');
    await tester.enterText(
      find.byKey(const Key('memory-edit-field')),
      'a' * 2000,
    );
    await tapKey(tester, 'memory-edit-save');
    final edited = (await all(tester)).first;
    expect(edited.content, 'a' * 2000);
    expect(edited.source, MemorySource.userEdited);
    expect(edited.revision, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmar una propuesta pendiente la activa', (tester) async {
    await open(tester);
    await tapKey(tester, 'memory-confirm-m2');
    final m2 = (await all(tester)).firstWhere((m) => m.id == 'm2');
    expect(m2.status, MemoryStatus.active);
    expect(find.byKey(const Key('memory-confirm-m2')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('borrar en local pide confirmación y no toca la nube', (
    tester,
  ) async {
    await open(tester, withTransport: transport, account: 'ana@example.com');
    await tapKey(tester, 'memory-delete-m1');
    expect(find.textContaining('No borra la copia'), findsOneWidget);
    await tapKey(tester, 'memory-dialog-cancel');
    expect((await all(tester)).first.status, MemoryStatus.active);

    await tapKey(tester, 'memory-delete-m1');
    await tapKey(tester, 'memory-dialog-confirm');
    expect((await all(tester)).first.status, MemoryStatus.deleted);
    expect(find.text('Prefiere leer por la mañana'), findsNothing);
    expect(transport.deletes + transport.writes + transport.reads, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin transporte las acciones de nube están deshabilitadas', (
    tester,
  ) async {
    await open(tester, account: 'ana@example.com');
    expect(
      find.text('Google Drive aún no está conectado en esta versión'),
      findsOneWidget,
    );
    for (final key in [
      'memory-cloud-save',
      'memory-cloud-load',
      'memory-cloud-delete',
    ]) {
      expect(enabled(tester, key), isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('con transporte pero sin cuenta siguen deshabilitadas', (
    tester,
  ) async {
    await open(tester, withTransport: transport);
    expect(find.byKey(const Key('memory-cloud-no-account')), findsOneWidget);
    expect(enabled(tester, 'memory-cloud-save'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guardar en la nube muestra cuenta y acción; cancelar no escribe', (
    tester,
  ) async {
    await open(tester, withTransport: transport, account: 'ana@example.com');
    expect(find.text('Cuenta: ana@example.com'), findsOneWidget);
    await tapKey(tester, 'memory-cloud-save');
    expect(find.textContaining('ana@example.com'), findsWidgets);
    expect(find.textContaining('Recuerdos a subir: 1'), findsOneWidget);
    await tapKey(tester, 'memory-dialog-cancel');
    expect(transport.writes, 0);

    await tapKey(tester, 'memory-cloud-save');
    await tapKey(tester, 'memory-dialog-confirm');
    expect(transport.writes, 1);
    expect(
      find.text('Copia guardada en la cuenta ana@example.com.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('memory-cloud-last')), findsOneWidget);
    // Solo se sube el activo; el pendiente no.
    final payload = transport.docs.values.single;
    expect(payload, contains('Prefiere leer por la mañana'));
    expect(payload, isNot(contains('novela negra')));
    expect((await all(tester)).length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un conflicto al guardar no sobrescribe y se informa', (
    tester,
  ) async {
    final other = MemoryGoogleDriveService(transport);
    await other.save(
      accountId: 'ana@example.com',
      snapshot: MemorySnapshot(
        profileId: 'perfil-a',
        companionId: 'lectura',
        memories: const [],
      ),
      knownRevision: null,
    );
    await open(tester, withTransport: transport, account: 'ana@example.com');
    await tapKey(tester, 'memory-cloud-save');
    await tapKey(tester, 'memory-dialog-confirm');
    expect(find.textContaining('es distinta de la última'), findsOneWidget);
    expect(transport.writes, 1); // solo la del sembrado
    expect(tester.takeException(), isNull);
  });

  testWidgets('cargar muestra vista previa; cancelar no cambia, aplicar añade', (
    tester,
  ) async {
    CompanionMemory incoming(String id, String text) => CompanionMemory(
      id: id,
      profileId: 'perfil-a',
      companionId: 'lectura',
      content: text,
      source: MemorySource.explicit,
      createdAt: t0,
      updatedAt: t0,
    );
    await MemoryGoogleDriveService(transport).save(
      accountId: 'ana@example.com',
      snapshot: MemorySnapshot(
        profileId: 'perfil-a',
        companionId: 'lectura',
        memories: [
          incoming('n1', 'Corre los domingos'),
          incoming('m1', 'Prefiere leer por la mañana'), // igual: se omite
          incoming('x9', 'prefiere leer por la mañana'), // mismo texto: omite
        ],
      ),
      knownRevision: null,
    );
    await open(tester, withTransport: transport, account: 'ana@example.com');
    await tapKey(tester, 'memory-cloud-load');
    expect(find.byKey(const Key('memory-import-preview')), findsOneWidget);
    expect(find.text('Se añadirían: 1'), findsOneWidget);
    expect(find.text('Se omiten (ya existen): 2'), findsOneWidget);
    expect(find.text('En conflicto (no se aplican): 0'), findsOneWidget);
    expect(find.text('+ Corre los domingos'), findsOneWidget);

    await tapKey(tester, 'memory-dialog-cancel');
    expect((await all(tester)).length, 2);
    expect(find.text('Carga cancelada. No se ha cambiado nada.'), findsOneWidget);

    await tapKey(tester, 'memory-cloud-load');
    await tapKey(tester, 'memory-dialog-confirm');
    final after = await all(tester);
    expect(after.length, 3);
    expect(after.any((m) => m.id == 'n1' && m.content == 'Corre los domingos'),
        isTrue);
    expect(find.text('Corre los domingos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un conflicto de contenido se muestra y no se aplica', (
    tester,
  ) async {
    await MemoryGoogleDriveService(transport).save(
      accountId: 'ana@example.com',
      snapshot: MemorySnapshot(
        profileId: 'perfil-a',
        companionId: 'lectura',
        memories: [
          CompanionMemory(
            id: 'm1',
            profileId: 'perfil-a',
            companionId: 'lectura',
            content: 'Prefiere leer por la noche',
            source: MemorySource.explicit,
            createdAt: t0,
            updatedAt: t0,
          ),
        ],
      ),
      knownRevision: null,
    );
    await open(tester, withTransport: transport, account: 'ana@example.com');
    await tapKey(tester, 'memory-cloud-load');
    expect(find.text('En conflicto (no se aplican): 1'), findsOneWidget);
    expect(find.byKey(const Key('memory-dialog-confirm')), findsNothing);
    await tapKey(tester, 'memory-dialog-cancel');
    expect((await all(tester)).first.content, 'Prefiere leer por la mañana');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cargar sin copia informa y no cambia nada', (tester) async {
    await open(tester, withTransport: transport, account: 'ana@example.com');
    await tapKey(tester, 'memory-cloud-load');
    expect(
      find.text('No hay copia en la nube para este acompañante.'),
      findsOneWidget,
    );
    expect((await all(tester)).length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('borrar en la nube: confirmación aparte, cancelar y confirmar', (
    tester,
  ) async {
    await MemoryGoogleDriveService(transport).save(
      accountId: 'ana@example.com',
      snapshot: MemorySnapshot(
        profileId: 'perfil-a',
        companionId: 'lectura',
        memories: const [],
      ),
      knownRevision: null,
    );
    await open(tester, withTransport: transport, account: 'ana@example.com');
    await tapKey(tester, 'memory-cloud-delete');
    expect(find.textContaining('No borra los recuerdos de este móvil'),
        findsOneWidget);
    await tapKey(tester, 'memory-dialog-cancel');
    expect(transport.deletes, 0);
    expect(transport.docs, isNotEmpty);

    await tapKey(tester, 'memory-cloud-delete');
    await tapKey(tester, 'memory-dialog-confirm');
    expect(transport.deletes, 1);
    expect(transport.docs, isEmpty);
    expect(find.textContaining('Copia borrada de la cuenta'), findsOneWidget);
    expect((await all(tester)).every((m) => m.status != MemoryStatus.deleted), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permiso denegado y resultado incierto se distinguen', (
    tester,
  ) async {
    transport.writeResult = MemoryCloudWriteResult.permissionDenied;
    await open(tester, withTransport: transport, account: 'ana@example.com');
    await tapKey(tester, 'memory-cloud-save');
    await tapKey(tester, 'memory-dialog-confirm');
    expect(find.text('Google no concedió el permiso. No se ha cambiado nada.'),
        findsOneWidget);
    transport.writeResult = MemoryCloudWriteResult.uncertain;
    await tapKey(tester, 'memory-cloud-save');
    await tapKey(tester, 'memory-dialog-confirm');
    expect(find.textContaining('No se pudo confirmar el resultado'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
