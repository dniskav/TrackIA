import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/domain/support_agreement.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 5);

  SupportAgreement create({
    String objective = 'Registrar una actividad elegida',
    double? target,
    String? unit,
  }) => SupportAgreement(
    id: 'agreement-opaque-1',
    profileId: 'profile-fixture-1',
    companionId: 'companion-fixture-1',
    objective: objective,
    unit: unit,
    target: target,
    createdAt: createdAt,
  );

  test('permite un objetivo libre sin unidad ni medida', () {
    final agreement = create();
    expect(agreement.objective, 'Registrar una actividad elegida');
    expect(agreement.target, isNull);
    expect(agreement.unit, isNull);
    expect(agreement.status, SupportAgreementStatus.active);
    expect(agreement.revision, 1);
  });

  test('valida objetivo, ámbito, medida, duración y campos opcionales', () {
    expect(() => create(objective: '  '), throwsArgumentError);
    expect(
      () => create(objective: 'x' * 2001),
      throwsArgumentError,
    );
    expect(
      () => SupportAgreement(
        id: 'agreement-1',
        profileId: ' ',
        companionId: 'companion-1',
        objective: 'Objetivo',
        createdAt: createdAt,
      ),
      throwsArgumentError,
    );
    for (final invalid in [-1.0, double.nan, double.infinity, double.negativeInfinity]) {
      expect(() => create(target: invalid), throwsArgumentError);
    }
    expect(
      () => SupportAgreement(
        id: 'agreement-1',
        profileId: 'profile-1',
        companionId: 'companion-1',
        objective: 'Objetivo',
        createdAt: createdAt,
        duration: const Duration(seconds: -1),
      ),
      throwsArgumentError,
    );
    expect(() => create(unit: '  '), throwsArgumentError);
    expect(
      () => create().modify(
        revisionId: 'rev-bad',
        changedAt: createdAt,
        target: double.nan,
      ),
      throwsArgumentError,
    );
  });

  test('modification creates a new revision and retains prior snapshot and event', () {
    final event = SupportAgreementEvent(
      id: 'event-opaque-1',
      agreementId: 'agreement-opaque-1',
      occurredAt: createdAt.add(const Duration(hours: 1)),
      amount: 2,
      note: 'Registro sintético',
    );
    final initial = create().recordEvent(event);
    final changed = initial.modify(
      revisionId: 'revision-2',
      changedAt: createdAt.add(const Duration(days: 1)),
      objective: 'Nuevo objetivo libre',
      unit: 'veces',
      target: 3,
      duration: const Duration(days: 10),
      reminder: 'Aviso opcional',
    );

    expect(initial.objective, 'Registrar una actividad elegida');
    expect(initial.revision, 1);
    expect(changed.objective, 'Nuevo objetivo libre');
    expect(changed.revision, 2);
    expect(changed.revisions, hasLength(1));
    expect(changed.revisions.single.revision, 2);
    expect(changed.revisions.single.objective, changed.objective);
    expect(changed.events, hasLength(1));
    expect(changed.events.single, same(event));
    expect(() => changed.events.clear(), throwsUnsupportedError);
  });

  test('pause, resume, completion are revisioned and completion is terminal', () {
    final active = create(target: 0);
    final paused = active.pause(revisionId: 'revision-2', at: createdAt);
    expect(paused.status, SupportAgreementStatus.paused);
    expect(paused.revision, 2);
    expect(paused.revisions.single.status, SupportAgreementStatus.paused);

    final resumed = paused.resume(
      revisionId: 'revision-3',
      at: createdAt.add(const Duration(days: 1)),
    );
    final completed = resumed.complete(
      revisionId: 'revision-4',
      at: createdAt.add(const Duration(days: 2)),
    );
    expect(resumed.status, SupportAgreementStatus.active);
    expect(completed.status, SupportAgreementStatus.completed);
    expect(completed.revisions.map((r) => r.revision), [2, 3, 4]);
    expect(
      () => completed.modify(revisionId: 'revision-5', changedAt: createdAt),
      throwsStateError,
    );
    expect(
      () => completed.recordEvent(
        SupportAgreementEvent(
          id: 'event-after-completion',
          agreementId: completed.id,
          occurredAt: createdAt,
        ),
      ),
      throwsStateError,
    );
  });

  test('manual events are immutable, scoped, uniquely identified and non-negative', () {
    final source = create();
    final event = SupportAgreementEvent(
      id: 'event-1',
      agreementId: source.id,
      occurredAt: createdAt,
      amount: 0,
    );
    final withEvent = source.recordEvent(event);
    final afterPause = withEvent.pause(revisionId: 'revision-2', at: createdAt);

    expect(withEvent.events, [event]);
    expect(afterPause.events, [event]);
    expect(() => source.events.add(event), throwsUnsupportedError);
    expect(
      () => source.recordEvent(event).recordEvent(event),
      throwsArgumentError,
    );
    expect(
      () => source.recordEvent(
        SupportAgreementEvent(
          id: 'foreign-event',
          agreementId: 'another-agreement',
          occurredAt: createdAt,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => SupportAgreementEvent(
        id: 'negative-event',
        agreementId: source.id,
        occurredAt: createdAt,
        amount: -0.1,
      ),
      throwsArgumentError,
    );
  });
}
