import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/ui/activity_builder.dart';
import 'package:trackia/ui/activity_focus.dart';
import 'package:trackia/ui/instant_record.dart';
import 'package:trackia/ui/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  final health = ActivityDefinition(
    name: 'Salud',
    repeated: false,
    restSeconds: 0,
    fields: const [
      {'key': 'glasses', 'label': 'Vasos', 'unit': '', 'type': 'number'},
      {'key': 'mood', 'label': 'Ánimo', 'unit': '', 'type': 'scale'},
      {'key': 'took', 'label': '¿Lo tomaste?', 'unit': '', 'type': 'boolean'},
      {
        'key': 'where',
        'label': 'Dónde',
        'unit': '',
        'type': 'choice',
        'options': ['casa', 'trabajo'],
      },
      {'key': 'comment', 'label': 'Comentario', 'unit': '', 'type': 'text'},
      {'key': 'old', 'label': 'Antiguo', 'unit': 'u'},
    ],
  );

  group('record sheet', () {
    InstantRecordResult? result;

    Future<void> open(WidgetTester tester, ActivityDefinition definition) async {
      result = null;
      await tester.pumpWidget(
        MaterialApp(
          theme: gymTheme,
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      result = await showModalBottomSheet<InstantRecordResult>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => InstantRecordSheet(definition: definition),
                      );
                    },
                    child: const Text('abrir'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    Future<void> reveal(WidgetTester tester, String key) async {
      final f = find.byKey(Key(key));
      if (f.evaluate().isEmpty) {
        await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).last);
      }
      await tester.ensureVisible(f);
      await tester.pump();
    }

    // Real handlers instead of coordinates: the sheet is taller than the test
    // screen, so hit-testing near its edge is unreliable.
    Future<void> submit(WidgetTester tester) async {
      tester.widget<FilledButton>(find.byKey(const Key('record-submit'))).onPressed!();
      await tester.pumpAndSettle();
    }

    Future<void> choose(WidgetTester tester, String key) async {
      tester.widget<ChoiceChip>(find.byKey(Key(key))).onSelected!(true);
      await tester.pump();
    }

    testWidgets('each field type gets its own control', (tester) async {
      await open(tester, health);
      expect(find.text('Salud'), findsOneWidget);
      for (final key in [
        'record-glasses', 'record-mood-1', 'record-mood-5', 'record-took-yes',
        'record-took-no', 'record-where-casa', 'record-where-trabajo',
        'record-comment', 'record-old', 'record-note',
      ]) {
        await reveal(tester, key);
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      expect(find.byKey(const Key('record-mood-6')), findsNothing);
    });

    testWidgets('returns only what was filled, with proper types', (tester) async {
      await open(tester, health);
      await reveal(tester, 'record-glasses');
      await tester.enterText(find.byKey(const Key('record-glasses')), '2,5');
      await choose(tester, 'record-mood-4');
      await choose(tester, 'record-took-no');
      await choose(tester, 'record-where-casa');
      await reveal(tester, 'record-comment');
      await tester.enterText(find.byKey(const Key('record-comment')), 'Con limón');
      await submit(tester);
      final r = result!;
      expect(r.values, {
        'glasses': 2.5,
        'mood': 4,
        'took': false,
        'where': 'casa',
        'comment': 'Con limón',
      });
      expect(r.values.containsKey('old'), isFalse, reason: 'vacío = no anotado');
      expect(r.original, contains('Vasos'));
      expect(r.original, contains('2,5'));
    });

    testWidgets('a boolean left alone is not recorded as false', (tester) async {
      await open(tester, health);
      await reveal(tester, 'record-glasses');
      await tester.enterText(find.byKey(const Key('record-glasses')), '1');
      await submit(tester);
      expect(result!.values, {'glasses': 1});
      expect(result!.values.containsKey('took'), isFalse);
    });

    testWidgets('zero is a value', (tester) async {
      await open(tester, health);
      await reveal(tester, 'record-glasses');
      await tester.enterText(find.byKey(const Key('record-glasses')), '0');
      await submit(tester);
      expect(result!.values, {'glasses': 0});
    });

    testWidgets('a note alone is enough and becomes the original', (tester) async {
      await open(tester, health);
      await reveal(tester, 'record-note');
      await tester.enterText(find.byKey(const Key('record-note')), 'Me sentí mareado');
      await submit(tester);
      expect(result!.values, isEmpty);
      expect(result!.original, 'Me sentí mareado');
    });

    testWidgets('a note is kept as the original next to the values', (tester) async {
      await open(tester, health);
      await reveal(tester, 'record-glasses');
      await tester.enterText(find.byKey(const Key('record-glasses')), '1');
      await reveal(tester, 'record-note');
      await tester.enterText(find.byKey(const Key('record-note')), 'Tras correr');
      await submit(tester);
      expect(result!.original, 'Tras correr');
      expect(result!.values, {'glasses': 1});
    });

    testWidgets('an empty record is rejected with a Spanish message', (tester) async {
      await open(tester, health);
      await submit(tester);
      expect(result, isNull);
      expect(find.byKey(const Key('record-error')), findsOneWidget);
      expect(find.textContaining('Anota algún valor'), findsOneWidget);
    });

    testWidgets('a number that is not a number is explained', (tester) async {
      await open(tester, health);
      await reveal(tester, 'record-glasses');
      await tester.enterText(find.byKey(const Key('record-glasses')), 'mucho');
      await submit(tester);
      expect(result, isNull);
      expect(find.textContaining('Vasos'), findsWidgets);
      expect(find.byKey(const Key('record-error')), findsOneWidget);
    });

    testWidgets('closing the sheet records nothing', (tester) async {
      await open(tester, health);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

  group('from the activity bar', () {
    late Directory dir;
    late SqliteWorkoutRepository repo;
    late WorkoutController c;
    final recorded = <String>[];

    final water = ActivityDefinition(
      name: 'Beber agua',
      repeated: false,
      restSeconds: 0,
      fields: const [
        {'key': 'glasses', 'label': 'Vasos', 'unit': '', 'type': 'number'},
      ],
    );

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      recorded.clear();
      dir = await Directory.systemTemp.createTemp('trackia-instant-');
      repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/test.sqlite',
      );
      c = WorkoutController(repo);
      await c.refresh();
    });

    tearDown(() async {
      c.dispose();
      await repo.close();
      await dir.delete(recursive: true);
    });

    Future<void> show(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: gymTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActivityFocusControls(
                controller: c,
                flushInput: () async {},
                onInstantRecorded: recorded.add,
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> until(WidgetTester tester, bool Function() done) async {
      for (var i = 0; i < 200 && !done(); i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(done(), isTrue);
    }

    testWidgets('without a point template there is no Registrar button', (
      tester,
    ) async {
      await show(tester);
      expect(find.byKey(const Key('record-instant')), findsNothing);
      expect(find.byKey(const Key('new-activity')), findsOneWidget);
    });

    testWidgets('a point template adds Registrar; saving stores an observation, not an activity', (
      tester,
    ) async {
      await tester.runAsync(
        () => repo.templates.save(companionId: 'gymbro', definition: water, instant: true),
      );
      await show(tester);
      expect(find.byKey(const Key('record-instant')), findsOneWidget);
      tester.widget<OutlinedButton>(find.byKey(const Key('record-instant'))).onPressed!();
      await tester.pumpAndSettle();
      expect(find.byType(InstantRecordSheet), findsOneWidget);
      await tester.enterText(find.byKey(const Key('record-glasses')), '1');
      tester.widget<FilledButton>(find.byKey(const Key('record-submit'))).onPressed!();
      await tester.pump();
      List<Object> saved = [];
      await until(tester, () {
        unawaited(
          repo.observations.list(companionId: 'gymbro').then((v) => saved = v),
        );
        return saved.isNotEmpty;
      });
      final obs = (await tester.runAsync(
        () => repo.observations.list(companionId: 'gymbro'),
      ))!;
      expect(obs.single.values, {'glasses': 1});
      expect(obs.single.runId, isNull);
      expect(obs.single.provenance, 'user');
      expect(obs.single.definition.name, 'Beber agua');
      expect((await tester.runAsync(repo.loadActivities))!, isEmpty);
      expect(c.focus, isNull);
      await until(tester, () => recorded.isNotEmpty);
      expect(recorded.single, startsWith('Registrado:'));
      expect(recorded.single, contains('Vasos'));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with several point templates Registrar asks which one', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await repo.templates.save(companionId: 'gymbro', definition: water, instant: true);
        await repo.templates.save(
          companionId: 'gymbro',
          definition: ActivityDefinition(name: 'Pesarme', repeated: false, restSeconds: 0),
          instant: true,
        );
      });
      await show(tester);
      tester.widget<OutlinedButton>(find.byKey(const Key('record-instant'))).onPressed!();
      await tester.pumpAndSettle();
      expect(find.text('Beber agua'), findsOneWidget);
      expect(find.text('Pesarme'), findsOneWidget);
      tester.widget<ListTile>(find.widgetWithText(ListTile, 'Pesarme')).onTap!();
      await tester.pumpAndSettle();
      expect(find.byType(InstantRecordSheet), findsOneWidget);
      expect(find.text('Pesarme'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('point templates of another companion are not offered', (
      tester,
    ) async {
      await tester.runAsync(
        () => repo.templates.save(
          companionId: 'calma',
          definition: ActivityDefinition(
            name: 'Respirar', repeated: false, restSeconds: 0, companionId: 'calma',
          ),
          instant: true,
        ),
      );
      await show(tester);
      expect(find.byKey(const Key('record-instant')), findsNothing);
    });

    testWidgets('building a Puntual activity saves its shape and opens the record sheet', (
      tester,
    ) async {
      await show(tester);
      tester.widget<OutlinedButton>(find.byKey(const Key('new-activity'))).onPressed!();
      for (var i = 0; i < 100 && find.byType(ActivityChooser).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      tester.widget<ListTile>(find.widgetWithText(ListTile, 'Nueva actividad')).onTap!();
      await tester.pumpAndSettle();
      expect(find.byType(ActivityBuilder), findsOneWidget);
      await tester.enterText(find.byKey(const Key('builder-name')), 'Pesarme');
      tester.widget<ListTile>(find.byKey(const Key('rhythm-instant'))).onTap!();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('builder-submit')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      tester.widget<FilledButton>(find.byKey(const Key('builder-submit'))).onPressed!();
      await until(tester, () => find.byType(InstantRecordSheet).evaluate().isNotEmpty);
      final saved = (await tester.runAsync(
        () => repo.templates.list(companionId: 'gymbro'),
      ))!;
      expect(saved.single.definition.name, 'Pesarme');
      expect(saved.single.instant, isTrue, reason: 'un registro puntual siempre se guarda');
      expect((await tester.runAsync(repo.loadActivities))!, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('timed templates do not turn into Registrar', (tester) async {
      await tester.runAsync(
        () => repo.templates.save(
          companionId: 'gymbro',
          definition: ActivityDefinition(name: 'Leer', repeated: false, restSeconds: 0),
        ),
      );
      await show(tester);
      expect(find.byKey(const Key('record-instant')), findsNothing);
    });
  });
}
