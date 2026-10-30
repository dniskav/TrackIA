import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/companion_creation.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/assistant_blocks.dart';
import 'package:trackia/domain/progress.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late CompanionStore store;
  late CompanionCreation creation;
  final now = DateTime(2026, 10, 29, 9);

  final activity = ActivityDefinition(
    name: 'Leer',
    repeated: false,
    restSeconds: 0,
    fields: const [
      {
        'key': 'paginas',
        'label': 'Páginas',
        'unit': '',
        'type': 'number',
        'aggregate': 'sum',
      },
    ],
  );
  final goal = GoalRule(
    metric: Metric(
      source: 'field',
      field: 'paginas',
      aggregate: 'sum',
      per: 'day',
    ),
    period: 'day',
    target: 20,
    minimum: 5,
  );
  const reminder = ReminderProposal(
    days: 0x1F,
    startMin: 1260,
    endMin: 1380,
    lastCallMin: 1350,
    tone: 'cheer',
  );
  CompanionDraft draft({String mode = 'game', String name = 'Lectura'}) =>
      CompanionDraft(
        name: name,
        description: 'Leer cada día',
        prompt: 'Sé breve.',
        icon: 'book',
        color: 'violet',
        mode: mode,
        activity: activity,
        goal: goal,
        reminder: reminder,
        origin: 'assistant',
      );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('trackia-creation-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    store = const CompanionStore(profileId: 'local');
    creation = CompanionCreation(
      store: store,
      progress: repo.progress,
      templates: repo.templates,
    );
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<void> expectNothingLeft(String id) async {
    expect((await store.load()).any((c) => c.id == id), isFalse);
    expect((await repo.progress.settings(id)).revision, 0);
    expect(await repo.progress.reminderFor(id), isNull);
    expect(await repo.progress.activeGoal(id), isNull);
    expect(await repo.templates.list(companionId: id), isEmpty);
    expect(await repo.progress.achievements(id), isEmpty);
  }

  test('a full draft creates everything, in the contract\'s order', () async {
    final steps = <String>[];
    creation.debugStep = steps.add;
    final c = await creation.create(draft());
    expect(steps, CompanionCreation.steps);
    expect(c.id, 'lectura');
    expect(
      [c.name, c.description, c.icon, c.color],
      ['Lectura', 'Leer cada día', 'book', 'violet'],
    );

    expect((await store.load()).map((x) => x.id), contains('lectura'));
    final settings = await repo.progress.settings('lectura');
    expect(
      [settings.mode, settings.achievementsEnabled, settings.goalsEnabled],
      ['game', true, true],
    );
    final templates = await repo.templates.list(companionId: 'lectura');
    expect(templates.single.definition.name, 'Leer');
    expect(templates.single.definition.companionId, 'lectura');
    expect(templates.single.instant, isFalse);
    expect(templates.single.origin, 'assistant');
    expect((await repo.progress.activeGoal('lectura'))!.target, 20);
    final saved = (await repo.progress.reminderFor('lectura'))!;
    expect(
      [saved.days, saved.windowStartMin, saved.lastCallMin, saved.tone],
      [0x1F, 1260, 1350, 'cheer'],
    );
    final achievements = await repo.progress.achievements('lectura');
    expect(
      achievements.map((a) => a.title),
      containsAll(['Primera vez', '10 páginas', '1.000 páginas']),
    );
    expect(achievements.every((a) => !a.unlocked), isTrue);
  });

  test('the middle level is game mode without achievements', () async {
    await creation.create(draft(mode: 'goals', name: 'Metas'));
    final settings = await repo.progress.settings('metas');
    expect([settings.mode, settings.achievementsEnabled], ['game', false]);
    expect(await repo.progress.achievements('metas'), isEmpty);
    expect(await repo.progress.activeGoal('metas'), isNotNull);
  });

  test('the lowest level only reminds, and keeps the goal for later', () async {
    await creation.create(draft(mode: 'reminder', name: 'Aviso'));
    final settings = await repo.progress.settings('aviso');
    expect(settings.mode, 'reminder');
    expect(await repo.progress.achievements('aviso'), isEmpty);
    expect(await repo.progress.reminderFor('aviso'), isNotNull);
    expect(await repo.progress.activeGoal('aviso'), isNotNull);
  });

  test('a point-record activity is saved as such', () async {
    await creation.create(
      CompanionDraft(
        name: 'Agua',
        mode: 'reminder',
        activity: activity,
        instant: true,
      ),
    );
    expect(
      (await repo.templates.list(companionId: 'agua')).single.instant,
      isTrue,
    );
    expect(
      (await repo.templates.list(companionId: 'agua')).single.origin,
      'user',
    );
  });

  for (final step in CompanionCreation.steps) {
    test('a failure at «$step» undoes everything', () async {
      creation.debugStep = (s) {
        if (s == step) throw StateError('falló $step');
      };
      await expectLater(creation.create(draft()), throwsA(isA<StateError>()));
      await expectNothingLeft('lectura');
      // And the same companion can be created afterwards.
      creation.debugStep = null;
      expect((await creation.create(draft())).id, 'lectura');
    });
  }

  test('a failure leaves the companions that already existed alone', () async {
    final before = (await store.load()).map((c) => c.id).toList();
    creation.debugStep = (s) {
      if (s == 'reminder') throw StateError('boom');
    };
    await expectLater(creation.create(draft()), throwsA(isA<StateError>()));
    expect((await store.load()).map((c) => c.id), before);
  });

  test('an activity without a place to save it fails and undoes', () async {
    final noTemplates = CompanionCreation(
      store: store,
      progress: repo.progress,
    );
    await expectLater(noTemplates.create(draft()), throwsA(anything));
    await expectNothingLeft('lectura');
  });

  group('ids', () {
    test('lowercase, without accents, unique among the existing', () {
      expect(companionIdFor('Lectura', []), 'lectura');
      expect(companionIdFor('Corazón y Mente', []), 'corazon-y-mente');
      expect(companionIdFor('Enfoque', ['enfoque']), 'enfoque-2');
      expect(companionIdFor('Enfoque', ['enfoque', 'enfoque-2']), 'enfoque-3');
      expect(companionIdFor('¡¡!!', []), 'acompanante');
      expect(companionIdFor('a' * 60, []).length, lessThanOrEqualTo(24));
    });

    test('a name that collides with a suggestion gets its own id', () async {
      final c = await creation.create(draft(name: 'Enfoque'));
      expect(c.id, 'enfoque-2');
      expect((await store.load()).where((x) => x.id == 'enfoque').length, 1);
    });
  });
}
