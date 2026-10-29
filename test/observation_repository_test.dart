import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/data/observation_repository.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/domain/activity.dart';
import 'package:gymia/domain/observation.dart';
import 'package:gymia/domain/workout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late String path;
  late SqliteWorkoutRepository repo;
  late ObservationRepository store;
  var now = DateTime(2026, 10, 29, 9);

  final water = ActivityDefinition(
    name: 'Beber agua',
    repeated: false,
    restSeconds: 0,
    companionId: 'salud',
    fields: const [
      {'key': 'glasses', 'label': 'Vasos', 'unit': '', 'type': 'number'},
      {'key': 'mood', 'label': 'Ánimo', 'unit': '', 'type': 'scale'},
    ],
  );

  setUp(() async {
    now = DateTime(2026, 10, 29, 9);
    dir = await Directory.systemTemp.createTemp('trackia-observations-');
    path = '${dir.path}/test.sqlite';
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: path,
      clock: () => now,
    );
    store = repo.observations;
  });

  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  test('records a point value with its original, provenance and local day', () async {
    final saved = await store.record(
      companionId: 'salud',
      definition: water,
      original: '1 vaso de agua',
      values: const {'glasses': 1, 'mood': 4},
    );
    expect(saved.original, '1 vaso de agua');
    expect(saved.values, {'glasses': 1, 'mood': 4});
    expect(saved.provenance, 'user');
    expect(saved.revision, 1);
    expect(saved.runId, isNull);
    expect(saved.supersedesId, isNull);
    expect(saved.localDay, '2026-10-29');
    expect(saved.definition.name, 'Beber agua');
    final listed = await store.list(companionId: 'salud');
    expect(listed.single.id, saved.id);
    expect(listed.single.values, {'glasses': 1, 'mood': 4});
  });

  test('zero is a value and a missing value stays missing', () async {
    final zero = await store.record(
      companionId: 'salud', definition: water, original: 'Ninguno',
      values: const {'glasses': 0},
    );
    final none = await store.record(
      companionId: 'salud', definition: water, original: 'Solo una nota',
    );
    expect(zero.values, {'glasses': 0});
    expect(none.values, isEmpty);
    final byId = {for (final o in await store.list(companionId: 'salud')) o.id: o};
    expect(byId[zero.id]!.values.containsKey('glasses'), isTrue);
    expect(byId[none.id]!.values.containsKey('glasses'), isFalse);
  });

  test('invalid values, originals and provenance store nothing', () async {
    Future<void> rejects(Future<Observation> Function() action) =>
        expectLater(action(), throwsA(isA<ValidationException>()));
    await rejects(() => store.record(
      companionId: 'salud', definition: water, original: 'x', values: const {'glasses': 'mucho'},
    ));
    await rejects(() => store.record(
      companionId: 'salud', definition: water, original: 'x', values: const {'mood': 9},
    ));
    await rejects(() => store.record(
      companionId: 'salud', definition: water, original: 'x', values: const {'otro': 1},
    ));
    await rejects(() => store.record(
      companionId: 'salud', definition: water, original: '   ',
    ));
    await rejects(() => store.record(
      companionId: 'salud', definition: water, original: 'x' * 8001,
    ));
    await rejects(() => store.record(
      companionId: 'salud', definition: water, original: 'x', provenance: 'robot',
    ));
    await rejects(() => store.record(
      companionId: 'otro', definition: water, original: 'x',
    ));
    expect(await store.list(companionId: 'salud'), isEmpty);
  });

  test('groups by local day and orders by observation time', () async {
    final late = await store.record(
      companionId: 'salud', definition: water, original: 'noche',
      observedAt: DateTime(2026, 10, 29, 23, 30),
    );
    final early = await store.record(
      companionId: 'salud', definition: water, original: 'mañana',
      observedAt: DateTime(2026, 10, 29, 7),
    );
    final next = await store.record(
      companionId: 'salud', definition: water, original: 'otro día',
      observedAt: DateTime(2026, 10, 30, 8),
    );
    expect(late.localDay, '2026-10-29');
    expect(next.localDay, '2026-10-30');
    final day = await store.list(companionId: 'salud', day: '2026-10-29');
    expect(day.map((o) => o.id), [early.id, late.id]);
    expect((await store.list(companionId: 'salud')).length, 3);
  });

  test('a correction is a new revision and never overwrites the original', () async {
    final first = await store.record(
      companionId: 'salud', definition: water, original: '2 vasos',
      values: const {'glasses': 2},
    );
    now = now.add(const Duration(minutes: 5));
    final fixed = await store.correct(first.id, values: const {'glasses': 3});
    expect(fixed.revision, 2);
    expect(fixed.supersedesId, first.id);
    expect(fixed.original, '2 vasos');
    expect(fixed.values, {'glasses': 3});
    expect(fixed.observedAt, first.observedAt);

    final current = await store.list(companionId: 'salud');
    expect(current.single.id, fixed.id, reason: 'solo cuenta la última revisión');
    final all = await store.list(companionId: 'salud', includeSuperseded: true);
    expect(all.map((o) => o.revision), [1, 2]);
    expect(all.first.values, {'glasses': 2}, reason: 'la primera revisión no cambia');

    final history = await store.history(fixed.id);
    expect(history.map((o) => o.revision), [1, 2]);
  });

  test('only the latest revision can be corrected', () async {
    final first = await store.record(
      companionId: 'salud', definition: water, original: 'x', values: const {'glasses': 1},
    );
    await store.correct(first.id, values: const {'glasses': 2});
    await expectLater(
      store.correct(first.id, values: const {'glasses': 5}),
      throwsA(isA<ValidationException>()),
    );
  });

  test('a correction is validated like a new record', () async {
    final first = await store.record(
      companionId: 'salud', definition: water, original: 'x', values: const {'glasses': 1},
    );
    await expectLater(
      store.correct(first.id, values: const {'mood': 99}),
      throwsA(isA<ValidationException>()),
    );
    expect((await store.history(first.id)).length, 1);
  });

  test('companions are kept apart', () async {
    await store.record(companionId: 'salud', definition: water, original: 'a');
    final other = ActivityDefinition(
      name: 'Leer', repeated: false, restSeconds: 0, companionId: 'lectura',
    );
    await store.record(companionId: 'lectura', definition: other, original: 'b');
    expect((await store.list(companionId: 'salud')).single.original, 'a');
    expect((await store.list(companionId: 'lectura')).single.original, 'b');
  });

  test('rows of another profile are invisible and cannot be corrected', () async {
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.insert('trackia_spaces', {
      'id': 'gym',
      'profile_id': 'google_otro',
      'name': 'Gimnasio',
      'revision': 1,
    });
    await db.insert('trackia_observations', {
      'id': 'foreign',
      'profile_id': 'google_otro',
      'space_id': 'gym',
      'companion_id': 'salud',
      'definition_snapshot': '{}',
      'original': 'ajeno',
      'values_json': '{}',
      'provenance': 'user',
      'revision': 1,
      'observed_at': 1,
      'recorded_at': 1,
      'local_day': '2026-10-29',
    });
    // The handle is the repository's own (single instance): do not close it.
    expect(await store.list(companionId: 'salud'), isEmpty);
    await expectLater(
      store.correct('foreign', values: const {'glasses': 1}),
      throwsA(isA<ValidationException>()),
    );
  });

  test('the definition is stored as a snapshot', () async {
    final saved = await store.record(
      companionId: 'salud', definition: water, original: 'x',
    );
    final renamed = ActivityDefinition(
      name: 'Hidratación', repeated: false, restSeconds: 0, companionId: 'salud',
    );
    expect(renamed.name, isNot(water.name));
    final again = (await store.list(companionId: 'salud')).single;
    expect(again.id, saved.id);
    expect(again.definition.name, 'Beber agua');
    expect(again.definition.fields.map((f) => f['key']), ['glasses', 'mood']);
  });

  test('records survive reopening the database', () async {
    final saved = await store.record(
      companionId: 'salud', definition: water, original: 'x', values: const {'glasses': 4},
    );
    await repo.close();
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi, path: path, clock: () => now,
    );
    store = repo.observations;
    final again = (await store.list(companionId: 'salud')).single;
    expect(again.id, saved.id);
    expect(again.values, {'glasses': 4});
  });
}
