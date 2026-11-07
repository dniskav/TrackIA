import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/data/feature_scope.dart';
import 'package:trackia/data/support_agreement_repository.dart';
import 'package:trackia/domain/support_agreement.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late Database db;
  late SupportAgreementRepository repo;
  final t0 = DateTime.utc(2026, 11, 1);
  final scopeA = FeatureScope(profileId: 'profile-a', companionId: 'comp-a');

  SupportAgreement base({String id = 'ag-1', FeatureScope? s}) =>
      SupportAgreement(
        id: id,
        profileId: (s ?? scopeA).profileId,
        companionId: (s ?? scopeA).companionId,
        objective: 'Aprender a meditar',
        unit: 'minutos',
        target: 10,
        duration: const Duration(days: 7),
        reminder: 'Por la tarde',
        createdAt: t0,
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('trackia-agreement-');
    db = await databaseFactoryFfi.openDatabase('${dir.path}/a.sqlite');
    repo = SupportAgreementRepository(db, scopeA);
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('guarda y lee un acuerdo con todos sus campos', () async {
    await repo.save(base());
    final got = (await repo.get('ag-1'))!;
    expect(got.objective, 'Aprender a meditar');
    expect(got.unit, 'minutos');
    expect(got.target, 10);
    expect(got.duration, const Duration(days: 7));
    expect(got.reminder, 'Por la tarde');
    expect(got.status, SupportAgreementStatus.active);
    expect(got.createdAt, t0);
    expect(await repo.get('otro'), isNull);
  });

  test('pausa, modificación y finalización conservan revisiones', () async {
    var a = base();
    await repo.save(a);
    a = a.pause(revisionId: 'r2', at: t0.add(const Duration(days: 1)));
    await repo.save(a);
    expect((await repo.get('ag-1'))!.status, SupportAgreementStatus.paused);
    a = a.resume(revisionId: 'r3', at: t0.add(const Duration(days: 2)));
    a = a.modify(revisionId: 'r4', changedAt: t0, objective: 'Meditar más', target: 15);
    await repo.save(a);
    a = a.complete(revisionId: 'r5', at: t0.add(const Duration(days: 3)));
    await repo.save(a);
    final got = (await repo.get('ag-1'))!;
    expect(got.status, SupportAgreementStatus.completed);
    expect(got.revision, 5);
    expect(got.objective, 'Meditar más');
    expect(got.revisions.map((r) => r.id), ['r2', 'r3', 'r4', 'r5']);
    expect(got.revisions.first.target, 10);
    expect(got.revisions.first.status, SupportAgreementStatus.paused);
    expect(await repo.list(status: SupportAgreementStatus.active), isEmpty);
    expect(await repo.list(status: SupportAgreementStatus.completed), hasLength(1));
  });

  test('los eventos son inmutables y se añaden sin reescribir', () async {
    var a = base().recordEvent(
      SupportAgreementEvent(id: 'e1', agreementId: 'ag-1', occurredAt: t0, amount: 5, note: 'bien'),
    );
    await repo.save(a);
    await repo.save(a); // idempotente
    a = a.recordEvent(
      SupportAgreementEvent(id: 'e2', agreementId: 'ag-1', occurredAt: t0.add(const Duration(hours: 1))),
    );
    await repo.save(a);
    final got = (await repo.get('ag-1'))!;
    expect(got.events.map((e) => e.id), ['e1', 'e2']);
    expect(got.events.first.amount, 5);
    expect(got.events.first.note, 'bien');
    expect(got.events.last.amount, isNull);

    final altered = base().recordEvent(
      SupportAgreementEvent(id: 'e1', agreementId: 'ag-1', occurredAt: t0, amount: 99),
    );
    await expectLater(repo.save(altered), throwsA(anything));
    expect((await repo.get('ag-1'))!.events.first.amount, 5);
    // La propia base rechaza UPDATE y DELETE directos.
    await expectLater(
      db.update('trackia_support_agreement_events', {'amount': 1}),
      throwsA(anything),
    );
    await expectLater(db.delete('trackia_support_agreement_events'), throwsA(anything));
    await repo.save(base(id: 'ag-2').pause(revisionId: 'rv', at: t0));
    await expectLater(
      db.delete('trackia_support_agreement_revisions'),
      throwsA(anything),
    );
    await expectLater(db.delete('trackia_support_agreement_revisions'), throwsA(anything));
  });

  test('rechaza revisión más antigua y acuerdo de otro ámbito', () async {
    final a = base().pause(revisionId: 'r2', at: t0);
    await repo.save(a);
    await expectLater(repo.save(base()), throwsA(anything));
    final foreign = FeatureScope(profileId: 'profile-b', companionId: 'comp-a');
    await expectLater(repo.save(base(id: 'x', s: foreign)), throwsA(anything));
    expect(await repo.get('x'), isNull);
  });

  test('aislamiento por perfil y acompañante', () async {
    await repo.save(base());
    final otherCompanion = SupportAgreementRepository(
      db, FeatureScope(profileId: 'profile-a', companionId: 'comp-b'));
    final otherProfile = SupportAgreementRepository(
      db, FeatureScope(profileId: 'profile-b', companionId: 'comp-a'));
    expect(await otherCompanion.get('ag-1'), isNull);
    expect(await otherProfile.list(), isEmpty);
    // El mismo ID puede existir en otro ámbito sin mezclar datos.
    await otherCompanion.save(SupportAgreement(
      id: 'ag-1', profileId: 'profile-a', companionId: 'comp-b',
      objective: 'Otro', createdAt: t0));
    expect((await repo.get('ag-1'))!.objective, 'Aprender a meditar');
    expect((await otherCompanion.get('ag-1'))!.objective, 'Otro');
  });

  test('sobrevive al reinicio con la base en archivo', () async {
    var a = base().recordEvent(
      SupportAgreementEvent(id: 'e1', agreementId: 'ag-1', occurredAt: t0, amount: 2),
    );
    a = a.pause(revisionId: 'r2', at: t0);
    await repo.save(a);
    await db.close();
    db = await databaseFactoryFfi.openDatabase('${dir.path}/a.sqlite');
    repo = SupportAgreementRepository(db, scopeA);
    final got = (await repo.get('ag-1'))!;
    expect(got.status, SupportAgreementStatus.paused);
    expect(got.revisions.single.id, 'r2');
    expect(got.events.single.amount, 2);
  });
}
