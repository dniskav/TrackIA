import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/support_agreement_service.dart';
import 'package:trackia/domain/support_agreement.dart';

void main() {
  const service = SupportAgreementService();
  final now = DateTime.utc(2026, 11, 5);
  SupportAgreementProposal? parse(Map<String, Object?> body) => service.parseProposal(
    body, profileId: 'profile-fixture', companionId: 'companion-fixture',
    sourceMessageId: 'message-fixture',
  );

  test('proposal is inert until explicit consent, then creates scoped agreement', () {
    final proposal = parse({'action': 'create', 'objective': 'Practicar una habilidad'})!;
    expect(service.accept(proposal, userConsented: false, id: 'a', revisionId: 'r', at: now), isNull);
    final accepted = service.accept(
      proposal, userConsented: true, id: 'agreement-fixture', revisionId: 'r1', at: now,
    )!;
    expect(accepted.objective, 'Practicar una habilidad');
    expect(accepted.profileId, 'profile-fixture');
    expect(accepted.companionId, 'companion-fixture');
    expect(accepted.events, isEmpty);
  });

  test('validates closed shape, free text bounds, and optional finite measures', () {
    expect(parse({'action': 'create', 'objective': 'x', 'profileId': 'foreign'}), isNull);
    expect(parse({'action': 'create', 'objective': '  '}), isNull);
    expect(parse({'action': 'create', 'objective': 'x' * 2001}), isNull);
    expect(parse({'action': 'create', 'objective': 'x', 'target': double.infinity}), isNull);
    expect(parse({'action': 'create', 'objective': 'x', 'durationSeconds': -1}), isNull);
    expect(parse({'action': 'execute', 'objective': 'x'}), isNull);
    expect(parse({'action': 'create'}), isNull);
    expect(parse({'action': 'create', 'objective': 'x', 'unit': ' '}), isNull);
  });

  test('modification requires matching scope and expected revision', () {
    final base = SupportAgreement(
      id: 'agreement-fixture', profileId: 'profile-fixture',
      companionId: 'companion-fixture', objective: 'Objetivo anterior', createdAt: now,
      unit: 'veces', target: 3, duration: const Duration(days: 5), reminder: 'Aviso',
    );
    final proposal = parse({
      'action': 'modify', 'agreementId': base.id, 'expectedRevision': 1,
      'objective': 'Objetivo revisado', 'target': 4,
    })!;
    expect(service.accept(proposal, userConsented: true, id: base.id, revisionId: 'r2', at: now,
      current: base), isNotNull);
    final revised = service.accept(proposal, userConsented: true, id: base.id,
      revisionId: 'r2', at: now, current: base)!;
    expect(revised.objective, 'Objetivo revisado');
    expect(revised.target, 4);
    expect(revised.unit, 'veces');
    expect(revised.duration, const Duration(days: 5));
    expect(revised.reminder, 'Aviso');
    expect(revised.revision, 2);
    expect(service.accept(proposal, userConsented: true, id: base.id,
      revisionId: 'r3', at: now, current: revised), isNull);
    final foreign = SupportAgreement(id: base.id, profileId: 'other-profile',
      companionId: base.companionId, objective: 'Otro', createdAt: now);
    expect(service.accept(proposal, userConsented: true, id: base.id,
      revisionId: 'r2', at: now, current: foreign), isNull);

    final clearProposal = parse({
      'action': 'modify', 'agreementId': base.id, 'expectedRevision': 1,
      'unit': null, 'target': null, 'durationSeconds': null, 'reminder': null,
    })!;
    final cleared = service.accept(clearProposal, userConsented: true, id: base.id,
      revisionId: 'r-clear', at: now, current: base)!;
    expect(cleared.unit, isNull);
    expect(cleared.target, isNull);
    expect(cleared.duration, isNull);
    expect(cleared.reminder, isNull);
  });

  test('manual event requires separate confirmation and stays explicit', () {
    final agreement = SupportAgreement(id: 'a', profileId: 'p', companionId: 'c',
      objective: 'Seguimiento libre', createdAt: now);
    expect(service.confirmEvent(agreement, userConfirmed: false, eventId: 'e', occurredAt: now), isNull);
    final event = service.confirmEvent(agreement, userConfirmed: true,
      eventId: 'e', occurredAt: now, amount: 0, note: 'Registro voluntario')!;
    expect(agreement.recordEvent(event).events, [event]);
  });
}
