import 'package:flutter/material.dart';
import '../application/reminder_scheduler.dart';
import '../data/progress_repository.dart';
import '../domain/companion.dart';
import '../domain/progress.dart';
import '../domain/reminder.dart';
import '../domain/workout.dart';

/// «Modo y avisos» of one companion: reminder or game, and the habit reminder
/// itself (days, window, last call, tone and minimum). FR-026, FR-027.
class CompanionSettingsScreen extends StatefulWidget {
  const CompanionSettingsScreen({
    super.key,
    required this.progress,
    required this.companion,
    this.scheduler,
    this.clock,
  });

  final ProgressRepository progress;
  final Companion companion;

  /// Told to resend the snapshot to the phone after saving.
  final ReminderScheduler? scheduler;
  final DateTime Function()? clock;

  @override
  State<CompanionSettingsScreen> createState() =>
      _CompanionSettingsScreenState();
}

class _CompanionSettingsScreenState extends State<CompanionSettingsScreen> {
  static const dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const dayNames = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  bool loading = true;
  bool saving = false;
  String? error;
  CompanionSettings settings = const CompanionSettings(companionId: '');
  Reminder? stored;

  bool remind = false;
  int days = 127;
  int startMin = 20 * 60;
  int endMin = 22 * 60;
  bool useLastCall = false;
  int lastCallMin = 21 * 60 + 30;
  String tone = 'neutral';
  bool useMinimum = false;
  String minimumMetric = 'sessions';
  final minimumValue = TextEditingController(text: '1');

  // Goal (game mode)
  List<Map<String, dynamic>> goalFields = [];
  bool useGoal = false;
  String goalMetric = 'sessions';
  String goalPeriod = 'day';
  final goalTarget = TextEditingController(text: '1');
  final goalMinimum = TextEditingController();

