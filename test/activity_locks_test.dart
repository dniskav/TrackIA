import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/workout.dart';

/// FR-023: cada edición a mano fija su propiedad en `userSet`; las ediciones
/// de la IA no; tocar el candado libera la propiedad.
void main() {
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('gymia-locks-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
    );
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  test('manual edits add their property to userSet (FR-023)', () async {
    final id = await repo.prepareActivity(
      ActivityDefinition(name: 'Sentadilla', restSeconds: 60),
    );
    await repo.renameActivity(id, 'Sentadilla búlgara');
    await repo.setActivityRest(id, 75);
    await repo.setActivityTiming(
      id,
      activitySeconds: 40,
      restSeconds: 75,
      targetCycles: null,
    );
    final a = (await repo.loadActivities()).singleWhere((x) => x.id == id);
    expect(a.definition.userSet, contains('name'));
    expect(a.definition.userSet, contains('restSeconds'));
    expect(a.definition.userSet, contains('activitySeconds'));
    expect(a.definition.userSet, isNot(contains('targetCycles')));
  });

  test('timing edit only locks what actually changed (FR-023)', () async {
    final id = await repo.prepareActivity(
      ActivityDefinition(
        name: 'Plancha',
        restSeconds: 60,
        activitySeconds: 30,
        targetCycles: 4,
      ),
    );
    // Solo cambia el descanso; duración y ciclos se reenvían iguales.
    await repo.setActivityTiming(
      id,
      activitySeconds: 30,
      restSeconds: 90,
      targetCycles: 4,
    );
    final a = (await repo.loadActivities()).singleWhere((x) => x.id == id);
    expect(a.definition.userSet, ['restSeconds']);
  });

  test('assistant edits do not add locks (FR-023)', () async {
    final id = await repo.prepareActivity(
      ActivityDefinition(name: 'Press banca', restSeconds: 60),
    );
    await repo.renameActivity(id, 'Press banca', source: 'assistant');
    await repo.setActivityRest(id, 90, source: 'assistant');
    await repo.setActivityTiming(
      id,
      activitySeconds: 20,
      restSeconds: 90,
      targetCycles: 3,
      source: 'assistant',
    );
    final a = (await repo.loadActivities()).singleWhere((x) => x.id == id);
    expect(a.definition.userSet, isEmpty);
    // Los valores sí se aplicaron.
    expect(a.definition.name, 'Press banca');
    expect(a.definition.restSeconds, 90);
    expect(a.definition.targetCycles, 3);
  });

  test('touching the lock frees the property (FR-023)', () async {
    final id = await repo.prepareActivity(
      ActivityDefinition(name: 'Remo', restSeconds: 60),
    );
    await repo.setActivityRest(id, 75);
    expect(
      (await repo.loadActivities())
          .singleWhere((x) => x.id == id)
          .definition
          .userSet,
      contains('restSeconds'),
    );
    await repo.clearUserSetLock(id, 'restSeconds');
    final a = (await repo.loadActivities()).singleWhere((x) => x.id == id);
    expect(a.definition.userSet, isNot(contains('restSeconds')));
    // El resto de los candados se conservan.
    expect(a.definition.userSet, isEmpty);
    await repo.setActivityRest(id, 80);
    await repo.clearUserSetLock(id, 'activitySeconds');
    expect(
      (await repo.loadActivities())
          .singleWhere((x) => x.id == id)
          .definition
          .userSet,
      contains('restSeconds'),
    );
  });

  test('unknown lock name is rejected', () async {
    final id = await repo.prepareActivity(ActivityDefinition(name: 'Plancha'));
    await expectLater(
      () => repo.clearUserSetLock(id, 'metrics'),
      throwsA(isA<ValidationException>()),
    );
  });
}
