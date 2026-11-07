import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/domain/block_names.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/companion_package.dart';

import 'fixtures/companion_package_fixtures.dart';

void expectProblem(void Function() body, CompanionPackageProblem problem) {
  try {
    body();
  } on CompanionPackageException catch (e) {
    expect(e.problem, problem, reason: e.message);
    expect(e.message, isNotEmpty);
    return;
  }
  fail('Se esperaba $problem y no hubo error');
}

void main() {
  group('ida y vuelta', () {
    test('típico, límite y RTL vuelven iguales', () {
      for (final p in [typicalPackage(), limitPackage(), rtlPackage()]) {
        final text = p.encode();
        expect(text, isNot(contains('=')));
        expect(CompanionPackage.decode(text), p);
        expect(CompanionPackage.decodeBytes(p.encodeBytes()), p);
        expect(CompanionPackage.decodeBytes(utf8.encode(text)), p);
        // El texto con relleno y espacios también vale.
        expect(CompanionPackage.decode('  $text\n'), p);
      }
    });

    test('el típico cabe en un QR y el del límite no', () {
      expect(CompanionPackage.fitsInQr(typicalPackage().encode()), isTrue);
      expect(CompanionPackage.fitsInQr(limitPackage().encode()), isFalse);
    });

    test('la forma canónica y el checksum son estables', () {
      final a = typicalPackage();
      expect(a.toCanonicalJson(), typicalPackage().toCanonicalJson());
      final json = jsonDecode(a.toCanonicalJson()) as Map<String, dynamic>;
      expect(json['format'], 'trackia-companion/1');
      expect(json['checksum'], matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(json['checksum'], CompanionPackage.checksumOf(a.toBody()));
      // Claves ordenadas y sin espacios.
      expect(a.toCanonicalJson(), startsWith('{"checksum":"'));
      expect(a.toCanonicalJson(), isNot(contains(': ')));
    });

    test('Unicode y RTL llegan intactos', () {
      final back = CompanionPackage.decode(rtlPackage().encode());
      expect(back.name, 'رفيق القراءة 📚');
      expect(back.instructions, contains('‏'));
      expect(back.instructions, contains('👨‍👩‍👧‍👦'));
      expect(back.templates.single.activity.name, 'جلسة قراءة 📖');
      expect(back.reminders!.windowStart.single, 'حان وقت القراءة 📚');
    });
  });

  group('campos prohibidos', () {
    test('el exportador solo emite la lista permitida', () {
      final p = CompanionPackage.fromCompanion(
        typicalCompanion(),
        mode: 'goals',
        templates: typicalPackage().templates,
      );
      final json = jsonDecode(p.toCanonicalJson()) as Map<String, dynamic>;
      expect(json.keys.toSet(), {
        ...CompanionPackage.allowedKeys,
        'format',
        'checksum',
      });
      final all = p.toCanonicalJson();
      // La identidad local (id del acompañante, origen, claves) no sale.
      expect(all, isNot(contains('lectura-2')));
      expect(all, isNot(contains('companionId')));
      expect(all, isNot(contains('"origin"')));
      expect(all, isNot(contains('userSet')));
      expect(all, isNot(contains('activityKey')));
      expect(all, isNot(contains('completedCycles')));
      final template = (json['templates'] as List).single as Map;
      expect(
        template.keys.toSet().difference({
          'name',
          'repeated',
          'restSeconds',
          'activitySeconds',
          'targetSets',
          'targetCycles',
          'fields',
          'instructions',
          'segmentSingular',
          'segmentPlural',
          'instant',
        }),
        isEmpty,
      );
    });

    test('ningún campo prohibido se acepta aunque la firma sea válida', () {
      for (final name in forbiddenFieldNames) {
        expectProblem(
          () => CompanionPackage.decode(hostileForbiddenField(name)),
          CompanionPackageProblem.forbiddenField,
        );
      }
    });

    test('un campo desconocido se rechaza', () {
      expectProblem(
        () => CompanionPackage.decode(hostileUnknownField()),
        CompanionPackageProblem.unknownField,
      );
    });

    test('campos extra dentro de plantillas y de campos de plantilla', () {
      final body = typicalPackage().toBody();
      final t = Map<String, Object?>.from(
        (body['templates']! as List).first as Map,
      );
      expectProblem(
        () => CompanionPackage.decode(
          rawEncode(
            rawJson(
              rawBody({
                'templates': [
                  {...t, 'companionId': 'x'},
                ],
              }),
            ),
          ),
        ),
        CompanionPackageProblem.unknownField,
      );
      final f = Map<String, Object?>.from(
        ((t['fields']! as List).first) as Map,
      );
      expectProblem(
        () => CompanionPackage.decode(
          rawEncode(
            rawJson(
              rawBody({
                'templates': [
                  {
                    ...t,
                    'fields': [
                      {...f, 'apiKey': 'x'},
                    ],
                  },
                ],
              }),
            ),
          ),
        ),
        CompanionPackageProblem.invalidField,
      );
    });

    test('faltan campos', () {
      expectProblem(
        () => CompanionPackage.decode(
          rawEncode(rawJson(rawBody({}, remove: {'instructions'}))),
        ),
        CompanionPackageProblem.missingField,
      );
    });
  });

  group('versión e integridad', () {
    test('versión futura rechazada con mensaje claro', () {
      try {
        CompanionPackage.decode(hostileFutureVersion());
        fail('debía fallar');
      } on CompanionPackageException catch (e) {
        expect(e.problem, CompanionPackageProblem.unsupportedVersion);
        expect(e.message, contains('trackia-companion/2'));
        expect(e.message, contains('Actualiza'));
      }
    });

    test('formatos que no son de TrackIA', () {
      for (final format in [
        'otra-cosa/1',
        'trackia-companion/',
        '',
        'trackia-companion/1.5',
      ]) {
        expectProblem(
          () => CompanionPackage.decode(
            rawEncode(rawJson(rawBody({}), format: format)),
          ),
          CompanionPackageProblem.notAPackage,
        );
      }
      expectProblem(
        () => CompanionPackage.decode(rawEncode({'hola': 1})),
        CompanionPackageProblem.notAPackage,
      );
    });

    test('checksum roto o contenido alterado', () {
      expectProblem(
        () => CompanionPackage.decode(hostileBadChecksum()),
        CompanionPackageProblem.checksumMismatch,
      );
      expectProblem(
        () => CompanionPackage.decode(hostileTampered()),
        CompanionPackageProblem.checksumMismatch,
      );
    });
  });

  group('límites', () {
    test('en el límite pasa', () {
      final p = limitPackage();
      expect(p.name.length, CompanionPackageLimits.nameChars);
      expect(p.instructions.length, CompanionPackageLimits.instructionsChars);
      expect(p.templates, hasLength(CompanionPackageLimits.maxTemplates));
      expect(CompanionPackage.decode(p.encode()), p);
      expect(
        utf8.encode(p.toCanonicalJson()).length,
        lessThan(CompanionPackageLimits.maxJsonBytes),
      );
      expect(
        p.encodeBytes().length,
        lessThan(CompanionPackageLimits.maxCompressedBytes),
      );
    });

    test('por encima se rechaza al construir y al decodificar', () {
      for (final field in ['name', 'description', 'instructions']) {
        expectProblem(
          () => CompanionPackage.decode(hostileTooLong(field)),
          CompanionPackageProblem.invalidField,
        );
      }
      expectProblem(
        () => CompanionPackage.decode(hostileTooManyTemplates()),
        CompanionPackageProblem.invalidField,
      );
      expectProblem(
        () => CompanionPackage(
          name: 'x' * (CompanionPackageLimits.nameChars + 1),
          icon: 'book',
          color: 'teal',
        ),
        CompanionPackageProblem.invalidField,
      );
      expectProblem(
        () => CompanionPackage(
          name: 'x',
          icon: 'book',
          color: 'teal',
          instructions: 'x' * (CompanionPackageLimits.instructionsChars + 1),
        ),
        CompanionPackageProblem.invalidField,
      );
    });

    test(
      'exportar un acompañante con instrucciones demasiado largas falla',
      () {
        final c = Companion(
          id: 'largo',
          name: 'Largo',
          description: '',
          prompt: 'x' * (CompanionPackageLimits.instructionsChars + 1),
        );
        expectProblem(
          () => CompanionPackage.fromCompanion(c),
          CompanionPackageProblem.invalidField,
        );
      },
    );

    test('textos de aviso: máximo por lista y por texto', () {
      final body = typicalPackage().toBody();
      expectProblem(
        () => CompanionPackage.decode(
          rawEncode(
            rawJson(
              rawBody({
                'reminders': {
                  ...(body['reminders']! as Map),
                  'inactive': List.filled(6, 'hola'),
                },
              }),
            ),
          ),
        ),
        CompanionPackageProblem.invalidField,
      );
      expectProblem(
        () => CompanionPackage.decode(
          rawEncode(
            rawJson(
              rawBody({
                'reminders': {
                  ...(body['reminders']! as Map),
                  'lastCall': [
                    noise(CompanionPackageLimits.reminderTextChars + 1),
                  ],
                },
              }),
            ),
          ),
        ),
        CompanionPackageProblem.invalidField,
      );
    });

    test('icono, color y modo fuera de catálogo', () {
      for (final f in ['icon', 'color', 'mode']) {
        expectProblem(
          () => CompanionPackage.decode(hostileBadCatalog(f)),
          CompanionPackageProblem.invalidField,
        );
      }
    });

    test('tipos incorrectos', () {
      for (final bad in [
        {'name': 5},
        {'templates': 'no'},
        {
          'templates': [5],
        },
        {'reminders': []},
        {'mode': null},
      ]) {
        expectProblem(
          () => CompanionPackage.decode(rawEncode(rawJson(rawBody(bad)))),
          CompanionPackageProblem.invalidField,
        );
      }
    });

    test('caracteres de control y saltos de línea en el nombre', () {
      for (final name in ['a\u0000b', 'a\nb']) {
        expectProblem(
          () => CompanionPackage.decode(
            rawEncode(rawJson(rawBody({'name': name}))),
          ),
          CompanionPackageProblem.invalidField,
        );
      }
    });

    test('tamaño: texto, comprimido y expandido', () {
      expectProblem(
        () => CompanionPackage.decode(
          'A' * (CompanionPackageLimits.maxEncodedChars + 1),
        ),
        CompanionPackageProblem.tooLarge,
      );
      expectProblem(
        () => CompanionPackage.decodeBytes([
          0x1f,
          0x8b,
          ...List.filled(CompanionPackageLimits.maxCompressedBytes + 1, 1),
        ]),
        CompanionPackageProblem.tooLarge,
      );
      expectProblem(
        () => CompanionPackage.decode(hostileOversizeExpanded()),
        CompanionPackageProblem.tooLargeExpanded,
      );
    });
  });

  group('entrada dañada', () {
    test('vacío', () {
      expectProblem(
        () => CompanionPackage.decode('  '),
        CompanionPackageProblem.empty,
      );
      expectProblem(
        () => CompanionPackage.decodeBytes([]),
        CompanionPackageProblem.empty,
      );
    });

    test('base64 inválido', () {
      for (final text in ['no es base64!', 'abc*def', 'a=b=', 'ñandú']) {
        expectProblem(
          () => CompanionPackage.decode(text),
          CompanionPackageProblem.badEncoding,
        );
      }
    });

    test('base64 válido pero no es gzip', () {
      expectProblem(
        () => CompanionPackage.decode(
          base64Url.encode(utf8.encode('hola mundo')),
        ),
        CompanionPackageProblem.badCompression,
      );
      // Cabecera gzip con cuerpo truncado.
      final good = typicalPackage().encodeBytes();
      expectProblem(
        () => CompanionPackage.decodeBytes(good.sublist(0, good.length ~/ 2)),
        CompanionPackageProblem.badCompression,
      );
    });

    test('JSON mal formado, o que no es un objeto', () {
      expectProblem(
        () => CompanionPackage.decodeBytes(rawGzip('{"format": ')),
        CompanionPackageProblem.malformed,
      );
      expectProblem(
        () => CompanionPackage.decodeBytes(rawGzip('[1,2,3]')),
        CompanionPackageProblem.malformed,
      );
      expectProblem(
        () => CompanionPackage.decodeBytes(rawGzip('"texto"')),
        CompanionPackageProblem.malformed,
      );
    });

    test('UTF-8 inválido', () {
      expectProblem(
        () => CompanionPackage.decodeBytes(
          Uint8List.fromList(gzip.encode([0x7b, 0xff, 0xfe, 0x7d])),
        ),
        CompanionPackageProblem.badEncoding,
      );
    });

    test('anidamiento profundo no revienta', () {
      final deep = '[' * 30000 + ']' * 30000;
      expectProblem(
        () => CompanionPackage.decodeBytes(rawGzip(deep)),
        CompanionPackageProblem.malformed,
      );
    });

    test('bomba de compresión: se corta sin expandir sin límite', () {
      final bomb = hostileGzipBomb();
      expect(
        bomb.length,
        lessThanOrEqualTo(CompanionPackageLimits.maxCompressedBytes),
      );
      final watch = Stopwatch()..start();
      expectProblem(
        () => CompanionPackage.decodeBytes(bomb),
        CompanionPackageProblem.tooLargeExpanded,
      );
      expectProblem(
        () => CompanionPackage.decode(base64Url.encode(bomb)),
        CompanionPackageProblem.tooLargeExpanded,
      );
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });

  group('bloques de la app', () {
    test('se retiran todas las variantes, también con espacio', () {
      final r = CompanionPackage.stripAppBlocks(hostileBlockText);
      expect(r.removed, 5);
      expect(r.text, contains('Estilo amable.'));
      expect(r.text, contains('Entre medias.'));
      expect(r.text, contains('Final del estilo.'));
      expect(r.text, isNot(contains('```')));
      expect(hiddenBlockPattern.hasMatch(r.text), isFalse);
      for (final kind in [
        'activity',
        'sheet-plan',
        'result',
        'recall',
        'sync',
      ]) {
        expect(hasBlock(r.text, kind), isFalse);
        expect(blockPattern(kind).hasMatch(r.text), isFalse);
      }
    });

    test('un bloque dentro de otro no deja uno formado', () {
      const nested =
          '````trackia-x\n``trackia-activity\n{}\n```trackia-activity\n{}\n```';
      final r = CompanionPackage.stripAppBlocks(nested);
      expect(
        RegExp(r'(trackia|gymia)-', caseSensitive: false).hasMatch(r.text) &&
            RegExp(
              '```[ \\t]*(trackia|gymia)-',
              caseSensitive: false,
            ).hasMatch(r.text),
        isFalse,
      );
      // Mayúsculas.
      final upper = CompanionPackage.stripAppBlocks(
        '```TrackIA-Activity\n{}\n```ok',
      );
      expect(upper.text, 'ok');
    });

    test('el texto normal y otros bloques de código se conservan', () {
      const text =
          'Usa ```python\nprint(1)\n``` y habla de trackia sin bloque.';
      final r = CompanionPackage.stripAppBlocks(text);
      expect(r.removed, 0);
      expect(r.text, text);
    });

    test('el exportador los retira de instrucciones y plantillas', () {
      final c = Companion(
        id: 'hostil',
        name: 'Hostil',
        description: '',
        prompt: hostileBlockText,
      );
      final p = CompanionPackage.fromCompanion(
        c,
        templates: [
          PackageTemplate(
            activity: templateOf('Plantilla', instructions: hostileBlockText),
          ),
        ],
      );
      expect(p.instructions, isNot(contains('trackia-')));
      expect(p.instructions, isNot(contains('gymia-')));
      expect(p.templates.single.activity.instructions, isNot(contains('```')));
      expect(p.instructions, contains('Estilo amable.'));
      final back = CompanionPackage.decode(p.encode());
      expect(back, p);
    });

    test('un paquete hostil se decodifica tal cual (se sanea al importar)', () {
      final p = CompanionPackage.decode(hostileBlocks());
      expect(p.instructions, contains('trackia-activity'));
      final p2 = CompanionPackage.decode(hostileIgnoreRules());
      expect(p2.instructions, contains('Ignora todas'));
    });
  });
}