  DateTime now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    minimumValue.dispose();
    goalTarget.dispose();
    goalMinimum.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final loaded = await widget.progress.settings(widget.companion.id);
      final reminder = await widget.progress.reminderFor(widget.companion.id);
      final goal = await widget.progress.activeGoal(widget.companion.id);
      final fields = await widget.progress.typedFields(widget.companion.id);
      if (!mounted) return;
      setState(() {
        settings = loaded;
        stored = reminder;
        goalFields = fields;
        if (goal != null) {
          useGoal = true;
          goalPeriod = goal.period;
          final metric = goal.metric;
          goalMetric = metric.source == 'field'
              ? 'field:${metric.field}'
              : metric.source;
          final divisor = metric.source == 'time' ? 60 : 1;
          goalTarget.text = _plain(goal.target / divisor);
          goalMinimum.text = goal.minimum == null
              ? ''
              : _plain(goal.minimum! / divisor);
        }
        if (reminder != null) {
          remind = reminder.enabled;
          days = reminder.days;
          startMin = reminder.windowStartMin;
          endMin = reminder.windowEndMin;
          useLastCall = reminder.lastCallMin != null;
          lastCallMin = reminder.lastCallMin ?? lastCallMin;
          tone = reminder.tone;
          final minimum = reminder.minimum;
          useMinimum = minimum != null;
          if (minimum != null) {
            minimumMetric = minimum['metric'] as String;
            minimumValue.text = '${(minimum['value'] as num).toInt()}';
          }
        }
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'No se pudieron cargar los ajustes.';
          loading = false;
        });
      }
    }
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  /// The goal the user described, or null when there is none. Time is typed in
  /// minutes and stored in seconds.
  GoalRule? buildGoal() {
    if (!settings.game || !settings.goalsEnabled || !useGoal) return null;
    final target = double.tryParse(goalTarget.text.trim().replaceAll(',', '.'));
    if (target == null || target <= 0) {
      throw const ValidationException(
        'El objetivo debe ser un número mayor que 0.',
      );
    }
    final minText = goalMinimum.text.trim();
    final minimum = minText.isEmpty
        ? null
        : double.tryParse(minText.replaceAll(',', '.'));
    if (minText.isNotEmpty && (minimum == null || minimum <= 0)) {
      throw const ValidationException(
        'El mínimo debe ser un número mayor que 0.',
      );
    }
    final factor = goalMetric == 'time' ? 60 : 1;
    final Metric metric;
    if (goalMetric.startsWith('field:')) {
      final key = goalMetric.substring(6);
      final field = goalFields.firstWhere((f) => f['key'] == key);
      metric = Metric(
        source: 'field',
        field: key,
        aggregate: field['aggregate'] as String,
        per: goalPeriod,
      );
    } else {
      metric = Metric(source: goalMetric, per: goalPeriod);
    }
    return GoalRule(
      metric: metric,
      period: goalPeriod,
      target: target * factor,
      minimum: minimum == null ? null : minimum * factor,
    );
  }

  static String clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  Future<int?> pickTime(int current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: 'Elige la hora',
    );
    return picked == null ? null : picked.hour * 60 + picked.minute;
  }

  Map<String, Object?>? get minimum {
    if (!remind || !useMinimum) return null;
    final value = int.tryParse(minimumValue.text.trim());
    if (value == null || value <= 0) {
      throw const ValidationException(
        'El mínimo debe ser un número mayor que 0.',
      );
    }
    return {'metric': minimumMetric, 'value': value};
  }

  Future<void> save() async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final id = widget.companion.id;
      final minimumValueToSave = minimum;
      final goal = buildGoal();
      await widget.progress.saveSettings(settings);
      // Leaving game mode keeps the goal for when the user comes back.
      if (settings.game) {
        if (settings.goalsEnabled && useGoal) {
          await widget.progress.saveGoal(id, goal!);
        } else {
          await widget.progress.clearGoal(id);
        }
      }
      if (remind) {
        await widget.progress.saveReminder(
          companionId: id,
          days: days,
          windowStartMin: startMin,
          windowEndMin: endMin,
          lastCallMin: useLastCall ? lastCallMin : null,
          tone: tone,
          minimum: minimumValueToSave,
        );
      } else if (stored != null) {
        await widget.progress.saveReminder(
          companionId: id,
          days: stored!.days,
          windowStartMin: stored!.windowStartMin,
          windowEndMin: stored!.windowEndMin,
          lastCallMin: stored!.lastCallMin,
          tone: stored!.tone,
          minimum: stored!.minimum,
          enabled: false,
        );
      }
      await widget.scheduler?.sync();
      if (mounted) Navigator.of(context).pop(true);
    } on ValidationException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'No se pudieron guardar los ajustes.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> resume() async {
    await widget.progress.setPaused(widget.companion.id, paused: false);
    await widget.scheduler?.sync();
    await load();
  }

  /// The two texts the user would get with the current choices.
  ({String start, String lastCall}) preview() {
    final today = now();
    final yesterday = today.subtract(const Duration(days: 1));
    final entry = ReminderEntry(
      id: 'preview',
      companionId: widget.companion.id,
      companionName: widget.companion.name,
      days: days,
      windowStartMin: startMin,
      windowEndMin: endMin,
      tone: tone,
      paused: false,
      lastDoneDate: reminderDay(yesterday),
      lastActivityDate: reminderDay(yesterday),
      streak: 3,
      minimumText: _previewMinimum(),
      weekId: isoWeekId(today),
      weekCount: 1,
      weekTarget: List.generate(
        7,
        (i) => days >> i & 1,
      ).fold<int>(0, (a, b) => a + b),
      templates: ReminderTemplates.defaults(
        tone: tone,
        companionId: widget.companion.id,
      ),
    );
    return (
      start: renderReminder(entry, ReminderKind.windowStart, today),
      lastCall: renderReminder(entry, ReminderKind.lastCall, today),
    );
  }

  String? _previewMinimum() {
    if (!useMinimum) return null;
    final value = int.tryParse(minimumValue.text.trim());
    if (value == null || value <= 0) return null;
    return ReminderScheduler.minimumText({
      'metric': minimumMetric,
      'value': value,
    });
  }

  Widget modeCard({
    required String mode,
    required IconData icon,
    required String title,
    required String detail,
  }) {
    final selected = settings.mode == mode;
    return Card(
      key: Key('mode-$mode'),
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Semantics(
        selected: selected,
        button: true,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(detail),
          trailing: selected ? const Icon(Icons.check_circle) : null,
          onTap: () => setState(() => settings = settings.copyWith(mode: mode)),
        ),
      ),
    );
  }

  Widget switchTile(
    String key,
    String title,
    bool value,
    void Function(bool) set,
  ) => SwitchListTile(
    key: Key(key),
    title: Text(title),
    value: value,
    onChanged: (v) => setState(() => set(v)),
  );

  Widget timeTile(
    String key,
    String label,
    int value,
    void Function(int) set,
  ) => ListTile(
    key: Key(key),
    title: Text(label),
    trailing: Text(
      clock(value),
      style: Theme.of(context).textTheme.titleMedium,
    ),
    onTap: () async {
      final picked = await pickTime(value);
      if (picked != null) setState(() => set(picked));
    },
  );

  List<Widget> goalEditor() => [
    switchTile('goal-enabled', 'Poner una meta', useGoal, (v) => useGoal = v),
    if (useGoal) ...[
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              key: const Key('goal-metric'),
              initialValue: goalMetric,
              decoration: const InputDecoration(labelText: 'Qué medir'),
              items: [
                const DropdownMenuItem(
                  value: 'time',
                  child: Text('Tiempo (minutos)'),
                ),
                const DropdownMenuItem(
                  value: 'sessions',
                  child: Text('Sesiones'),
                ),
                for (final f in goalFields)
                  DropdownMenuItem(
                    value: 'field:${f['key']}',
                    child: Text('${f['label']}'),
                  ),
              ],
              onChanged: (v) => setState(() => goalMetric = v!),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            key: const Key('goal-period'),
            value: goalPeriod,
            items: const [
              DropdownMenuItem(value: 'day', child: Text('al día')),
              DropdownMenuItem(value: 'week', child: Text('a la semana')),
            ],
            onChanged: (v) => setState(() => goalPeriod = v!),
          ),
        ],
      ),
      TextField(
        key: const Key('goal-target'),
        controller: goalTarget,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Objetivo'),
      ),
      TextField(
        key: const Key('goal-minimum'),
        controller: goalMinimum,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Mínimo para mantener la racha (opcional)',
        ),
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final paused = stored?.paused ?? false;
    return Scaffold(
      appBar: AppBar(title: Text('Modo y avisos · ${widget.companion.name}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Modo', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                modeCard(
                  mode: 'reminder',
                  icon: Icons.notifications_active_outlined,
                  title: 'Recordatorio',
                  detail: 'Solo te avisa a la hora que elijas.',
                ),
                modeCard(
                  mode: 'game',
                  icon: Icons.emoji_events_outlined,
                  title: 'Juego',
                  detail: 'Metas, rachas y logros, además de los avisos.',
                ),
                if (settings.game) ...[
                  switchTile(
                    'game-goals',
                    'Metas',
                    settings.goalsEnabled,
                    (v) => settings = settings.copyWith(goalsEnabled: v),
                  ),
                  switchTile(
                    'game-streaks',
                    'Rachas',
                    settings.streaksEnabled,
                    (v) => settings = settings.copyWith(streaksEnabled: v),
                  ),
                  switchTile(
                    'game-achievements',
                    'Logros',
                    settings.achievementsEnabled,
                    (v) => settings = settings.copyWith(achievementsEnabled: v),
                  ),
                  switchTile(
                    'game-cheers',
                    'Mensajes de ánimo',
                    settings.cheersEnabled,
                    (v) => settings = settings.copyWith(cheersEnabled: v),
                  ),
                  if (settings.goalsEnabled) ...goalEditor(),
                  ListTile(
                    title: const Text('Días libres por semana'),
                    subtitle: const Text('No rompen la racha.'),
                    trailing: DropdownButton<int>(
                      key: const Key('free-days'),
                      value: settings.freeDaysPerWeek,
                      items: [
                        for (var n = 0; n <= 3; n++)
                          DropdownMenuItem(value: n, child: Text('$n')),
                      ],
                      onChanged: (v) => setState(
                        () => settings = settings.copyWith(freeDaysPerWeek: v),
                      ),
                    ),
                  ),
                ],
                const Divider(height: 32),
                Text(
                  'Aviso diario',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (paused)
                  Card(
                    key: const Key('reminder-paused'),
                    child: ListTile(
                      leading: const Icon(Icons.pause_circle_outline),
                      title: const Text('Recordatorios en pausa'),
                      subtitle: const Text(
                        'Pasaron 7 días programados sin registrar nada.',
                      ),
                      trailing: TextButton(
                        key: const Key('resume-reminder'),
                        onPressed: resume,
                        child: const Text('Reanudar'),
                      ),
                    ),
                  ),
                switchTile(
                  'remind-enabled',
                  'Recordarme esta actividad',
                  remind,
                  (v) => remind = v,
                ),
                if (remind) ...[
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Semantics(
                          label: dayNames[i],
                          child: FilterChip(
                            key: Key('day-$i'),
                            label: Text(dayLetters[i]),
                            selected: days >> i & 1 == 1,
                            onSelected: (on) => setState(
                              () => days = on
                                  ? days | (1 << i)
                                  : days & ~(1 << i),
                            ),
                          ),
                        ),
                    ],
                  ),
                  timeTile(
                    'window-start',
                    'Desde',
                    startMin,
                    (v) => startMin = v,
                  ),
                  timeTile('window-end', 'Hasta', endMin, (v) => endMin = v),
                  switchTile(
                    'last-call-enabled',
                    'Última llamada',
                    useLastCall,
                    (v) => useLastCall = v,
                  ),
                  if (useLastCall)
                    timeTile(
                      'last-call',
                      'Hora de la última llamada',
                      lastCallMin,
                      (v) => lastCallMin = v,
                    ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    key: const Key('tone'),
                    segments: const [
                      ButtonSegment(value: 'neutral', label: Text('Neutro')),
                      ButtonSegment(value: 'cheer', label: Text('Motivador')),
                    ],
                    selected: {tone},
                    onSelectionChanged: (v) => setState(() => tone = v.first),
                  ),
                  switchTile(
                    'minimum-enabled',
                    'Mínimo para ese día',
                    useMinimum,
                    (v) => useMinimum = v,
                  ),
                  if (useMinimum)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('minimum-value'),
                            controller: minimumValue,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          key: const Key('minimum-metric'),
                          value: minimumMetric == 'time' ? 'time' : 'sessions',
                          items: const [
                            DropdownMenuItem(
                              value: 'sessions',
                              child: Text('sesiones'),
                            ),
                            DropdownMenuItem(
                              value: 'time',
                              child: Text('minutos'),
                            ),
                          ],
                          onChanged: (v) => setState(() => minimumMetric = v!),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('reminder-preview'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Así se verá',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preview().start,
                            key: const Key('preview-start'),
                          ),
                          if (useLastCall) ...[
                            const SizedBox(height: 6),
                            Text(
                              preview().lastCall,
                              key: const Key('preview-last-call'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      key: const Key('settings-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('save-settings'),
                  onPressed: saving ? null : save,
                  child: const Text('Guardar'),
                ),
              ],
            ),
    );
  }
}
