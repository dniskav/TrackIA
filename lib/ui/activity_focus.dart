import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/workout_controller.dart';
import '../domain/activity.dart';
import '../domain/workout.dart';
import '../data/activity_template_repository.dart';
import 'activity_builder.dart';
import 'instant_record.dart';
import 'proposal_card.dart' show LockBadge;
import 'session_control.dart';
import 'theme.dart';
import 'timer_ring.dart';

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
        const SnackBar(
          content: Text('No se pudo guardar el contador. Vuelve a intentarlo.'),
        ),
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
          const SnackBar(
            content: Text(
              'No se pudo guardar el resultado. Conserva el texto y vuelve a intentarlo.',
            ),
          ),
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
                title: const Text('Revisar hora'),
                content: const Text(
                  'La hora elegida no coincide con los registros. ¿Guardar esa hora y conservarlos?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Volver'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Guardar esa hora'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!accept) return;
      }
      await c.run(
        () => c.activityRepository!.finishActivity(
          a.id,
          end,
          acceptConflicts: accept,
        ),
      );
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
          const SnackBar(
            content: Text('No se pudo guardar en tus actividades.'),
          ),
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
          const SnackBar(
            content: Text(
              'No se pudo guardar el registro. Vuelve a intentarlo.',
            ),
          ),
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
      final done = await c.run(
        () => c.activityRepository!.setActivityRest(a.id, value),
      );
      if (done) {
        widget.onActivityEdited?.call('Cambiaste el descanso a $value s');
      }
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
      await finishSession(context, c, workout, title: 'Finalizar día');
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
          closingDay ? 'Finalizar día' : 'Terminar',
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
          (definition.companionId == 'gymbro' ? 'serie' : 'tramo');
      final segments =
          definition.segmentPlural ??
          (definition.companionId == 'gymbro' ? 'series' : 'tramos');
      final status = running != null
          ? definition.repeated
                ? '${segment[0].toUpperCase()}${segment.substring(1)} ${a.intervals.length}${definition.targetSets == null ? '' : ' de ${definition.targetSets}'}'
                : 'En marcha'
          : a.intervals.isEmpty
          ? 'Listo'
          : definition.repeated
          ? '${a.intervals.where((i) => i.endedAt != null).length}${definition.targetSets == null ? '' : '/${definition.targetSets}'} $segments · Descanso'
          : 'Descanso';
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
                          IconButton(
                            key: const Key('change-activity'),
                            tooltip: 'Elegir otra actividad',
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
                                'Ciclos ${definition.completedCycles}/${definition.targetCycles}',
                                key: const Key('cycle-count'),
                              ),
                              const Spacer(),
                              IconButton(
                                key: const Key('cycle-decrement'),
                                tooltip: 'Restar ciclo',
                                onPressed:
                                    enabled && definition.completedCycles > 0
                                    ? () => changeCycle(-1)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              IconButton(
                                key: const Key('cycle-increment'),
                                tooltip: 'Añadir ciclo completado',
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
                                  tooltip: 'Quitar ${field['label']}',
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
                                  tooltip: 'Añadir ${field['label']}',
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
                                running == null ? 'Iniciar' : 'Parar',
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
                                  'Avisos desactivados',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const Key('notices-enable'),
                                onPressed: widget.onEnableNotices,
                                child: const Text('Activar'),
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

  /// No activity: a thin bar that works without AI and offers to create one.
  Widget _idleBar(
    BuildContext context, {
    required bool blockedByOther,
    required bool enabled,
    required bool closingDay,
    required Widget finishButton,
    required Widget? restButton,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final compact = widget.compact;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          blockedByOther ? 'Otro acompañante activo' : 'Sin actividad',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        if (!compact)
          Text(
            blockedByOther
                ? 'Termina la otra actividad para iniciar aquí'
                : 'Registra una cuando quieras',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
      ],
    );
    final newButton = OutlinedButton.icon(
      key: const Key('new-activity'),
      onPressed: enabled ? choose : null,
      icon: const Icon(Icons.add),
      label: const Text('Nueva actividad'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
    );
    // Closing the day or resting adds buttons; they wrap instead of overflowing
    // on narrow screens or with large system fonts.
    final extras = [
      if (restButton != null) restButton,
      if (closingDay) finishButton,
      if (instantTemplates.isNotEmpty && !blockedByOther)
        OutlinedButton.icon(
          key: const Key('record-instant'),
          onPressed: enabled ? startInstantRecord : null,
          icon: const Icon(Icons.edit_note),
          label: const Text('Registrar'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: title),
                if (!blockedByOther && extras.isEmpty)
                  Flexible(child: newButton),
              ],
            ),
            if (extras.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [...extras, if (!blockedByOther) newButton],
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
    );
  }
}

String _clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

class ActivityNameDialog extends StatefulWidget {
  const ActivityNameDialog({super.key, required this.initial});
  final String initial;
  @override
  State<ActivityNameDialog> createState() => _ActivityNameDialogState();
}

class _ActivityNameDialogState extends State<ActivityNameDialog> {
  late final input = TextEditingController(text: widget.initial);
  String? error;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void save() {
    try {
      Navigator.pop(context, validName(input.text));
    } on ValidationException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nombre de la actividad'),
    content: TextField(
      key: const Key('activity-name-input'),
      controller: input,
      autofocus: true,
      maxLength: 80,
      decoration: InputDecoration(labelText: 'Nombre', errorText: error),
      onSubmitted: (_) => save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: save, child: const Text('Guardar nombre')),
    ],
  );
}

ActivityDefinition _legacyStrength(
  String name,
  int restSeconds, {
  int? targetSets,
  String instructions = '',
}) => ActivityDefinition(
  name: name,
  restSeconds: restSeconds,
  targetSets: targetSets,
  instructions: instructions,
  fields: const [
    {'key': 'weight_kg', 'label': 'Peso', 'unit': 'kg'},
    {'key': 'reps', 'label': 'Repeticiones', 'unit': ''},
    {'key': 'failure', 'label': 'Fallo', 'unit': ''},
  ],
);

class ActivityChoice {
  const ActivityChoice(this.definition, [this.exerciseId])
    : instant = false,
      save = false;

  /// What the activity builder or a saved template returned.
  const ActivityChoice.built(
    this.definition, {
    this.instant = false,
    this.save = false,
  }) : exerciseId = null;
  final ActivityDefinition definition;
  final String? exerciseId;

  /// A point record with no clock: nothing is prepared, a value is recorded.
  final bool instant;

  /// Keep it among the companion's saved activities.
  final bool save;
}

class ActivityChooser extends StatefulWidget {
  const ActivityChooser({
    super.key,
    required this.controller,
    this.companionId = 'gymbro',
  });
  final WorkoutController controller;
  final String companionId;
  @override
  State<ActivityChooser> createState() => _ActivityChooserState();
}

class _ActivityChooserState extends State<ActivityChooser> {
  List<ActivityTemplate> templates = [];
  WorkoutController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.templates
        ?.list(companionId: widget.companionId)
        .then((found) {
          if (mounted) setState(() => templates = found);
        })
        .catchError((Object _) {
          // The saved list is a convenience: the chooser works without it.
        });
  }

  @override
  Widget build(BuildContext context) {
    final unique = <String, ActivityDefinition>{};
    for (final a in controller.activities) {
      unique.putIfAbsent(a.definition.name.toLowerCase(), () => a.definition);
    }
    for (final t in templates) {
      unique.remove(t.definition.name.toLowerCase());
    }
    for (final w in controller.history) {
      for (final e in w.exercises) {
        unique.putIfAbsent(
          e.name.toLowerCase(),
          () => _legacyStrength(e.name, e.restSeconds),
        );
      }
    }
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '¿Qué vas a hacer?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (templates.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Text('Tus actividades'),
                    ),
                    for (final t in templates)
                      ListTile(
                        key: Key('template-${t.id}'),
                        leading: Icon(
                          t.instant
                              ? Icons.touch_app_outlined
                              : Icons.bookmark_outline,
                        ),
                        title: Text(t.definition.name),
                        subtitle: Text(
                          t.instant ? 'Registro puntual' : 'Tu actividad',
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          ActivityChoice.built(
                            t.definition,
                            instant: t.instant,
                          ),
                        ),
                      ),
                    const Divider(),
                  ],
                  for (final e in controller.active?.exercises ?? <Exercise>[])
                    ListTile(
                      title: Text(e.name),
                      subtitle: Text(
                        e.targetSets == null
                            ? 'Del entrenamiento actual'
                            : '${e.sets.length + controller.activities.where((a) => a.exerciseId == e.id).fold<int>(0, (n, a) => n + a.intervals.where((i) => i.endedAt != null).length)}/${e.targetSets} series · ${e.repsMin}–${e.repsMax} reps',
                      ),
                      onTap: () => Navigator.pop(
                        context,
                        ActivityChoice(
                          ActivityDefinition(
                            name: e.name,
                            restSeconds: e.restSeconds,
                            fields: const [
                              {
                                'key': 'weight_kg',
                                'label': 'Peso',
                                'unit': 'kg',
                              },
                              {
                                'key': 'reps',
                                'label': 'Repeticiones',
                                'unit': '',
                              },
                              {'key': 'failure', 'label': 'Fallo', 'unit': ''},
                            ],
                          ),
                          e.id,
                        ),
                      ),
                    ),
                  for (final d in unique.values)
                    ListTile(
                      title: Text(d.name),
                      subtitle: const Text('Volver a hacer'),
                      onTap: () => Navigator.pop(
                        context,
                        ActivityChoice(
                          ActivityDefinition.fromJson({
                            ...d.toJson(),
                            'completedCycles': 0,
                          }),
                        ),
                      ),
                    ),
                  for (final routine in controller.routines)
                    for (final e in routine.exercises)
                      ListTile(
                        title: Text(e.name),
                        subtitle: Text(
                          '${routine.name} · ${e.targetSets} series',
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          ActivityChoice(
                            _legacyStrength(
                              e.name,
                              e.restSeconds,
                              targetSets: e.targetSets,
                              instructions:
                                  'De la rutina ${routine.name}: ${e.targetSets} series, ${e.repsMin}–${e.repsMax} repeticiones previstas. No son resultados realizados.',
                            ),
                          ),
                        ),
                      ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Nueva actividad'),
                    onTap: () async {
                      final built = await Navigator.of(context)
                          .push<ActivityBuilderResult>(
                            MaterialPageRoute(
                              builder: (_) => ActivityBuilder(
                                companionId: widget.companionId,
                              ),
                            ),
                          );
                      if (context.mounted && built != null) {
                        Navigator.pop(
                          context,
                          ActivityChoice.built(
                            built.definition,
                            instant: built.instant,
                            save: built.save,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityRestDialog extends StatefulWidget {
  const ActivityRestDialog({super.key, required this.seconds});
  final int seconds;
  @override
  State<ActivityRestDialog> createState() => _ActivityRestDialogState();
}

class _ActivityRestDialogState extends State<ActivityRestDialog> {
  late final input = TextEditingController(text: '${widget.seconds}');
  String? error;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Descanso'),
    content: TextField(
      controller: input,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: 'Segundos', errorText: error),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          final value = int.tryParse(input.text);
          if (value == null || value < 0 || value > 1800) {
            setState(() => error = 'Entre 0 y 1800');
            return;
          }
          Navigator.pop(context, value);
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}

class ActivityEndDialog extends StatefulWidget {
  const ActivityEndDialog({super.key, required this.initial});
  final DateTime initial;
  @override
  State<ActivityEndDialog> createState() => _ActivityEndDialogState();
}

class _ActivityEndDialogState extends State<ActivityEndDialog> {
  late DateTime end = widget.initial.toLocal();
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Terminar actividad'),
    content: Row(
      children: [
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: end,
                firstDate: DateTime(1970),
                lastDate: DateTime(2100, 12, 31),
              );
              if (date != null && mounted) {
                setState(
                  () => end = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    end.hour,
                    end.minute,
                    end.second,
                  ),
                );
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Fecha'),
              child: Text(DateFormat('d/M/yyyy').format(end)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(end),
                initialEntryMode: TimePickerEntryMode.input,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (time != null && mounted) {
                setState(
                  () => end = DateTime(
                    end.year,
                    end.month,
                    end.day,
                    time.hour,
                    time.minute,
                  ),
                );
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Hora'),
              child: Text(DateFormat('HH:mm').format(end)),
            ),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, end),
        child: const Text('Guardar'),
      ),
    ],
  );
}
