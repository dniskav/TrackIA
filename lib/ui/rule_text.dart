import '../domain/assistant_blocks.dart' show ReminderProposal;
import '../domain/progress.dart';
import 'activity_summary.dart' show durationText;

/// Readable Spanish for goals, achievement rules and reminders, used by the
/// cards that ask the user to accept a proposal.

String _number(double v) => v == v.roundToDouble()
    ? '${v.toInt()}'
    : v.toStringAsFixed(1).replaceAll('.', ',');

String _unit(Metric metric, Map<String, String> labels) =>
    switch (metric.source) {
      'time' => 'min',
      'sessions' => 'sesiones',
      _ => (labels[metric.field] ?? metric.field ?? '').toLowerCase(),
    };

/// «Tiempo», «Sesiones», «Páginas», «Máximo de páginas»…
String metricNoun(Metric metric, Map<String, String> labels) {
  final label = labels[metric.field] ?? metric.field ?? '';
  switch (metric.source) {
    case 'time':
      return 'Tiempo';
    case 'sessions':
      return 'Sesiones';
  }
  return switch (metric.aggregate) {
    'max' => 'Máximo de ${label.toLowerCase()}',
    'avg' => 'Promedio de ${label.toLowerCase()}',
    'distinct' => '$label distintos',
    'countTrue' => 'Veces: ${label.toLowerCase()}',
    _ => label,
  };
}

String perText(String per) => switch (per) {
  'day' => 'por día',
  'week' => 'por semana',
  'session' => 'por sesión',
  _ => 'en total',
};

/// A value of [metric] as people say it: minutes for time.
String amount(Metric metric, double value, Map<String, String> labels) {
  final shown = metric.source == 'time' ? value / 60 : value;
  if (metric.source == 'sessions' && shown == 1) return '1 sesión';
  return '${_number(shown)} ${_unit(metric, labels)}';
}

/// «20 páginas al día (mínimo 5)».
String goalText(GoalRule goal, Map<String, String> labels) {
  final shown = goal.metric.source == 'time' ? 60.0 : 1.0;
  final min = goal.minimum == null
      ? ''
      : ' (mínimo ${_number(goal.minimum! / shown)})';
  return '${amount(goal.metric, goal.target, labels)} '
      '${goal.period == 'day' ? 'al día' : 'a la semana'}$min';
}

/// «Tiempo ≥ 15 min por día» or «Racha de 7 días».
String ruleText(AchievementRule rule, Map<String, String> labels) {
  if (rule.kind == 'streak') {
    final n = rule.threshold.toInt();
    return n == 1 ? 'Racha de 1 día' : 'Racha de $n días';
  }
  final metric = rule.metric!;
  return '${metricNoun(metric, labels)} ≥ ${amount(metric, rule.threshold, labels)} '
      '${perText(metric.per)}';
}

String clockText(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

String daysText(int mask) {
  if (mask == 127) return 'Todos los días';
  if (mask == 0x1F) return 'De lunes a viernes';
  if (mask == 0x60) return 'Fines de semana';
  const names = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  return [
    for (var i = 0; i < 7; i++)
      if (mask >> i & 1 == 1) names[i],
  ].join(', ');
}

/// «De lunes a viernes, 21:00–23:00 · última llamada 22:30».
String reminderText(ReminderProposal r) =>
    '${daysText(r.days)}, ${clockText(r.startMin)}–${clockText(r.endMin)}'
    '${r.lastCallMin == null ? '' : ' · última llamada ${clockText(r.lastCallMin!)}'}';

/// Keeps [durationText] reachable for callers that only import this file.
String shortDuration(Duration d) => durationText(d);
