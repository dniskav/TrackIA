import 'package:flutter/material.dart';
import '../application/localization.dart';
import '../domain/workout.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w700,
    ),
  );
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 30,
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

class NameDialog extends StatefulWidget {
  const NameDialog({
    super.key,
    required this.title,
    required this.label,
    required this.action,
    this.initial = '',
    this.suggestions = false,
  });
  final String title, label, action, initial;
  final bool suggestions;
  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  late final text = TextEditingController(text: widget.initial);
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  void submit() {
    if (form.currentState!.validate()) Navigator.pop(context, text.text.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: text,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: widget.label),
              onFieldSubmitted: (_) => submit(),
              validator: (value) {
                try {
                  validName(value ?? '');
                  return null;
                } on ValidationException catch (e) {
                  return e.message;
                }
              },
            ),
            if (widget.suggestions) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final name in [
                    appText(context).homeSuggestionSquat,
                    appText(context).homeSuggestionBench,
                    appText(context).homeSuggestionRow,
                  ])
                    ActionChip(
                      label: Text(name),
                      onPressed: () => text.text = name,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(appText(context).cancel),
      ),
      FilledButton(onPressed: submit, child: Text(widget.action)),
    ],
  );
}

class SetInput {
  const SetInput(this.weight, this.reps);
  final String weight, reps;
}

class SetDialog extends StatefulWidget {
  const SetDialog({super.key, this.existing, this.previous});
  final WorkoutSet? existing, previous;
  @override
  State<SetDialog> createState() => _SetDialogState();
}

class _SetDialogState extends State<SetDialog> {
  late final weight = TextEditingController(
    text: widget.existing != null
        ? formatWeight(widget.existing!.weight)
        : widget.previous != null
        ? formatWeight(widget.previous!.weight)
        : '',
  );
  late final reps = TextEditingController(
    text: (widget.existing?.reps ?? widget.previous?.reps)?.toString() ?? '',
  );
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    weight.dispose();
    reps.dispose();
    super.dispose();
  }

  void submit() {
    if (form.currentState!.validate()) {
      Navigator.pop(context, SetInput(weight.text, reps.text));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.existing == null
          ? appText(context).homeNewSet
          : appText(context).homeEditSet,
    ),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: const Key('weight-input'),
              controller: weight,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: appText(context).homeWeightLabel,
                hintText: appText(context).homeWeightHint,
                errorMaxLines: 3,
              ),
              validator: (v) {
                try {
                  parseWeight(v ?? '');
                  return null;
                } on ValidationException catch (e) {
                  return e.message;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('reps-input'),
              controller: reps,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: appText(context).homeRepsLabel,
                hintText: appText(context).homeRepsHint,
                errorMaxLines: 3,
              ),
              onFieldSubmitted: (_) => submit(),
              validator: (v) {
                try {
                  parseReps(v ?? '');
                  return null;
                } on ValidationException catch (e) {
                  return e.message;
                }
              },
            ),
            const SizedBox(height: 14),
            Text(
              appText(context).homeZeroWeightHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(appText(context).cancel),
      ),
      FilledButton(onPressed: submit, child: Text(appText(context).save)),
    ],
  );
}
