import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import 'activity.dart';
import 'block_names.dart';
import 'companion.dart';
import 'progress.dart';
import 'reminder.dart';
import 'workout.dart';

/// Parsers of the `trackia-*` blocks the AI may add to a reply
/// (`contracts/assistant-blocks.md`).
///
/// Rules shared by all of them: one block of each kind per reply (two or more
/// of the same kind are all ignored); the JSON is an object with exactly the
/// allowed keys; any unknown key, wrong type or out-of-range value rejects the
/// whole block. Each parser returns `null` for an invalid block and logs only
/// the reason, never what the user wrote. Nothing here persists anything: the
/// app shows a card and only the user's action saves.

const _blockProblem = 'La propuesta no es válida y no se aplicó.';

/// The sentence added under a reply whose block was rejected.
String get blockRejectedText => _blockProblem;

/// Whether [answer] tries to use a `trackia-<kind>` block at all, valid or not.
bool mentionsBlock(String answer, String kind) =>
    RegExp('$fenceOpen${RegExp.escape('trackia-$kind')}').hasMatch(answer);

T? _reject<T>(String kind, String reason) {
  debugPrint('trackia-$kind rechazado: $reason');
  return null;
}

/// The JSON object of the single `trackia-<kind>` block of [answer].
Map<String, dynamic>? _single(String answer, String kind) {
  final blocks =
      RegExp(
        '${fenceOpen}trackia-$kind\\s*\\n([\\s\\S]*?)```',
      ).allMatches(answer).toList();
  if (blocks.isEmpty) return null;
  if (blocks.length != 1) return _reject(kind, 'más de un bloque');
  try {
    final value = jsonDecode(blocks.single.group(1)!);
    if (value is! Map) return _reject(kind, 'no es un objeto');
    return Map<String, dynamic>.from(value);
  } catch (_) {
    return _reject(kind, 'JSON roto');
  }
}

bool _keys(
  String kind,
  Map<String, dynamic> json,
  Set<String> required,
  Set<String> optional,
) {
  final extra = json.keys.where(
    (k) => !required.contains(k) && !optional.contains(k),
  );
  if (extra.isNotEmpty) {
    debugPrint('trackia-$kind rechazado: clave desconocida ${extra.first}');
    return false;
  }
  final missing = required.where((k) => !json.containsKey(k));
  if (missing.isNotEmpty) {
    debugPrint('trackia-$kind rechazado: falta ${missing.first}');
    return false;
  }
  return true;
}

bool _text(Object? v, int min, int max) =>
    v is String && v.trim().length >= min && v.trim().length <= max;

/// A single explicit target; null means remove the target.
///
/// [expectedRevision] is the activity revision (monotonic counter stored with
/// the activity, [FocusActivity.revision]) the model saw when it proposed the
/// change; null for proposals that carry none.
class ActivityTargetProposal {
  const ActivityTargetProposal(this.targetSets, {this.expectedRevision});
  final int? targetSets;
  final int? expectedRevision;
}

ActivityTargetProposal? parseActivityTargetBlock(String answer) {
  const kind = 'activity-target';
  final json = _single(answer, kind);
  if (json == null ||
      !_keys(kind, json, {'targetSets'}, {'expectedRevision'})) {
    return null;
  }
  final value = json['targetSets'];
  if (value != null && (value is! int || value < 1 || value > 100)) {
    return _reject(kind, 'objetivo fuera de rango');
  }
  final revision = json['expectedRevision'];
  if (json.containsKey('expectedRevision') &&
      !(revision is int && revision >= 1)) {
    return _reject(kind, 'revisión esperada no válida');
  }
  return ActivityTargetProposal(
    value as int?,
    expectedRevision: revision as int?,
  );
}

/// Why a target proposal was not accepted.
enum TargetProposalProblem { ambiguous, stale }

/// Sentence shown when the activity changed after the proposal was made.
const staleTargetText =
    'La actividad cambió desde que se propuso; vuelve a pedirlo.';

