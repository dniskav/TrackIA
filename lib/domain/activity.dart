import 'dart:convert';
import 'dart:typed_data';
import 'space.dart';
import 'workout.dart';

class ActivityDefinition {
  ActivityDefinition({
    required String name,
    this.repeated = true,
    this.restSeconds = 90,
    this.activitySeconds,
    this.targetSets,
    this.targetCycles,
    this.completedCycles = 0,
    List<Map<String, Object>> fields = const [],
    this.instructions = '',
    this.origin = 'user',
    String companionId = 'gymbro',
    this.segmentSingular,
    this.segmentPlural,
    List<String> userSet = const [],
    String? activityKey,
  }) : name = validName(name),
       companionId = validTrackiaId(companionId),
       fields = List.unmodifiable(
         fields.map(
           (f) => Map<String, Object>.unmodifiable(_normalizeField(f)),
         ),
       ),
       userSet = List.unmodifiable(userSet),
       _activityKey = activityKey {
    validName(name);
    if (restSeconds < 0 ||
        restSeconds > 1800 ||
        (activitySeconds != null &&
            (activitySeconds! < 1 || activitySeconds! > 86400)) ||
        (targetSets != null && (targetSets! < 1 || targetSets! > 100)) ||
        (targetCycles != null && (targetCycles! < 1 || targetCycles! > 100)) ||
        completedCycles < 0 ||
        completedCycles > 999 ||
        fields.length > 12 ||
        instructions.length > 3000 ||
        fields.map((f) => f['key']).toSet().length != fields.length) {
      throw const ValidationException(
        'La propuesta de actividad no es válida.',
      );
    }
    final singular = segmentSingular, plural = segmentPlural;
    if ((singular == null) != (plural == null) ||
        (singular != null && !_segmentName(singular)) ||
        (plural != null && !_segmentName(plural))) {
      throw const ValidationException(
        'El nombre del tramo no es válido: indica singular y plural de 1 a 24 caracteres.',
      );
    }
    final fieldKeys = this.fields.map((f) => f['key']).toSet();
    if (this.userSet.toSet().length != this.userSet.length ||
        this.userSet.any(
          (lock) =>
              !(_lockNames.contains(lock) ||
                  (lock.startsWith('field:') &&
                      fieldKeys.contains(lock.substring(6)))),
        )) {
      throw const ValidationException('Los datos fijados no son válidos.');
    }
    if (activityKey != null &&
        (activityKey.isEmpty || activityKey.length > 80)) {
      throw const ValidationException('La clave de la actividad no es válida.');
    }
  }

  /// Properties and fields the user has set by hand. The assistant may only
  /// propose changes to them; it never applies them on its own.
  /// True for a lock identifier that may appear in `userSet`.
  static bool isLockable(String lock) =>
      _lockNames.contains(lock) ||
      (lock.startsWith('field:') && lock.length > 6);

  static const _lockNames = {
    'name',
    'restSeconds',
    'activitySeconds',
    'targetSets',
    'targetCycles',
    'segmentSingular',
    'segmentPlural',
    'instructions',
  };

  /// Keys a field may carry. `key`, `label` and `unit` are the original three;
  /// the rest exist only on typed fields.
  static const _fieldKeys = {
    'key',
    'label',
    'unit',
    'type',
    'aggregate',
    'options',
    'min',
    'max',
    'countSingular',
    'countPlural',
  };
  static const _typedOnly = {
    'aggregate',
    'options',
    'min',
    'max',
    'countSingular',
    'countPlural',
  };
  static const fieldTypes = {'number', 'scale', 'text', 'choice', 'boolean'};
  static const _aggregates = <String, Set<String>>{
    'number': {'sum', 'max', 'avg', 'none'},
    'scale': {'avg', 'none'},
    'text': {'distinct', 'none'},
    'choice': {'distinct', 'none'},
    'boolean': {'countTrue', 'none'},
  };
  static const _defaultAggregate = <String, String>{
    'number': 'sum',
    'scale': 'avg',
    'text': 'none',
    'choice': 'distinct',
    'boolean': 'countTrue',
  };

  static bool _segmentName(String value) =>
      value.trim() == value && value.isNotEmpty && value.length <= 24;

  static bool _shortText(Object? value, int max) =>
      value is String && value.isNotEmpty && value.length <= max;

