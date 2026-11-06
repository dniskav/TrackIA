import 'space.dart';

/// Persisted state of an external operation linked to a message revision.
enum EffectStatus { proposed, confirmed, failed, uncertain, superseded }

/// An idempotent operation identity, never an authorization to repeat work.
class EffectLink {
  EffectLink({
    required String id,
    required String profileId,
    required String companionId,
    required String messageRevisionId,
    required String targetType,
    required String targetId,
    required String operationId,
    required this.createdAt,
    this.status = EffectStatus.proposed,
  }) : id = validTrackiaId(id),
       profileId = validTrackiaId(profileId),
       companionId = validTrackiaId(companionId),
       messageRevisionId = validTrackiaId(messageRevisionId),
       targetId = validTrackiaId(targetId),
       operationId = validTrackiaId(operationId),
       targetType = _targetType(targetType);

  final String id;
  final String profileId;
  final String companionId;
  final String messageRevisionId;
  final String targetType;
  final String targetId;
  final String operationId;
  final DateTime createdAt;
  final EffectStatus status;

  static String _targetType(String value) {
    if (value.trim().isEmpty) throw ArgumentError.value(value, 'targetType');
    return value;
  }
}
