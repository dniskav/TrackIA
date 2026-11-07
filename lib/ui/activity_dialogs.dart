import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/localization.dart';
import '../application/workout_controller.dart';
import '../domain/activity.dart';
import '../domain/workout.dart';
import '../data/activity_template_repository.dart';
import 'activity_builder.dart';

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
    title: Text(appText(context).activityDialogNameTitle),
    content: TextField(
      key: const Key('activity-name-input'),
      controller: input,
      autofocus: true,
      maxLength: 80,
      decoration: InputDecoration(labelText: appText(context).companionName, errorText: error),
      onSubmitted: (_) => save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(appText(context).cancel),
      ),
      FilledButton(onPressed: save, child: Text(appText(context).activityDialogSaveName)),
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
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                appText(context).activityDialogWhatToDo,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (templates.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Text(appText(context).activityDialogYourActivities),
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
                          t.instant ? appText(context).activityDialogInstantRecord : appText(context).activityDialogYourActivity,
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
                            ? appText(context).activityDialogFromCurrentWorkout
                            : appText(context).activityDialogSetsProgress('${e.sets.length + controller.activities.where((a) => a.exerciseId == e.id).fold<int>(0, (n, a) => n + a.intervals.where((i) => i.endedAt != null).length)}', '${e.targetSets}', '${e.repsMin}', '${e.repsMax}'),
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
                      subtitle: Text(appText(context).activityDialogRepeat),
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
                          appText(context).activityDialogRoutineSets(routine.name, e.targetSets),
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
                    title: Text(appText(context).activityNewActivity),
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
    title: Text(appText(context).activityRestLabel),
    content: TextField(
      controller: input,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: appText(context).activityRestSecondsLabel, errorText: error),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(appText(context).cancel),
      ),
      FilledButton(
        onPressed: () {
          final value = int.tryParse(input.text);
          if (value == null || value < 0 || value > 1800) {
            setState(() => error = appText(context).activityDialogRestRange);
            return;
          }
          Navigator.pop(context, value);
        },
        child: Text(appText(context).save),
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
    title: Text(appText(context).activityDialogEndTitle),
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
              decoration: InputDecoration(labelText: appText(context).activityDialogDate),
              child: Text(DateFormat(appText(context).datePatternNumericDate, Localizations.localeOf(context).toString()).format(end)),
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
              decoration: InputDecoration(labelText: appText(context).activityDialogTime),
              child: Text(DateFormat('HH:mm').format(end)),
            ),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(appText(context).cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, end),
        child: Text(appText(context).save),
      ),
    ],
  );
}
