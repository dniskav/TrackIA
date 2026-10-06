import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../domain/workout.dart';
import '../domain/workout_repository.dart';

class SqliteWorkoutRepository implements WorkoutRepository {
  SqliteWorkoutRepository._(this._db);
  final Database _db;
  static const _uuid = Uuid();

  static Future<SqliteWorkoutRepository> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'gymia.sqlite');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''CREATE TABLE workouts (
          id TEXT PRIMARY KEY, name TEXT NOT NULL,
          started_at INTEGER NOT NULL, finished_at INTEGER,
          active_slot INTEGER UNIQUE DEFAULT 1,
          CHECK ((finished_at IS NULL AND active_slot IS 1)
            OR (finished_at IS NOT NULL AND active_slot IS NULL)))''');
          await db.execute('''CREATE TABLE exercises (
          id TEXT PRIMARY KEY, workout_id TEXT NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
          name TEXT NOT NULL, position INTEGER NOT NULL)''');
          await db.execute(
            'CREATE INDEX exercises_workout ON exercises(workout_id)',
          );
          await db.execute(
            '''CREATE TABLE sets (
          id TEXT PRIMARY KEY, exercise_id TEXT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
          weight INTEGER NOT NULL CHECK(weight BETWEEN 0 AND 999999),
          reps INTEGER NOT NULL CHECK(reps BETWEEN 1 AND 999), position INTEGER NOT NULL)''',
          );
          await db.execute('CREATE INDEX sets_exercise ON sets(exercise_id)');
        },
      ),
    );
    return SqliteWorkoutRepository._(db);
  }

  @override
  Future<List<Workout>> load() => _db.transaction((tx) async {
    final workouts = await tx.query(
      'workouts',
      orderBy: 'started_at DESC, rowid DESC',
    );
    final exercises = await tx.query('exercises', orderBy: 'position ASC');
    final sets = await tx.query('sets', orderBy: 'position ASC');
    return workouts
        .map(
          (w) => Workout(
            id: w['id'] as String,
            name: w['name'] as String,
            startedAt: DateTime.fromMillisecondsSinceEpoch(
              w['started_at'] as int,
            ),
            finishedAt:
                w['finished_at'] == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                      w['finished_at'] as int,
                    ),
            exercises:
                exercises
                    .where((e) => e['workout_id'] == w['id'])
                    .map(
                      (e) => Exercise(
                        id: e['id'] as String,
                        name: e['name'] as String,
                        sets:
                            sets
                                .where((s) => s['exercise_id'] == e['id'])
                                .map(
                                  (s) => WorkoutSet(
                                    id: s['id'] as String,
                                    weight: s['weight'] as int,
                                    reps: s['reps'] as int,
                                  ),
                                )
                                .toList(),
                      ),
                    )
                    .toList(),
          ),
        )
        .toList();
  });

  Future<void> _requireActive(Transaction tx, String workoutId) async {
    final rows = await tx.query(
      'workouts',
      where: 'id = ? AND finished_at IS NULL',
      whereArgs: [workoutId],
    );
    if (rows.isEmpty) {
      throw const ValidationException('Esta sesión ya no está activa.');
    }
  }

  Future<void> _requireExercise(Transaction tx, String exerciseId) async {
    final rows = await tx.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
    if (rows.isEmpty) {
      throw const ValidationException('No se encuentra el ejercicio.');
    }
    await _requireActive(tx, rows.first['workout_id'] as String);
  }

  Future<void> _requireSet(Transaction tx, String setId) async {
    final rows = await tx.query('sets', where: 'id = ?', whereArgs: [setId]);
    if (rows.isEmpty) {
      throw const ValidationException('No se encuentra la serie.');
    }
    await _requireExercise(tx, rows.first['exercise_id'] as String);
  }

  Future<int> _nextPosition(
    Transaction tx,
    String table,
    String parent,
    String id,
  ) async {
    final rows = await tx.rawQuery(
      'SELECT COALESCE(MAX(position), -1) + 1 AS next FROM $table WHERE $parent = ?',
      [id],
    );
    return rows.first['next'] as int;
  }

  @override
  Future<String> start(String name) async {
    final clean = validName(name);
    return _db.transaction((tx) async {
      final active = await tx.query('workouts', where: 'finished_at IS NULL');
      if (active.isNotEmpty) {
        throw const ValidationException(
          'Ya tienes una sesión en curso. Continúala primero.',
        );
      }
      final id = _uuid.v4();
      await tx.insert('workouts', {
        'id': id,
        'name': clean,
        'started_at': DateTime.now().millisecondsSinceEpoch,
      });
      return id;
    });
  }

  @override
  Future<void> addExercise(String workoutId, String name) async {
    final clean = validName(name);
    await _db.transaction((tx) async {
      await _requireActive(tx, workoutId);
      await tx.insert('exercises', {
        'id': _uuid.v4(),
        'workout_id': workoutId,
        'name': clean,
        'position': await _nextPosition(
          tx,
          'exercises',
          'workout_id',
          workoutId,
        ),
      });
    });
  }

  @override
  Future<void> addSet(String exerciseId, String weight, String reps) async {
    final w = parseWeight(weight);
    final r = parseReps(reps);
    await _db.transaction((tx) async {
      await _requireExercise(tx, exerciseId);
      await tx.insert('sets', {
        'id': _uuid.v4(),
        'exercise_id': exerciseId,
        'weight': w,
        'reps': r,
        'position': await _nextPosition(tx, 'sets', 'exercise_id', exerciseId),
      });
    });
  }

  @override
  Future<void> editSet(String setId, String weight, String reps) async {
    final w = parseWeight(weight);
    final r = parseReps(reps);
    await _db.transaction((tx) async {
      await _requireSet(tx, setId);
      await tx.update(
        'sets',
        {'weight': w, 'reps': r},
        where: 'id = ?',
        whereArgs: [setId],
      );
    });
  }

  @override
  Future<void> deleteSet(String setId) => _db.transaction((tx) async {
    await _requireSet(tx, setId);
    await tx.delete('sets', where: 'id = ?', whereArgs: [setId]);
  });

  @override
  Future<void> deleteExercise(String exerciseId) => _db.transaction((tx) async {
    await _requireExercise(tx, exerciseId);
    await tx.delete('exercises', where: 'id = ?', whereArgs: [exerciseId]);
  });

  @override
  Future<void> finish(String workoutId) => _db.transaction((tx) async {
    await _requireActive(tx, workoutId);
    final count = Sqflite.firstIntValue(
      await tx.rawQuery(
        'SELECT COUNT(*) FROM sets s JOIN exercises e ON e.id = s.exercise_id WHERE e.workout_id = ?',
        [workoutId],
      ),
    );
    if (count == 0) {
      throw const ValidationException(
        'Registra al menos una serie antes de finalizar.',
      );
    }
    await tx.update(
      'workouts',
      {
        'finished_at': DateTime.now().millisecondsSinceEpoch,
        'active_slot': null,
      },
      where: 'id = ?',
      whereArgs: [workoutId],
    );
  });

  @override
  Future<void> discard(String workoutId) => _db.transaction((tx) async {
    await _requireActive(tx, workoutId);
    await tx.delete('workouts', where: 'id = ?', whereArgs: [workoutId]);
  });

  @override
  Future<void> close() => _db.close();
}
