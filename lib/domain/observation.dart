import 'activity.dart';

/// A value recorded without a running clock: a glass of water, a weigh-in, a
/// note. The original text and the definition at that moment are kept as they
/// were; a correction adds a revision instead of rewriting anything.
class Observation {
  const Observation({
    required this.id,
    required this.profileId,
    required this.spaceId,
    required this.companionId,
    required this.definition,
    required this.original,
    required this.values,
    required this.provenance,
    required this.revision,
    required this.observedAt,
    required this.recordedAt,
    required this.localDay,
    this.runId,
    this.templateId,
    this.supersedesId,
  });

  static const provenances = {'user', 'assistant', 'import'};

  final String id, profileId, spaceId, companionId;

  /// Always null for a point record; reserved for records made during a run.
  final String? runId;
  final String? templateId;

  /// The definition as it was when the value was recorded.
  final ActivityDefinition definition;
  final String original;

  /// Only the fields that were given: a missing key means «not recorded».
  final Map<String, Object> values;
  final String provenance;
  final int revision;
  final String? supersedesId;
  final DateTime observedAt, recordedAt;

  /// `YYYY-MM-DD` in the device's local time when it was observed.
  final String localDay;

  static String dayOf(DateTime moment) {
    final local = moment.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}';
  }
}
