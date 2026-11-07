import 'package:flutter/material.dart';
import '../application/localization.dart';
import '../domain/activity.dart';
import '../domain/workout.dart';

class InstantRecordResult {
  const InstantRecordResult(this.original, this.values);

  /// What the user wrote, or a summary of the values when there is no note.
  final String original;

  /// Only the fields that were filled: a missing key means «not recorded».
  final Map<String, Object> values;
}

/// Bottom sheet to record one value of a point activity (no clock): a control
/// per field type and an optional note.
class InstantRecordSheet extends StatefulWidget {
  const InstantRecordSheet({super.key, required this.definition});

  final ActivityDefinition definition;

  @override
  State<InstantRecordSheet> createState() => _InstantRecordSheetState();
}

class _InstantRecordSheetState extends State<InstantRecordSheet> {
  final texts = <String, TextEditingController>{};
  final chosen = <String, Object>{};
  final note = TextEditingController();
  String? error;

  @override
  void initState() {
    super.initState();
    for (final f in widget.definition.fields) {
      final type = f['type'];
      if (type == null || type == 'number' || type == 'text') {
        texts[f['key'] as String] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in texts.values) {
      c.dispose();
    }
    note.dispose();
    super.dispose();
  }

  static String formatNumber(num value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString().replaceAll('.', ',');

  void submit() {
    final values = <String, Object>{};
    try {
      for (final f in widget.definition.fields) {
        final key = f['key'] as String, label = f['label'] as String;
        final raw = texts[key]?.text.trim();
        switch (f['type']) {
          case 'number':
            if (raw == null || raw.isEmpty) continue;
            final value = num.tryParse(raw.replaceAll(',', '.'));
            if (value == null || !value.isFinite) {
              throw ValidationException(
                appText(context).homeNumberInvalid(label),
              );
            }
            values[key] = value;
          case 'scale' || 'choice' || 'boolean':
            final value = chosen[key];
            if (value != null) values[key] = value;
          default:
            if (raw != null && raw.isNotEmpty) values[key] = raw;
        }
      }
      final text = note.text.trim();
      if (values.isEmpty && text.isEmpty) {
        throw ValidationException(appText(context).homeNoteOrValueRequired);
      }
      validateFieldValues(widget.definition, values);
      Navigator.pop(
        context,
        InstantRecordResult(text.isEmpty ? summary(values) : text, values),
      );
    } on ValidationException catch (e) {
      setState(() => error = e.message);
    }
  }

  String summary(Map<String, Object> values) => values.entries
      .map((e) {
        final f = widget.definition.fields.firstWhere((f) => f['key'] == e.key);
        final value = e.value;
        final shown =
            value is num
                ? formatNumber(value)
                : value is bool
                // Se guarda como resultado y lo lee el asistente: no depende del idioma.
                ? (value ? 'sí' : 'no')
                : '$value';
        final unit = f['unit'] as String;
        return '${f['label']} $shown${unit.isEmpty ? '' : ' $unit'}';
      })
      .join(' · ');

  Widget chips(String key, List<(Object, String, String)> options) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final (value, label, id) in options)
        ChoiceChip(
          key: Key('record-$key-$id'),
          label: Text(label),
          selected: chosen[key] == value,
          onSelected:
              (on) => setState(() {
                if (on) {
                  chosen[key] = value;
                } else {
                  chosen.remove(key);
                }
                error = null;
              }),
        ),
    ],
  );

  Widget field(Map<String, Object> f) {
    final key = f['key'] as String, label = f['label'] as String;
    final unit = f['unit'] as String;
    final title = unit.isEmpty || f['type'] != 'number' ? label : '$label ($unit)';
    switch (f['type']) {
      case 'scale':
        return labelled(title, chips(key, [
          for (var n = f['min'] as int; n <= (f['max'] as int); n++) (n, '$n', '$n'),
        ]));
      case 'choice':
        return labelled(title, chips(key, [
          for (final o in f['options'] as List) (o as Object, o as String, o),
        ]));
      case 'boolean':
        return labelled(title, chips(key, [(true, appText(context).homeOptionYes, 'yes'), (false, appText(context).homeOptionNo, 'no')]));
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            key: Key('record-$key'),
            controller: texts[key],
            keyboardType:
                f['type'] == 'number'
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
            decoration: InputDecoration(labelText: title),
          ),
        );
    }
  }

  Widget labelled(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.definition.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final f in widget.definition.fields) field(f),
            TextField(
              key: const Key('record-note'),
              controller: note,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(labelText: appText(context).homeNoteOptional),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  error!,
                  key: const Key('record-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('record-submit'),
                onPressed: submit,
                child: Text(appText(context).save),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
