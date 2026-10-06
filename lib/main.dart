import 'package:flutter/material.dart';
import 'data/sqlite_workout_repository.dart';
import 'application/workout_controller.dart';
import 'ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<WorkoutController> future = _open();
  Future<WorkoutController> _open() async {
    final repository = await SqliteWorkoutRepository.open();
    final controller = WorkoutController(repository);
    await controller.refresh();
    return controller;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WorkoutController>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasData) return GymApp(controller: snapshot.data!);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: gymTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child:
                  snapshot.hasError
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storage_rounded, size: 40),
                          const SizedBox(height: 16),
                          const Text(
                            'No se pudo abrir tu bitácora. Tus datos no se han borrado.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => setState(() => future = _open()),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      )
                      : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}
