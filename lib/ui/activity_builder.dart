import 'package:flutter/material.dart';
import '../domain/activity.dart';
import '../domain/workout.dart';

/// How an activity unfolds in time. It is derived from the saved definition,
/// never stored (specs/004-trackia-experience/research.md → D2).
enum Rhythm { instant, free, timed, segments }

class ActivityBuilderResult {
  const ActivityBuilderResult(
    this.definition, {
    required this.instant,
    required this.save,
  });

  final ActivityDefinition definition;

  /// A point record with no clock, like «Beber agua».
  final bool instant;

  /// Keep it among the companion's own activities.
  final bool save;
}

/// A starting point that fills the same form; it is not a type of activity.
class _Preset {
  const _Preset({
    required this.name,
    required this.rhythm,
    this.minutes,
    this.restSeconds,
    this.sets,
    this.cycles,
    this.singular,
    this.plural,
    this.fields = const [],
  });

  final String name;
  final Rhythm rhythm;
  final int? minutes, restSeconds, sets, cycles;
  final String? singular, plural;
  final List<Map<String, Object>> fields;
}

const _presets = <String, (String, _Preset)>{
  'futbol': (
    'Fútbol',
    _Preset(
      name: 'Partido de fútbol',
      rhythm: Rhythm.segments,
      sets: 2,
      minutes: 25,
      restSeconds: 300,
      singular: 'tiempo',
      plural: 'tiempos',
      fields: [
        {'key': 'goals', 'label': 'Goles', 'unit': '', 'type': 'number'},
        {'key': 'assists', 'label': 'Asistencias', 'unit': '', 'type': 'number'},
      ],
    ),
  ),
  'yoga': (
    'Yoga',
    _Preset(
      name: 'Clase de yoga',
      rhythm: Rhythm.timed,
      minutes: 60,
      fields: [
        {'key': 'intensity', 'label': 'Intensidad', 'unit': '', 'type': 'scale'},
      ],
    ),
  ),
  'pomodoro': (
    'Pomodoro',
    _Preset(
      name: 'Pomodoro',
      rhythm: Rhythm.segments,
      minutes: 25,
      restSeconds: 300,
      cycles: 4,
      singular: 'pomodoro',
      plural: 'pomodoros',
      fields: [
        {'key': 'task', 'label': 'Tarea', 'unit': '', 'type': 'text', 'aggregate': 'none'},
      ],
    ),
  ),
  'series': (
    'Series',
    _Preset(
      name: 'Series',
      rhythm: Rhythm.segments,
      sets: 4,
      restSeconds: 90,
      singular: 'serie',
      plural: 'series',
      fields: [
        {'key': 'weight', 'label': 'Peso', 'unit': 'kg', 'type': 'number', 'aggregate': 'max'},
        {'key': 'reps', 'label': 'Repeticiones', 'unit': '', 'type': 'number'},
      ],
    ),
  ),
  'correr': (
    'Correr',
    _Preset(
      name: 'Correr',
      rhythm: Rhythm.free,
      fields: [
        {'key': 'distance', 'label': 'Distancia', 'unit': 'km', 'type': 'number'},
      ],
    ),
  ),
  'leer': (
    'Leer',
    _Preset(
      name: 'Leer',
      rhythm: Rhythm.free,
      fields: [
        {'key': 'pages', 'label': 'Páginas', 'unit': 'páginas', 'type': 'number'},
        {
          'key': 'book',
          'label': 'Libro',
          'unit': '',
          'type': 'text',
          'aggregate': 'distinct',
          'countSingular': 'libro',
          'countPlural': 'libros',
        },
      ],
    ),
  ),
};

/// Creates an activity by hand, with no AI: how it unfolds, what to note and,
/// optionally, a template to start from.
class ActivityBuilder extends StatefulWidget {
  const ActivityBuilder({super.key, required this.companionId});

  final String companionId;

  static const _typeLabels = {
    'number': 'Número',
    'scale': 'Escala',
    'text': 'Texto',
    'choice': 'Opción',
    'boolean': 'Sí o no',
  };
  static const _aggregateLabels = {
    'sum': 'Sumar',
    'max': 'Mejor marca',
    'avg': 'Promedio',
    'distinct': 'Contar distintos',
    'countTrue': 'Contar síes',
    'none': 'Solo notas',
  };
  static const _aggregatesByType = {
    'number': ['sum', 'max', 'avg', 'none'],
    'scale': ['avg', 'none'],
    'text': ['distinct', 'none'],
    'choice': ['distinct', 'none'],
    'boolean': ['countTrue', 'none'],
  };