  /// Validates one field and fills the defaults of typed fields. A field with
  /// no `type` is a note-only field saved before typed fields existed and is
  /// returned exactly as it came.
  static Map<String, Object> _normalizeField(Map<String, Object> field) {
    const invalid = ValidationException('Los datos propuestos no son válidos.');
    final keys = field.keys.toSet();
    final key = field['key'], label = field['label'], unit = field['unit'];
    if (keys.difference(_fieldKeys).isNotEmpty ||
        !keys.containsAll({'key', 'label', 'unit'}) ||
        key is! String ||
        label is! String ||
        unit is! String ||
        !RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(key) ||
        label.isEmpty ||
        label.length > 80 ||
        unit.length > 30) {
      throw invalid;
    }
    final type = field['type'];
    if (type == null) {
      if (keys.any(_typedOnly.contains)) throw invalid;
      return Map<String, Object>.of(field);
    }
    if (type is! String || !fieldTypes.contains(type)) throw invalid;
    final aggregate = field['aggregate'] ?? _defaultAggregate[type]!;
    if (aggregate is! String || !_aggregates[type]!.contains(aggregate)) {
      throw invalid;
    }
    final result = <String, Object>{
      'key': key,
      'label': label,
      'unit': unit,
      'type': type,
      'aggregate': aggregate,
    };
    final options = field['options'];
    if (type == 'choice') {
      if (options is! List ||
          options.isEmpty ||
          options.length > 20 ||
          options.any((o) => !_shortText(o, 40)) ||
          options.toSet().length != options.length) {
        throw invalid;
      }
      result['options'] = List<String>.unmodifiable(options.cast<String>());
    } else if (options != null) {
      throw invalid;
    }
    if (type == 'scale') {
      final min = field['min'] ?? 1, max = field['max'] ?? 5;
      if (min is! int || max is! int || min < 1 || min >= max || max > 10) {
        throw invalid;
      }
      result['min'] = min;
      result['max'] = max;
    } else if (field.containsKey('min') || field.containsKey('max')) {
      throw invalid;
    }
    for (final name in ['countSingular', 'countPlural']) {
      final value = field[name];
      if (value == null) continue;
      if (!_shortText(value, 40)) throw invalid;
      result[name] = value;
    }
    return result;
  }

  final String name, instructions, origin, companionId;
  final bool repeated;
  final int restSeconds;
  final int? activitySeconds;
  final int? targetSets;
  final int? targetCycles;
  final int completedCycles;
  final List<Map<String, Object>> fields;

  /// Names of one tramo, e.g. «tiempo»/«tiempos». Both or neither.
  final String? segmentSingular, segmentPlural;

  /// Locked properties; see [_lockNames] and `field:<key>`.
  final List<String> userSet;
  final String? _activityKey;

  /// Stable identity of the activity across renames. Goals and achievements
  /// follow it; it is derived from the name until the name changes by hand.
  String get activityKey =>
      _activityKey ?? name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  Map<String, dynamic> toJson() => {
    'name': name,
    'repeated': repeated,
    'restSeconds': restSeconds,
    if (activitySeconds != null) 'activitySeconds': activitySeconds,
    if (targetSets != null) 'targetSets': targetSets,
    if (targetCycles != null) 'targetCycles': targetCycles,
    'completedCycles': completedCycles,
    'fields': fields,
    'instructions': instructions,
    'origin': origin,
    'companionId': companionId,
    if (segmentSingular != null) 'segmentSingular': segmentSingular,
    if (segmentPlural != null) 'segmentPlural': segmentPlural,
    if (userSet.isNotEmpty) 'userSet': userSet,
    if (_activityKey != null) 'activityKey': _activityKey,
  };
  factory ActivityDefinition.fromJson(Map<String, dynamic> value) =>
      ActivityDefinition(
        name: value['name'] as String,
        repeated: value['repeated'] as bool,
        restSeconds: value['restSeconds'] as int,
        activitySeconds: value['activitySeconds'] as int?,
        targetSets: value['targetSets'] as int?,
        targetCycles: value['targetCycles'] as int?,
        completedCycles: value['completedCycles'] as int? ?? 0,
        fields: (value['fields'] as List)
            .map((f) => Map<String, Object>.from(f as Map))
            .toList(),
        instructions: value['instructions'] as String? ?? '',
        origin: value['origin'] as String? ?? 'user',
        companionId: value['companionId'] as String? ?? 'gymbro',
        segmentSingular: value['segmentSingular'] as String?,
        segmentPlural: value['segmentPlural'] as String?,
        userSet:
            (value['userSet'] as List?)?.map((e) => e as String).toList() ??
            const [],
        activityKey: value['activityKey'] as String?,
      );

  ActivityDefinition forCompanion(String id) =>
      ActivityDefinition.fromJson({...toJson(), 'companionId': id});