/// Result of [checkActivityTargetProposal]: exactly one of the two is set.
class TargetProposalCheck {
  const TargetProposalCheck.accepted(this.proposal) : problem = null;
  const TargetProposalCheck.rejected(this.problem) : proposal = null;
  final ActivityTargetProposal? proposal;
  final TargetProposalProblem? problem;
}

/// Validates the target proposal in [answer] against the [current] definition
/// of the activity it must apply to. Ambiguous means: not exactly one valid
/// block, other action blocks next to it, or no repeated activity to apply it
/// to. Stale means the proposal quotes a revision other than [currentRevision];
/// a proposal without revision is accepted (the repository still compares the
/// definition when saving).
TargetProposalCheck checkActivityTargetProposal(
  String answer, {
  required ActivityDefinition? current,
  int? currentRevision,
}) {
  final proposal = parseActivityTargetBlock(answer);
  final otherBlock = RegExp('$fenceOpen(?:trackia|gymia)-([a-z][a-z-]*)')
      .allMatches(answer)
      .any((match) => match.group(1) != 'activity-target');
  if (proposal == null ||
      current == null ||
      !current.repeated ||
      otherBlock) {
    return const TargetProposalCheck.rejected(TargetProposalProblem.ambiguous);
  }
  final quoted = proposal.expectedRevision;
  if (quoted != null && quoted != currentRevision) {
    return const TargetProposalCheck.rejected(TargetProposalProblem.stale);
  }
  return TargetProposalCheck.accepted(proposal);
}

// --- trackia-goal --------------------------------------------------------

class GoalProposal {
  const GoalProposal(this.rule, {this.activityKey});
  final GoalRule rule;
  final String? activityKey;
}

GoalProposal? _goalFrom(
  Map<String, dynamic> json,
  Set<String>? activityKeys,
  String kind,
) {
  if (!_keys(
    kind,
    json,
    {'metric', 'period', 'target'},
    {'minimum', 'activityKey'},
  )) {
    return null;
  }
  final key = json['activityKey'];
  if (key != null) {
    if (key is! String ||
        (activityKeys != null && !activityKeys.contains(key))) {
      return _reject(kind, 'la actividad no existe en el acompañante');
    }
  }
  final target = json['target'];
  final minimum = json['minimum'];
  if (target is! num || target > 100000) {
    return _reject(kind, 'objetivo fuera de rango');
  }
  if (minimum != null && (minimum is! num || minimum >= target)) {
    return _reject(kind, 'mínimo fuera de rango');
  }
  try {
    return GoalProposal(
      GoalRule.fromJson({
        'metric': json['metric'],
        'period': json['period'],
        'target': target,
        if (minimum != null) 'minimum': minimum,
      }),
      activityKey: key as String?,
    );
  } on ValidationException {
    return _reject(kind, 'regla de meta no válida');
  }
}

GoalProposal? parseGoalBlock(String answer, {Set<String>? activityKeys}) {
  final json = _single(answer, 'goal');
  return json == null ? null : _goalFrom(json, activityKeys, 'goal');
}

// --- trackia-achievement ---------------------------------------------------

class AchievementProposal {
  const AchievementProposal({
    required this.title,
    required this.rule,
    required this.icon,
    this.activityKey,
  });
  final String title, icon;
  final AchievementRule rule;
  final String? activityKey;
}

AchievementProposal? parseAchievementBlock(
  String answer, {
  Set<String>? activityKeys,
}) {
  const kind = 'achievement';
  final json = _single(answer, kind);
  if (json == null) return null;
  if (!_keys(kind, json, {'title', 'rule'}, {'icon', 'activityKey'})) {
    return null;
  }
  if (!_text(json['title'], 1, 60)) return _reject(kind, 'título no válido');
  final icon = json['icon'];
  if (icon != null && (icon is! String || !Achievement.icons.contains(icon))) {
    return _reject(kind, 'icono desconocido');
  }
  final key = json['activityKey'];
  if (key != null &&
      (key is! String ||
          (activityKeys != null && !activityKeys.contains(key)))) {
    return _reject(kind, 'la actividad no existe en el acompañante');
  }
  final AchievementRule rule;
  try {
    rule = AchievementRule.fromJson(json['rule']);
  } on ValidationException {
    return _reject(kind, 'regla no válida');
  }
  if (rule.threshold > 1000000) return _reject(kind, 'umbral demasiado alto');
  return AchievementProposal(
    title: (json['title'] as String).trim(),
    rule: rule,
    icon: (icon as String?) ?? (rule.kind == 'streak' ? 'streak' : 'trophy'),
    activityKey: key as String?,
  );
}

