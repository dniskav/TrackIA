import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/localization.dart';
import '../application/workout_controller.dart';
import '../domain/workout.dart';
import 'routines.dart';
import 'rest_timer_panel.dart';
import 'data_transfer.dart';
import 'assistant_chat.dart';
import 'session_control.dart';
import 'gym_widgets.dart';

class GymHome extends StatefulWidget {
  const GymHome({super.key, required this.controller, this.onAssistant});
  final WorkoutController controller;
  final VoidCallback? onAssistant;
  @override
  State<GymHome> createState() => _GymHomeState();
}

class _GymHomeState extends State<GymHome> {
  int tab = 0;
  String? selectedId;
  WorkoutController get c => widget.controller;
  int _recordsFor(Workout w) =>
      w.setCount +
      c.activities
          .where((a) => a.workoutId == w.id)
          .fold(
            0,
            (count, a) =>
                count + a.intervals.where((i) => i.endedAt != null).length,
          );
  int _activitiesFor(Workout w) =>
      w.exercises.length +
      c.activities
          .where(
            (a) =>
                a.workoutId == w.id &&
                a.exerciseId == null &&
                a.intervals.isNotEmpty,
          )
          .length;

  Future<void> _start() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => NameDialog(
        title: appText(context).homeNewWorkoutTitle,
        label: appText(context).homeSessionNameLabel,
        initial: appText(context).homeWorkout,
        action: appText(context).start,
      ),
    );
    if (name == null || !mounted) return;
    final ok = await c.run(() async {
      await c.repository.start(name);
    });
    if (ok && mounted) setState(() => selectedId = c.active?.id);
  }

  Future<void> _addExercise(Workout workout) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => NameDialog(
        title: appText(context).homeAddExerciseTitle,
        label: appText(context).homeExerciseNameLabel,
        action: appText(context).homeAdd,
        suggestions: true,
      ),
    );
    if (name != null) {
      await c.run(() => c.repository.addExercise(workout.id, name));
    }
  }

  Future<void> _set(Exercise exercise, [WorkoutSet? existing]) async {
    final result = await showDialog<SetInput>(
      context: context,
      builder: (_) => SetDialog(
        existing: existing,
        previous:
            exercise.sets.lastOrNull ??
            (c.active == null
                ? null
                : c.previousFor(exercise, c.active!)?.sets.firstOrNull),
      ),
    );
    if (result == null) return;
    await c.run(
      () => existing == null
          ? c.repository.addSet(exercise.id, result.weight, result.reps)
          : c.repository.editSet(existing.id, result.weight, result.reps),
    );
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(appText(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _finish(Workout workout) async {
    await finishSession(context, c, workout);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final selected = c.workouts.where((w) => w.id == selectedId).firstOrNull;
      return PopScope(
        canPop: selected == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) setState(() => selectedId = null);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: selected == null
                ? null
                : IconButton(
                    tooltip: appText(context).homeBack,
                    onPressed: () => setState(() => selectedId = null),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
            title: Row(
              children: [
                if (selected == null) ...[
                  Icon(
                    Icons.fitness_center_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 23,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  selected == null
                      ? 'TrackIA'
                      : selected.isActive
                      ? appText(context).homeYourSession
                      : appText(context).homeWorkout,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: appText(context).homeAssistantTooltip,
                onPressed:
                    widget.onAssistant ??
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AssistantChatScreen(
                          controller: c,
                          chatStore: c.chats,
                        ),
                      ),
                    ),
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (selected == null)
                IconButton(
                  tooltip: appText(context).yourData,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DataTransferScreen(controller: c),
                    ),
                  ),
                  icon: Icon(
                    Icons.folder_open_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                if (c.busy) const LinearProgressIndicator(minHeight: 2),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(child: Text(c.error!)),
                            TextButton(
                              onPressed: c.busy ? null : c.refresh,
                              child: Text(appText(context).homeReload),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (selected?.isActive == true)
                  RestTimerPanel(
                    key: ValueKey(selected!.id),
                    controller: c,
                    workout: selected,
                  ),
                Expanded(
                  child: !c.loaded
                      ? Center(
                          child: c.busy
                              ? const CircularProgressIndicator()
                              : FilledButton(
                                  onPressed: c.refresh,
                                  child: Text(appText(context).homeLoadLog),
                                ),
                        )
                      : AbsorbPointer(
                          absorbing: c.busy,
                          child: selected != null
                              ? _detail(selected)
                              : tab == 0
                              ? _today()
                              : tab == 1
                              ? RoutineLibrary(
                                  controller: c,
                                  onStart: (routine) async {
                                    if (c.active != null) {
                                      setState(() => selectedId = c.active!.id);
                                      return;
                                    }
                                    final ok = await c.run(() async {
                                      await c.repository.startRoutine(
                                        routine.id,
                                      );
                                    });
                                    if (ok && mounted) {
                                      setState(() => selectedId = c.active?.id);
                                    }
                                  },
                                )
                              : _history(),
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: selected == null
              ? NavigationBar(
                  selectedIndex: tab,
                  onDestinationSelected: (value) => setState(() => tab = value),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  destinations: [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded),
                      label: appText(context).homeTabToday,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.view_list_rounded),
                      label: appText(context).homeTabRoutines,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history_rounded),
                      label: appText(context).homeTabHistory,
                    ),
                  ],
                )
              : null,
        ),
      );
    },
  );

  Widget _today() {
    final active = c.active;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        Text(
          DateFormat(
            "EEEE, d 'de' MMMM",
            'es',
          ).format(DateTime.now()).toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          appText(context).homeHeroTitle,
          style: TextStyle(
            fontSize: 38,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          appText(context).homeHeroSubtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    active == null
                        ? appText(context).homeNextSession
                        : appText(context).homeInProgress,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Icon(
                    Icons.fitness_center_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                active?.name ?? appText(context).homeReadyQuestion,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                active == null
                    ? appText(context).homeAddExercisesHint
                    : appText(context).homeActivitiesRecords(
                        _activitiesFor(active),
                        _recordsFor(active),
                      ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onPrimary,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: active == null
                      ? _start
                      : () => setState(() => selectedId = active.id),
                  icon: Icon(
                    active == null
                        ? Icons.add_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    active == null
                        ? appText(context).homeStartWorkout
                        : appText(context).homeContinueWorkout,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: '${c.history.length}',
                label: appText(context).homeCompletedSessions,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value:
                    '${c.history.fold<int>(0, (n, w) => n + _recordsFor(w))}',
                label: appText(context).homeRecords,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        SectionLabel(appText(context).homeLastActivity),
        const SizedBox(height: 12),
        if (c.history.isEmpty)
          EmptyPanel(
            icon: Icons.show_chart_rounded,
            title: appText(context).homeEmptyHistoryTitle,
            subtitle: appText(context).homeEmptyHistorySubtitle,
          )
        else
          _workoutTile(c.history.first),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 15,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                appText(context).homeSavedOffline,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _history() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        appText(context).homeJourneyTitle,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        appText(context).homeEverySessionCounts,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 24),
      if (c.history.isEmpty)
        EmptyPanel(
          icon: Icons.history_rounded,
          title: appText(context).homeNoSessionsTitle,
          subtitle: appText(context).homeNoSessionsSubtitle,
        ),
      for (final w in c.history) ...[
        _workoutTile(w),
        const SizedBox(height: 12),
      ],
    ],
  );

  Widget _workoutTile(Workout w) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => selectedId = w.id),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d MMM yyyy · HH:mm', 'es').format(w.startedAt),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_activitiesFor(w)} actividades · ${_recordsFor(w)} registros',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _detail(Workout w) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
    children: [
      Text(
        w.isActive
            ? appText(context).homeStatusInProgress
            : appText(context).homeStatusCompleted,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        w.name,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.8,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        DateFormat("d 'de' MMMM · HH:mm", 'es').format(w.startedAt),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      if (w.finishedAt != null) ...[
        const SizedBox(height: 8),
        Text(
          appText(context).homeFinishedAt(
            DateFormat('d/M/yyyy HH:mm:ss').format(w.finishedAt!.toLocal()),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (w.finishedRecordedAt != null)
          Text(
            w.finishTimeSource == FinishTimeSource.user
                ? appText(context).homeFinishRecordedByUser(
                    DateFormat('d/M/yyyy HH:mm:ss').format(w.finishedRecordedAt!.toLocal()),
                  )
                : appText(context).homeFinishRecorded(
                    DateFormat('d/M/yyyy HH:mm:ss').format(w.finishedRecordedAt!.toLocal()),
                  ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        if (w.finishTimeIssues.isNotEmpty)
          Text(
            appText(context).homeTimeKeptWarning,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
      ],
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: StatTile(
              value: '${_activitiesFor(w)}',
              label: appText(context).homeActivities,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(value: '${_recordsFor(w)}', label: appText(context).homeRecords),
          ),
        ],
      ),
      const SizedBox(height: 28),
      SectionLabel(appText(context).homeExercisesLabel),
      const SizedBox(height: 12),
      if (w.exercises.isEmpty)
        EmptyPanel(
          icon: Icons.fitness_center_rounded,
          title: appText(context).homeFirstSetTitle,
          subtitle: appText(context).homeFirstSetSubtitle,
        ),
      for (var i = 0; i < w.exercises.length; i++) ...[
        _exerciseCard(w.exercises[i], i + 1, w),
        const SizedBox(height: 16),
      ],
      for (final activity in c.activities.where(
        (a) => a.workoutId == w.id,
      )) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.definition.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  activity.intervals.isEmpty
                      ? appText(context).homeNotStarted
                      : activity.definition.repeated
                      ? appText(context).homeIntervalsRepeated(
                          activity.intervals.where((i) => i.endedAt != null).length,
                        )
                      : appText(context).homeIntervals(
                          activity.intervals.where((i) => i.endedAt != null).length,
                        ),
                ),
                if (activity.finishedAt != null)
                  Text(
                    appText(context).homeEndedAt(
                      DateFormat('d/M/yyyy HH:mm').format(activity.finishedAt!.toLocal()),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (activity.finishIssues
                    .where((i) => i != 'not_started')
                    .isNotEmpty)
                  Text(
                    appText(context).homeTimeKeptWarningShort,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                for (final message in activity.messages.where(
                  (m) => m.role == 'user',
                ))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SelectableText(message.text),
                  ),
                if (activity.draft.isNotEmpty)
                  Text(appText(context).homeDraft(activity.draft)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (w.isActive) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addExercise(w),
          icon: const Icon(Icons.add_rounded),
          label: Text(appText(context).homeAddExerciseTitle),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _recordsFor(w) == 0 || c.focus != null
              ? null
              : () => _finish(w),
          icon: const Icon(Icons.check_rounded),
          label: Text(appText(context).homeFinishWorkout),
        ),
        const SizedBox(height: 8),
        Text(
          _recordsFor(w) == 0
              ? appText(context).homeAddSetToFinish
              : appText(context).homeEachSetSaved,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () async {
            if (!await _confirm(
              appText(context).homeDiscardTitle,
              appText(context).homeDiscardBody,
              appText(context).homeDiscard,
            )) {
              return;
            }
            final ok = await c.run(() => c.repository.discard(w.id));
            if (ok && mounted) setState(() => selectedId = null);
          },
          child: Text(
            appText(context).homeDiscardSession,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ] else ...[
        const SizedBox(height: 8),
        Text(
          appText(context).homeSavedWellDone,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => setState(() {
            selectedId = null;
            tab = 2;
          }),
          child: Text(appText(context).homeViewHistory),
        ),
      ],
    ],
  );

  Widget _exerciseCard(Exercise e, int number, Workout workout) {
    final editable = workout.isActive;
    final previous = editable ? c.previousFor(e, workout) : null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                number.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (editable)
                IconButton(
                  tooltip: appText(context).homeDeleteExerciseTooltip(e.name),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () async {
                    if (await _confirm(
                      appText(context).homeDeleteExerciseTitle,
                      appText(context).homeDeleteExerciseBody(e.name, e.sets.length),
                      appText(context).homeDelete,
                    )) {
                      await c.run(() => c.repository.deleteExercise(e.id));
                    }
                  },
                ),
            ],
          ),
          if (e.targetSets != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                appText(context).homeTargetProgress(
                  e.targetSets!,
                  '${e.repsMin}',
                  '${e.repsMax}',
                  e.sets.length,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          if (editable)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      previous == null
                          ? appText(context).homeNoPreviousSession
                          : appText(context).homeLastTime(
                              DateFormat('d MMM', 'es').format(previous.date),
                            ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (previous != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        previous.sets
                            .map(
                              (s) => appText(context).homeWeightReps(formatWeight(s.weight), s.reps),
                            )
                            .join('  /  '),
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (e.sets.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                appText(context).homeNoSetsYet,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          if (e.sets.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    appText(context).homeSetHeader,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    appText(context).homeKgHeader,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    appText(context).homeRepsHeader,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
                SizedBox(width: 48),
              ],
            ),
            for (var i = 0; i < e.sets.length; i++)
              Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatWeight(e.sets[i].weight),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${e.sets[i].reps}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (editable)
                    PopupMenuButton<String>(
                      tooltip: appText(context).homeSetOptionsTooltip(i + 1),
                      onSelected: (action) async {
                        if (action == 'edit') {
                          await _set(e, e.sets[i]);
                        } else if (await _confirm(
                          appText(context).homeDeleteSetTitle,
                          appText(context).homeSetDeleteBody(
                            formatWeight(e.sets[i].weight),
                            e.sets[i].reps,
                          ),
                          appText(context).homeDelete,
                        )) {
                          await c.run(
                            () => c.repository.deleteSet(e.sets[i].id),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(appText(context).homeEditSet),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(appText(context).homeDeleteSet),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                    ),
                ],
              ),
          ],
          if (editable) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _set(e),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(appText(context).homeAddSet),
              ),
            ),
            TextButton.icon(
              onPressed: () => c.run(
                () => c.repository.startRest(workout.id, e.restSeconds),
              ),
              icon: const Icon(Icons.timer_outlined, size: 18),
              label: Text(appText(context).homeRest(e.restSeconds)),
            ),
          ],
        ],
      ),
    );
  }
}
