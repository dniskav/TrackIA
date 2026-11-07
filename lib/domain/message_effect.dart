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

/// A real operation the app executed because of an assistant answer, tied to
/// the user message (and revision) that triggered it.
///
/// [operationKey] is the idempotency identity. It is built from the message,
/// not the revision, so resending or editing the same message cannot apply the
/// same operation twice.
class MessageEffect {
  MessageEffect({
    required String id,
    required String profileId,
    required String companionId,
    required String messageId,
    required String revisionId,
    required String kind,
    required String targetId,
    required String operationKey,
    required String summary,
    required this.createdAt,
    this.status = EffectStatus.confirmed,
  }) : id = validTrackiaId(id),
       profileId = validTrackiaId(profileId),
       companionId = validTrackiaId(companionId),
       messageId = validTrackiaId(messageId),
       revisionId = validTrackiaId(revisionId),
       targetId = validTrackiaId(targetId),
       operationKey = validTrackiaId(operationKey),
       kind = _kind(kind),
       summary = summary.trim();

  final String id;
  final String profileId;
  final String companionId;
  final String messageId;
  final String revisionId;

  /// `activity`, `target`, `timing`, `goal`, `achievement`, `reminder-copy`,
  /// `sheet-edit`, `observation`, `memory`...
  final String kind;
  final String targetId;
  final String operationKey;

  /// Short Spanish sentence that can be handed to the model.
  final String summary;
  final DateTime createdAt;
  final EffectStatus status;

  /// Stable key: same message + kind + content gives the same key.
  static String keyFor(String messageId, String kind, String discriminator) {
    var hash = 0xcbf29ce484222325;
    for (final unit in discriminator.codeUnits) {
      hash = ((hash ^ unit) * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return '${validTrackiaId(messageId)}-${_kind(kind)}-${hash.toRadixString(16)}';
  }

  static String _kind(String value) {
    if (!RegExp(r'^[a-z][a-z0-9-]{0,40}$').hasMatch(value)) {
      throw ArgumentError.value(value, 'kind');
    }
    return value;
  }
}
