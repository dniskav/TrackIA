import 'package:flutter/material.dart';
import '../application/localization.dart';
import '../application/progress_engine.dart' show formatCount;
import '../domain/progress.dart';
import 'goal_ring.dart';

/// Icon of an achievement (`contracts/visual-tokens.md` → «Iconos de logro»).
IconData achievementIcon(String id) => switch (id) {
  'first' => Icons.rocket_launch,
  'streak' => Icons.local_fire_department,
  'record' => Icons.military_tech,
  'time' => Icons.schedule,
  'count' => Icons.task_alt,
  'variety' => Icons.explore,
  _ => Icons.emoji_events,
};

String durationText(Duration value) {
  final minutes = value.inMinutes;
  if (minutes >= 60) {
    final rest = minutes % 60;
    return rest == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h $rest min';
  }
  if (minutes >= 1) return '$minutes min';
  return '${value.inSeconds} s';
}

String _number(double value) => value == value.roundToDouble()
    ? formatCount(value.toInt())
    : value.toStringAsFixed(1).replaceAll('.', ',');

/// «Sesión terminada»: a full ring, what was done and what is new (FR-035).
class ActivitySummary extends StatelessWidget {
  const ActivitySummary({
    super.key,
    required this.name,
    required this.duration,
    required this.delta,
  });

  final String name;
  final Duration duration;
  final ProgressDelta delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appText(context).homeSessionFinished,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const GoalRing(
              key: Key('summary-ring'),
              fraction: 1,
              size: 112,
              child: Icon(Icons.check, size: 44),
            ),
            const SizedBox(height: 12),
            Text(
              '$name · ${durationText(duration)}',
              key: const Key('summary-line'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (delta.isEmpty)
              Text(
                appText(context).homeSummaryEmpty,
                key: const Key('summary-empty'),
                style: theme.textTheme.bodyMedium,
              ),
            for (final (i, record) in delta.records.indexed)
              ListTile(
                key: Key('summary-record-$i'),
                dense: true,
                leading: Icon(achievementIcon('record')),
                title: Text(record.label),
                trailing: Text(
                  '${_number(record.value)}${record.unit.isEmpty ? '' : ' ${record.unit}'}',
                ),
              ),
            for (final achievement in delta.unlocked)
              ListTile(
                key: Key('summary-unlock-${achievement.ruleHash}'),
                dense: true,
                leading: Icon(achievementIcon(achievement.icon)),
                title: Text(achievement.title),
                subtitle: Text(appText(context).homeNewAchievement),
              ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('summary-close'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(appText(context).homeDone),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showActivitySummary(
  BuildContext context, {
  required String name,
  required Duration duration,
  required ProgressDelta delta,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => ActivitySummary(name: name, duration: duration, delta: delta),
);
