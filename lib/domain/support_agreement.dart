/// Lifecycle of a manually tracked, user-confirmed support agreement.
enum SupportAgreementStatus { active, paused, completed }

/// An immutable snapshot of an agreement's definition at a revision.
class SupportAgreementRevision {
  SupportAgreementRevision({
    required this.id,
    required this.agreementId,
    required this.revision,
    required this.objective,
    required this.createdAt,
    required this.status,
    this.unit,
    this.target,
    this.duration,
    this.reminder,
  }) {
    _required(id, 'id');
    _required(agreementId, 'agreementId');
    _validateRevision(revision);
    _validateObjective(objective);
    _optionalText(unit, 'unit');
    _optionalText(reminder, 'reminder');
    _validateNumber(target, 'target');
    _validateDuration(duration);
  }

  final String id;
  final String agreementId;
  final int revision;
  final String objective;
  final String? unit;
  final double? target;
  final Duration? duration;
  final String? reminder;
  final SupportAgreementStatus status;
  final DateTime createdAt;
}

/// A single manually recorded event. Events are immutable and never rewritten
/// when the agreement definition or its status changes.
class SupportAgreementEvent {
  SupportAgreementEvent({
    required this.id,
    required this.agreementId,
    required this.occurredAt,
    this.amount,
    this.note,
  }) {
    _required(id, 'id');
    _required(agreementId, 'agreementId');
    _validateNumber(amount, 'amount');
    _optionalText(note, 'note');
  }

  final String id;
  final String agreementId;
  final DateTime occurredAt;
  final double? amount;
  final String? note;
}

/// General-purpose agreement, independent of any particular habit or activity.
/// Constructing one represents a confirmed creation; proposals belong in the
/// application layer and must not be passed here until the user confirms them.
class SupportAgreement {
  SupportAgreement({
    required this.id,
    required this.profileId,
    required this.companionId,
    required String objective,
    required this.createdAt,
    this.unit,
    this.target,
    this.duration,
    this.reminder,
    this.status = SupportAgreementStatus.active,
    this.revision = 1,
    List<SupportAgreementRevision> revisions = const [],
    List<SupportAgreementEvent> events = const [],
  }) : objective = _normalizeObjective(objective),
       revisions = List.unmodifiable(revisions),
       events = List.unmodifiable(events) {
    _required(id, 'id');
    _required(profileId, 'profileId');
    _required(companionId, 'companionId');
    _validateRevision(revision);
    _optionalText(unit, 'unit');
    _optionalText(reminder, 'reminder');
    _validateNumber(target, 'target');
    _validateDuration(duration);
    if (this.revisions.any((r) => r.agreementId != id) ||
        this.events.any((e) => e.agreementId != id)) {
      throw ArgumentError('Revision/event belongs to another agreement.');
    }
    if (this.revisions.isNotEmpty &&
        (this.revisions.last.revision != revision ||
            this.revisions.last.objective != this.objective ||
            this.revisions.last.unit != unit ||
            this.revisions.last.target != target ||
            this.revisions.last.duration != duration ||
            this.revisions.last.reminder != reminder ||
            this.revisions.last.status != status)) {
      throw ArgumentError('Latest revision must match the agreement.');
    }
  }

  static const int maxObjectiveLength = 2000;

  final String id;
  final String profileId;
  final String companionId;
  final String objective;
  final String? unit;
  final double? target;
  final Duration? duration;
  final String? reminder;
  final SupportAgreementStatus status;
  final int revision;
  final DateTime createdAt;
  final List<SupportAgreementRevision> revisions;
  final List<SupportAgreementEvent> events;

  /// Changes definition fields and appends an immutable new revision.
  SupportAgreement modify({
    required String revisionId,
    required DateTime changedAt,
    String? objective,
    Object? unit = _unchanged,
    Object? target = _unchanged,
    Object? duration = _unchanged,
    Object? reminder = _unchanged,
  }) {
    _ensureNotCompleted();
    return _revise(
      revisionId: revisionId,
      changedAt: changedAt,
      objective: objective ?? this.objective,
      unit: identical(unit, _unchanged) ? this.unit : unit as String?,
      target: identical(target, _unchanged)
          ? this.target
          : (target as num?)?.toDouble(),
      duration: identical(duration, _unchanged)
          ? this.duration
          : duration as Duration?,
      reminder: identical(reminder, _unchanged)
          ? this.reminder
          : reminder as String?,
      status: status,
    );
  }

