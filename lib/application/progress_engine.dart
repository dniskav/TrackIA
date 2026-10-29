import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/progress.dart';
import '../domain/reminder.dart' show isoWeekId;

/// Goals, streaks and achievements, computed from saved data only (FR-032).
///
/// Everything here is pure: no database, no clock, no AI. Days are the stored
/// local days (`YYYY-MM-DD`), so a change of time zone never rewrites history.

DateTime _day(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

String _key(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

DateTime _previous(DateTime day) => DateTime(day.year, day.month, day.day - 1);

String _week(String day) => isoWeekId(_day(day));

bool _inPeriod(String period, String day, String at) => switch (period) {
  'day' => day == at,
  'week' => _week(day) == _week(at),
  _ => true,
};

num? _number(Object value) => value is num ? value : null;

double _aggregate(String aggregate, Iterable<Object> values) {
  switch (aggregate) {
    case 'sum':
      return values
          .map(_number)
          .whereType<num>()
          .fold<double>(0, (a, b) => a + b);
    case 'max':
      final numbers = values.map(_number).whereType<num>();
      return numbers.isEmpty
          ? 0
          : numbers.reduce((a, b) => a > b ? a : b).toDouble();
    case 'avg':
      final numbers = values.map(_number).whereType<num>().toList();
      return numbers.isEmpty
          ? 0
          : numbers.fold<double>(0, (a, b) => a + b) / numbers.length;
    case 'distinct':
      return values.map((v) => v.toString()).toSet().length.toDouble();
    case 'countTrue':
      return values.where((v) => v == true).length.toDouble();
  }
  return 0;
}

double _forSessions(Metric metric, ProgressData data, Set<String> ids) {
  switch (metric.source) {
    case 'time':
      return data.sessions
          .where((s) => ids.contains(s.id))
          .fold<double>(0, (a, s) => a + s.seconds);
    case 'sessions':
      return data.sessions.where((s) => ids.contains(s.id)).length.toDouble();
    default:
      if (!data.typedFields.contains(metric.field)) return 0;
      return _aggregate(
        metric.aggregate!,
        data.values
            .where((v) => v.field == metric.field && ids.contains(v.sessionId))
            .map((v) => v.value),
      );
  }
}

/// The value of [metric] for the period that contains [at] (a stored day). For
/// `per: session` it is the best single session; for `total`, everything.
double metricValue(Metric metric, ProgressData data, {required String at}) {
  if (metric.per == 'session') {
    var best = 0.0;
    for (final s in data.sessions) {
      final v = _forSessions(metric, data, {s.id});
      if (v > best) best = v;
    }
    return best;
  }
  final ids = {
    for (final s in data.sessions)
      if (_inPeriod(metric.per, s.day, at)) s.id,
  };
  if (metric.source == 'field' && metric.aggregate != null) {
    // Values count by their own day, so a session spanning midnight is split.
    if (!data.typedFields.contains(metric.field)) return 0;
    return _aggregate(
      metric.aggregate!,
      data.values
          .where(
            (v) => v.field == metric.field && _inPeriod(metric.per, v.day, at),
          )
          .map((v) => v.value),
    );
  }
  return _forSessions(metric, data, ids);
}

GoalProgress goalProgress(
  GoalRule goal,
  ProgressData data, {
  required String at,
}) => GoalProgress(
  value: metricValue(goal.metric, data, at: at),
  target: goal.target,
  minimum: goal.minimum,
);

/// Days that count for the streak: with a daily goal, the days that reach the
/// goal or its minimum; otherwise any day with at least one record.
Set<String> fulfilledDays(ProgressData data, {GoalRule? goal}) {
  final days = {
    for (final s in data.sessions) s.day,
    for (final v in data.values) v.day,
  };
  if (goal == null || goal.period != 'day') return days;
  return {
    for (final day in days)
      if (_reached(goalProgress(goal, data, at: day))) day,
  };
}

bool _reached(GoalProgress p) => p.met || p.minimumMet;

/// Current and best streak (research D14).
///
/// Counts consecutive fulfilled days backwards from yesterday (and today if it
/// is already fulfilled). In each ISO week the first [freeDays] unfulfilled
/// days neither add nor break; the next one breaks. Today, while open, never
/// breaks anything.
StreakResult streak(
  Set<String> fulfilled, {
  required String today,
  int freeDays = 1,
}) {
  if (fulfilled.isEmpty) {
    return const StreakResult(current: 0, best: 0, freeDaysUsedThisWeek: 0);
  }
  final first = fulfilled.map(_day).reduce((a, b) => a.isBefore(b) ? a : b);
  final todayDay = _day(today);

  // Unfulfilled days of [day]'s ISO week that come before it (and not before
  // the first record: nothing was expected then).
  int missedEarlierInWeek(DateTime day) {
    var count = 0;
    var cursor = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    while (cursor.isBefore(day)) {
      if (!cursor.isBefore(first) && !fulfilled.contains(_key(cursor))) count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
    return count;
  }

  int walk(DateTime end) {
    var count = 0;
    var day = end;
    while (!day.isBefore(first)) {
      if (fulfilled.contains(_key(day))) {
        count++;
      } else if (missedEarlierInWeek(day) >= freeDays) {
        break;
      }
      day = _previous(day);
    }
    return count;
  }

  final end = fulfilled.contains(today) ? todayDay : _previous(todayDay);
  var best = 0;
  for (final day in fulfilled) {
    final d = _day(day);
    if (d.isAfter(todayDay)) continue;
    final run = walk(d);
    if (run > best) best = run;
  }
  final current = walk(end);
  final monday = DateTime(
    todayDay.year,
    todayDay.month,
    todayDay.day - (todayDay.weekday - 1),
  );
  var missedThisWeek = 0;
  for (
    var cursor = monday;
    cursor.isBefore(todayDay);
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 1)
  ) {
    if (!cursor.isBefore(first) && !fulfilled.contains(_key(cursor))) {
      missedThisWeek++;
    }
  }
  return StreakResult(
    current: current,
    best: best < current ? current : best,
    freeDaysUsedThisWeek: missedThisWeek < freeDays ? missedThisWeek : freeDays,
  );
}

/// An achievement that just reached its threshold.
class NewUnlock {
  const NewUnlock(this.achievement, this.value);
  final Achievement achievement;
  final double value;
}

/// Achievements not yet unlocked whose rule is met by [data]. A rule unlocks
/// only when its computed value reaches the threshold (SC-006); it never
/// depends on anything the AI said.
List<NewUnlock> newUnlocks(
  Iterable<Achievement> achievements,
  ProgressData data, {
  required String today,
  int freeDays = 1,
  GoalRule? dailyGoal,
}) {
  final best = streak(
    fulfilledDays(data, goal: dailyGoal),
    today: today,
    freeDays: freeDays,
  ).best.toDouble();
  final unlocked = <NewUnlock>[];
  for (final achievement in achievements) {
    if (achievement.unlocked) continue;
    final rule = achievement.rule;
    final value = rule.kind == 'streak'
        ? best
        : metricValue(rule.metric!, data, at: today);
    if (value >= rule.threshold) unlocked.add(NewUnlock(achievement, value));
  }
  return unlocked;
}

String ruleHash(AchievementRule rule) =>
    sha256.convert(utf8.encode(jsonEncode(rule.toJson()))).toString();

/// 1.234 with the Spanish thousands separator.
String formatCount(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return value < 0 ? '-$out' : '$out';
}

/// An achievement the app creates by itself from a companion's fields.
class GeneratedAchievement {
  const GeneratedAchievement({
    required this.rule,
    required this.title,
    required this.icon,
    required this.ruleHash,
  });

  final AchievementRule rule;
  final String title, icon, ruleHash;
}

/// The families of `data-model.md` §4: universal ones for sessions, time and
/// streak, plus one per typed field by how it is counted. `max` and `avg`
/// fields only show as records and averages.
List<GeneratedAchievement> generateAchievements({
  required String companionName,
  required List<Map<String, dynamic>> fields,
}) {
  final out = <GeneratedAchievement>[];
  void add(AchievementRule rule, String title, String icon) => out.add(
    GeneratedAchievement(
      rule: rule,
      title: title,
      icon: icon,
      ruleHash: ruleHash(rule),
    ),
  );

  for (final n in const [1, 10, 50, 100]) {
    add(
      AchievementRule.threshold(
        metric: Metric.sessions('total'),
        threshold: n.toDouble(),
      ),
      n == 1 ? 'Primera vez' : '$n sesiones',
      n == 1 ? 'first' : 'trophy',
    );
  }
  for (final n in const [1, 10, 50, 100]) {
    add(
      AchievementRule.threshold(
        metric: Metric.time('total'),
        threshold: n * 3600.0,
      ),
      '$n h en $companionName',
      'time',
    );
  }
  for (final n in const [3, 7, 30, 100]) {
    add(
      AchievementRule.streak(threshold: n.toDouble()),
      'Racha de $n días',
      'streak',
    );
  }

  for (final field in fields) {
    final type = field['type'];
    final aggregate = field['aggregate'];
    final key = field['key'];
    if (type == null || aggregate == null || key is! String) continue;
    final label = (field['label'] as String? ?? key).trim();
    final plural = field['countPlural'] as String?;
    final singular = field['countSingular'] as String?;
    Metric metric() => Metric(
      source: 'field',
      field: key,
      aggregate: aggregate as String,
      per: 'total',
    );
    switch (aggregate) {
      case 'sum':
        for (final n in const [10, 100, 500, 1000, 5000]) {
          add(
            AchievementRule.threshold(
              metric: metric(),
              threshold: n.toDouble(),
            ),
            '${formatCount(n)} ${label.toLowerCase()}',
            'count',
          );
        }
      case 'distinct':
        for (final n in const [3, 10, 25]) {
          add(
            AchievementRule.threshold(
              metric: metric(),
              threshold: n.toDouble(),
            ),
            plural == null ? '$label: $n distintos' : '$n $plural',
            'variety',
          );
        }
      case 'countTrue':
        for (final n in const [1, 5, 25]) {
          final name = n == 1 ? singular : plural;
          add(
            AchievementRule.threshold(
              metric: metric(),
              threshold: n.toDouble(),
            ),
            name == null ? '$label: $n' : '$n $name',
            'count',
          );
        }
    }
  }
  return out;
}
