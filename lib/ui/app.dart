import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import '../application/workout_controller.dart';
import '../domain/workout.dart';

const lime = Color(0xFFD4F876);
const ink = Color(0xFF111716);
const panel = Color(0xFF1E2724);
const muted = Color(0xFFAEBBB4);

final gymTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ink,
  colorScheme: ColorScheme.fromSeed(
    seedColor: lime,
    brightness: Brightness.dark,
  ).copyWith(primary: lime, onPrimary: ink, surface: panel),
  appBarTheme: const AppBarTheme(
    backgroundColor: ink,
    surfaceTintColor: Colors.transparent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ink,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
);

class GymApp extends StatelessWidget {
  const GymApp({super.key, required this.controller});
  final WorkoutController controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GymIA',
    debugShowCheckedModeBanner: false,
    theme: gymTheme,
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: GymHome(controller: controller),
  );
}

class GymHome extends StatefulWidget {
  const GymHome({super.key, required this.controller});
  final WorkoutController controller;
  @override
  State<GymHome> createState() => _GymHomeState();
}

class _GymHomeState extends State<GymHome> {
  int tab = 0;
  String? selectedId;
  WorkoutController get c => widget.controller;

  Future<void> _start() async {
    final name = await showDialog<String>(
      context: context,
      builder:
          (_) => const NameDialog(
            title: 'Nuevo entrenamiento',
            label: 'Nombre de la sesión',
            initial: 'Entrenamiento',
            action: 'Empezar',
          ),
    );
    if (name == null || !mounted) return;
    final ok = await c.run(() async {
      await c.repository.start(name);
    });
    if (ok && mounted) setState(() => selectedId = c.active?.id);
  }

  Future<void> _addExercise(Workout workout) async {
    final name = await showDialog<String>(
      context: context,
      builder:
          (_) => const NameDialog(
            title: 'Añadir ejercicio',
            label: 'Nombre del ejercicio',
            action: 'Añadir',
            suggestions: true,
          ),
    );
    if (name != null) {
      await c.run(() => c.repository.addExercise(workout.id, name));
    }
  }

