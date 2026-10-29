import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/progress_repository.dart';
import '../domain/companion.dart';
import '../domain/reminder.dart';

/// Builds the reminders snapshot and hands it to Android, which schedules the
/// notifications on its own (`contracts/reminders-android.md`). Flutter only
/// regenerates it; the phone keeps working without the app open.
class ReminderScheduler {
  ReminderScheduler({
    required this.progress,
    required this.companions,
    Future<Object?> Function(String method, Map<String, Object?> args)? invoke,
    DateTime Function()? clock,
    bool? supported,
    this.doneDays,
  }) : _invoke = invoke ?? _channelInvoke,
       _clock = clock ?? DateTime.now,
       supported = supported ?? Platform.isAndroid;

  static const channel = MethodChannel('com.gymia.app/reminders');
  static const pauseAfterMissedDays = 7;
  static const _lookBackDays = 60;

  static Future<Object?> _channelInvoke(
    String method,
    Map<String, Object?> args,
  ) => channel.invokeMethod<Object?>(method, args);

  final ProgressRepository progress;

  /// Days that count as done for a companion. By default a day with any session
  /// does; the app passes the progress engine's rule instead (goals, minimum).
  final Future<Set<String>> Function(String companionId)? doneDays;
  final Future<List<Companion>> Function() companions;
  final Future<Object?> Function(String method, Map<String, Object?> args)
  _invoke;
  final DateTime Function() _clock;
  final bool supported;

  Timer? _pending;

  /// Number of times a snapshot was sent; useful to tests and diagnostics.
  int syncs = 0;

  /// Asks for a sync shortly, folding bursts (a value, a stop, a finish) into
  /// one call: while one is already waiting, further requests join it.
  void schedule([Duration delay = const Duration(seconds: 2)]) {
    if (!supported || (_pending?.isActive ?? false)) return;
    _pending = Timer(delay, () => unawaited(sync()));
  }

  Listenable? _source;

  /// Follows [source] (the workout controller): every save, stop or finish it
  /// announces asks for a sync.
  void attach(Listenable source) {
    _source?.removeListener(schedule);
    _source = source..addListener(schedule);
  }

  void dispose() {
    _source?.removeListener(schedule);
    _source = null;
    _pending?.cancel();
  }

  /// Applies the 7-day pause rule and sends the current snapshot. Never
  /// throws: a reminder that cannot be scheduled must not break the app.
  Future<void> sync() async {
    _pending?.cancel();
    if (!supported) return;
    try {
      final snapshot = await buildSnapshot();
      await _invoke('sync', {'snapshot': jsonEncode(snapshot)});
      syncs++;
    } on MissingPluginException {
      // No native side (tests, other platforms).
    } on PlatformException {
      // Android refused; the next sync retries.
    }
  }