// --- trackia-reminder-copy -------------------------------------------------

/// Markers a reminder text may use.
const reminderMarkers = {'dias', 'faltan', 'racha', 'minimo', 'meta', 'nombre'};

ReminderTemplates? parseReminderCopyBlock(String answer) {
  const kind = 'reminder-copy';
  final json = _single(answer, kind);
  if (json == null) return null;
  if (!_keys(kind, json, const {}, {'windowStart', 'lastCall', 'inactive'})) {
    return null;
  }
  if (json.isEmpty) return _reject(kind, 'sin textos');
  final marker = RegExp(r'\{([^{}]*)\}');
  List<String>? list(String name) {
    final value = json[name];
    if (value == null) return const [];
    if (value is! List || value.isEmpty || value.length > 5) {
      return _reject(kind, '$name debe tener de 1 a 5 textos');
    }
    for (final text in value) {
      if (!_text(text, 1, 140)) {
        return _reject(kind, 'texto de $name no válido');
      }
      for (final m in marker.allMatches(text as String)) {
        if (!reminderMarkers.contains(m.group(1))) {
          return _reject(kind, 'marcador desconocido en $name');
        }
      }
      if (text.replaceAll(marker, '').contains(RegExp('[{}]'))) {
        return _reject(kind, 'llaves sueltas en $name');
      }
    }
    return [for (final text in value) (text as String).trim()];
  }

  final start = list('windowStart');
  final last = start == null ? null : list('lastCall');
  final inactive = last == null ? null : list('inactive');
  if (start == null || last == null || inactive == null) return null;
  return ReminderTemplates(
    windowStart: start,
    lastCall: last,
    inactive: inactive,
  );
}

// --- trackia-companion -------------------------------------------------------

/// The reminder a companion proposal asks for.
class ReminderProposal {
  const ReminderProposal({
    required this.days,
    required this.startMin,
    required this.endMin,
    required this.tone,
    this.lastCallMin,
  });

  /// Bit 0 = Monday … bit 6 = Sunday.
  final int days;
  final int startMin, endMin;
  final int? lastCallMin;
  final String tone;
}

class CompanionProposal {
  const CompanionProposal({
    required this.name,
    required this.description,
    required this.prompt,
    required this.icon,
    required this.color,
    required this.mode,
    this.activity,
    this.instant = false,
    this.goal,
    this.reminder,
  });

  /// `reminder`, `goals` (game mode without achievements) or `game`.
  static const modes = {'reminder', 'goals', 'game'};

  final String name, description, prompt;
  final String? icon, color;
  final String mode;
  final ActivityDefinition? activity;
  final bool instant;
  final GoalProposal? goal;
  final ReminderProposal? reminder;

  /// The level in the user's words.
  String get levelText => switch (mode) {
    'game' => 'Juego completo',
    'goals' => 'Metas y rachas',
    _ => 'Solo recordatorio',
  };
}

const _dayNames = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

int? _clock(Object? value, {bool allowEndOfDay = false}) {
  if (value is! String) return null;
  if (allowEndOfDay && value == '24:00') return 1440;
  final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
  return m == null
      ? null
      : int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
}