  /// Ways of counting that suit [type], in display order.
  static List<String> aggregatesFor(String type) =>
      _aggregatesByType[type] ?? const [];

  /// A valid, unique field key made from the label the user typed.
  static String fieldKeyFor(String label, List<String> existing) {
    const accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    };
    var base = label
        .toLowerCase()
        .split('')
        .map((c) => accents[c] ?? c)
        .join()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) base = 'campo';
    if (RegExp(r'^[0-9]').hasMatch(base)) base = 'campo_$base';
    if (base.length > 36) base = base.substring(0, 36).replaceAll(RegExp(r'_+$'), '');
    var key = base;
    for (var n = 2; existing.contains(key); n++) {
      key = '${base}_$n';
    }
    return key;
  }

  @override
  State<ActivityBuilder> createState() => _ActivityBuilderState();
}

class _ActivityBuilderState extends State<ActivityBuilder> {
  final name = TextEditingController();
  final duration = TextEditingController();
  final rest = TextEditingController();
  final segments = TextEditingController();
  final cycles = TextEditingController();
  final singular = TextEditingController();
  final plural = TextEditingController();
  Rhythm rhythm = Rhythm.free;
  final fields = <Map<String, Object>>[];
  bool save = true;
  String? error;
  String? lastPresetName;

  @override
  void dispose() {
    for (final c in [name, duration, rest, segments, cycles, singular, plural]) {
      c.dispose();
    }
    super.dispose();
  }

  void apply(_Preset preset) => setState(() {
    if (name.text.trim().isEmpty || name.text == lastPresetName) {
      name.text = preset.name;
    }
    lastPresetName = preset.name;
    rhythm = preset.rhythm;
    duration.text = preset.minutes?.toString() ?? '';
    rest.text = preset.restSeconds?.toString() ?? '';
    segments.text = preset.sets?.toString() ?? '';
    cycles.text = preset.cycles?.toString() ?? '';
    singular.text = preset.singular ?? '';
    plural.text = preset.plural ?? '';
    fields
      ..clear()
      ..addAll(preset.fields.map((f) => Map<String, Object>.of(f)));
    error = null;
  });

  int? whole(TextEditingController c, {required int min, required int max, required String what}) {
    final text = c.text.trim();
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    if (value == null) {
      throw const ValidationException('Escribe solo números enteros.');
    }
    if (value < min || value > max) {
      throw ValidationException('$what va de $min a $max.');
    }
    return value;
  }

  ActivityDefinition buildDefinition() {
    if (name.text.trim().isEmpty) {
      throw const ValidationException('Escribe un nombre para la actividad.');
    }
    int? seconds;
    var restSeconds = 0;
    int? sets, cycleGoal;
    String? one, many;
    switch (rhythm) {
      case Rhythm.instant || Rhythm.free:
        break;
      case Rhythm.timed:
        final minutes = whole(duration, min: 1, max: 1440, what: 'La duración');
        if (minutes == null) {
          throw const ValidationException('Indica la duración en minutos.');
        }
        seconds = minutes * 60;
      case Rhythm.segments:
        final minutes = whole(duration, min: 1, max: 1440, what: 'La duración');
        seconds = minutes == null ? null : minutes * 60;
        restSeconds =
            whole(rest, min: 0, max: 1800, what: 'El descanso') ?? 90;
        sets = whole(segments, min: 1, max: 100, what: 'Los tramos previstos');
        cycleGoal = whole(cycles, min: 1, max: 100, what: 'Los ciclos previstos');
        one = singular.text.trim().isEmpty ? null : singular.text.trim();
        many = plural.text.trim().isEmpty ? null : plural.text.trim();
        if ((one == null) != (many == null)) {
          throw const ValidationException(
            'Indica singular y plural del tramo, o deja los dos vacíos.',
          );
        }
    }
    return ActivityDefinition(
      name: name.text,
      repeated: rhythm == Rhythm.segments,
      restSeconds: restSeconds,
      activitySeconds: seconds,
      targetSets: sets,
      targetCycles: cycleGoal,
      fields: fields,
      companionId: widget.companionId,
      segmentSingular: one,
      segmentPlural: many,
    );
  }

