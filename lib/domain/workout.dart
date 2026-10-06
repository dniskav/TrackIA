class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

String validName(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value.length > 80) {
    throw const ValidationException(
      'Escribe un nombre de entre 1 y 80 caracteres.',
    );
  }
  return value;
}

// Store hundredths of a kg as an integer, avoiding floating-point drift.
int parseWeight(String raw) {
  final value = raw.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,4}(\.\d{1,2})?$').hasMatch(value)) {
    throw const ValidationException(
      'Usa un peso de 0 a 9999,99 kg, con hasta 2 decimales.',
    );
  }
  final parts = value.split('.');
  return int.parse(parts.first) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}

int parseReps(String raw) {
  final value = raw.trim();
  final reps = int.tryParse(value);
  if (!RegExp(r'^\d{1,3}$').hasMatch(value) || reps == null || reps < 1) {
    throw const ValidationException('Introduce entre 1 y 999 repeticiones.');
  }
  return reps;
}

String formatWeight(int hundredths) {
  final whole = hundredths ~/ 100;
  final decimal = hundredths % 100;
  return decimal == 0
      ? '$whole'
      : '$whole,${decimal.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '')}';
}

class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.weight,
    required this.reps,
  });
  final String id;
  final int weight;
  final int reps;
}

class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required List<WorkoutSet> sets,
  }) : sets = List.unmodifiable(sets);
  final String id;
  final String name;
  final List<WorkoutSet> sets;
}

class Workout {
  Workout({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.finishedAt,
    required List<Exercise> exercises,
  }) : exercises = List.unmodifiable(exercises);
  final String id;
  final String name;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<Exercise> exercises;
  bool get isActive => finishedAt == null;
  int get setCount => exercises.fold(0, (n, e) => n + e.sets.length);
  int get repCount =>
      exercises.fold(0, (n, e) => n + e.sets.fold(0, (s, r) => s + r.reps));
}