  SupportAgreement pause({required String revisionId, required DateTime at}) {
    if (status != SupportAgreementStatus.active) {
      throw StateError('Only an active agreement can be paused.');
    }
    return _revise(
      revisionId: revisionId,
      changedAt: at,
      objective: objective,
      unit: unit,
      target: target,
      duration: duration,
      reminder: reminder,
      status: SupportAgreementStatus.paused,
    );
  }

  SupportAgreement resume({required String revisionId, required DateTime at}) {
    if (status != SupportAgreementStatus.paused) {
      throw StateError('Only a paused agreement can be resumed.');
    }
    return _revise(
      revisionId: revisionId,
      changedAt: at,
      objective: objective,
      unit: unit,
      target: target,
      duration: duration,
      reminder: reminder,
      status: SupportAgreementStatus.active,
    );
  }

  SupportAgreement complete({required String revisionId, required DateTime at}) {
    _ensureNotCompleted();
    return _revise(
      revisionId: revisionId,
      changedAt: at,
      objective: objective,
      unit: unit,
      target: target,
      duration: duration,
      reminder: reminder,
      status: SupportAgreementStatus.completed,
    );
  }

  /// Returns a new agreement with [event] appended, preserving prior events.
  SupportAgreement recordEvent(SupportAgreementEvent event) {
    _ensureNotCompleted();
    if (event.agreementId != id) {
      throw ArgumentError.value(event.agreementId, 'event.agreementId');
    }
    if (events.any((existing) => existing.id == event.id)) {
      throw ArgumentError.value(event.id, 'event.id', 'Duplicate event ID.');
    }
    return SupportAgreement(
      id: id,
      profileId: profileId,
      companionId: companionId,
      objective: objective,
      unit: unit,
      target: target,
      duration: duration,
      reminder: reminder,
      status: status,
      revision: revision,
      createdAt: createdAt,
      revisions: revisions,
      events: [...events, event],
    );
  }

  SupportAgreement _revise({
    required String revisionId,
    required DateTime changedAt,
    required String objective,
    required String? unit,
    required double? target,
    required Duration? duration,
    required String? reminder,
    required SupportAgreementStatus status,
  }) {
    if (revisions.any((existing) => existing.id == revisionId)) {
      throw ArgumentError.value(revisionId, 'revisionId', 'Duplicate revision ID.');
    }
    final normalizedObjective = _normalizeObjective(objective);
    final nextRevision = revision + 1;
    final snapshot = SupportAgreementRevision(
      id: revisionId,
      agreementId: id,
      revision: nextRevision,
      objective: normalizedObjective,
      unit: unit,
      target: target,
      duration: duration,
      reminder: reminder,
      status: status,
      createdAt: changedAt,
    );
    return SupportAgreement(
      id: id,
      profileId: profileId,
      companionId: companionId,
      objective: normalizedObjective,
      unit: unit,
      target: target,
      duration: duration,
      reminder: reminder,
      status: status,
      revision: nextRevision,
      createdAt: createdAt,
      revisions: [...revisions, snapshot],
      events: events,
    );
  }

  void _ensureNotCompleted() {
    if (status == SupportAgreementStatus.completed) {
      throw StateError('A completed agreement is immutable.');
    }
  }

  static const Object _unchanged = Object();
}

String _normalizeObjective(String value) {
  if (value.trim().isEmpty || value.length > SupportAgreement.maxObjectiveLength) {
    throw ArgumentError.value(value, 'objective', 'Must contain 1–2000 characters.');
  }
  return value.trim();
}

void _validateObjective(String value) => _normalizeObjective(value);
void _required(String value, String field) {
  if (value.trim().isEmpty) throw ArgumentError.value(value, field);
}

void _optionalText(String? value, String field) {
  if (value != null && value.trim().isEmpty) throw ArgumentError.value(value, field);
}

void _validateNumber(double? value, String field) {
  if (value != null && (!value.isFinite || value < 0)) {
    throw ArgumentError.value(value, field, 'Must be finite and non-negative.');
  }
}

void _validateDuration(Duration? value) {
  if (value != null && value.isNegative) {
    throw ArgumentError.value(value, 'duration', 'Must be non-negative.');
  }
}

void _validateRevision(int revision) {
  if (revision <= 0) throw ArgumentError.value(revision, 'revision');
}
