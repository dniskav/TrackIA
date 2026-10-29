import 'workout.dart';

ValidationException _invalid(String what) =>
    ValidationException('La regla no es válida: $what.');

void _onlyKeys(Map<String, dynamic> json, Set<String> allowed) {
  final extra = json.keys.where((k) => !allowed.contains(k));
  if (extra.isNotEmpty) throw _invalid('no admite «${extra.first}»');
}

/// What a goal or an achievement measures (data-model §4).
class Metric {
  Metric({
    required this.source,
    required this.per,
    this.field,
    this.aggregate,
  }) {
    if (!sources.contains(source)) throw _invalid('origen desconocido');
    if (!pers.contains(per)) throw _invalid('periodo desconocido');
    if (source == 'field') {
      if (field == null || field!.isEmpty || field!.length > 64) {
        throw _invalid('falta el campo');
      }
      if (!aggregates.contains(aggregate)) {
        throw _invalid('forma de contar desconocida');
      }
    } else if (field != null || aggregate != null) {
      throw _invalid('solo un campo lleva forma de contar');
    }
  }

  factory Metric.time(String per) => Metric(source: 'time', per: per);
  factory Metric.sessions(String per) => Metric(source: 'sessions', per: per);

  static const sources = {'time', 'sessions', 'field'};
  static const aggregates = {'sum', 'max', 'avg', 'distinct', 'countTrue'};
  static const pers = {'session', 'day', 'week', 'total'};

  final String source, per;

  /// Only with `source == 'field'`.
  final String? field, aggregate;

  Map<String, Object> toJson() => {
    'source': source,
    if (field != null) 'field': field!,
    if (aggregate != null) 'aggregate': aggregate!,
    'per': per,
  };

  factory Metric.fromJson(Object? value) {
    if (value is! Map) throw _invalid('la métrica debe ser un objeto');
    final json = Map<String, dynamic>.from(value);
    _onlyKeys(json, {'source', 'field', 'aggregate', 'per'});
    final source = json['source'], per = json['per'];
    final field = json['field'], aggregate = json['aggregate'];
    if (source is! String || per is! String) {
      throw _invalid('faltan origen o periodo');
    }
    if ((field != null && field is! String) ||
        (aggregate != null && aggregate is! String)) {
      throw _invalid('campo o forma de contar no válidos');
    }
    return Metric(
      source: source,
      per: per,
      field: field as String?,
      aggregate: aggregate as String?,
    );
  }

  Metric withPer(String newPer) =>
      Metric(source: source, per: newPer, field: field, aggregate: aggregate);

  @override
  bool operator ==(Object other) =>
      other is Metric &&
      other.source == source &&
      other.per == per &&
      other.field == field &&
      other.aggregate == aggregate;

  @override
  int get hashCode => Object.hash(source, per, field, aggregate);
}

/// A daily or weekly target; reaching [minimum] keeps the day «done».
class GoalRule {
  GoalRule({
    required this.metric,
    required this.period,
    required this.target,
    this.minimum,
  }) {
    if (!{'day', 'week'}.contains(period)) throw _invalid('periodo de meta');
    if (metric.per != period) {
      throw _invalid('la métrica debe medirse por $period');
    }
    if (!(target > 0) || target.isNaN || target.isInfinite) {
      throw _invalid('el objetivo debe ser mayor que 0');
    }
    final min = minimum;
    if (min != null && (!(min > 0) || min > target)) {
      throw _invalid('el mínimo debe ser mayor que 0 y no superar el objetivo');
    }
  }

  final Metric metric;
  final String period;
  final double target;
  final double? minimum;

  Map<String, Object> toJson() => {
    'metric': metric.toJson(),
    'period': period,
    'target': target,
    if (minimum != null) 'minimum': minimum!,
  };

  factory GoalRule.fromJson(Object? value) {
    if (value is! Map) throw _invalid('la meta debe ser un objeto');
    final json = Map<String, dynamic>.from(value);
    _onlyKeys(json, {'metric', 'period', 'target', 'minimum'});
    final period = json['period'], target = json['target'];
    final minimum = json['minimum'];
    if (period is! String ||
        target is! num ||
        (minimum != null && minimum is! num)) {
      throw _invalid('faltan datos de la meta');
    }
    return GoalRule(
      metric: Metric.fromJson(json['metric']),
      period: period,
      target: target.toDouble(),
      minimum: (minimum as num?)?.toDouble(),
    );
  }

  /// `null` for anything that does not validate: a rule proposed by the AI is
  /// dropped whole (FR-036).
  static GoalRule? tryParse(Object? value) {
    try {
      return GoalRule.fromJson(value);
    } on ValidationException {
      return null;
    }
  }
}

/// Unlocks once, when the computed value reaches [threshold].
class AchievementRule {
  AchievementRule.threshold({
    required Metric this.metric,
    required this.threshold,
  }) : kind = 'threshold' {
    _check();
  }
  AchievementRule.streak({required this.threshold})
    : kind = 'streak',
      metric = null {
    _check();
  }

