import '../domain/assistant_blocks.dart' show ReminderProposal;
import '../domain/progress.dart';
import '../l10n/generated/app_localizations.dart';
import 'activity_summary.dart' show durationText;

/// Readable Spanish for goals, achievement rules and reminders, used by the
/// cards that ask the user to accept a proposal.

String _number(double v) => v == v.roundToDouble()
    ? '${v.toInt()}'
    : v.toStringAsFixed(1).replaceAll('.', ',');

String _unit(Metric metric, Map<String, String> labels, AppLocalizations l) =>
    switch (metric.source) {
      'time' => l.ruleUnitMin,
      'sessions' => l.ruleUnitSessions,
      _ => (labels[metric.field] ?? metric.field ?? '').toLowerCase(),
    };

/// «Tiempo», «Sesiones», «Páginas», «Máximo de páginas»…
String metricNoun(
  Metric metric,
  Map<String, String> labels,
  AppLocalizations l,
) {
  final label = labels[metric.field] ?? metric.field ?? '';
  switch (metric.source) {
    case 'time':
      return l.ruleMetricTime;
    case 'sessions':
      return l.ruleMetricSessions;
  }
  return switch (metric.aggregate) {
    'max' => l.ruleMetricMax(label.toLowerCase()),
    'avg' => l.ruleMetricAvg(label.toLowerCase()),
    'distinct' => l.ruleMetricDistinct(label),
    'countTrue' => l.ruleMetricCountTrue(label.toLowerCase()),
    _ => label,
  };
}

String perText(String per, AppLocalizations l) => switch (per) {
  'day' => l.rulePerDay,
  'week' => l.rulePerWeek,
  'session' => l.rulePerSession,
  _ => l.rulePerTotal,
};

/// A value of [metric] as people say it: minutes for time.
String amount(
  Metric metric,
  double value,
  Map<String, String> labels,
  AppLocalizations l,
) {
  final shown = metric.source == 'time' ? value / 60 : value;
  if (metric.source == 'sessions' && shown == 1) return l.ruleSessionOne;
  return '${_number(shown)} ${_unit(metric, labels, l)}';
}

/// «20 páginas al día (mínimo 5)».
String goalText(GoalRule goal, Map<String, String> labels, AppLocalizations l) {
  final shown = goal.metric.source == 'time' ? 60.0 : 1.0;
  final min = goal.minimum == null
      ? ''
      : ' ${l.ruleGoalMinimum(_number(goal.minimum! / shown))}';
  return '${amount(goal.metric, goal.target, labels, l)} '
      '${goal.period == 'day' ? l.ruleGoalDaily : l.ruleGoalWeekly}$min';
}

/// «Tiempo ≥ 15 min por día» or «Racha de 7 días».
String ruleText(
  AchievementRule rule,
  Map<String, String> labels,
  AppLocalizations l,
) {
  if (rule.kind == 'streak') {
    final n = rule.threshold.toInt();
    return n == 1 ? l.ruleStreakOne : l.ruleStreakDays(n);
  }
  final metric = rule.metric!;
  return l.ruleAtLeast(
    metricNoun(metric, labels, l),
    amount(metric, rule.threshold, labels, l),
    perText(metric.per, l),
  );
}

String clockText(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

String daysText(int mask, AppLocalizations l) {
  if (mask == 127) return l.ruleDaysAll;
  if (mask == 0x1F) return l.ruleDaysWeekdays;
  if (mask == 0x60) return l.ruleDaysWeekend;
  final names = [
    l.ruleDayMon,
    l.ruleDayTue,
    l.ruleDayWed,
    l.ruleDayThu,
    l.ruleDayFri,
    l.ruleDaySat,
    l.ruleDaySun,
  ];
  return [
    for (var i = 0; i < 7; i++)
      if (mask >> i & 1 == 1) names[i],
  ].join(', ');
}

/// «De lunes a viernes, 21:00–23:00 · última llamada 22:30».
String reminderText(ReminderProposal r, AppLocalizations l) {
  final window =
      '${daysText(r.days, l)}, ${clockText(r.startMin)}–${clockText(r.endMin)}';
  return r.lastCallMin == null
      ? window
      : '$window ${l.ruleReminderLastCall(clockText(r.lastCallMin!))}';
}

/// Keeps [durationText] reachable for callers that only import this file.
String shortDuration(Duration d, AppLocalizations l) => durationText(d, l);
