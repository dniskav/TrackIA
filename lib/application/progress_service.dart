import '../data/progress_repository.dart';
import '../domain/progress.dart';
import '../domain/reminder.dart' show reminderDay;
import 'progress_engine.dart' as engine;

/// Everything the screens show about a companion's progress.
class ProgressState {
  const ProgressState({
    required this.settings,
    required this.streak,
    required this.doneDays,
    required this.achievements,
    this.goal,
    this.goalProgress,
    this.achievementFractions = const {},
  });

  final CompanionSettings settings;
  final StreakResult streak;
  final Set<String> doneDays;
  final List<Achievement> achievements;
  final GoalRule? goal;

  /// The goal at today's period (the day or the week the goal is set for).
  final GoalProgress? goalProgress;

  /// How close each locked achievement is, 0 to 1, by achievement id.
  final Map<String, double> achievementFractions;

  int get unlockedCount => achievements.where((a) => a.unlocked).length;
}

/// Evaluates progress after something is saved and stores what was unlocked
/// (FR-032, FR-035). The AI never takes part: it only reads the result.
class ProgressService {
  ProgressService({required this.progress, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ProgressRepository progress;
  final DateTime Function() _clock;

  String get today => reminderDay(_clock());

  static String dayOf(DateTime moment) => reminderDay(moment);

  /// Days that count as done for the companion, by the same rule the streak
  /// uses; the reminders read this instead of a plain «has a session».
  Future<Set<String>> doneDays(String companionId) async =>
      engine.fulfilledDays(
        await progress.loadData(companionId),
        goal: await progress.activeGoal(companionId),
      );

  Future<ProgressState> state(String companionId) async {
    final settings = await progress.settings(companionId);
    final data = await progress.loadData(companionId);
    final goal = await progress.activeGoal(companionId);
    final done = engine.fulfilledDays(data, goal: goal);
    final result = engine.streak(
      done,
      today: today,
      freeDays: settings.freeDaysPerWeek,
    );
    final achievements = await progress.achievements(companionId);
    final fractions = <String, double>{};
    for (final a in achievements) {
      if (a.unlocked) continue;
      final rule = a.rule;
      final value = rule.kind == 'streak'
          ? result.best.toDouble()
          : engine.metricValue(rule.metric!, data, at: today);
      fractions[a.id] = (value / rule.threshold).clamp(0.0, 1.0);
    }
    return ProgressState(
      settings: settings,
      streak: result,
      doneDays: done,
      achievements: achievements,
      achievementFractions: fractions,
      goal: goal,
      goalProgress: goal == null
          ? null
          : engine.goalProgress(goal, data, at: today),
    );
  }

  /// Call after a value is saved, a segment stopped or an activity finished.
  ///
  /// In game mode with achievements on, it creates the families of
  /// [fields] (idempotent), unlocks what the saved data reaches and returns
  /// the news. [activityId] / [observationId] say which record caused them;
  /// records beaten by [activityId] are returned either way.
  Future<ProgressDelta> afterChange(
    String companionId, {
    required String companionName,
    required List<Map<String, dynamic>> fields,
    String? activityId,
    String? observationId,
  }) async {
    final settings = await progress.settings(companionId);
    final data = await progress.loadData(companionId);
    final records = activityId == null
        ? const <ProgressRecord>[]
        : newRecords(data, activityId, fields);
    if (!settings.game || !settings.achievementsEnabled) {
      return ProgressDelta(records: records);
    }
    await progress.ensureAchievements(
      companionId,
      engine.generateAchievements(companionName: companionName, fields: fields),
    );
    final goal = await progress.activeGoal(companionId);
    final unlocks = engine.newUnlocks(
      await progress.achievements(companionId),
      data,
      today: today,
      freeDays: settings.freeDaysPerWeek,
      dailyGoal: goal,
    );
    await progress.recordUnlocks(
      unlocks,
      sourceActivityId: activityId,
      sourceObservationId: observationId,
    );
    return ProgressDelta(
      unlocked: [for (final u in unlocks) u.achievement],
      records: records,
    );
  }

  /// Records [sessionId] beats compared with everything before it: the longest
  /// session and, per typed field counted by `sum` or `max`, the best single
  /// session. A first value is not a record.
  static List<ProgressRecord> newRecords(
    ProgressData data,
    String sessionId,
    List<Map<String, dynamic>> fields,
  ) {
    final before = data.without(sessionId);
    final out = <ProgressRecord>[];

    final time = Metric.time('session');
    final timeNow = engine.metricValue(
      time,
      data.onlySession(sessionId),
      at: '',
    );
    final timeBefore = engine.metricValue(time, before, at: '');
    if (timeBefore > 0 && timeNow > timeBefore) {
      out.add(ProgressRecord('Sesión más larga', timeNow / 60, unit: 'min'));
    }

    for (final field in fields) {
      final key = field['key'];
      final aggregate = field['aggregate'];
      if (field['type'] == null ||
          key is! String ||
          (aggregate != 'sum' && aggregate != 'max')) {
        continue;
      }
      final metric = Metric(
        source: 'field',
        field: key,
        aggregate: aggregate as String,
        per: 'session',
      );
      final now = engine.metricValue(
        metric,
        data.onlySession(sessionId),
        at: '',
      );
      final prior = engine.metricValue(metric, before, at: '');
      if (prior > 0 && now > prior) {
        out.add(
          ProgressRecord(
            'Récord de ${(field['label'] as String? ?? key).toLowerCase()}',
            now,
            unit: field['unit'] as String? ?? '',
          ),
        );
      }
    }
    return out;
  }
}
