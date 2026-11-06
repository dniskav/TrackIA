import '../domain/support_agreement.dart';

enum SupportAgreementProposalAction { create, modify }

/// Validated but inert suggestion. It cannot create or modify anything until
/// the caller supplies explicit user consent to [accept].
class SupportAgreementProposal {
  const SupportAgreementProposal._({
    required this.action,
    required this.profileId,
    required this.companionId,
    required this.sourceMessageId,
    required this.expectedAgreementId,
    required this.expectedRevision,
    required this.objective,
    required this.unit,
    required this.target,
    required this.duration,
    required this.reminder,
    required this.hasUnit,
    required this.hasTarget,
    required this.hasDuration,
    required this.hasReminder,
  });

  final SupportAgreementProposalAction action;
  final String profileId;
  final String companionId;
  final String sourceMessageId;
  final String? expectedAgreementId;
  final int? expectedRevision;
  final String? objective;
  final String? unit;
  final double? target;
  final Duration? duration;
  final String? reminder;
  final bool hasUnit;
  final bool hasTarget;
  final bool hasDuration;
  final bool hasReminder;
}

/// Pure proposal validation and explicit-consent rules. No AI client,
/// persistence, timers, or implicit event counting is used here.
class SupportAgreementService {
  const SupportAgreementService();

  SupportAgreementProposal? parseProposal(
    Map<String, Object?> data, {
    required String profileId,
    required String companionId,
    required String sourceMessageId,
  }) {
    if (_blank(profileId) || _blank(companionId) || _blank(sourceMessageId)) {
      return null;
    }
    const allowed = {
      'action', 'agreementId', 'expectedRevision', 'objective', 'unit',
      'target', 'durationSeconds', 'reminder',
    };
    if (data.keys.any((key) => !allowed.contains(key))) return null;
    final action = switch (data['action']) {
      'create' => SupportAgreementProposalAction.create,
      'modify' => SupportAgreementProposalAction.modify,
      _ => null,
    };
    if (action == null) return null;
    final creating = action == SupportAgreementProposalAction.create;
    final agreementId = data['agreementId'];
    final expectedRevision = data['expectedRevision'];
    if (creating) {
      if (agreementId != null || expectedRevision != null ||
          data['objective'] is! String) {
        return null;
      }
    } else if (agreementId is! String || _blank(agreementId) ||
        expectedRevision is! int || expectedRevision <= 0 ||
        data.keys.every((key) => const {'action', 'agreementId', 'expectedRevision'}.contains(key))) {
      return null;
    }
    final objective = data['objective'];
    final unit = data['unit'];
    final reminder = data['reminder'];
    final target = data['target'];
    final duration = data['durationSeconds'];
    if (objective != null && (objective is! String || objective.trim().isEmpty ||
        objective.length > SupportAgreement.maxObjectiveLength)) {
      return null;
    }
    if (unit != null && (unit is! String || unit.trim().isEmpty)) return null;
    if (reminder != null && (reminder is! String || reminder.trim().isEmpty)) return null;
    if (target != null && (target is! num || !target.isFinite || target < 0)) return null;
    if (duration != null && (duration is! int || duration < 0)) return null;
    try {
      // Reuse domain validation, including all numeric boundaries.
      SupportAgreementRevision(
        id: 'proposal-validation', agreementId: 'proposal-validation', revision: 1,
        objective: (objective as String?) ?? 'Validación',
        createdAt: DateTime.utc(2000), status: SupportAgreementStatus.active,
        unit: unit as String?, target: (target as num?)?.toDouble(),
        duration: duration == null ? null : Duration(seconds: duration as int),
        reminder: reminder as String?,
      );
    } on ArgumentError {
      return null;
    }
    return SupportAgreementProposal._(
      action: action,
      profileId: profileId.trim(), companionId: companionId.trim(),
      sourceMessageId: sourceMessageId.trim(),
      expectedAgreementId: agreementId as String?,
      expectedRevision: expectedRevision as int?,
      objective: objective, unit: unit,
      target: target?.toDouble(),
      duration: duration == null ? null : Duration(seconds: duration as int),
      reminder: reminder,
      hasUnit: data.containsKey('unit'),
      hasTarget: data.containsKey('target'),
      hasDuration: data.containsKey('durationSeconds'),
      hasReminder: data.containsKey('reminder'),
    );
  }

  SupportAgreement? accept(
    SupportAgreementProposal proposal, {
    required bool userConsented,
    required String id,
    required String revisionId,
    required DateTime at,
    SupportAgreement? current,
  }) {
    if (!userConsented) return null;
    if (proposal.action == SupportAgreementProposalAction.create) {
      if (current != null) return null;
      return SupportAgreement(
        id: id, profileId: proposal.profileId, companionId: proposal.companionId,
        objective: proposal.objective!, unit: proposal.unit, target: proposal.target,
        duration: proposal.duration, reminder: proposal.reminder, createdAt: at,
      );
    }
    if (current == null || current.id != proposal.expectedAgreementId ||
        current.profileId != proposal.profileId ||
        current.companionId != proposal.companionId ||
        current.revision != proposal.expectedRevision) {
      return null;
    }
    return current.modify(
      revisionId: revisionId,
      changedAt: at,
      objective: proposal.objective,
      unit: proposal.hasUnit ? proposal.unit : _unchanged,
      target: proposal.hasTarget ? proposal.target : _unchanged,
      duration: proposal.hasDuration ? proposal.duration : _unchanged,
      reminder: proposal.hasReminder ? proposal.reminder : _unchanged,
    );
  }

  /// Manual event recording requires a separate affirmative confirmation.
  SupportAgreementEvent? confirmEvent(
    SupportAgreement agreement, {
    required bool userConfirmed,
    required String eventId,
    required DateTime occurredAt,
    double? amount,
    String? note,
  }) {
    if (!userConfirmed) return null;
    return SupportAgreementEvent(
      id: eventId, agreementId: agreement.id, occurredAt: occurredAt,
      amount: amount, note: note,
    );
  }
}

const Object _unchanged = Object();
bool _blank(String value) => value.trim().isEmpty;