  static ActivityDefinition? proposal(String response) {
    final matches = RegExp(
      r'```gymia-activity\s*\n([\s\S]*?)```',
    ).allMatches(response).toList();
    if (matches.length != 1) return null;
    try {
      final json = jsonDecode(matches.single.group(1)!) as Map<String, dynamic>;
      if (json.keys.toSet().difference({
        'name',
        'repeated',
        'restSeconds',
        'activitySeconds',
        'targetSets',
        'targetCycles',
        'fields',
        'instructions',
        'segmentSingular',
        'segmentPlural',
      }).isNotEmpty) {
        return null;
      }
      return ActivityDefinition.fromJson({...json, 'origin': 'llm'});
    } catch (_) {
      return null;
    }
  }
}

Map<String, int>? activityTimingProposal(String response) {
  final matches = RegExp(
    r'```gymia-timing\s*\n([\s\S]*?)```',
  ).allMatches(response).toList();
  if (matches.length != 1) return null;
  try {
    final value = jsonDecode(matches.single.group(1)!) as Map<String, dynamic>;
    final keys = value.keys.toSet();
    if (keys.isEmpty ||
        keys.difference({
          'activitySeconds',
          'restSeconds',
          'targetCycles',
        }).isNotEmpty ||
        value.values.any((v) => v is! int)) {
      return null;
    }
    final activity = value['activitySeconds'] as int?;
    final rest = value['restSeconds'] as int?;
    final cycles = value['targetCycles'] as int?;
    if ((activity != null && (activity < 1 || activity > 86400)) ||
        (rest != null && (rest < 0 || rest > 1800)) ||
        (cycles != null && (cycles < 1 || cycles > 100))) {
      return null;
    }
    return value.cast<String, int>();
  } catch (_) {
    return null;
  }
}

class ActivityInterval {
  const ActivityInterval(
    this.id,
    this.startedAt,
    this.endedAt, {
    this.restSeconds,
  });
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? restSeconds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'plannedRestSeconds': restSeconds,
  };
}

class ActivityMedia {
  ActivityMedia({
    required this.name,
    required this.mime,
    required Uint8List bytes,
  }) : bytes = Uint8List.fromList(bytes) {
    if (name.isEmpty ||
        name.length > 255 ||
        bytes.isEmpty ||
        bytes.length > 4 * 1024 * 1024 ||
        ![
          'image/png',
          'image/jpeg',
          'image/webp',
          'audio/mpeg',
          'audio/wav',
          'audio/mp4',
          'audio/ogg',
          'audio/flac',
          'application/pdf',
        ].contains(mime)) {
      throw const ValidationException('El adjunto no es válido o supera 4 MB.');
    }
  }
  final String name, mime;
  final Uint8List bytes;
  Map<String, dynamic> metadata() => {'name': name, 'mime': mime};
  Map<String, dynamic> toJson() => {
    ...metadata(),
    'base64': base64Encode(bytes),
  };
  factory ActivityMedia.fromJson(Map<String, dynamic> json) {
    final encoded = json['base64'] as String;
    if (encoded.length > 6 * 1024 * 1024) {
      throw const ValidationException('El adjunto es demasiado grande.');
    }
    return ActivityMedia(
      name: json['name'] as String,
      mime: json['mime'] as String,
      bytes: base64Decode(encoded),
    );
  }
}

class ActivityMessage {
  const ActivityMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.recordedAt,
    this.intervalId,
    this.metrics = const {},
    this.mediaName,
    this.mediaMime,
  });
  final String id, text, role;
  final String? intervalId;
  final DateTime recordedAt;
  final Map<String, dynamic> metrics;
  final String? mediaName, mediaMime;
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'role': role,
    'intervalId': intervalId,
    'recordedAt': recordedAt.toIso8601String(),
    'metrics': metrics,
    'attachment': mediaName == null
        ? null
        : {'name': mediaName, 'mime': mediaMime},
  };
}

class FocusActivity {
  const FocusActivity({
    required this.id,
    required this.workoutId,
    required this.definition,
    required this.createdAt,
    required this.intervals,
    required this.messages,
    this.exerciseId,
    this.finishedAt,
    this.draft = '',
    this.restEndsAt,
    this.finishedRecordedAt,
    this.finishIssues = const [],
  });
  final String id, workoutId, draft;
  final String? exerciseId;
  final ActivityDefinition definition;
  final DateTime createdAt;
  final DateTime? finishedAt, restEndsAt, finishedRecordedAt;
  final List<String> finishIssues;
  final List<ActivityInterval> intervals;
  final List<ActivityMessage> messages;
  ActivityInterval? get running =>
      intervals.where((i) => i.endedAt == null).firstOrNull;
  bool get active => finishedAt == null;
  Map<String, dynamic> toJson() => {
    'id': id,
    'workoutId': workoutId,
    'definition': definition.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'finishedRecordedAt': finishedRecordedAt?.toIso8601String(),
    'finishIssues': finishIssues,
    'intervals': [
      for (var index = 0; index < intervals.length; index++)
        {
          ...intervals[index].toJson(),
          'durationSeconds':
              intervals[index].endedAt != null &&
                  !intervals[index].endedAt!.isBefore(
                    intervals[index].startedAt,
                  )
              ? intervals[index].endedAt!
                    .difference(intervals[index].startedAt)
                    .inSeconds
              : null,
          'actualRestSeconds':
              index + 1 < intervals.length &&
                  intervals[index].endedAt != null &&
                  !intervals[index + 1].startedAt.isBefore(
                    intervals[index].endedAt!,
                  )
              ? intervals[index + 1].startedAt
                    .difference(intervals[index].endedAt!)
                    .inSeconds
              : null,
        },
    ],
    'messages': messages.map((m) => m.toJson()).toList(),
  };
}

