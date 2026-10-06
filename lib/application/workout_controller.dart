import 'package:flutter/foundation.dart';
import '../domain/workout.dart';
import '../domain/workout_repository.dart';

class WorkoutController extends ChangeNotifier {
  WorkoutController(this.repository);
  final WorkoutRepository repository;
  List<Workout> workouts = [];
  bool busy = false;
  bool loaded = false;
  String? error;
  Workout? get active => workouts.where((w) => w.isActive).firstOrNull;
  List<Workout> get history => workouts.where((w) => !w.isActive).toList();

  Future<bool> run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    var ok = false;
    try {
      await action();
      workouts = await repository.load();
      loaded = true;
      ok = true;
    } on ValidationException catch (e) {
      error = e.message;
    } catch (e, stack) {
      debugPrint('Storage error: $e\n$stack');
      error = 'No se pudo completar la operación. Inténtalo de nuevo.';
    } finally {
      busy = false;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> refresh() => run(() async {});
}
