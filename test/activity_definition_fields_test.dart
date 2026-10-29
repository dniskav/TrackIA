import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/domain/activity.dart';
import 'package:gymia/domain/workout.dart';

// JSON written by the app before typed fields existed (captured 2026-10-29).
const _legacyStrength =
    '{"name":"Press banca","repeated":true,"restSeconds":120,"activitySeconds":45,"targetSets":4,"targetCycles":2,"completedCycles":0,"fields":[{"key":"weight_kg","label":"Peso","unit":"kg"},{"key":"reps","label":"Reps","unit":""}],"instructions":"Controla la bajada.","origin":"user","companionId":"gymbro"}';
const _legacyContinuous =
    '{"name":"Movilidad","repeated":false,"restSeconds":0,"completedCycles":0,"fields":[],"instructions":"","origin":"user","companionId":"gymbro"}';

ActivityDefinition _build({
  List<Map<String, Object>> fields = const [],
  String name = 'Leer',
  String? segmentSingular,
  String? segmentPlural,
  List<String> userSet = const [],
  String? activityKey,
}) => ActivityDefinition(
  name: name,
  repeated: false,
  restSeconds: 0,
  fields: fields,
  segmentSingular: segmentSingular,
  segmentPlural: segmentPlural,
  userSet: userSet,
  activityKey: activityKey,
);

Matcher get _invalid => throwsA(isA<ValidationException>());

