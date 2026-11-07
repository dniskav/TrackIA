import 'package:flutter/material.dart';
import '../application/localization.dart';
import '../application/progress_service.dart';
import '../domain/companion.dart';
import '../domain/progress.dart';
import '../domain/reminder.dart' show reminderDay;
import 'activity_summary.dart';
import 'goal_ring.dart';

/// «Progreso» of one companion: streak, the last four weeks, the goal and the
/// achievements (FR-032). Everything shown was calculated by the app.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    required this.service,
    required this.companion,
  });

  final ProgressService service;
  final Companion companion;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressState? state;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final loaded = await widget.service.state(widget.companion.id);
      if (mounted) setState(() => state = loaded);
    } catch (_) {
      if (mounted) {
        setState(() => error = appText(context).progressLoadError);
      }
    }
  }

  /// Month name for the calendar labels, from the active catalog (1 = January).
  static String monthName(BuildContext context, int month) {
    final t = appText(context);
    final names = [
      t.progressMonth1,
      t.progressMonth2,
      t.progressMonth3,
      t.progressMonth4,
      t.progressMonth5,
      t.progressMonth6,
      t.progressMonth7,
      t.progressMonth8,
      t.progressMonth9,
      t.progressMonth10,
      t.progressMonth11,
      t.progressMonth12,
    ];
    return names[month - 1];
  }

  Widget calendar(ProgressState s) {
    final todayKey = widget.service.today;
    final parts = todayKey.split('-').map(int.parse).toList();
    final today = DateTime(parts[0], parts[1], parts[2]);
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    final start = DateTime(monday.year, monday.month, monday.day - 21);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const Key('calendar'),
      children: [
        for (var week = 0; week < 4; week++)
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Builder(
                  builder: (context) {
                    final day = DateTime(
                      start.year,
                      start.month,
                      start.day + week * 7 + d,
                    );
                    final key = reminderDay(day);
                    final done = s.doneDays.contains(key);
                    final future = day.isAfter(today);
                    final isToday = key == todayKey;
                    final t = appText(context);
                    final status = done
                        ? t.progressDayDone
                        : future
                        ? t.progressDayPending
                        : t.progressDayMissed;
                    final label = t.progressDayStatus(
                      day.day,
                      monthName(context, day.month),
                      status,
                    );
                    return Expanded(
                      child: Semantics(
                        label: label,
                        excludeSemantics: true,
                        child: Container(
                          key: Key('day-$key-${done ? 'done' : 'open'}'),
                          height: 36,
                          margin: const EdgeInsets.all(2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: done
                                ? scheme.primary
                                : scheme.onSurface.withValues(
                                    alpha: future ? 0.04 : 0.10,
                                  ),
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: scheme.primary, width: 2)
                                : null,
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 12,
                              color: done ? scheme.onPrimary : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }

  Widget achievementTile(ProgressState s, Achievement a) {
    final unlocked = a.unlocked;
    final fraction = unlocked ? 1.0 : (s.achievementFractions[a.id] ?? 0);
    return Semantics(
      label: unlocked
          ? appText(context).progressAchievementUnlocked(a.title)
          : appText(
              context,
            ).progressAchievementLocked(a.title, (fraction * 100).round()),
      excludeSemantics: true,
      child: Column(
        key: Key('achievement-${a.ruleHash}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          GoalRing(
            key: Key(
              unlocked ? 'unlocked-${a.ruleHash}' : 'locked-${a.ruleHash}',
            ),
            fraction: fraction,
            locked: !unlocked,
            size: 56,
            child: Icon(
              unlocked ? achievementIcon(a.icon) : Icons.lock_outline,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(appText(context).progressTitle(widget.companion.name)),
      ),
      body: error != null
          ? Center(child: Text(error!))
          : s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_fire_department, size: 32),
                    title: Text(
                      appText(context).progressStreakCurrent(s.streak.current),
                      key: const Key('streak-current'),
                    ),
                    subtitle: Text(
                      '${appText(context).progressStreakBest(s.streak.best)}'
                      '${s.settings.freeDaysPerWeek == 0 ? '' : ' · ${appText(context).progressFreeDays(s.streak.freeDaysUsedThisWeek, s.settings.freeDaysPerWeek)}'}',
                      key: const Key('streak-best'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  appText(context).progressLastFourWeeks,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                calendar(s),
                const SizedBox(height: 16),
                if (s.goal != null && s.goalProgress != null)
                  Card(
                    key: const Key('goal-card'),
                    child: ListTile(
                      leading: GoalRing(
                        fraction: s.goalProgress!.fraction,
                        child: Text(
                          '${(s.goalProgress!.fraction * 100).round()}%',
                        ),
                      ),
                      title: Text(
                        s.goal!.period == 'day'
                            ? appText(context).progressGoalToday
                            : appText(context).progressGoalWeek,
                      ),
                      subtitle: Text(
                        appText(context).progressGoalValues(
                          _n(s.goalProgress!.value),
                          _n(s.goal!.target),
                        ),
                        key: const Key('goal-text'),
                      ),
                      trailing: s.goalProgress!.met
                          ? const Icon(Icons.check_circle)
                          : null,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  appText(context).progressAchievementsTitle(
                    s.unlockedCount,
                    s.achievements.length,
                  ),
                  key: const Key('achievements-title'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (s.achievements.isEmpty)
                  Text(
                    s.settings.game && s.settings.achievementsEnabled
                        ? appText(context).progressAchievementsEmptyPlay
                        : appText(context).progressAchievementsEmptyEnable(
                            appText(context).modeAndNotices,
                          ),
                    key: const Key('achievements-empty'),
                  )
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.78,
                    children: [
                      for (final a in s.achievements) achievementTile(s, a),
                    ],
                  ),
              ],
            ),
    );
  }

  static String _n(double v) => v == v.roundToDouble()
      ? '${v.toInt()}'
      : v.toStringAsFixed(1).replaceAll('.', ',');
}