  Future<void> _set(Exercise exercise, [WorkoutSet? existing]) async {
    final result = await showDialog<SetInput>(
      context: context,
      builder:
          (_) =>
              SetDialog(existing: existing, previous: exercise.sets.lastOrNull),
    );
    if (result == null) return;
    await c.run(
      () =>
          existing == null
              ? c.repository.addSet(exercise.id, result.weight, result.reps)
              : c.repository.editSet(existing.id, result.weight, result.reps),
    );
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(action),
                ),
              ],
            ),
      ) ??
      false;

  Future<void> _finish(Workout workout) async {
    if (!await _confirm(
      '¿Finalizar entrenamiento?',
      '${workout.setCount} series registradas. Podrás consultar esta sesión en tu historial.',
      'Finalizar',
    )) {
      return;
    }
    final ok = await c.run(() => c.repository.finish(workout.id));
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrenamiento guardado en tu historial.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final selected = c.workouts.where((w) => w.id == selectedId).firstOrNull;
      return PopScope(
        canPop: selected == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) setState(() => selectedId = null);
        },
        child: Scaffold(
          appBar: AppBar(
            leading:
                selected == null
                    ? null
                    : IconButton(
                      tooltip: 'Volver',
                      onPressed: () => setState(() => selectedId = null),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
            title: Row(
              children: [
                if (selected == null) ...[
                  const Icon(
                    Icons.fitness_center_rounded,
                    color: lime,
                    size: 23,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  selected == null
                      ? 'gymia'
                      : selected.isActive
                      ? 'Tu sesión'
                      : 'Entrenamiento',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              if (selected == null)
                const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.offline_bolt_outlined, color: muted),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                if (c.busy) const LinearProgressIndicator(minHeight: 2),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Material(
                      color: const Color(0xFF482727),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(child: Text(c.error!)),
                            TextButton(
                              onPressed: c.busy ? null : c.refresh,
                              child: const Text('Recargar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child:
                      !c.loaded
                          ? Center(
                            child:
                                c.busy
                                    ? const CircularProgressIndicator()
                                    : FilledButton(
                                      onPressed: c.refresh,
                                      child: const Text('Cargar bitácora'),
                                    ),
                          )
                          : AbsorbPointer(
                            absorbing: c.busy,
                            child:
                                selected != null
                                    ? _detail(selected)
                                    : tab == 0
                                    ? _today()
                                    : _history(),
                          ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              selected == null
                  ? NavigationBar(
                    selectedIndex: tab,
                    onDestinationSelected:
                        (value) => setState(() => tab = value),
                    backgroundColor: ink,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.grid_view_rounded),
                        label: 'Hoy',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.history_rounded),
                        label: 'Historial',
                      ),
                    ],
                  )
                  : null,
        ),
      );
    },
  );

  Widget _today() {
    final active = c.active;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        Text(
          DateFormat(
            "EEEE, d 'de' MMMM",
            'es',
          ).format(DateTime.now()).toUpperCase(),
          style: const TextStyle(
            color: muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Tu esfuerzo.\nTu progreso.',
          style: TextStyle(
            fontSize: 38,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Una serie a la vez. Lleva el registro de lo que haces hoy.',
          style: TextStyle(color: muted, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: lime,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    active == null ? 'TU PRÓXIMA SESIÓN' : 'SESIÓN EN CURSO',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Icon(Icons.fitness_center_rounded, color: ink),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                active?.name ?? '¿Vamos a entrenar?',
                style: const TextStyle(
                  color: ink,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                active == null
                    ? 'Añade tus ejercicios y registra cada serie.'
                    : '${active.exercises.length} ejercicios · ${active.setCount} series guardadas',
                style: const TextStyle(color: Color(0xFF39452B), height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ink,
                    foregroundColor: lime,
                  ),
                  onPressed:
                      active == null
                          ? _start
                          : () => setState(() => selectedId = active.id),
                  icon: Icon(
                    active == null
                        ? Icons.add_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    active == null
                        ? 'Empezar entrenamiento'
                        : 'Continuar entrenamiento',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: '${c.history.length}',
                label: 'sesiones completas',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: '${c.history.fold<int>(0, (n, w) => n + w.setCount)}',
                label: 'series registradas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const SectionLabel('ÚLTIMA ACTIVIDAD'),
        const SizedBox(height: 12),
        if (c.history.isEmpty)
          const EmptyPanel(
            icon: Icons.show_chart_rounded,
            title: 'Aquí empieza tu historia',
            subtitle:
                'Tu primer entrenamiento aparecerá aquí cuando lo finalices.',
          )
        else
          _workoutTile(c.history.first),
        const SizedBox(height: 22),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 15, color: muted),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Guardado en este dispositivo · Sin conexión',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _history() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        'Tu recorrido',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Cada sesión cuenta.',
        style: TextStyle(color: muted, fontSize: 16),
      ),
      const SizedBox(height: 24),
      if (c.history.isEmpty)
        const EmptyPanel(
          icon: Icons.history_rounded,
          title: 'Todavía no hay sesiones',
          subtitle:
              'Finaliza un entrenamiento y consulta aquí todos sus ejercicios y series.',
        ),
      for (final w in c.history) ...[
        _workoutTile(w),
        const SizedBox(height: 12),
      ],
    ],
  );

  Widget _workoutTile(Workout w) => Material(
    color: panel,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => selectedId = w.id),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: lime),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d MMM yyyy · HH:mm', 'es').format(w.startedAt),
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${w.exercises.length} ejercicios · ${w.setCount} series',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    ),
  );

  Widget _detail(Workout w) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
    children: [
      Text(
        w.isActive ? 'EN CURSO' : 'COMPLETADO',
        style: const TextStyle(
          color: lime,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        w.name,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.8,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        DateFormat("d 'de' MMMM · HH:mm", 'es').format(w.startedAt),
        style: const TextStyle(color: muted),
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: StatTile(
              value: '${w.exercises.length}',
              label: 'ejercicios',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(value: '${w.setCount}', label: 'series guardadas'),
          ),
        ],
      ),
      const SizedBox(height: 28),
      const SectionLabel('EJERCICIOS'),
      const SizedBox(height: 12),
      if (w.exercises.isEmpty)
        const EmptyPanel(
          icon: Icons.fitness_center_rounded,
          title: 'Prepara tu primera serie',
          subtitle:
              'Añade un ejercicio para empezar a registrar peso y repeticiones.',
        ),
      for (var i = 0; i < w.exercises.length; i++) ...[
        _exerciseCard(w.exercises[i], i + 1, w.isActive),
        const SizedBox(height: 16),
      ],
      if (w.isActive) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addExercise(w),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Añadir ejercicio'),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: w.setCount == 0 ? null : () => _finish(w),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Finalizar entrenamiento'),
        ),
        const SizedBox(height: 8),
        Text(
          w.setCount == 0
              ? 'Registra al menos una serie para finalizar.'
              : 'Cada serie se guarda al pulsar Guardar.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () async {
            if (!await _confirm(
              '¿Descartar sesión?',
              'Se eliminarán esta sesión y todas sus series. Esta acción no se puede deshacer.',
              'Descartar',
            )) {
              return;
            }
            final ok = await c.run(() => c.repository.discard(w.id));
            if (ok && mounted) setState(() => selectedId = null);
          },
          child: const Text('Descartar sesión', style: TextStyle(color: muted)),
        ),
      ] else ...[
        const SizedBox(height: 8),
        const Text(
          'Sesión guardada. Buen trabajo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: lime, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed:
              () => setState(() {
                selectedId = null;
                tab = 1;
              }),
          child: const Text('Ver historial'),
        ),
      ],
    ],
  );

  Widget _exerciseCard(Exercise e, int number, bool editable) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              number.toString().padLeft(2, '0'),
              style: const TextStyle(color: lime, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                e.name,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (editable)
              IconButton(
                tooltip: 'Eliminar ejercicio ${e.name}',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: muted,
                ),
                onPressed: () async {
                  if (await _confirm(
                    '¿Eliminar ejercicio?',
                    'Se eliminará ${e.name} y sus ${e.sets.length} series.',
                    'Eliminar',
                  )) {
                    await c.run(() => c.repository.deleteExercise(e.id));
                  }
                },
              ),
          ],
        ),
        if (e.sets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Todavía no has registrado series.',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ),
        if (e.sets.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  'SERIE',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ),
              Expanded(
                child: Text('KG', style: TextStyle(color: muted, fontSize: 10)),
              ),
              Expanded(
                child: Text(
                  'REPS',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ),
              SizedBox(width: 48),
            ],
          ),
          for (var i = 0; i < e.sets.length; i++)
            Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text('${i + 1}', style: const TextStyle(color: muted)),
                ),
                Expanded(
                  child: Text(
                    formatWeight(e.sets[i].weight),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${e.sets[i].reps}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (editable)
                  PopupMenuButton<String>(
                    tooltip: 'Opciones de la serie ${i + 1}',
                    onSelected: (action) async {
                      if (action == 'edit') {
                        await _set(e, e.sets[i]);
                      } else if (await _confirm(
                        '¿Eliminar serie?',
                        '${formatWeight(e.sets[i].weight)} kg × ${e.sets[i].reps} repeticiones.',
                        'Eliminar',
                      )) {
                        await c.run(() => c.repository.deleteSet(e.sets[i].id));
                      }
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar serie'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar serie'),
                          ),
                        ],
                  )
                else
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.check_rounded, color: lime, size: 18),
                  ),
              ],
            ),
        ],
        if (editable) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _set(e),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Añadir serie'),
            ),
          ),
        ],
      ],
    ),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      color: muted,
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
      color: panel,
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
        Text(label, style: const TextStyle(color: muted, fontSize: 12)),
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
      border: Border.all(color: const Color(0xFF334039)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: muted, size: 30),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: muted, height: 1.5, fontSize: 14),
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
                  for (final name in ['Sentadilla', 'Press banca', 'Remo'])
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
        child: const Text('Cancelar'),
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
    text:
        widget.existing != null
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
    title: Text(widget.existing == null ? 'Nueva serie' : 'Editar serie'),
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
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                hintText: 'Ej. 20,5',
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
              decoration: const InputDecoration(
                labelText: 'Repeticiones',
                hintText: 'Ej. 10',
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
            const Text(
              'Usa 0 kg si entrenas sin carga externa.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: submit, child: const Text('Guardar')),
    ],
  );
}
