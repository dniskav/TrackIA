import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/activity_template_repository.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/workout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late String path;
  late SqliteWorkoutRepository repo;
  late ActivityTemplateRepository store;
  var now = DateTime(2026, 10, 29, 9);

  ActivityDefinition reading({String name = 'Leer', String companion = 'lectura'}) =>
      ActivityDefinition(
        name: name,
        repeated: false,
        restSeconds: 0,
        companionId: companion,
        fields: const [
          {'key': 'pages', 'label': 'Páginas', 'unit': 'págs', 'type': 'number'},
        ],
      );

  setUp(() async {
    now = DateTime(2026, 10, 29, 9);
    dir = await Directory.systemTemp.createTemp('trackia-templates-');
    path = '${dir.path}/test.sqlite';
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: path,
      clock: () => now,
    );
    store = repo.templates;
  });

  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  test('saves a template and lists it for its companion', () async {
    final saved = await store.save(companionId: 'lectura', definition: reading());
    expect(saved.origin, 'user');
    expect(saved.instant, isFalse);
    expect(saved.definition.name, 'Leer');
    expect(saved.definition.fields.single['type'], 'number');
    final listed = await store.list(companionId: 'lectura');
    expect(listed.single.id, saved.id);
  });

  test('lists oldest first and keeps the instant flag', () async {
    final first = await store.save(companionId: 'lectura', definition: reading());
    now = now.add(const Duration(minutes: 1));
    final second = await store.save(
      companionId: 'lectura',
      definition: reading(name: 'Beber agua'),
      instant: true,
      origin: 'template',
    );
    final listed = await store.list(companionId: 'lectura');
    expect(listed.map((t) => t.id), [first.id, second.id]);
    expect(listed.last.instant, isTrue);
    expect(listed.last.origin, 'template');
  });

  test('saving the same activity again updates it instead of duplicating', () async {
    final first = await store.save(companionId: 'lectura', definition: reading());
    final again = await store.save(
      companionId: 'lectura',
      definition: ActivityDefinition(
        name: '  leer ',
        repeated: false,
        restSeconds: 0,
        companionId: 'lectura',
        fields: const [
          {'key': 'pages', 'label': 'Páginas', 'unit': 'págs', 'type': 'number'},
          {'key': 'book', 'label': 'Libro', 'unit': '', 'type': 'text'},
        ],
      ),
    );
    expect(again.id, first.id);
    final listed = await store.list(companionId: 'lectura');
    expect(listed, hasLength(1));
    expect(listed.single.definition.fields, hasLength(2));
  });

  test('an instant record and a timed activity with the same name stay apart', () async {
    await store.save(companionId: 'lectura', definition: reading());
    await store.save(companionId: 'lectura', definition: reading(), instant: true);
    expect(await store.list(companionId: 'lectura'), hasLength(2));
  });

  test('archiving hides a template without deleting it', () async {
    final saved = await store.save(companionId: 'lectura', definition: reading());
    await store.archive(saved.id);
    expect(await store.list(companionId: 'lectura'), isEmpty);
    final all = await store.list(companionId: 'lectura', includeArchived: true);
    expect(all.single.archived, isTrue);
    final again = await store.save(companionId: 'lectura', definition: reading());
    expect(again.id, isNot(saved.id), reason: 'una archivada no se reutiliza');
  });

  test('companions are kept apart', () async {
    await store.save(companionId: 'lectura', definition: reading());
    await store.save(
      companionId: 'enfoque',
      definition: reading(companion: 'enfoque'),
    );
    expect(await store.list(companionId: 'lectura'), hasLength(1));
    expect(await store.list(companionId: 'enfoque'), hasLength(1));
    expect(await store.list(companionId: 'calma'), isEmpty);
  });

  test('another profile\'s templates are invisible and cannot be archived', () async {
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.insert('trackia_activity_templates', {
      'id': 'foreign',
      'profile_id': 'google_otro',
      'companion_id': 'lectura',
      'definition': jsonEncode(reading().toJson()),
      'instant': 0,
      'origin': 'user',
      'created_at': 1,
    });
    expect(await store.list(companionId: 'lectura'), isEmpty);
    await expectLater(store.archive('foreign'), throwsA(isA<ValidationException>()));
  });

  test('rejects a definition of another companion and an unknown origin', () async {
    await expectLater(
      store.save(companionId: 'enfoque', definition: reading()),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      store.save(companionId: 'lectura', definition: reading(), origin: 'robot'),
      throwsA(isA<ValidationException>()),
    );
    expect(await store.list(companionId: 'lectura'), isEmpty);
  });

  test('templates survive reopening the database', () async {
    final saved = await store.save(companionId: 'lectura', definition: reading());
    await repo.close();
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi, path: path, clock: () => now,
    );
    store = repo.templates;
    expect((await store.list(companionId: 'lectura')).single.id, saved.id);
  });
}