  final String kind;
  final Metric? metric;
  final double threshold;

  void _check() {
    if (!(threshold > 0) || threshold.isNaN || threshold.isInfinite) {
      throw _invalid('el umbral debe ser mayor que 0');
    }
  }

  Map<String, Object> toJson() => {
    'kind': kind,
    if (metric != null) 'metric': metric!.toJson(),
    'threshold': threshold == threshold.roundToDouble()
        ? threshold.toInt()
        : threshold,
  };

  factory AchievementRule.fromJson(Object? value) {
    if (value is! Map) throw _invalid('el logro debe ser un objeto');
    final json = Map<String, dynamic>.from(value);
    final threshold = json['threshold'];
    if (threshold is! num) throw _invalid('falta el umbral');
    switch (json['kind']) {
      case 'threshold':
        _onlyKeys(json, {'kind', 'metric', 'threshold'});
        return AchievementRule.threshold(
          metric: Metric.fromJson(json['metric']),
          threshold: threshold.toDouble(),
        );
      case 'streak':
        _onlyKeys(json, {'kind', 'threshold'});
        return AchievementRule.streak(threshold: threshold.toDouble());
      default:
        throw _invalid('tipo de logro desconocido');
    }
  }

  static AchievementRule? tryParse(Object? value) {
    try {
      return AchievementRule.fromJson(value);
    } on ValidationException {
      return null;
    }
  }
}

/// A saved achievement: its rule, title and icon (`contracts/visual-tokens.md`).
class Achievement {
  const Achievement({
    required this.id,
    required this.companionId,
    required this.rule,
    required this.ruleHash,
    required this.title,
    required this.icon,
    required this.origin,
    this.activityKey,
    this.unlock,
  });

  static const icons = {
    'first',
    'streak',
    'record',
    'time',
    'count',
    'variety',
    'trophy',
  };
  static const origins = {'generated', 'user', 'assistant'};

  final String id, companionId, ruleHash, title, icon, origin;
  final String? activityKey;
  final AchievementRule rule;
  final AchievementUnlock? unlock;

  bool get unlocked => unlock != null;
}

class AchievementUnlock {
  const AchievementUnlock({
    required this.achievementId,
    required this.unlockedAt,
    required this.value,
    this.sourceActivityId,
    this.sourceObservationId,
  });

  final String achievementId;
  final DateTime unlockedAt;
  final double value;
  final String? sourceActivityId, sourceObservationId;
}

/// One finished activity or point record. It counts 1 session and, for an
/// activity, the time of its ended segments.
class ProgressSession {
  const ProgressSession({
    required this.id,
    required this.day,
    this.seconds = 0,
    this.activityId,
    this.observationId,
  });

  final String id;

  /// `YYYY-MM-DD`, local day of the device.
  final String day;
  final int seconds;
  final String? activityId, observationId;
}

/// A value recorded for a typed field, with the session it belongs to.
class ProgressValue {
  const ProgressValue({
    required this.sessionId,
    required this.day,
    required this.field,
    required this.value,
  });

  final String sessionId, day, field;

  /// A number, a text, a choice or a boolean.
  final Object value;
}

/// Everything the engine reads: no database, no clock.
class ProgressData {
  const ProgressData({
    this.sessions = const [],
    this.values = const [],
    this.typedFields = const {},
  });

  final List<ProgressSession> sessions;
  final List<ProgressValue> values;

  /// Keys of fields that have a `type`; the legacy «notes only» fields do
  /// not take part in any calculation.
  final Set<String> typedFields;

  ProgressData onlySession(String sessionId) => ProgressData(
    sessions: sessions.where((s) => s.id == sessionId).toList(),
    values: values.where((v) => v.sessionId == sessionId).toList(),
    typedFields: typedFields,
  );

  ProgressData without(String sessionId) => ProgressData(
    sessions: sessions.where((s) => s.id != sessionId).toList(),
    values: values.where((v) => v.sessionId != sessionId).toList(),
    typedFields: typedFields,
  );
}

/// How a goal stands at a moment.
class GoalProgress {
  const GoalProgress({required this.value, required this.target, this.minimum});

  final double value, target;
  final double? minimum;

  bool get met => value >= target;
  bool get minimumMet => minimum != null && value >= minimum!;
  double get fraction => (value / target).clamp(0.0, 1.0);
}

class StreakResult {
  const StreakResult({
    required this.current,
    required this.best,
    required this.freeDaysUsedThisWeek,
  });

  final int current, best, freeDaysUsedThisWeek;
}

/// A record beaten by a session (shown in «Sesión terminada»).
class ProgressRecord {
  const ProgressRecord(this.label, this.value, {this.unit = ''});

  final String label, unit;
  final double value;
}

/// What changed after a save: new unlocks and new records.
class ProgressDelta {
  const ProgressDelta({this.unlocked = const [], this.records = const []});

  final List<Achievement> unlocked;
  final List<ProgressRecord> records;

  bool get isEmpty => unlocked.isEmpty && records.isEmpty;
}
