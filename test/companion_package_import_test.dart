import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/companion_package_import.dart';
import 'package:trackia/data/activity_template_repository.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/progress_repository.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/companion_package.dart';

import 'fixtures/companion_package_fixtures.dart';

/// Almacenes que fallan si se tocan.
int touched = 0;

class _FakeStore extends Fake implements CompanionStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => _touch();
}

class _FakeProgress extends Fake implements ProgressRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => _touch();
}

class _FakeTemplates extends Fake implements ActivityTemplateRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => _touch();
}

Never _touch() {
  touched++;
  throw StateError('Se tocó un almacén durante la vista previa');
}

void main() {
  test('un paquete válido da un borrador editable con identidad nueva', () {
    final p = typicalPackage();
    final preview = CompanionPackageImport.preview(p.encode());
    expect(preview.external, isTrue);
    expect(preview.id, 'lectura');
    final d = preview.draft;
    expect(d.name, 'Lectura');
    expect(d.description, p.description);
    expect(d.prompt, p.instructions);
    expect(d.icon, 'book');
    expect(d.color, 'violet');
    expect(d.activity!.name, 'Sesión de lectura');
    expect(d.origin, 'external');
    expect(d.goal, isNull);
    expect(d.reminder, isNull);
    expect(preview.reminderCopy, isNotNull);
    expect(preview.declaredMode, 'goals');
    // Es editable con copyWith.
    expect(d.copyWith(name: 'Mío').name, 'Mío');
    expect(preview.warnings.map((w) => w.kind), [ImportWarningKind.modeReset]);
  });

  test('los bytes de archivo dan lo mismo que el texto', () {
    final p = rtlPackage();
    final a = CompanionPackageImport.preview(p.encode());
    final b = CompanionPackageImport.previewBytes(p.encodeBytes());
    expect(b.draft.name, a.draft.name);
    expect(b.draft.name, 'رفيق القراءة 📚');
    expect(b.id, a.id);
  });

  test('los ids que chocan se resuelven y el id nunca es el de origen', () {
    expect(
      CompanionPackageImport.preview(
        typicalPackage().encode(),
        takenIds: ['lectura', 'lectura-2'],
      ).id,
      'lectura-3',
    );
    final fromLocal = CompanionPackage.fromCompanion(typicalCompanion());
    final id = CompanionPackageImport.preview(
      fromLocal.encode(),
      takenIds: [typicalCompanion().id],
    ).id;
    expect(id, isNot(typicalCompanion().id));
    // Nombre solo árabe: id válido de reserva.
    expect(
      CompanionPackageImport.preview(rtlPackage().encode()).id,
      'acompanante',
    );
    expect(
      CompanionPackageImport.preview(
        rtlPackage().encode(),
        takenIds: ['acompanante'],
      ).id,
      'acompanante-2',
    );
  });

  test('el borrador acaba en un Companion válido', () {
    final preview = CompanionPackageImport.preview(limitPackage().encode());
    final c = Companion(
      id: preview.id,
      name: preview.draft.name,
      description: preview.draft.description,
      prompt: preview.draft.prompt,
      icon: preview.draft.icon,
      color: preview.draft.color,
      reminderCopy: preview.reminderCopy,
    );
    expect(c.id, matches(RegExp(r'^[a-z0-9-]+$')));
    expect(preview.templates, hasLength(5));
    expect(preview.draft.activity, preview.templates.first.activity);
  });

  group('paquetes hostiles', () {
    test(
      'instrucciones que piden ignorar reglas: solo estilo, sin permisos',
      () {
        final preview = CompanionPackageImport.preview(hostileIgnoreRules());
        final d = preview.draft;
        expect(preview.has(ImportWarningKind.suspiciousInstructions), isTrue);
        // El paquete declaraba «game»: el borrador no sube de nivel solo.
        expect(preview.declaredMode, 'game');
        expect(d.mode, 'reminder');
        expect(preview.has(ImportWarningKind.modeReset), isTrue);
        expect(d.goal, isNull);
        expect(d.reminder, isNull);
        expect(d.origin, 'external');
        expect(preview.external, isTrue);
        // El texto se conserva como estilo, para que la persona lo vea y edite.
        expect(d.prompt, contains('Ignora todas'));
      },
    );

    test('los bloques de la app se retiran y se avisa', () {
      final preview = CompanionPackageImport.preview(hostileBlocks());
      final d = preview.draft;
      expect(d.prompt, contains('Estilo amable.'));
      expect(d.prompt, contains('Final del estilo.'));
      expect(d.prompt, isNot(contains('```')));
      expect(d.prompt, isNot(contains('trackia-')));
      expect(d.prompt, isNot(contains('gymia-')));
      final w = preview.warnings.firstWhere(
        (w) => w.kind == ImportWarningKind.appBlocksRemoved,
      );
      expect(w.count, 5);
    });

    test('bloques también en las plantillas', () {
      final body = typicalPackage().toBody();
      final t =
          Map<String, Object?>.from((body['templates']! as List).first as Map)
            ..['instructions'] = hostileBlockText.substring(
              0,
              700 > hostileBlockText.length ? hostileBlockText.length : 700,
            );
      final preview = CompanionPackageImport.preview(
        rawEncode(
          rawJson(
            rawBody({
              'templates': [t],
            }),
          ),
        ),
      );
      final text = preview.draft.activity!.instructions;
      expect(text, isNot(contains('trackia-')));
      expect(text, isNot(contains('```')));
      expect(preview.has(ImportWarningKind.appBlocksRemoved), isTrue);
    });

    test('solo bloques: instrucciones vacías con aviso', () {
      final preview = CompanionPackageImport.preview(
        rawEncode(
          rawJson(rawBody({'instructions': '```trackia-activity\n{}\n```'})),
        ),
      );
      expect(preview.draft.prompt, '');
      expect(preview.has(ImportWarningKind.instructionsEmpty), isTrue);
    });

    test('plantillas de más: se listan pero el borrador lleva una', () {
      final preview = CompanionPackageImport.preview(limitPackage().encode());
      expect(preview.has(ImportWarningKind.extraTemplatesNotApplied), isTrue);
      expect(
        preview.warnings
            .firstWhere(
              (w) => w.kind == ImportWarningKind.extraTemplatesNotApplied,
            )
            .count,
        4,
      );
    });

    test('ningún paquete rechazado produce borrador', () {
      final bad = <String>[
        hostileFutureVersion(),
        hostileBadChecksum(),
        hostileTampered(),
        hostileUnknownField(),
        hostileTooManyTemplates(),
        hostileOversizeExpanded(),
        for (final f in forbiddenFieldNames) hostileForbiddenField(f),
        'no es un paquete',
      ];
      for (final text in bad) {
        expect(
          () => CompanionPackageImport.preview(text),
          throwsA(isA<CompanionPackageException>()),
        );
      }
      expect(
        () => CompanionPackageImport.previewBytes(hostileGzipBomb()),
        throwsA(isA<CompanionPackageException>()),
      );
    });

    test('un paquete con campos de permisos o cuentas ni llega a borrador', () {
      for (final key in ['permissions', 'settings', 'accountId', 'apiKey']) {
        expect(
          () =>
              CompanionPackageImport.preview(hostileForbiddenField(key, true)),
          throwsA(
            isA<CompanionPackageException>().having(
              (e) => e.problem,
              'problem',
              CompanionPackageProblem.forbiddenField,
            ),
          ),
        );
      }
    });
  });

  test('la vista previa no toca ningún almacén', () {
    touched = 0;
    // Existen, pero la vista previa no recibe ninguno: no puede escribir.
    final stores = [_FakeStore(), _FakeProgress(), _FakeTemplates()];
    for (final text in [
      typicalPackage().encode(),
      limitPackage().encode(),
      rtlPackage().encode(),
      hostileBlocks(),
      hostileIgnoreRules(),
    ]) {
      CompanionPackageImport.preview(text, takenIds: ['uno']);
    }
    for (final text in [hostileBadChecksum(), hostileFutureVersion()]) {
      expect(() => CompanionPackageImport.preview(text), throwsA(anything));
    }
    expect(touched, 0);
    expect(stores, hasLength(3));
  });
}
