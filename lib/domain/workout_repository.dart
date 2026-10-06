import 'workout.dart';

abstract interface class WorkoutRepository {
  Future<List<Workout>> load();
  Future<String> start(String name);
  Future<void> addExercise(String workoutId, String name);
  Future<void> addSet(String exerciseId, String weight, String reps);
  Future<void> editSet(String setId, String weight, String reps);
  Future<void> deleteSet(String setId);
  Future<void> deleteExercise(String exerciseId);
  Future<void> finish(String workoutId);
  Future<void> discard(String workoutId);
  Future<void> close();
}