  /// The companion a tapped reminder asked to open, once. Null when none.
  Future<({String profileId, String companionId})?> takePendingOpen() async {
    if (!supported) return null;
    try {
      final raw = await _invoke('pendingOpen', const {});
      if (raw is! Map) return null;
      final profileId = raw['profileId'];
      final companionId = raw['companionId'];
      if (profileId is! String || companionId is! String) return null;
      return (profileId: profileId, companionId: companionId);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// The companion to open for a tapped reminder: only one of the current
  /// profile. A reminder of another profile never switches profile; the app
  /// just stays on its dashboard.
  static Companion? resolveOpen(
    ({String profileId, String companionId}) pending, {
    required String currentProfileId,
    required List<Companion> companions,
  }) {
    if (pending.profileId != currentProfileId) return null;
    return companions.where((c) => c.id == pending.companionId).firstOrNull;
  }

  /// Removes this profile's reminders from the phone.
  Future<void> clear() async {
    if (!supported) return;
    try {
      await _invoke('clear', {'profileId': progress.profileId});
    } on MissingPluginException {
      // Nothing to clear.
    } on PlatformException {
      // Ignored: the snapshot is stale at worst and is replaced on next sync.
    }
  }

  Future<Map<String, Object?>> buildSnapshot() async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final names = {for (final c in await companions()) c.id: c.name};
    final entries = <Map<String, Object?>>[];
    for (var reminder in await progress.activeReminders()) {
      final name = names[reminder.companionId];
      if (name == null) continue;
      final done = await (doneDays ?? progress.sessionDays)(
        reminder.companionId,
      );
      reminder = await _applyPause(reminder, done, today, now);
      entries.add(_entry(reminder, name, done, today).toJson());
    }
    return {
      'version': 1,
      'profileId': progress.profileId,
      'generatedAt': now.millisecondsSinceEpoch,
      'reminders': entries,
    };
  }

  /// 7 scheduled days in a row without a session pause the reminder; a session
  /// recorded after the pause (or «Reanudar») lifts it.
  Future<Reminder> _applyPause(
    Reminder reminder,
    Set<String> done,
    DateTime today,
    DateTime now,
  ) async {
    final pausedAt = reminder.pausedAt;
    if (pausedAt != null) {
      final since = reminderDay(pausedAt);
      if (done.any((day) => day.compareTo(since) >= 0)) {
        await progress.setPaused(reminder.companionId, paused: false);
        return reminder.copyWith(pausedAt: null);
      }
      return reminder;
    }
    final created = DateTime(
      reminder.createdAt.year,
      reminder.createdAt.month,
      reminder.createdAt.day,
    );
    var missed = 0;
    for (var back = 1; back <= _lookBackDays; back++) {
      final day = today.subtract(Duration(days: back));
      if (day.isBefore(created)) break;
      if (!reminder.scheduledOn(day.weekday)) continue;
      if (done.contains(reminderDay(day))) break;
      if (++missed >= pauseAfterMissedDays) {
        await progress.setPaused(reminder.companionId, paused: true);
        return reminder.copyWith(pausedAt: now);
      }
    }
    return reminder;
  }

  ReminderEntry _entry(
    Reminder reminder,
    String name,
    Set<String> done,
    DateTime today,
  ) {
    final todayKey = reminderDay(today);
    final past = done.where((d) => d.compareTo(todayKey) <= 0).toList()..sort();
    final last = past.isEmpty ? null : past.last;

    // Consecutive done days ending today, or yesterday if today is open.
    var streak = 0;
    var cursor = done.contains(todayKey)
        ? today
        : today.subtract(const Duration(days: 1));
    while (done.contains(reminderDay(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final monday = today.subtract(Duration(days: today.weekday - 1));
    var weekCount = 0;
    for (var i = 0; i < today.weekday; i++) {
      if (done.contains(reminderDay(monday.add(Duration(days: i))))) {
        weekCount++;
      }
    }

    return ReminderEntry(
      id: reminder.id,
      companionId: reminder.companionId,
      companionName: name,
      days: reminder.days,
      windowStartMin: reminder.windowStartMin,
      windowEndMin: reminder.windowEndMin,
      lastCallMin: reminder.lastCallMin,
      tone: reminder.tone,
      paused: reminder.paused,
      lastDoneDate: last,
      lastActivityDate: last,
      streak: streak,
      minimumText: minimumText(reminder.minimum),
      weekId: isoWeekId(today),
      weekCount: weekCount,
      weekTarget: reminder.daysPerWeek,
      templates: ReminderTemplates.defaults(
        tone: reminder.tone,
        companionId: reminder.companionId,
      ),
    );
  }

  /// «5 páginas»-style text for the reminder's minimum, if it has one. A
  /// field minimum may carry a `label` to show instead of the field key.
  static String? minimumText(Map<String, Object?>? minimum) {
    if (minimum == null) return null;
    final value = minimum['value'] as num;
    final n = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    final label = minimum['label'];
    return switch (minimum['metric']) {
      'sessions' => value == 1 ? '1 sesión' : '$n sesiones',
      'time' => '$n min',
      final String field => '$n ${label is String ? label : field}',
      _ => null,
    };
  }
}
