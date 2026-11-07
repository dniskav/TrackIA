import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/data/feature_scope.dart';
import 'package:trackia/data/message_effect_repository.dart';
import 'package:trackia/data/message_revision_repository.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/message_effect.dart';
import 'package:trackia/domain/message_revision.dart';
import 'package:trackia/domain/workout.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String path;
  late Database db;
  late MessageRevisionRepository revisions;
  late MessageEffectRepository effects;
  final scope = FeatureScope(profileId: 'profile-a', companionId: 'gym');
  final t0 = DateTime.utc(2026, 11, 7, 10);

  Future<void> open() async {
    db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    revisions = MessageRevisionRepository(db, scope);
    effects = MessageEffectRepository.on(revisions);
  }

  Future<void> message(String id, {String? companion}) async {
    final repo = companion == null
        ? revisions
        : MessageRevisionRepository(
            db,
            FeatureScope(profileId: scope.profileId, companionId: companion),
          );
    await repo.create(
      Message(
        id: id,
        profileId: scope.profileId,
        companionId: companion ?? scope.companionId,
        chatId: 'chat-a',
        createdAt: t0,
        currentRevisionId: 'rev-$id-1',
      ),
      MessageRevision(
        id: 'rev-$id-1',
        messageId: id,
        revision: 1,
        text: 'hola',
        createdAt: t0,
      ),
    );
  }

  MessageEffect effect(
    String id,
    String messageId,
    String kind,
    String what,
    String summary, {
    int revision = 1,
    int minute = 0,
  }) => MessageEffect(
    id: id,
    profileId: scope.profileId,
    companionId: scope.companionId,
    messageId: messageId,
    revisionId: 'rev-$messageId-$revision',
    kind: kind,
    targetId: 'target-$id',
    operationKey: MessageEffect.keyFor(messageId, kind, what),
    summary: summary,
    createdAt: t0.add(Duration(minutes: minute)),
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('trackia-effects-');
    path = '${directory.path}/effects.sqlite';
    final migrated = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: path,
      profileId: scope.profileId,
    );
    await migrated.close();
    await open();
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test('record es idempotente y se ordena por fecha', () async {
    await message('m1');
    final second = effect(
      'e2',
      'm1',
      'target',
      '10x60',
      'Fijé 10 series',
      minute: 2,
    );
    final first = effect(
      'e1',
      'm1',
      'activity',
      'press',
      'Preparé «Press banca»',
    );
    expect(await effects.record(second), isTrue);
    expect(await effects.record(first), isTrue);
    // Misma clave con otro id y texto: no duplica.
    final dup = effect('e3', 'm1', 'target', '10x60', 'otro texto', minute: 5);
    expect(await effects.record(dup), isFalse);
    expect(await effects.isApplied(second.operationKey), isTrue);
    final all = await effects.effectsFor('m1');
    expect(all.map((e) => e.id), ['e1', 'e2']);
    expect(all.last.summary, 'Fijé 10 series');
    expect(all.first.status, EffectStatus.confirmed);
  });

  test('por revisión, ámbito y revisión ajena al mensaje', () async {
    await message('m1');
    await revisions.append(
      'm1',
      expectedRevisionId: 'rev-m1-1',
      revision: MessageRevision(
        id: 'rev-m1-2',
        messageId: 'm1',
        revision: 2,
        text: 'corregido',
        createdAt: t0,
        supersedesId: 'rev-m1-1',
      ),
    );
    await effects.record(effect('e1', 'm1', 'goal', 'a', 'Añadí una meta'));
    await effects.record(
      effect(
        'e2',
        'm1',
        'timing',
        'b',
        'Cambié tiempos',
        revision: 2,
        minute: 1,
      ),
    );
    expect((await effects.effectsForRevision('rev-m1-1')).map((e) => e.id), [
      'e1',
    ]);
    expect((await effects.effectsForRevision('rev-m1-2')).map((e) => e.id), [
      'e2',
    ]);
    expect((await effects.effectsFor('m1')).length, 2);
    final other = MessageEffectRepository(
      db,
      FeatureScope(profileId: scope.profileId, companionId: 'otro'),
    );
    expect(await other.effectsFor('m1'), isEmpty);
    await message('m2');
    expect(
      () => effects.record(
        MessageEffect(
          id: 'bad',
          profileId: scope.profileId,
          companionId: scope.companionId,
          messageId: 'm2',
          revisionId: 'rev-m1-1',
          kind: 'goal',
          targetId: 't',
          operationKey: 'm2-goal-x',
          summary: '',
          createdAt: t0,
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('resumen para el modelo y marca de corregido', () async {
    await message('m1');
    expect(await effects.appliedEffectsSummary('m1'), '');
    await effects.record(
      effect(
        'e1',
        'm1',
        'observation',
        'x',
        'Registré 4 series de press banca a 80 kg',
      ),
    );
    await effects.record(effect('e2', 'm1', 'goal', 'y', '', minute: 1));
    expect(
      await effects.appliedEffectsSummary('m1'),
      'Efectos ya aplicados por la respuesta anterior: '
      'Registré 4 series de press banca a 80 kg; Añadí una meta.',
    );
    expect(await effects.markReverted('e1'), isTrue);
    expect(await effects.markReverted('e1'), isFalse);
    final text = await effects.appliedEffectsSummary('m1');
    expect(
      text,
      contains('ya aplicados por la respuesta anterior: Añadí una meta.'),
    );
    expect(
      text,
      contains(
        'Corregidos o revertidos después: Registré 4 series de press banca a 80 kg.',
      ),
    );
    expect(
      (await effects.effectsFor('m1')).first.status,
      EffectStatus.superseded,
    );
  });

  test(
    'reenviar o editar no repite: la clave sale del mensaje, no de la revisión',
    () async {
      await message('m1');
      final key = MessageEffect.keyFor('m1', 'activity', 'press');
      expect(await effects.isApplied(key), isFalse);
      await effects.record(
        effect('e1', 'm1', 'activity', 'press', 'Preparé «Press»'),
      );
      await revisions.append(
        'm1',
        expectedRevisionId: 'rev-m1-1',
        revision: MessageRevision(
          id: 'rev-m1-2',
          messageId: 'm1',
          revision: 2,
          text: 'editado',
          createdAt: t0,
          supersedesId: 'rev-m1-1',
        ),
      );
      // La respuesta a la revisión 2 propone lo mismo: ya aplicado.
      expect(await effects.isApplied(key), isTrue);
      expect(
        await effects.record(
          effect(
            'e2',
            'm1',
            'activity',
            'press',
            'Preparé «Press»',
            revision: 2,
          ),
        ),
        isFalse,
      );
      expect((await effects.effectsFor('m1')).length, 1);
      // Otro contenido sí es un efecto nuevo.
      expect(
        await effects.isApplied(MessageEffect.keyFor('m1', 'activity', 'remo')),
        isFalse,
      );
    },
  );

  test('sobrevive al reinicio con la base en archivo', () async {
    await message('m1');
    await effects.record(
      effect('e1', 'm1', 'target', '10x10', 'Fijé 10 series'),
    );
    await effects.markReverted('e1');
    await db.close();
    await open();
    final loaded = await effects.effectsFor('m1');
    expect(loaded.single.summary, 'Fijé 10 series');
    expect(loaded.single.status, EffectStatus.superseded);
    expect(await effects.isApplied(loaded.single.operationKey), isTrue);
  });
}
