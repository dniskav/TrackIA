import 'activity_dialogs.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../application/workout_controller.dart';
import '../application/localization.dart';
import '../domain/activity.dart';
import '../data/activity_template_repository.dart';
import 'instant_record.dart';
import 'proposal_card.dart' show LockBadge;
import 'session_control.dart';
import 'theme.dart';
import 'timer_ring.dart';
export 'activity_dialogs.dart';

part 'focus_idle_bar.dart';

class ActivityFocusControls extends StatefulWidget {
  const ActivityFocusControls({
    super.key,
    required this.controller,
    required this.flushInput,
    this.compact = false,
    this.aiReady = true,
    this.hideStart = false,
    this.companionId = 'gymbro',
    this.noticesOff = false,
    this.onEnableNotices,
    this.onInstantRecorded,
    this.onActivityEdited,
    this.onActivityFinished,
  });
  final WorkoutController controller;
  final Future<void> Function() flushInput;
  final bool compact;
  final bool aiReady;
  final bool hideStart;
  final String companionId;

  /// Shows «Avisos desactivados · Activar» when the activity has a rest or a
  /// duration that would normally announce itself.
  final bool noticesOff;
  final VoidCallback? onEnableNotices;

  /// Told what was recorded so the chat can show «Registrado: …».
  final void Function(String)? onInstantRecorded;

  /// Told about a manual edit so the chat can note it for the assistant.
  final void Function(String)? onActivityEdited;

  /// Told when the activity was finished, so the chat can show its summary.
  final void Function(FocusActivity)? onActivityFinished;
  @override
  State<ActivityFocusControls> createState() => _ActivityFocusControlsState();
}

