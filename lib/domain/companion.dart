import 'package:uuid/uuid.dart';
import 'reminder.dart';
import 'space.dart';
import 'workout.dart';

class Companion {
  Companion({
    required String id,
    required String name,
    required String description,
    required String prompt,
    String? icon,
    String? color,
    ReminderTemplates? reminderCopy,
  }) : id = validTrackiaId(id),
       name = validName(name),
       description = description.trim(),
       prompt = prompt.trim(),
       icon = _validChoice(icon ?? _defaultIcon(id), iconIds, 'icono'),
       color = _validChoice(color ?? _defaultColor(id), colorIds, 'color'),
       reminderCopy = _validCopy(reminderCopy) {
    if (this.prompt.length > 8000) {
      throw const FormatException(
        'Las instrucciones no pueden superar los 8000 caracteres.',
      );
    }
  }

  /// Instructions used when the companion has none (data-model §2, FR-016).
  static const neutralPrompt =
      'Acompaña al usuario con un tono cercano y claro. Ayúdale a registrar lo que hace sin inventar datos.';

  /// IDs from specs/004-trackia-experience/contracts/visual-tokens.md.
  static const iconIds = {
    'barbell',
    'hourglass',
    'leaf',
    'notebook',
    'sparkles',
    'book',
    'water',
    'run',
    'bike',
    'ball',
    'music',
    'brush',
    'work',
    'pill',
    'heart',
    'school',
  };
  static const colorIds = {
    'teal',
    'orange',
    'green',
    'amber',
    'crimson',
    'violet',
  };

  static const _suggestedIcons = {
    'gymbro': 'barbell',
    'enfoque': 'hourglass',
    'calma': 'leaf',
    'diario': 'notebook',
  };
  static const _suggestedColors = {
    'gymbro': 'orange',
    'enfoque': 'teal',
    'calma': 'green',
    'diario': 'amber',
  };
  static String _defaultIcon(String id) => _suggestedIcons[id] ?? 'sparkles';
  static String _defaultColor(String id) => _suggestedColors[id] ?? 'teal';
  static String _validChoice(String value, Set<String> allowed, String what) {
    if (!allowed.contains(value)) {
      throw FormatException('El $what elegido no es válido.');
    }
    return value;
  }

  final String id;
  final String name;
  final String description;
  final String prompt;
  final String icon;
  final String color;

  /// Reminder texts of this companion; each list that is given replaces the
  /// default one (`trackia-reminder-copy`). Null when it has none.
  final ReminderTemplates? reminderCopy;

  static ReminderTemplates? _validCopy(ReminderTemplates? copy) {
    if (copy == null) return null;
    final all = [...copy.windowStart, ...copy.lastCall, ...copy.inactive];
    if (all.isEmpty) return null;
    if (copy.windowStart.length > 5 ||
        copy.lastCall.length > 5 ||
        copy.inactive.length > 5 ||
        all.any((t) => t.trim().isEmpty || t.length > 140)) {
      throw const FormatException('Los textos de recordatorio no son válidos.');
    }
    return copy;
  }

  Companion copyWith({
    String? name,
    String? description,
    String? prompt,
    String? icon,
    String? color,
    Object? reminderCopy = _keep,
  }) => Companion(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    prompt: prompt ?? this.prompt,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    reminderCopy: identical(reminderCopy, _keep)
        ? this.reminderCopy
        : reminderCopy as ReminderTemplates?,
  );

  static const _keep = Object();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'prompt': prompt,
    'icon': icon,
    'color': color,
    if (reminderCopy != null) 'reminderCopy': reminderCopy!.toJson(),
  };

  factory Companion.fromJson(Map<String, dynamic> json) => Companion(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    prompt: json['prompt'] as String,
    icon: json['icon'] as String?,
    color: json['color'] as String?,
    reminderCopy: json['reminderCopy'] is Map
        ? ReminderTemplates.fromJson(
            Map<String, dynamic>.from(json['reminderCopy'] as Map),
          )
        : null,
  );

  static Companion custom({required String name, required String prompt}) =>
      Companion(
        id: const Uuid().v4(),
        name: name,
        description: '',
        prompt: prompt,
      );

  static List<Companion> get suggestions => [
    Companion(
      id: 'gymbro',
      name: 'GymBro',
      description: 'Entrenamiento, series y progreso',
      prompt:
          'Acompáñame en el gimnasio con un tono cercano y directo. Ayúdame a preparar ejercicios, registrar resultados y comparar el progreso sin inventar datos. Respeta mis límites y pregunta cuando falten detalles.',
    ),
    Companion(
      id: 'enfoque',
      name: 'Enfoque',
      description: 'Pomodoro, tareas y descansos',
      prompt:
          'Ayúdame a concentrarme. Divide el trabajo en pasos pequeños, propón periodos de actividad y descanso, y celebra avances concretos sin interrumpir demasiado. Pregunta qué tarea quiero abordar.',
    ),
    Companion(
      id: 'calma',
      name: 'Calma',
      description: 'Meditación y bienestar',
      prompt:
          'Guíame con un tono sereno y sencillo. Ofrece ejercicios breves de respiración o atención plena cuando los pida. Adapta la duración a mi tiempo y evita afirmar resultados que no haya comunicado.',
    ),
    Companion(
      id: 'diario',
      name: 'Diario',
      description: 'Hábitos, ideas y seguimiento diario',
      prompt:
          'Ayúdame a registrar y revisar mis hábitos, ideas y objetivos cotidianos. Haz preguntas claras, resume lo que realmente he hecho y sugiere próximos pasos prácticos sin asumir que ya los completé.',
    ),
  ];
}