  void submit() {
    try {
      final definition = buildDefinition();
      Navigator.pop(
        context,
        ActivityBuilderResult(
          definition,
          instant: rhythm == Rhythm.instant,
          save: save,
        ),
      );
    } on ValidationException catch (e) {
      setState(() => error = e.message);
    }
  }

  Future<void> addField() async {
    final field = await showDialog<Map<String, Object>>(
      context: context,
      builder: (_) => const _FieldDialog(),
    );
    if (field == null) return;
    setState(() {
      final key = ActivityBuilder.fieldKeyFor(
        field['label'] as String,
        fields.map((f) => f['key'] as String).toList(),
      );
      fields.add({'key': key, ...field});
      error = null;
    });
  }

  Widget rhythmOption(Rhythm value, IconData icon, String title, String detail) {
    final selected = rhythm == value;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        key: Key('rhythm-${value.name}'),
        selected: selected,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(detail),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
        ),
        onTap: () => setState(() {
          rhythm = value;
          error = null;
        }),
      ),
    );
  }

  Widget numberField(String key, String label, {String? helper}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: Key(key),
      controller: key == 'builder-duration'
          ? duration
          : key == 'builder-rest'
          ? rest
          : key == 'builder-segments'
          ? segments
          : cycles,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, helperText: helper),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final instant = rhythm == Rhythm.instant;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva actividad')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
            key: const Key('builder-name'),
            controller: name,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          Text('Empezar desde una plantilla', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entry in _presets.entries)
                ActionChip(
                  key: Key('template-${entry.key}'),
                  label: Text(entry.value.$1),
                  onPressed: () => apply(entry.value.$2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('¿Cómo se mide?', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          rhythmOption(Rhythm.instant, Icons.touch_app_outlined, 'Puntual', 'Un registro sin cronómetro'),
          rhythmOption(Rhythm.free, Icons.play_arrow_outlined, 'Libre', 'Cronómetro, sin cuenta atrás'),
          rhythmOption(Rhythm.timed, Icons.hourglass_top, 'Con duración', 'Cuenta atrás de un tiempo fijo'),
          rhythmOption(Rhythm.segments, Icons.repeat, 'Por tramos', 'Varios tramos con descanso'),
          if (rhythm == Rhythm.timed || rhythm == Rhythm.segments)
            numberField('builder-duration', 'Duración (minutos)',
                helper: rhythm == Rhythm.segments ? 'Opcional: de cada tramo' : null),
          if (rhythm == Rhythm.segments) ...[
            numberField('builder-segments', 'Tramos previstos (opcional)'),
            numberField('builder-rest', 'Descanso entre tramos (segundos)',
                helper: '90 es un minuto y medio'),
            numberField('builder-cycles', 'Ciclos previstos (opcional)'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('builder-segment-singular'),
                    controller: singular,
                    maxLength: 24,
                    decoration: const InputDecoration(labelText: 'Un tramo se llama'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const Key('builder-segment-plural'),
                    controller: plural,
                    maxLength: 24,
                    decoration: const InputDecoration(labelText: 'Varios se llaman'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text('¿Qué quieres anotar? (opcional)', style: Theme.of(context).textTheme.labelLarge),
          for (final field in fields)
            Card(
              key: Key('field-${field['key']}'),
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                title: Text(field['label'] as String),
                subtitle: Text(
                  [
                    ActivityBuilder._typeLabels[field['type']] ?? '',
                    ActivityBuilder._aggregateLabels[field['aggregate']] ?? '',
                    if ((field['unit'] as String).isNotEmpty) field['unit'] as String,
                  ].where((t) => t.isNotEmpty).join(' · '),
                ),
                trailing: IconButton(
                  key: Key('field-remove-${field['key']}'),
                  tooltip: 'Quitar ${field['label']}',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => fields.remove(field)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('builder-add-field'),
              onPressed: fields.length >= 12 ? null : addField,
              icon: const Icon(Icons.add),
              label: Text(fields.length >= 12 ? 'Máximo 12 campos' : 'Añadir campo'),
            ),
          ),
          CheckboxListTile(
            key: const Key('builder-save'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Guardar en tus actividades'),
            subtitle: const Text('Para repetirla sin volver a crearla.'),
            value: save,
            onChanged: (value) => setState(() => save = value ?? true),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error!,
                key: const Key('builder-error'),
                style: TextStyle(color: scheme.error),
              ),
            ),
          FilledButton(
            key: const Key('builder-submit'),
            onPressed: submit,
            child: Text(instant ? 'Guardar' : 'Preparar actividad'),
          ),
        ],
      ),
    );
  }
}

class _FieldDialog extends StatefulWidget {
  const _FieldDialog();

  @override
  State<_FieldDialog> createState() => _FieldDialogState();
}

class _FieldDialogState extends State<_FieldDialog> {
  final label = TextEditingController();
  final unit = TextEditingController();
  final options = TextEditingController();
  final min = TextEditingController(text: '1');
  final max = TextEditingController(text: '5');
  final countOne = TextEditingController();
  final countMany = TextEditingController();
  String type = 'number';
  String aggregate = 'sum';
  String? error;

  @override
  void dispose() {
    for (final c in [label, unit, options, min, max, countOne, countMany]) {
      c.dispose();
    }
    super.dispose();
  }

  void submit() {
    try {
      final text = label.text.trim();
      if (text.isEmpty || text.length > 80) {
        throw const ValidationException('Escribe un nombre de campo de hasta 80 caracteres.');
      }
      final field = <String, Object>{
        'label': text,
        'unit': type == 'number' ? unit.text.trim() : '',
        'type': type,
        'aggregate': aggregate,
      };
      if (type == 'choice') {
        final list = options.text
            .split(',')
            .map((o) => o.trim())
            .where((o) => o.isNotEmpty)
            .toList();
        field['options'] = list;
      }
      if (type == 'scale') {
        final low = int.tryParse(min.text.trim());
        final high = int.tryParse(max.text.trim());
        if (low == null || high == null) {
          throw const ValidationException('Escribe el mínimo y el máximo de la escala.');
        }
        field['min'] = low;
        field['max'] = high;
      }
      if (countOne.text.trim().isNotEmpty) field['countSingular'] = countOne.text.trim();
      if (countMany.text.trim().isNotEmpty) field['countPlural'] = countMany.text.trim();
      // The domain checks every limit; reuse it instead of repeating the rules.
      ActivityDefinition(
        name: 'x',
        fields: [
          {'key': 'campo', ...field},
        ],
      );
      Navigator.pop(context, field);
    } on ValidationException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = aggregate == 'distinct' || aggregate == 'countTrue';
    return AlertDialog(
      title: const Text('Nuevo campo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('field-label'),
              controller: label,
              autofocus: true,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nombre del campo'),
            ),
            DropdownButtonFormField<String>(
              key: const Key('field-type'),
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final entry in ActivityBuilder._typeLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => setState(() {
                type = value ?? 'number';
                aggregate = ActivityBuilder.aggregatesFor(type).first;
              }),
            ),
            if (type == 'number')
              TextField(
                key: const Key('field-unit'),
                controller: unit,
                maxLength: 30,
                decoration: const InputDecoration(labelText: 'Unidad (opcional)'),
              ),
            if (type == 'choice')
              TextField(
                key: const Key('field-options'),
                controller: options,
                decoration: const InputDecoration(
                  labelText: 'Opciones',
                  helperText: 'Separadas por comas',
                ),
              ),
            if (type == 'scale')
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('field-min'),
                      controller: min,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Mínimo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('field-max'),
                      controller: max,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Máximo'),
                    ),
                  ),
                ],
              ),
            KeyedSubtree(
              key: ValueKey('aggregate-$type'),
              child: DropdownButtonFormField<String>(
                key: const Key('field-aggregate'),
                initialValue: aggregate,
                decoration: const InputDecoration(labelText: 'Cómo cuenta'),
                items: [
                  for (final a in ActivityBuilder.aggregatesFor(type))
                    DropdownMenuItem(
                      value: a,
                      child: Text(ActivityBuilder._aggregateLabels[a]!),
                    ),
                ],
                onChanged: (value) => setState(() => aggregate = value ?? aggregate),
              ),
            ),
            if (counts) ...[
              TextField(
                key: const Key('field-count-singular'),
                controller: countOne,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Se cuenta como (uno)', helperText: 'Opcional, p. ej. libro'),
              ),
              TextField(
                key: const Key('field-count-plural'),
                controller: countMany,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Se cuenta como (varios)', helperText: 'Opcional, p. ej. libros'),
              ),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error!,
                  key: const Key('field-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('field-submit'),
          onPressed: submit,
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}