class _ActivityFocusControlsState extends State<ActivityFocusControls>
    with WidgetsBindingObserver {
  WorkoutController get c => widget.controller;
  FocusActivity? get focus {
    final activity = c.focus;
    return activity?.definition.companionId == widget.companionId
        ? activity
        : null;
  }

  Timer? ticker;
  bool acting = false, foreground = true;
  FocusActivity? get resting {
    final current = focus;
    if (current?.running != null) return null;
    if (current?.restEndsAt != null) return current;
    return c.activities
        .where(
          (a) =>
              a.definition.companionId == widget.companionId &&
              (a.restEndsAt?.isAfter(c.now()) ?? false),
        )
        .firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c.addListener(syncTicker);
    syncTicker();
    unawaited(loadInstantTemplates());
  }

  /// The clock only shows whole seconds, and only while an interval or rest
  /// is counting. Idle or backgrounded screens must not wake the CPU.
  void syncTicker() {
    final counting = focus?.running != null || resting != null;
    if (!mounted || !foreground || !counting) {
      ticker?.cancel();
      ticker = null;
      return;
    }
    ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      syncTicker();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground && mounted) setState(() {});
    syncTicker();
  }

  @override
  void dispose() {
    counterTimer?.cancel();
    final a = focus;
    if (a != null && pending.isNotEmpty) {
      // Leaving the screen must not lose the taps: save them without the UI.
      final controller = c;
      final batch = Map<String, int>.of(pending);
      final text = batch.entries
          .map((e) => '${labelOf(a, e.key)}: +${e.value}')
          .join(' · ');
      unawaited(
        controller.run(
          () => controller.activityRepository!.recordActivityMessage(
            a.id,
            text,
            intervalId: a.running?.id,
            metrics: Map<String, Object>.of(batch),
          ),
        ),
      );
    }
    ticker?.cancel();
    c.removeListener(syncTicker);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<ActivityTemplate> instantTemplates = [];

  Future<void> loadInstantTemplates() async {
    try {
      final all = await c.templates?.list(companionId: widget.companionId);
      if (mounted && all != null) {
        setState(() => instantTemplates = all.where((t) => t.instant).toList());
      }
    } catch (_) {
      // Point records are optional: the bar works without the list.
    }
  }

  /// Taps on a quick counter wait here so a burst becomes one message.
  final pending = <String, int>{};
  Timer? counterTimer;

  static bool countsUp(Map<String, Object> field) =>
      field['type'] == 'number' && field['aggregate'] == 'sum';

  String labelOf(FocusActivity a, String key) =>
      a.definition.fields.firstWhere((f) => f['key'] == key)['label'] as String;

  void bump(String key, int delta) {
    if (focus == null) return;
    setState(() {
      final next = (pending[key] ?? 0) + delta;
      if (next <= 0) {
        pending.remove(key);
      } else {
        pending[key] = next;
      }
    });
    counterTimer?.cancel();
    counterTimer = pending.isEmpty
        ? null
        : Timer(const Duration(seconds: 3), () => unawaited(flushCounters()));
  }

  /// Records the pending taps as a single message with their quantities (never
  /// running totals), linked to the current or last tramo.
  Future<void> flushCounters() async {
    counterTimer?.cancel();
    counterTimer = null;
    final a = focus;
    if (a == null || pending.isEmpty) return;
    final batch = Map<String, int>.of(pending);
    pending.clear();
    if (mounted) setState(() {});
    final text = batch.entries
        .map((e) => '${labelOf(a, e.key)}: +${e.value}')
        .join(' · ');
    final ok = await c.run(
      () => c.activityRepository!.recordActivityMessage(
        a.id,
        text,
        intervalId: a.running?.id,
        metrics: Map<String, Object>.of(batch),
      ),
    );
    if (!ok && mounted) {
      pending.addAll(batch);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appText(context).focusCounterSaveError)),
      );
    }
  }

  num recordedFor(FocusActivity a, String key) {
    final id = a.running?.id ?? a.intervals.lastOrNull?.id;
    return a.messages
        .where((m) => m.role == 'user' && m.intervalId == id)
        .fold<num>(0, (sum, m) {
          final v = m.metrics[key];
          return v is num ? sum + v : sum;
        });
  }

  static String shown(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  Future<void> act() async {
    final a = focus;
    if (a == null || acting || c.busy) return;
    if (a.running == null && widget.hideStart) return;
    setState(() => acting = true);
    try {
      if (a.running != null) {
        await flushCounters();
        await c.run(() => c.activityRepository!.stopInterval(a.id));
        await flush();
      } else {
        if (!await flush()) return;
        if (focus?.id == a.id) {
          await c.run(() => c.activityRepository!.startInterval(a.id));
        }
      }
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<bool> flush() async {
    try {
      await widget.flushInput();
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appText(context).focusResultSaveError)),
        );
      }
      return false;
    }
  }

  Future<void> finish() async {
    final a = focus;
    if (a == null || a.running != null || acting) return;
    setState(() => acting = true);
    try {
      await flushCounters();
      if (!await flush()) return;
      if (!mounted) return;
      final end = await showDialog<DateTime>(
        context: context,
        builder: (_) => ActivityEndDialog(initial: c.now()),
      );
      if (end == null || !mounted || focus?.id != a.id) return;
      final conflict =
          end.isBefore(a.createdAt) ||
          end.isAfter(c.now()) ||
          a.intervals.any((i) => i.endedAt != null && end.isBefore(i.endedAt!));
      var accept = false;
      if (conflict) {
        accept =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(appText(context).focusReviewTimeTitle),
                content: Text(appText(context).focusReviewTimeBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(appText(context).focusBack),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(appText(context).focusSaveThatTime),
                  ),
                ],
              ),
            ) ??
            false;
        if (!accept) return;
      }
      final done = await c.run(
        () => c.activityRepository!.finishActivity(
          a.id,
          end,
          acceptConflicts: accept,
        ),
      );
      if (done) widget.onActivityFinished?.call(a);
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  /// Keeps what the user asked to save (always for a point record, which only
  /// makes sense as a reusable shape). A failure never blocks the activity.
  Future<void> saveChoice(ActivityChoice choice) async {
    final templates = c.templates;
    if (templates == null || !(choice.save || choice.instant)) return;
    try {
      await templates.save(
        companionId: widget.companionId,
        definition: choice.definition.forCompanion(widget.companionId),
        instant: choice.instant,
      );
      unawaited(loadInstantTemplates());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appText(context).focusSaveActivityError)),
        );
      }
    }
  }

  Future<void> choose() async {
    if (!await flush()) return;
    if (!mounted) return;
    final choice = await showModalBottomSheet<ActivityChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          ActivityChooser(controller: c, companionId: widget.companionId),
    );
    if (choice == null) return;
    await saveChoice(choice);
    if (choice.instant) return recordInstant(choice.definition);
    await c.run(() async {
      await c.activityRepository!.prepareActivity(
        choice.definition.forCompanion(widget.companionId),
        exerciseId: choice.exerciseId,
      );
    });
  }

  Future<void> changePreparation() async {
    final a = focus;
    if (a == null || a.intervals.isNotEmpty || !await flush()) return;
    if (!mounted) return;
    final choice = await showModalBottomSheet<ActivityChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          ActivityChooser(controller: c, companionId: widget.companionId),
    );
    if (choice == null || focus?.id != a.id) return;
    await saveChoice(choice);
    if (choice.instant) return recordInstant(choice.definition);
    await c.run(
      () => c.activityRepository!.replaceActivityPreparation(
        a.id,
        choice.definition.forCompanion(widget.companionId),
        exerciseId: choice.exerciseId,
      ),
    );
  }

  /// Records one value of a point activity: no clock, no activity row.
  Future<void> recordInstant(ActivityDefinition definition) async {
    final observations = c.observations;
    if (observations == null || !mounted) return;
    final result = await showModalBottomSheet<InstantRecordResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InstantRecordSheet(definition: definition),
    );
    if (result == null) return;
    try {
      await observations.record(
        companionId: widget.companionId,
        definition: definition.forCompanion(widget.companionId),
        original: result.original,
        values: result.values,
      );
      widget.onInstantRecorded?.call('Registrado: ${result.original}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appText(context).focusRecordSaveError)),
        );
      }
    }
  }

  /// With one point shape the sheet opens straight away; with several the
  /// user picks first.
  Future<void> startInstantRecord() async {
    if (instantTemplates.length == 1) {
      return recordInstant(instantTemplates.single.definition);
    }
    final picked = await showModalBottomSheet<ActivityTemplate>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final t in instantTemplates)
              ListTile(
                leading: const Icon(Icons.touch_app_outlined),
                title: Text(t.definition.name),
                onTap: () => Navigator.pop(sheet, t),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await recordInstant(picked.definition);
  }

  Future<void> rename() async {
    final a = focus;
    if (a == null || acting || c.busy) return;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => ActivityNameDialog(initial: a.definition.name),
    );
    if (name == null || focus?.id != a.id) return;
    final done = await c.run(
      () => c.activityRepository!.renameActivity(a.id, name),
    );
    if (done) {
      widget.onActivityEdited?.call('Renombraste la actividad a «$name»');
    }
  }

  Future<void> releaseLock(String activityId, String lock) =>
      c.run(() => c.activityRepository!.clearUserSetLock(activityId, lock));

  Future<void> rest() async {
    final a = resting ?? focus;
    if (a == null) return;
    final value = await showDialog<int>(
      context: context,
      builder: (_) => ActivityRestDialog(seconds: a.definition.restSeconds),
    );
    if (value != null) {
      var updateActiveRest = false;
      if (a.restEndsAt?.isAfter(c.now()) ?? false) {
        if (!mounted) return;
        final choice = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(appText(context).activityRestInProgress),
            content: Text(appText(context).activityRestChangeNoticePrompt),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(appText(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(appText(context).activityKeepNotice),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(appText(context).activityChangeNotice),
              ),
            ],
          ),
        );
        if (choice == null) return;
        updateActiveRest = choice;
      }
      final done = await c.run(
        () => c.activityRepository!.setActivityRest(
          a.id,
          value,
          updateActiveRest: updateActiveRest,
          expectedRestEndsAt: updateActiveRest ? a.restEndsAt : null,
        ),
      );
      if (done) {
        widget.onActivityEdited?.call('Cambiaste el descanso a $value s');
      }
    }
  }

  Future<void> editTarget() async {
    final a = focus;
    if (a == null || acting || c.busy) return;
    var input = a.definition.targetSets?.toString() ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(appText(context).activityTargetTitle),
        content: TextFormField(
          initialValue: input,
          onChanged: (value) => input = value,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: appText(context).activityTargetLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(appText(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, input.trim()),
            child: Text(appText(context).save),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final target = result.isEmpty ? null : int.tryParse(result);
    if ((result.isNotEmpty && target == null) ||
        (target != null && (target < 1 || target > 100))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appText(context).activityTargetInvalid)),
      );
      return;
    }
    final done = await c.run(
      () => c.activityRepository!.setActivityTarget(
        a.id,
        target,
        expected: a.definition,
        expectedRevision: a.revision,
      ),
    );
    if (done && mounted) {
      final completed = (c.focus?.id == a.id ? c.focus! : a).intervals
          .where((i) => i.endedAt != null)
          .length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            target != null && completed > target
                ? appText(
                    context,
                  ).activityTargetPreservedProgress(target, completed)
                : appText(context).activityTargetUpdated,
          ),
        ),
      );
      widget.onActivityEdited?.call(
        appText(context).activityTargetChangedEvent(
          target?.toString() ?? appText(context).activityNoTarget,
        ),
      );
    }
  }

  Future<void> changeCycle(int delta) async {
    final a = focus;
    if (a == null || a.definition.targetCycles == null || acting || c.busy) {
      return;
    }
    await c.run(() => c.activityRepository!.changeCompletedCycles(a.id, delta));
  }

  Future<void> closeDay() async {
    if (!await flush()) return;
    final workout = c.active;
    if (mounted &&
        workout != null &&
        c.focus == null &&
        widget.companionId == 'gymbro') {
      await finishSession(
        context,
        c,
        workout,
        title: appText(context).activityFinishDay,
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final a = focus;
      final blockedByOther = c.focus != null && a == null;
      final running = a?.running;
      final compact = widget.compact;
      final enabled =
          c.loaded &&
          !c.busy &&
          !acting &&
          !blockedByOther &&
          c.activityRepository != null;
      final restOwner = resting;
      final remaining =
          restOwner?.restEndsAt?.difference(c.now()).inSeconds.clamp(0, 1800) ??
          0;
      final scheme = Theme.of(context).colorScheme;
      final closingDay =
          a == null &&
          c.active != null &&
          c.focus == null &&
          widget.companionId == 'gymbro';
      final finishButton = TextButton(
        key: const Key('finish-activity'),
        onPressed: closingDay
            ? (enabled ? closeDay : null)
            : enabled && running == null && a != null && a.intervals.isNotEmpty
            ? finish
            : null,
        child: Text(
          closingDay
              ? appText(context).activityFinishDay
              : appText(context).activityFinish,
          maxLines: 1,
          softWrap: false,
        ),
      );
      final restButton = TextButton(
        key: const Key('activity-rest'),
        onPressed: enabled && (a != null || restOwner != null) ? rest : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              restOwner == null
                  ? a == null
                        ? '—'
                        : '${a.definition.restSeconds}s'
                  : '${_clock(remaining)} · ${restOwner.definition.restSeconds}s',
            ),
            if ((restOwner ?? a)?.definition.userSet.contains('restSeconds') ??
                false)
              LockBadge(
                key: const Key('lock-restSeconds'),
                onRelease: () =>
                    releaseLock((restOwner ?? a)!.id, 'restSeconds'),
              ),
          ],
        ),
      );
      if (a == null) {
        return _idleBar(
          context,
          blockedByOther: blockedByOther,
          enabled: enabled,
          closingDay: closingDay,
          finishButton: finishButton,
          restButton: restOwner == null ? null : restButton,
        );
      }
      final definition = a.definition;
      // The activity names its own tramo; without one GymBro says «serie» and
      // every other companion «tramo», as before.
      final segment =
          definition.segmentSingular ??
          (definition.companionId == 'gymbro'
              ? appText(context).focusSegmentSerie
              : appText(context).focusSegmentTramo);
      final segments =
          definition.segmentPlural ??
          (definition.companionId == 'gymbro'
              ? appText(context).focusSegmentSeries
              : appText(context).focusSegmentTramos);
      final doneCount = a.intervals.where((i) => i.endedAt != null).length;
      final capitalSegment =
          '${segment[0].toUpperCase()}${segment.substring(1)}';
      final status = running != null
          ? definition.repeated
                ? definition.targetSets == null
                      ? appText(
                          context,
                        ).focusSegmentCount(capitalSegment, a.intervals.length)
                      : appText(context).focusSegmentCountOfTarget(
                          capitalSegment,
                          a.intervals.length,
                          definition.targetSets!,
                        )
                : appText(context).focusRunning
          : a.intervals.isEmpty
          ? appText(context).focusReady
          : definition.repeated
          ? appText(context).focusRepeatedRest(
              definition.targetSets == null
                  ? '$doneCount'
                  : '$doneCount/${definition.targetSets}',
              segments,
            )
          : appText(context).focusRest;
      final elapsed = running == null
          ? Duration.zero
          : c.now().difference(running.startedAt);
      final total = definition.activitySeconds == null
          ? null
          : Duration(seconds: definition.activitySeconds!);
      final canAct = enabled && (running != null || !widget.hideStart);
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ColoredBox(
            color: scheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 3,
                  color: running != null ? brandOrange : Colors.transparent,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              key: const Key('rename-activity'),
                              onTap: enabled ? rename : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        definition.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.edit_outlined, size: 18),
                                    if (definition.userSet.contains('name'))
                                      LockBadge(
                                        key: const Key('lock-name'),
                                        onRelease: () =>
                                            releaseLock(a.id, 'name'),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (definition.repeated)
                            IconButton(
                              key: const Key('edit-activity-target'),
                              tooltip: appText(
                                context,
                              ).activityTargetEditTooltip,
                              onPressed: enabled ? editTarget : null,
                              icon: const Icon(Icons.flag_outlined),
                            ),
                          IconButton(
                            key: const Key('change-activity'),
                            tooltip: appText(context).activityChooseAnother,
                            onPressed: enabled && a.intervals.isEmpty
                                ? changePreparation
                                : null,
                            icon: const Icon(Icons.swap_horiz),
                          ),
                          finishButton,
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (running != null && compact)
                              Text(
                                _clock(
                                  total == null
                                      ? elapsed.inSeconds.clamp(0, 8640000)
                                      : (total - elapsed).inSeconds.clamp(
                                          0,
                                          total.inSeconds,
                                        ),
                                ),
                                key: const Key('activity-clock'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (running == null) restButton,
                          ],
                        ),
                      ),
                      if (running != null && !compact)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TimerRing(
                            key: const Key('activity-clock'),
                            elapsed: elapsed,
                            total: total,
                          ),
                        ),
                      if (definition.targetCycles != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Row(
                            children: [
                              Text(
                                '${appText(context).activityCycles} ${definition.completedCycles}/${definition.targetCycles}',
                                key: const Key('cycle-count'),
                              ),
                              const Spacer(),
                              IconButton(
                                key: const Key('cycle-decrement'),
                                tooltip: appText(context).activitySubtractCycle,
                                onPressed:
                                    enabled && definition.completedCycles > 0
                                    ? () => changeCycle(-1)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              IconButton(
                                key: const Key('cycle-increment'),
                                tooltip: appText(context).activityAddCycle,
                                onPressed:
                                    enabled && definition.completedCycles < 999
                                    ? () => changeCycle(1)
                                    : null,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      if (!compact &&
                          (running != null || a.intervals.isNotEmpty))
                        for (final field in definition.fields.where(countsUp))
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    field['label'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  key: Key('counter-dec-${field['key']}'),
                                  tooltip: appText(
                                    context,
                                  ).focusRemoveField(field['label'] as String),
                                  onPressed: (pending[field['key']] ?? 0) > 0
                                      ? () => bump(field['key'] as String, -1)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    shown(
                                      recordedFor(a, field['key'] as String) +
                                          (pending[field['key']] ?? 0),
                                    ),
                                    key: Key('counter-${field['key']}'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  key: Key('counter-inc-${field['key']}'),
                                  tooltip: appText(
                                    context,
                                  ).focusAddField(field['label'] as String),
                                  onPressed: enabled
                                      ? () => bump(field['key'] as String, 1)
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                      if (!widget.hideStart || running != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8, top: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              key: const Key('activity-start-stop'),
                              style: running == null
                                  ? startButtonStyle(context)
                                  : stopButtonStyle(context),
                              onPressed: canAct ? act : null,
                              icon: Icon(
                                running == null ? Icons.play_arrow : Icons.stop,
                              ),
                              label: Text(
                                running == null
                                    ? appText(context).activityStart
                                    : appText(context).activityStop,
                              ),
                            ),
                          ),
                        ),
                      if (widget.noticesOff &&
                          !compact &&
                          (definition.restSeconds > 0 ||
                              definition.activitySeconds != null))
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  appText(context).activityNoticesOff,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const Key('notices-enable'),
                                onPressed: widget.onEnableNotices,
                                child: Text(
                                  appText(context).activityEnableNotices,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (c.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            c.error!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
