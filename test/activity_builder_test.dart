import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/ui/activity_builder.dart';
import 'package:gymia/ui/theme.dart';

void main() {
  ActivityBuilderResult? result;

  Future<void> open(WidgetTester tester, {String companionId = 'lectura'}) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      result = await Navigator.of(context)
                          .push<ActivityBuilderResult>(
                            MaterialPageRoute(
                              builder:
                                  (_) => ActivityBuilder(companionId: companionId),
                            ),
                          );
                    },
                    child: const Text('abrir'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  // The list is lazy: bring a far widget into the tree before using it.
  Future<void> reveal(WidgetTester tester, String key) async {
    final target = find.byKey(Key(key));
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      return;
    }
    final list = find.byType(Scrollable).first;
    try {
      await tester.scrollUntilVisible(target, 300, scrollable: list, maxScrolls: 40);
    } catch (_) {
      await tester.scrollUntilVisible(target, -300, scrollable: list, maxScrolls: 80);
    }
  }

  Future<void> fill(WidgetTester tester, String key, String text) async {
    await reveal(tester, key);
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await reveal(tester, key);
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) => tapKey(tester, 'builder-submit');

  group('rhythms', () {
    testWidgets('Puntual is a point record with no times', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Beber agua');
      await tapKey(tester, 'rhythm-instant');
      await submit(tester);
      final r = result!;
      expect(r.instant, isTrue);
      final d = r.definition;
      expect((d.repeated, d.activitySeconds, d.restSeconds), (false, null, 0));
      expect(d.companionId, 'lectura');
      expect(find.byKey(const Key('builder-duration')), findsNothing);
    });

    testWidgets('Libre has no countdown and no rest', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Leer');
      await tapKey(tester, 'rhythm-free');
      await submit(tester);
      final d = result!.definition;
      expect(result!.instant, isFalse);
      expect((d.repeated, d.activitySeconds, d.restSeconds), (false, null, 0));
    });

    testWidgets('Con duración counts down a fixed time', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Meditar');
      await tapKey(tester, 'rhythm-timed');
      await fill(tester, 'builder-duration', '20');
      await submit(tester);
      final d = result!.definition;
      expect((d.repeated, d.activitySeconds), (false, 1200));
      expect(find.byKey(const Key('builder-rest')), findsNothing);
    });

    testWidgets('Por tramos repeats with rest, goals and segment names', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Partido');
      await tapKey(tester, 'rhythm-segments');
      await fill(tester, 'builder-segments', '2');
      await fill(tester, 'builder-duration', '25');
      await fill(tester, 'builder-rest', '300');
      await fill(tester, 'builder-cycles', '3');
      await fill(tester, 'builder-segment-singular', 'tiempo');
      await fill(tester, 'builder-segment-plural', 'tiempos');
      await submit(tester);
      final d = result!.definition;
      expect(d.repeated, isTrue);
      expect((d.targetSets, d.activitySeconds, d.restSeconds, d.targetCycles), (2, 1500, 300, 3));
      expect((d.segmentSingular, d.segmentPlural), ('tiempo', 'tiempos'));
    });

    testWidgets('only the fields of the chosen rhythm are shown', (tester) async {
      await open(tester);
      for (final key in ['builder-duration', 'builder-rest', 'builder-segments', 'builder-segment-singular']) {
        expect(find.byKey(Key(key)), findsNothing, reason: 'por defecto $key');
      }
      await tapKey(tester, 'rhythm-timed');
      expect(find.byKey(const Key('builder-duration')), findsOneWidget);
      expect(find.byKey(const Key('builder-segments')), findsNothing);
      await tapKey(tester, 'rhythm-segments');
      expect(find.byKey(const Key('builder-segments')), findsOneWidget);
      expect(find.byKey(const Key('builder-rest')), findsOneWidget);
      await tapKey(tester, 'rhythm-free');
      expect(find.byKey(const Key('builder-duration')), findsNothing);
    });
  });

  group('templates', () {
    testWidgets('Pomodoro fills 25 min, 5 min rest, 4 cycles and its names', (tester) async {
      await open(tester);
      await tapKey(tester, 'template-pomodoro');
      await submit(tester);
      final d = result!.definition;
      expect(d.name, 'Pomodoro');
      expect((d.activitySeconds, d.restSeconds, d.targetCycles), (1500, 300, 4));
      expect((d.segmentSingular, d.segmentPlural), ('pomodoro', 'pomodoros'));
      expect(d.fields.single['key'], 'task');
      expect(d.fields.single['type'], 'text');
    });

    testWidgets('Fútbol is two timed periods with goals and assists', (tester) async {
      await open(tester);
      await tapKey(tester, 'template-futbol');
      await submit(tester);
      final d = result!.definition;
      expect((d.repeated, d.targetSets, d.activitySeconds, d.restSeconds), (true, 2, 1500, 300));
      expect(d.segmentSingular, 'tiempo');
      expect(d.fields.map((f) => f['key']), ['goals', 'assists']);
    });

    testWidgets('Leer is free and counts pages and distinct books', (tester) async {
      await open(tester);
      await tapKey(tester, 'template-leer');
      await submit(tester);
      final d = result!.definition;
      expect(d.repeated, isFalse);
      final pages = d.fields.firstWhere((f) => f['key'] == 'pages');
      final book = d.fields.firstWhere((f) => f['key'] == 'book');
      expect((pages['type'], pages['aggregate'], pages['unit']), ('number', 'sum', 'páginas'));
      expect((book['type'], book['aggregate'], book['countPlural']), ('text', 'distinct', 'libros'));
    });

    testWidgets('Series, Yoga and Correr give their own shape', (tester) async {
      await open(tester);
      await tapKey(tester, 'template-series');
      await submit(tester);
      var d = result!.definition;
      expect((d.repeated, d.targetSets, d.restSeconds), (true, 4, 90));
      expect(d.segmentSingular, 'serie');
      expect(d.fields.map((f) => f['key']), ['weight', 'reps']);

      await open(tester);
      await tapKey(tester, 'template-yoga');
      await submit(tester);
      d = result!.definition;
      expect((d.repeated, d.activitySeconds), (false, 3600));
      expect((d.fields.single['type'], d.fields.single['aggregate']), ('scale', 'avg'));

      await open(tester);
      await tapKey(tester, 'template-correr');
      await submit(tester);
      d = result!.definition;
      expect((d.repeated, d.activitySeconds, d.fields.single['unit']), (false, null, 'km'));
    });

    testWidgets('a template does not overwrite a name the user typed', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Mi lectura');
      await tapKey(tester, 'template-leer');
      await submit(tester);
      expect(result!.definition.name, 'Mi lectura');
      expect(result!.definition.fields.map((f) => f['key']), contains('pages'));
    });
  });

  group('validation', () {
    testWidgets('a missing name is explained in Spanish and nothing is returned', (tester) async {
      await open(tester);
      await submit(tester);
      expect(find.byKey(const Key('builder-error')), findsOneWidget);
      expect(find.textContaining('nombre'), findsWidgets);
      expect(result, isNull);
      expect(find.byType(ActivityBuilder), findsOneWidget);
    });

    testWidgets('Con duración asks for the minutes', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Meditar');
      await tapKey(tester, 'rhythm-timed');
      await submit(tester);
      expect(find.textContaining('duración'), findsWidgets);
      expect(result, isNull);
      await fill(tester, 'builder-duration', '0');
      await submit(tester);
      expect(result, isNull);
    });

    testWidgets('numbers must be whole and within limits', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Partido');
      await tapKey(tester, 'rhythm-segments');
      await fill(tester, 'builder-segments', 'dos');
      await submit(tester);
      expect(result, isNull);
      await fill(tester, 'builder-segments', '101');
      await submit(tester);
      expect(result, isNull);
      await fill(tester, 'builder-segments', '2');
      await fill(tester, 'builder-rest', '1801');
      await submit(tester);
      expect(result, isNull);
    });

    testWidgets('segment names need both singular and plural', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Partido');
      await tapKey(tester, 'rhythm-segments');
      await fill(tester, 'builder-segment-singular', 'tiempo');
      await submit(tester);
      expect(result, isNull);
      expect(find.textContaining('singular y plural'), findsOneWidget);
    });
  });

  group('fields', () {
    test('field keys come from the label, are unique and valid', () {
      expect(ActivityBuilder.fieldKeyFor('Páginas leídas', const []), 'paginas_leidas');
      expect(ActivityBuilder.fieldKeyFor('Páginas leídas', const ['paginas_leidas']), 'paginas_leidas_2');
      expect(ActivityBuilder.fieldKeyFor('12 vasos', const []), 'campo_12_vasos');
      expect(ActivityBuilder.fieldKeyFor('¿¿??', const []), 'campo');
      expect(ActivityBuilder.fieldKeyFor('x' * 80, const []).length, lessThanOrEqualTo(40));
      expect(RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(ActivityBuilder.fieldKeyFor('Ñandú ✓', const [])), isTrue);
    });

    test('only aggregates that suit the type are offered', () {
      expect(ActivityBuilder.aggregatesFor('number'), ['sum', 'max', 'avg', 'none']);
      expect(ActivityBuilder.aggregatesFor('scale'), ['avg', 'none']);
      expect(ActivityBuilder.aggregatesFor('text'), ['distinct', 'none']);
      expect(ActivityBuilder.aggregatesFor('choice'), ['distinct', 'none']);
      expect(ActivityBuilder.aggregatesFor('boolean'), ['countTrue', 'none']);
      expect(ActivityBuilder.aggregatesFor('date'), isEmpty);
    });

    testWidgets('adds a typed field through the dialog', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Leer');
      await tapKey(tester, 'builder-add-field');
      await tester.enterText(find.byKey(const Key('field-label')), 'Páginas');
      await tester.enterText(find.byKey(const Key('field-unit')), 'págs');
      await tester.tap(find.byKey(const Key('field-submit')));
      await tester.pumpAndSettle();
      await submit(tester);
      final f = result!.definition.fields.single;
      expect((f['key'], f['label'], f['unit'], f['type'], f['aggregate']), ('paginas', 'Páginas', 'págs', 'number', 'sum'));
    });

    testWidgets('the aggregate list follows the chosen type', (tester) async {
      await open(tester);
      await tapKey(tester, 'builder-add-field');
      await tester.tap(find.byKey(const Key('field-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí o no').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('field-aggregate')));
      await tester.pumpAndSettle();
      expect(find.text('Contar síes'), findsWidgets);
      expect(find.text('Sumar'), findsNothing);
    });

    testWidgets('a field can be removed', (tester) async {
      await open(tester);
      await tapKey(tester, 'template-leer');
      expect(find.byKey(const Key('field-pages')), findsOneWidget);
      await tapKey(tester, 'field-remove-pages');
      expect(find.byKey(const Key('field-pages')), findsNothing);
      await fill(tester, 'builder-name', 'Leer');
      await submit(tester);
      expect(result!.definition.fields.map((f) => f['key']), ['book']);
    });

    testWidgets('twelve fields is the limit', (tester) async {
      await open(tester);
      for (var i = 0; i < 12; i++) {
        await tapKey(tester, 'builder-add-field');
        await tester.enterText(find.byKey(const Key('field-label')), 'Campo $i');
        await tester.tap(find.byKey(const Key('field-submit')));
        await tester.pumpAndSettle();
      }
      expect(
        tester.widget<OutlinedButton>(find.byKey(const Key('builder-add-field'))).onPressed,
        isNull,
      );
    });
  });

  group('saving', () {
    testWidgets('saving as one of your activities is on by default', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Leer');
      await submit(tester);
      expect(result!.save, isTrue);
    });

    testWidgets('it can be switched off', (tester) async {
      await open(tester);
      await fill(tester, 'builder-name', 'Leer');
      await tapKey(tester, 'builder-save');
      await submit(tester);
      expect(result!.save, isFalse);
    });

    testWidgets('the point-record button says Guardar and the others Preparar', (tester) async {
      await open(tester);
      await reveal(tester, 'builder-submit');
      expect(find.text('Preparar actividad'), findsOneWidget);
      await tapKey(tester, 'rhythm-instant');
      await reveal(tester, 'builder-submit');
      expect(find.text('Guardar'), findsWidgets);
      expect(find.text('Preparar actividad'), findsNothing);
    });
  });
}
