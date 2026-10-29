import 'package:flutter/material.dart';
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
      if (mounted) setState(() => error = 'No se pudo calcular el progreso.');
    }
  }

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

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
                    final label =
                        '${day.day} de ${_months[day.month - 1]}: ${done
                            ? 'cumplido'
                            : future
                            ? 'pendiente'
                            : 'sin cumplir'}';
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
          ? '${a.title}, desbloqueado'
          : '${a.title}, bloqueado, ${(fraction * 100).round()} % de progreso',
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
      appBar: AppBar(title: Text('Progreso · ${widget.companion.name}')),
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
                      s.streak.current == 1
                          ? 'Racha actual: 1 día'
                          : 'Racha actual: ${s.streak.current} días',
                      key: const Key('streak-current'),
                    ),
                    subtitle: Text(
                      'Mejor racha: ${s.streak.best}'
                      '${s.settings.freeDaysPerWeek == 0 ? '' : ' · Días libres esta semana: ${s.streak.freeDaysUsedThisWeek}/${s.settings.freeDaysPerWeek}'}',
                      key: const Key('streak-best'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Últimas 4 semanas', style: theme.textTheme.titleSmall),
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
                            ? 'Meta de hoy'
                            : 'Meta de la semana',
                      ),
                      subtitle: Text(
                        '${_n(s.goalProgress!.value)} de ${_n(s.goal!.target)}',
                        key: const Key('goal-text'),
                      ),
                      trailing: s.goalProgress!.met
                          ? const Icon(Icons.check_circle)
                          : null,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Logros · ${s.unlockedCount} de ${s.achievements.length}',
                  key: const Key('achievements-title'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (s.achievements.isEmpty)
                  Text(
                    s.settings.game && s.settings.achievementsEnabled
                        ? 'Tus logros aparecerán al terminar tu primera actividad.'
                        : 'Activa el modo Juego y los logros en «Modo y avisos».',
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
