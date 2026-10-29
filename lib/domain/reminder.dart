import 'workout.dart';

/// A habit reminder for one companion (data-model §5, FR-027).
class Reminder {
  Reminder({
    required this.id,
    required this.companionId,
    required this.days,
    required this.windowStartMin,
    required this.windowEndMin,
    this.lastCallMin,
    this.tone = 'neutral',
    this.minimum,
    this.enabled = true,
    this.pausedAt,
    this.revision = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0) {
    if (days < 1 || days > 127) {
      throw const ValidationException('Elige al menos un día de la semana.');
    }
    if (windowStartMin < 0 ||
        windowEndMin > 1440 ||
        windowStartMin >= windowEndMin) {
      throw const ValidationException(
        'La hora de inicio debe ser anterior a la de fin.',
      );
    }
    final last = lastCallMin;
    if (last != null && (last <= windowStartMin || last >= windowEndMin)) {
      throw const ValidationException(
        'La última llamada debe estar entre el inicio y el fin.',
      );
    }
    if (!tones.contains(tone)) {
      throw const ValidationException('El tono no es válido.');
    }
    final min = minimum;
    if (min != null) {
      final metric = min['metric'];
      final value = min['value'];
      if (metric is! String || metric.isEmpty || value is! num || value <= 0) {
        throw const ValidationException('El mínimo no es válido.');
      }
    }
  }

  static const tones = {'neutral', 'cheer'};

  final String id, companionId, tone;

  /// Bit 0 = Monday … bit 6 = Sunday.
  final int days;
  final int windowStartMin, windowEndMin;
  final int? lastCallMin;

  /// `{"metric": "sessions" | "time" | <field key>, "value": n}`.
  final Map<String, Object?>? minimum;
  final bool enabled;
  final DateTime? pausedAt;
  final int revision;
  final DateTime createdAt;

  bool get paused => pausedAt != null;

  /// [weekday] follows [DateTime.weekday] (1 = Monday … 7 = Sunday).
  bool scheduledOn(int weekday) => days & (1 << (weekday - 1)) != 0;

  int get daysPerWeek => List.generate(7, (i) => days >> i & 1).reduce(_sum);
  static int _sum(int a, int b) => a + b;

  Reminder copyWith({
    int? days,
    int? windowStartMin,
    int? windowEndMin,
    Object? lastCallMin = _keep,
    String? tone,
    Object? minimum = _keep,
    bool? enabled,
    Object? pausedAt = _keep,
  }) => Reminder(
    id: id,
    companionId: companionId,
    days: days ?? this.days,
    windowStartMin: windowStartMin ?? this.windowStartMin,
    windowEndMin: windowEndMin ?? this.windowEndMin,
    lastCallMin: identical(lastCallMin, _keep)
        ? this.lastCallMin
        : lastCallMin as int?,
    tone: tone ?? this.tone,
    minimum: identical(minimum, _keep)
        ? this.minimum
        : minimum as Map<String, Object?>?,
    enabled: enabled ?? this.enabled,
    pausedAt: identical(pausedAt, _keep)
        ? this.pausedAt
        : pausedAt as DateTime?,
    revision: revision,
    createdAt: createdAt,
  );

  static const _keep = Object();
}

enum ReminderKind { windowStart, lastCall }

/// The three template lists a reminder can use, in order of preference; the
/// last of each list carries no markers.
class ReminderTemplates {
  const ReminderTemplates({
    required this.windowStart,
    required this.lastCall,
    required this.inactive,
  });

  final List<String> windowStart, lastCall, inactive;

  Map<String, Object> toJson() => {
    'windowStart': windowStart,
    'lastCall': lastCall,
    'inactive': inactive,
  };

  factory ReminderTemplates.fromJson(Map<String, dynamic> json) =>
      ReminderTemplates(
        windowStart: List<String>.from(json['windowStart'] as List),
        lastCall: List<String>.from(json['lastCall'] as List),
        inactive: List<String>.from(json['inactive'] as List),
      );