ReminderProposal? _reminderFrom(Object? value) {
  const kind = 'companion';
  if (value is! Map) return _reject(kind, 'aviso no es un objeto');
  final json = Map<String, dynamic>.from(value);
  if (!_keys(kind, json, {'days', 'start', 'end', 'tone'}, {'lastCall'})) {
    return null;
  }
  final names = json['days'];
  if (names is! List ||
      names.isEmpty ||
      names.length > 7 ||
      names.toSet().length != names.length ||
      names.any((d) => !_dayNames.contains(d))) {
    return _reject(kind, 'días del aviso no válidos');
  }
  final start = _clock(json['start']);
  final end = _clock(json['end'], allowEndOfDay: true);
  final last = json['lastCall'] == null ? null : _clock(json['lastCall']);
  if (start == null ||
      end == null ||
      (json['lastCall'] != null && last == null)) {
    return _reject(kind, 'hora del aviso no válida');
  }
  final tone = json['tone'];
  if (tone is! String) return _reject(kind, 'tono no válido');
  final mask = names.fold<int>(
    0,
    (a, d) => a | (1 << _dayNames.indexOf(d as String)),
  );
  try {
    // Reuses the reminder's own validation (window and last call order, tone).
    Reminder(
      id: 'proposal',
      companionId: 'proposal',
      days: mask,
      windowStartMin: start,
      windowEndMin: end,
      lastCallMin: last,
      tone: tone,
    );
  } on ValidationException {
    return _reject(kind, 'franja del aviso no válida');
  }
  return ReminderProposal(
    days: mask,
    startMin: start,
    endMin: end,
    lastCallMin: last,
    tone: tone,
  );
}

const _activityKeys = {
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
  'instant',
};

CompanionProposal? parseCompanionBlock(String answer) {
  const kind = 'companion';
  final json = _single(answer, kind);
  if (json == null) return null;
  if (!_keys(
    kind,
    json,
    {'name', 'mode'},
    {'description', 'prompt', 'icon', 'color', 'activity', 'goal', 'reminder'},
  )) {
    return null;
  }
  if (!_text(json['name'], 1, 40)) return _reject(kind, 'nombre no válido');
  final description = json['description'] ?? '';
  if (description is! String || description.trim().length > 80) {
    return _reject(kind, 'descripción no válida');
  }
  final prompt = json['prompt'] ?? '';
  if (prompt is! String || prompt.trim().length > 2000) {
    return _reject(kind, 'instrucciones no válidas');
  }
  final icon = json['icon'];
  if (icon != null && (icon is! String || !Companion.iconIds.contains(icon))) {
    return _reject(kind, 'icono desconocido');
  }
  final color = json['color'];
  if (color != null &&
      (color is! String || !Companion.colorIds.contains(color))) {
    return _reject(kind, 'color desconocido');
  }
  final mode = json['mode'];
  if (mode is! String || !CompanionProposal.modes.contains(mode)) {
    return _reject(kind, 'modo desconocido');
  }

  ActivityDefinition? activity;
  var instant = false;
  final rawActivity = json['activity'];
  if (rawActivity != null) {
    if (rawActivity is! Map) return _reject(kind, 'actividad no es un objeto');
    final map = Map<String, dynamic>.from(rawActivity);
    if (map.keys.any((k) => !_activityKeys.contains(k))) {
      return _reject(kind, 'clave desconocida en la actividad');
    }
    final flag = map.remove('instant');
    if (flag != null && flag is! bool) {
      return _reject(kind, 'instant no es booleano');
    }
    instant = flag == true;
    try {
      activity = ActivityDefinition.fromJson({...map, 'origin': 'llm'});
    } catch (_) {
      return _reject(kind, 'actividad no válida');
    }
  }

  GoalProposal? goal;
  if (json['goal'] != null) {
    final raw = json['goal'];
    if (raw is! Map) return _reject(kind, 'meta no es un objeto');
    goal = _goalFrom(Map<String, dynamic>.from(raw), null, kind);
    if (goal == null) return null;
  }
  ReminderProposal? reminder;
  if (json['reminder'] != null) {
    reminder = _reminderFrom(json['reminder']);
    if (reminder == null) return null;
  }
  return CompanionProposal(
    name: (json['name'] as String).trim(),
    description: description.trim(),
    prompt: prompt.trim(),
    icon: icon as String?,
    color: color as String?,
    mode: mode,
    activity: activity,
    instant: instant,
    goal: goal,
    reminder: reminder,
  );
}