/// Checks recorded values against the activity's fields. Every key must be a
/// field of the activity and every value must suit that field's type; fields
/// saved before types existed keep their original rules (number, boolean or
/// text up to 500 characters). A missing key means «not recorded», never zero.
Map<String, Object> validateFieldValues(
  ActivityDefinition definition,
  Map<String, Object?> values,
) {
  const mismatch = ValidationException(
    'Los valores no coinciden con los datos de esta actividad.',
  );
  final byKey = {for (final f in definition.fields) f['key'] as String: f};
  final result = <String, Object>{};
  for (final entry in values.entries) {
    final field = byKey[entry.key];
    final value = entry.value;
    if (field == null || value == null) throw mismatch;
    final ok = switch (field['type']) {
      null =>
        value is num && value.isFinite ||
            value is bool ||
            value is String && value.length <= 500,
      'number' => value is num && value.isFinite,
      'scale' =>
        value is int &&
            value >= (field['min'] as int) &&
            value <= (field['max'] as int),
      'text' => value is String && value.length <= 500,
      'choice' => value is String && (field['options'] as List).contains(value),
      'boolean' => value is bool,
      _ => false,
    };
    if (!ok) throw mismatch;
    result[entry.key] = value;
  }
  return result;
}

/// Only a complete unambiguous strength shorthand is parsed locally. Preserve
/// everything else as original text, without forcing it into strength metrics.
Map<String, dynamic> compactStrengthMetrics(
  String text,
  ActivityDefinition definition,
) {
  if (!definition.fields.any(
        (f) => f['key'] == 'weight_kg' && f['unit'] == 'kg',
      ) ||
      !definition.fields.any((f) => f['key'] == 'reps')) {
    return {};
  }
  final match = RegExp(
    r'^\s*(\d{1,4}(?:[.,]\d{1,2})?)\s*(?:kg|k)\s*(\d{1,3})\s*r(?:eps)?(?:\s*(f|nf))?\s*$',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return {};
  try {
    return {
      'weight_kg': parseWeight(match[1]!) / 100,
      'reps': parseReps(match[2]!),
      if (match[3] != null &&
          definition.fields.any((f) => f['key'] == 'failure'))
        'failure': match[3]!.toLowerCase() == 'f',
    };
  } on ValidationException {
    return {};
  }
}

abstract interface class ActivityRepository {
  Future<List<FocusActivity>> loadActivities();
  Future<String> prepareActivity(
    ActivityDefinition definition, {
    String? exerciseId,
  });
  Future<void> startInterval(String activityId);
  Future<void> stopInterval(String activityId);
  Future<void> setActivityDraft(String activityId, String text);
  Future<String> recordActivityMessage(
    String activityId,
    String text, {
    String role = 'user',
    String? intervalId,
    ActivityMedia? media,
    Map<String, Object>? metrics,
  });
  Future<void> finishActivity(
    String activityId,
    DateTime end, {
    bool acceptConflicts = false,
  });
  Future<void> setActivityRest(
    String activityId,
    int seconds, {
    String source = 'user',
  });
  Future<void> setActivityTiming(
    String activityId, {
    required int? activitySeconds,
    required int restSeconds,
    required int? targetCycles,
    String source = 'user',
  });
  Future<ActivityMedia?> loadActivityMedia(String messageId);
  Future<void> cancelActivityPreparation(String activityId);
  Future<void> renameActivity(
    String activityId,
    String name, {
    String source = 'user',
  });
  Future<void> changeCompletedCycles(String activityId, int delta);
  Future<void> replaceActivityPreparation(
    String activityId,
    ActivityDefinition definition, {
    String? exerciseId,
  });
  Future<void> resumeActivityPreparation(String activityId);
  Future<void> interpretActivityMessage(
    String messageId,
    Map<String, dynamic> metrics, {
    List<Map<String, Object>> fields = const [],
  });

  /// Frees one property the user had fixed by hand (FR-023); the lock UI calls
  /// this when the padlock is tapped.
  Future<void> clearUserSetLock(String activityId, String lock);
}