  /// Default Spanish copy of `contracts/reminders-android.md`. [custom] (the
  /// companion's own `trackia-reminder-copy`) replaces any list it provides.
  static ReminderTemplates defaults({
    required String tone,
    required String companionId,
    ReminderTemplates? custom,
  }) {
    final cheer = tone == 'cheer';
    final base = ReminderTemplates(
      windowStart: cheer
          ? const [
              '{nombre} te espera: hoy toca {meta}.',
              '{nombre} te espera hoy.',
            ]
          : const [
              'Es buen momento para tu actividad. Meta de hoy: {meta}.',
              'Es buen momento para tu actividad.',
            ],
      lastCall: cheer
          ? const [
              'Última llamada: con {minimo} mantienes tu racha de {racha} días.',
              'No pierdas la racha: te faltan {faltan} esta semana.',
              'Última llamada para hoy.',
            ]
          : const [
              'Aún estás a tiempo hoy. Con {minimo} basta.',
              'Te faltan {faltan} esta semana.',
              'Aún estás a tiempo hoy.',
            ],
      inactive: [
        if (cheer && companionId == 'gymbro')
          'Amigo, llevamos {dias} días sin entrenar. Vamos a movernos un poco.',
        ...cheer
            ? const [
                'Llevamos {dias} días sin vernos. ¿Algo corto hoy?',
                '¿Algo corto hoy?',
              ]
            : const [
                'Llevas {dias} días sin registrar.',
                'Hace unos días que no registras.',
              ],
      ],
    );
    if (custom == null) return base;
    List<String> pick(List<String> mine, List<String> fallback) =>
        mine.isEmpty ? fallback : mine;
    return ReminderTemplates(
      windowStart: pick(custom.windowStart, base.windowStart),
      lastCall: pick(custom.lastCall, base.lastCall),
      inactive: pick(custom.inactive, base.inactive),
    );
  }
}

/// One reminder as the native side receives it (snapshot version 1).
class ReminderEntry {
  const ReminderEntry({
    required this.id,
    required this.companionId,
    required this.companionName,
    required this.days,
    required this.windowStartMin,
    required this.windowEndMin,
    required this.tone,
    required this.paused,
    required this.templates,
    this.lastCallMin,
    this.lastDoneDate,
    this.lastActivityDate,
    this.streak = 0,
    this.goalText,
    this.minimumText,
    this.weekId,
    this.weekCount = 0,
    this.weekTarget,
  });

  final String id, companionId, companionName, tone;
  final int days, windowStartMin, windowEndMin;
  final int? lastCallMin;
  final bool paused;

  /// `YYYY-MM-DD` in the device's local zone.
  final String? lastDoneDate, lastActivityDate;
  final int streak;
  final String? goalText, minimumText;
  final String? weekId;
  final int weekCount;
  final int? weekTarget;
  final ReminderTemplates templates;

  Map<String, Object?> toJson() => {
    'id': id,
    'companionId': companionId,
    'companionName': companionName,
    'days': days,
    'windowStartMin': windowStartMin,
    'windowEndMin': windowEndMin,
    'lastCallMin': lastCallMin,
    'tone': tone,
    'paused': paused,
    'lastDoneDate': lastDoneDate,
    'lastActivityDate': lastActivityDate,
    'streak': streak,
    'goalText': goalText,
    'minimumText': minimumText,
    'weekId': weekId,
    'weekCount': weekCount,
    'weekTarget': weekTarget,
    'templates': templates.toJson(),
  };
}

/// ISO-8601 week of [day], like `2026-W44`.
String isoWeekId(DateTime day) {
  final date = DateTime.utc(day.year, day.month, day.day);
  final thursday = date.add(Duration(days: 4 - date.weekday));
  final jan1 = DateTime.utc(thursday.year, 1, 1);
  final week = (thursday.difference(jan1).inDays ~/ 7) + 1;
  return '${thursday.year.toString().padLeft(4, '0')}-W${week.toString().padLeft(2, '0')}';
}

String reminderDay(DateTime moment) {
  final local = moment.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}';
}

/// Picks and fills the notification text (the Kotlin side mirrors this).
///
/// Start-of-window uses the `inactive` list when the last activity is older
/// than yesterday; the last call always uses `lastCall`. The first template
/// whose markers all have a value wins; if none does, the last one is used.
String renderReminder(ReminderEntry entry, ReminderKind kind, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  int? daysSince;
  final last = entry.lastActivityDate;
  if (last != null) {
    final parts = last.split('-').map(int.parse).toList();
    daysSince = today.difference(DateTime(parts[0], parts[1], parts[2])).inDays;
  }
  final inactive = daysSince != null && daysSince >= 2;
  final list = switch (kind) {
    ReminderKind.lastCall => entry.templates.lastCall,
    ReminderKind.windowStart =>
      inactive ? entry.templates.inactive : entry.templates.windowStart,
  };
  if (list.isEmpty) return '';

  final target = entry.weekTarget;
  int? missing;
  if (target != null) {
    missing = entry.weekId == isoWeekId(today)
        ? target - entry.weekCount
        : target;
    if (missing <= 0) missing = null;
  }
  final values = <String, String?>{
    'dias': inactive ? '$daysSince' : null,
    'faltan': missing == null ? null : '$missing',
    'racha': entry.streak > 0 ? '${entry.streak}' : null,
    'minimo': entry.minimumText,
    'meta': entry.goalText,
    'nombre': entry.companionName,
  };
  final marker = RegExp(r'\{(\w+)\}');
  bool complete(String template) => marker
      .allMatches(template)
      .every((m) => (values[m.group(1)] ?? '').isNotEmpty);
  final chosen = list.firstWhere(complete, orElse: () => list.last);
  return chosen.replaceAllMapped(marker, (m) => values[m.group(1)] ?? '');
}
