import '../data/activity_template_repository.dart';
import '../data/companion_store.dart';
import '../data/progress_repository.dart';
import '../domain/activity.dart';
import '../domain/assistant_blocks.dart';
import '../domain/companion.dart';
import '../domain/progress.dart';
import '../domain/workout.dart';
import 'progress_engine.dart';

/// Everything a new companion is made of, before anything is saved. It comes
/// from a `trackia-companion` proposal or from the manual builder.
class CompanionDraft {
  const CompanionDraft({
    required this.name,
    this.description = '',
    this.prompt = '',
    this.icon,
    this.color,
    this.mode = 'reminder',
    this.activity,
    this.instant = false,
    this.goal,
    this.reminder,
    this.origin = 'user',
  });

  factory CompanionDraft.fromProposal(CompanionProposal proposal) =>
      CompanionDraft(
        name: proposal.name,
        description: proposal.description,
        prompt: proposal.prompt,
        icon: proposal.icon,
        color: proposal.color,
        mode: proposal.mode,
        activity: proposal.activity,
        instant: proposal.instant,
        goal: proposal.goal?.rule,
        reminder: proposal.reminder,
        origin: 'assistant',
      );

  final String name, description, prompt;
  final String? icon, color;

  /// `reminder`, `goals` (game without achievements) or `game`.
  final String mode;
  final ActivityDefinition? activity;
  final bool instant;
  final GoalRule? goal;
  final ReminderProposal? reminder;

  /// `user` for the manual builder, `assistant` for an AI proposal.
  final String origin;

  String get levelText => switch (mode) {
    'game' => 'Juego completo',
    'goals' => 'Metas y rachas',
    _ => 'Solo recordatorio',
  };

  CompanionDraft copyWith({
    String? name,
    String? description,
    String? prompt,
    Object? icon = _keep,
    Object? color = _keep,
    String? mode,
    Object? activity = _keep,
    bool? instant,
    Object? goal = _keep,
    Object? reminder = _keep,
  }) => CompanionDraft(
    name: name ?? this.name,
    description: description ?? this.description,
    prompt: prompt ?? this.prompt,
    icon: identical(icon, _keep) ? this.icon : icon as String?,
    color: identical(color, _keep) ? this.color : color as String?,
    mode: mode ?? this.mode,
    activity: identical(activity, _keep)
        ? this.activity
        : activity as ActivityDefinition?,
    instant: instant ?? this.instant,
    goal: identical(goal, _keep) ? this.goal : goal as GoalRule?,
    reminder: identical(reminder, _keep)
        ? this.reminder
        : reminder as ReminderProposal?,
    origin: origin,
  );

  static const _keep = Object();
}

/// A short id from a name: lowercase letters, digits and dashes, unique among
/// [taken].
String companionIdFor(String name, Iterable<String> taken) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
    'à': 'a',
    'è': 'e',
    'ì': 'i',
    'ò': 'o',
    'ù': 'u',
  };
  var slug = name
      .toLowerCase()
      .split('')
      .map((c) => accents[c] ?? c)
      .join()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) slug = 'acompanante';
  if (slug.length > 24) {
    slug = slug.substring(0, 24).replaceAll(RegExp(r'-+$'), '');
  }
  final used = taken.toSet();
  var candidate = slug;
  for (var n = 2; used.contains(candidate); n++) {
    candidate = '$slug-$n';
  }
  return candidate;
}

/// Saves a [CompanionDraft] in a fixed order and undoes it if a step fails
/// (`contracts/assistant-blocks.md`): companion, settings, activity template,
/// goal, reminder, generated achievements.
class CompanionCreation {
  CompanionCreation({
    required this.store,
    required this.progress,
    this.templates,
  });

  final CompanionStore store;
  final ProgressRepository progress;
  final ActivityTemplateRepository? templates;

  /// The steps in the order they run.
  static const steps = [
    'companion',
    'settings',
    'activity',
    'goal',
    'reminder',
    'achievements',
  ];

  /// Test hook called before each step; it may throw.
  void Function(String step)? debugStep;

  Future<Companion> create(CompanionDraft draft) async {
    final existing = await store.load();
    final id = companionIdFor(draft.name, existing.map((c) => c.id));
    final companion = Companion(
      id: id,
      name: draft.name,
      description: draft.description,
      prompt: draft.prompt,
      icon: draft.icon,
      color: draft.color,
    );
    try {
      debugStep?.call('companion');
      await store.upsert(companion);

      debugStep?.call('settings');
      final game = draft.mode != 'reminder';
      await progress.saveSettings(
        CompanionSettings(
          companionId: id,
          mode: game ? 'game' : 'reminder',
          achievementsEnabled: draft.mode == 'game',
        ),
      );

      debugStep?.call('activity');
      final activity = draft.activity;
      if (activity != null) {
        final repository = templates;
        if (repository == null) {
          throw const ValidationException('No se puede guardar la actividad.');
        }
        await repository.save(
          companionId: id,
          definition: activity.forCompanion(id),
          instant: draft.instant,
          origin: draft.origin == 'assistant' ? 'assistant' : 'user',
        );
      }

      debugStep?.call('goal');
      final goal = draft.goal;
      if (goal != null) {
        await progress.saveGoal(id, goal, origin: draft.origin);
      }

      debugStep?.call('reminder');
      final reminder = draft.reminder;
      if (reminder != null) {
        await progress.saveReminder(
          companionId: id,
          days: reminder.days,
          windowStartMin: reminder.startMin,
          windowEndMin: reminder.endMin,
          lastCallMin: reminder.lastCallMin,
          tone: reminder.tone,
        );
      }

      debugStep?.call('achievements');
      if (draft.mode == 'game') {
        await progress.ensureAchievements(
          id,
          generateAchievements(
            companionName: companion.name,
            fields: [
              for (final f in activity?.fields ?? const <Map<String, Object>>[])
                Map<String, dynamic>.from(f),
            ],
          ),
        );
      }
      return companion;
    } catch (_) {
      await _undo(id);
      rethrow;
    }
  }

  /// Removes whatever was saved for [id]; a failure here is not reported over
  /// the original one.
  Future<void> _undo(String id) async {
    try {
      await progress.deleteCompanion(id);
    } catch (_) {
      // The companion record below is what matters most.
    }
    try {
      await store.delete(id);
    } catch (_) {
      // Nothing more can be done.
    }
  }
}