void main() {
  group('definitions saved before typed fields', () {
    test('load and serialize to exactly the same JSON', () {
      for (final source in [_legacyStrength, _legacyContinuous]) {
        final loaded = ActivityDefinition.fromJson(
          jsonDecode(source) as Map<String, dynamic>,
        );
        expect(jsonEncode(loaded.toJson()), source);
      }
    });

    test('their fields are notes only: no type, no aggregate', () {
      final loaded = ActivityDefinition.fromJson(
        jsonDecode(_legacyStrength) as Map<String, dynamic>,
      );
      expect(loaded.fields.every((f) => !f.containsKey('type')), isTrue);
      expect(loaded.fields.every((f) => !f.containsKey('aggregate')), isTrue);
      expect(loaded.userSet, isEmpty);
      expect(loaded.segmentSingular, isNull);
    });

    test('forCompanion keeps the exact legacy shape', () {
      final loaded = ActivityDefinition.fromJson(
        jsonDecode(_legacyContinuous) as Map<String, dynamic>,
      );
      expect(
        jsonEncode(loaded.forCompanion('gymbro').toJson()),
        _legacyContinuous,
      );
    });
  });

  group('typed fields', () {
    Map<String, Object> field(String type, {Map<String, Object> extra = const {}}) => {
      'key': 'k',
      'label': 'Campo',
      'unit': '',
      'type': type,
      ...extra,
    };

    test('every type gets its default way of counting', () {
      const expected = {
        'number': 'sum',
        'scale': 'avg',
        'text': 'none',
        'choice': 'distinct',
        'boolean': 'countTrue',
      };
      for (final entry in expected.entries) {
        final f = _build(
          fields: [
            field(
              entry.key,
              extra: entry.key == 'choice' ? {'options': ['a', 'b']} : {},
            ),
          ],
        ).fields.single;
        expect(f['aggregate'], entry.value, reason: entry.key);
      }
    });

    test('aggregate must suit the type', () {
      const allowed = {
        'number': ['sum', 'max', 'avg', 'none'],
        'scale': ['avg', 'none'],
        'text': ['distinct', 'none'],
        'boolean': ['countTrue', 'none'],
      };
      for (final entry in allowed.entries) {
        for (final aggregate in [
          'sum', 'max', 'avg', 'distinct', 'countTrue', 'none',
        ]) {
          ActivityDefinition build() => _build(
            fields: [field(entry.key, extra: {'aggregate': aggregate})],
          );
          if (entry.value.contains(aggregate)) {
            expect(build().fields.single['aggregate'], aggregate);
          } else {
            expect(build, _invalid, reason: '${entry.key}/$aggregate');
          }
        }
      }
    });

    test('unknown types and aggregates are rejected', () {
      expect(() => _build(fields: [field('date')]), _invalid);
      expect(
        () => _build(fields: [field('number', extra: {'aggregate': 'median'})]),
        _invalid,
      );
    });

    test('extra attributes without a type are rejected', () {
      final bare = {'key': 'k', 'label': 'Campo', 'unit': ''};
      for (final extra in [
        {'aggregate': 'sum'},
        {'options': ['a']},
        {'min': 1},
        {'countSingular': 'libro'},
      ]) {
        expect(() => _build(fields: [{...bare, ...extra}]), _invalid, reason: '$extra');
      }
    });

    test('choice needs 1 to 20 unique options of 1 to 40 characters', () {
      expect(() => _build(fields: [field('choice')]), _invalid);
      expect(() => _build(fields: [field('choice', extra: {'options': <String>[]})]), _invalid);
      expect(() => _build(fields: [field('choice', extra: {'options': ['a', 'a']})]), _invalid);
      expect(() => _build(fields: [field('choice', extra: {'options': ['']})]), _invalid);
      expect(
        () => _build(fields: [field('choice', extra: {'options': ['x' * 41]})]),
        _invalid,
      );
      expect(
        () => _build(
          fields: [field('choice', extra: {'options': [for (var i = 0; i < 21; i++) 'o$i']})],
        ),
        _invalid,
      );
      expect(
        _build(
          fields: [field('choice', extra: {'options': [for (var i = 0; i < 20; i++) 'o$i']})],
        ).fields.single['options'],
        hasLength(20),
      );
      expect(() => _build(fields: [field('text', extra: {'options': ['a']})]), _invalid);
    });

    test('scale limits default to 1–5 and must satisfy 1 ≤ min < max ≤ 10', () {
      final f = _build(fields: [field('scale')]).fields.single;
      expect((f['min'], f['max']), (1, 5));
      expect(_build(fields: [field('scale', extra: {'min': 1, 'max': 10})]).fields.single['max'], 10);
      for (final bad in [
        {'min': 0, 'max': 5},
        {'min': 5, 'max': 5},
        {'min': 6, 'max': 5},
        {'min': 1, 'max': 11},
        {'min': 1.5, 'max': 5},
      ]) {
        expect(() => _build(fields: [field('scale', extra: bad)]), _invalid, reason: '$bad');
      }
      expect(() => _build(fields: [field('number', extra: {'min': 1})]), _invalid);
    });

    test('count names are optional texts of 1 to 40 characters', () {
      final f = _build(
        fields: [
          field('boolean', extra: {'countSingular': 'libro terminado', 'countPlural': 'libros terminados'}),
        ],
      ).fields.single;
      expect(f['countPlural'], 'libros terminados');
      expect(() => _build(fields: [field('boolean', extra: {'countSingular': ''})]), _invalid);
      expect(() => _build(fields: [field('boolean', extra: {'countPlural': 'x' * 41})]), _invalid);
    });

    test('typed fields survive a JSON round trip unchanged', () {
      final built = _build(
        fields: [
          field('number', extra: {'unit': 'páginas'}),
          {...field('choice', extra: {'options': ['bien', 'mal']}), 'key': 'mood', 'label': 'Ánimo'},
        ],
      );
      final again = ActivityDefinition.fromJson(
        jsonDecode(jsonEncode(built.toJson())) as Map<String, dynamic>,
      );
      expect(jsonEncode(again.toJson()), jsonEncode(built.toJson()));
    });

    test('at most 12 fields with unique keys, as before', () {
      expect(
        () => _build(fields: [
          for (var i = 0; i < 13; i++)
            {'key': 'k$i', 'label': 'L', 'unit': '', 'type': 'number'},
        ]),
        _invalid,
      );
      expect(
        () => _build(fields: [field('number'), field('text')]),
        _invalid,
        reason: 'misma clave',
      );
    });
  });

  group('segment names', () {
    test('need singular and plural of 1 to 24 characters together', () {
      final d = _build(segmentSingular: 'pomodoro', segmentPlural: 'pomodoros');
      expect((d.segmentSingular, d.segmentPlural), ('pomodoro', 'pomodoros'));
      expect(() => _build(segmentSingular: 'tiempo'), _invalid);
      expect(() => _build(segmentPlural: 'tiempos'), _invalid);
      expect(() => _build(segmentSingular: '', segmentPlural: 'x'), _invalid);
      expect(
        () => _build(segmentSingular: 'x' * 25, segmentPlural: 'y'),
        _invalid,
      );
    });

    test('are written only when set', () {
      expect(_build().toJson().containsKey('segmentSingular'), isFalse);
      expect(
        _build(segmentSingular: 'serie', segmentPlural: 'series').toJson()['segmentPlural'],
        'series',
      );
    });
  });

  group('locks (userSet)', () {
    test('accept the editable properties and existing fields', () {
      final d = _build(
        fields: [
          {'key': 'pages', 'label': 'Páginas', 'unit': '', 'type': 'number'},
        ],
        userSet: ['name', 'restSeconds', 'field:pages'],
      );
      expect(d.userSet, ['name', 'restSeconds', 'field:pages']);
    });

    test('reject unknown names, missing fields and duplicates', () {
      expect(() => _build(userSet: ['origin']), _invalid);
      expect(() => _build(userSet: ['field:nope']), _invalid);
      expect(() => _build(userSet: ['name', 'name']), _invalid);
    });

    test('are written only when not empty', () {
      expect(_build().toJson().containsKey('userSet'), isFalse);
      expect(_build(userSet: ['name']).toJson()['userSet'], ['name']);
    });
  });

  group('activity key', () {
    test('is derived from the name and ignores case and extra spaces', () {
      expect(_build(name: '  Leer   Mucho ').activityKey, 'leer mucho');
      expect(_build(name: 'LEER MUCHO').activityKey, 'leer mucho');
    });

    test('is written only when it was set explicitly', () {
      expect(_build().toJson().containsKey('activityKey'), isFalse);
      final fixed = _build(name: 'Nuevo nombre', activityKey: 'leer');
      expect(fixed.activityKey, 'leer');
      expect(fixed.toJson()['activityKey'], 'leer');
    });
  });

  group('assistant proposals', () {
    ActivityDefinition? parse(Map<String, Object?> json) =>
        ActivityDefinition.proposal('```gymia-activity\n${jsonEncode(json)}\n```');

    final base = {'name': 'Leer', 'repeated': false, 'restSeconds': 0, 'fields': <Object>[]};

    test('accept typed fields and segment names', () {
      final d = parse({
        ...base,
        'segmentSingular': 'tiempo',
        'segmentPlural': 'tiempos',
        'fields': [
          {'key': 'pages', 'label': 'Páginas', 'unit': 'págs', 'type': 'number', 'aggregate': 'sum'},
        ],
      });
      expect(d, isNotNull);
      expect(d!.segmentPlural, 'tiempos');
      expect(d.fields.single['type'], 'number');
      expect(d.origin, 'llm');
    });

    test('never accept locks or the activity key from the model', () {
      expect(parse({...base, 'userSet': ['name']}), isNull);
      expect(parse({...base, 'activityKey': 'otra'}), isNull);
    });

    test('still reject unknown keys and invalid typed fields', () {
      expect(parse({...base, 'color': 'rojo'}), isNull);
      expect(
        parse({
          ...base,
          'fields': [
            {'key': 'k', 'label': 'L', 'unit': '', 'type': 'number', 'aggregate': 'distinct'},
          ],
        }),
        isNull,
      );
    });
  });
}
