import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../application/ai_availability.dart';
import '../application/assistant_context.dart';
import '../application/companion_creation.dart';
import '../data/activity_template_repository.dart';
import '../data/ai_client.dart';
import '../data/ai_settings_store.dart';
import '../data/companion_store.dart';
import '../data/progress_repository.dart';
import '../domain/assistant_blocks.dart';
import '../domain/block_names.dart' show fenceOpen;
import '../domain/companion.dart';
import '../domain/reminder.dart';
import '../domain/workout.dart';
import 'chat_message.dart';
import 'companion_style.dart';
import 'rule_text.dart';

/// «Crear acompañante»: by hand, or with the AI's help when a provider is
/// verified (FR-037). Pops with the created [Companion], or null.
class CompanionCreatorScreen extends StatefulWidget {
  const CompanionCreatorScreen({
    super.key,
    required this.store,
    required this.progress,
    required this.availability,
    required this.aiStore,
    this.templates,
    this.client,
    this.onOpenAiSettings,
  });

  final CompanionStore store;
  final ProgressRepository progress;
  final ActivityTemplateRepository? templates;
  final AiAvailability availability;
  final AiSettingsStore aiStore;
  final AiClient? client;

  /// Where to send the user when no AI is connected.
  final VoidCallback? onOpenAiSettings;

  @override
  State<CompanionCreatorScreen> createState() => _CompanionCreatorScreenState();
}

class _CompanionCreatorScreenState extends State<CompanionCreatorScreen> {
  String? error;
  bool busy = false;

  late final creation = CompanionCreation(
    store: widget.store,
    progress: widget.progress,
    templates: widget.templates,
  );

  Future<void> manual() async {
    final draft = await Navigator.of(context).push<CompanionDraft>(
      MaterialPageRoute(
        builder: (_) => const CompanionBuilderScreen(submitLabel: 'Crear'),
      ),
    );
    if (draft == null || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final created = await creation.create(draft);
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is ValidationException
              ? e.message
              : 'No se pudo crear el acompañante. No se guardó nada.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> assisted() async {
    final created = await Navigator.of(context).push<Companion>(
      MaterialPageRoute(
        builder: (_) => CompanionAssistedScreen(
          creation: creation,
          aiStore: widget.aiStore,
          client: widget.client,
        ),
      ),
    );
    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.availability,
    builder: (context, _) => _chooser(context, widget.availability.ready),
  );

  Widget _chooser(BuildContext context, bool ready) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear acompañante')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            key: const Key('creator-ai'),
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Con ayuda de la IA'),
              subtitle: Text(
                ready
                    ? 'Cuéntale qué quieres seguir y te propone un acompañante.'
                    : 'Necesitas conectar y verificar un proveedor de IA.',
              ),
              enabled: ready && !busy,
              onTap: ready && !busy ? assisted : null,
            ),
          ),
          if (!ready)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('creator-open-ai-settings'),
                onPressed: widget.onOpenAiSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Abrir Ajustes de IA'),
              ),
            ),
          Card(
            key: const Key('creator-manual'),
            child: ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('A mano'),
              subtitle: const Text(
                'Elige nombre, icono, color, modo y aviso tú mismo.',
              ),
              enabled: !busy,
              onTap: busy ? null : manual,
            ),
          ),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error!,
                key: const Key('creator-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

/// The form of a companion: name, icon, colour, level and reminder. Pops with
/// the [CompanionDraft]. The activity and goal an AI proposed are kept and can
/// be removed here.
class CompanionBuilderScreen extends StatefulWidget {
  const CompanionBuilderScreen({
    super.key,
    this.initial,
    this.submitLabel = 'Listo',
  });

  final CompanionDraft? initial;
  final String submitLabel;

  @override
  State<CompanionBuilderScreen> createState() => _CompanionBuilderScreenState();
}

class _CompanionBuilderScreenState extends State<CompanionBuilderScreen> {
  static const _dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  late final name = TextEditingController(text: widget.initial?.name ?? '');
  late final description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late final prompt = TextEditingController(text: widget.initial?.prompt ?? '');
  late String icon = widget.initial?.icon ?? 'sparkles';
  late String color = widget.initial?.color ?? 'teal';
  late String mode = widget.initial?.mode ?? 'reminder';
  late bool remind = widget.initial?.reminder != null;
  late int days = widget.initial?.reminder?.days ?? 127;
  late int start = widget.initial?.reminder?.startMin ?? 20 * 60;
  late int end = widget.initial?.reminder?.endMin ?? 22 * 60;
  late int? lastCall = widget.initial?.reminder?.lastCallMin;
  late String tone = widget.initial?.reminder?.tone ?? 'neutral';
  late var activity = widget.initial?.activity;
  late var goal = widget.initial?.goal;
  String? error;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    prompt.dispose();
    super.dispose();
  }

  Future<void> pick(int current, void Function(int) set) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: 'Elige la hora',
    );
    if (picked != null) setState(() => set(picked.hour * 60 + picked.minute));
  }

  void submit() {
    try {
      final clean = name.text.trim();
      if (clean.isEmpty || clean.length > 40) {
        throw const ValidationException(
          'Escribe un nombre de entre 1 y 40 caracteres.',
        );
      }
      ReminderProposal? reminder;
      if (remind) {
        final last = lastCall != null && lastCall! > start && lastCall! < end
            ? lastCall
            : null;
        // The reminder's own validation of days, window and last call.
        Reminder(
          id: 'builder',
          companionId: 'builder',
          days: days,
          windowStartMin: start,
          windowEndMin: end,
          lastCallMin: last,
          tone: tone,
        );
        final proposal = ReminderProposal(
          days: days,
          startMin: start,
          endMin: end,
          lastCallMin: last,
          tone: tone,
        );
        reminder = proposal;
      }
      Navigator.of(context).pop(
        CompanionDraft(
          name: clean,
          description: description.text.trim(),
          prompt: prompt.text.trim(),
          icon: icon,
          color: color,
          mode: mode,
          activity: activity,
          instant: widget.initial?.instant ?? false,
          goal: goal,
          reminder: reminder,
          origin: widget.initial?.origin ?? 'user',
        ),
      );
    } on ValidationException catch (e) {
      setState(() => error = e.message);
    }
  }

  Widget level(String value, String title, String detail) =>
      RadioListTile<String>(
        key: Key('level-$value'),
        value: value,
        title: Text(title),
        subtitle: Text(detail),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.initial == null ? 'Nuevo acompañante' : 'Editar propuesta',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          key: const Key('builder-name'),
          controller: name,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        TextField(
          key: const Key('builder-description'),
          controller: description,
          maxLength: 80,
          decoration: const InputDecoration(labelText: '¿Para qué sirve?'),
        ),
        TextField(
          key: const Key('builder-prompt'),
          controller: prompt,
          maxLines: 4,
          maxLength: 4000,
          decoration: const InputDecoration(
            labelText: 'Instrucciones para la IA (opcional)',
            helperText: 'Se usan cuando conectes un proveedor.',
          ),
        ),
        const SizedBox(height: 8),
        Text('Icono', style: Theme.of(context).textTheme.labelLarge),
        Wrap(
          spacing: 4,
          children: [
            for (final e in companionIcons.entries)
              IconButton(
                key: Key('builder-icon-${e.key}'),
                tooltip: e.key,
                isSelected: icon == e.key,
                icon: Icon(e.value),
                selectedIcon: Icon(
                  e.value,
                  color: companionColor(context, color),
                ),
                onPressed: () => setState(() => icon = e.key),
              ),
          ],
        ),
        Text('Color', style: Theme.of(context).textTheme.labelLarge),
        Wrap(
          spacing: 4,
          children: [
            for (final id in Companion.colorIds)
              IconButton(
                key: Key('builder-color-$id'),
                tooltip: id,
                isSelected: color == id,
                icon: Icon(Icons.circle, color: companionColor(context, id)),
                selectedIcon: Icon(
                  Icons.check_circle,
                  color: companionColor(context, id),
                ),
                onPressed: () => setState(() => color = id),
              ),
          ],
        ),
        const Divider(height: 24),
        Text('Nivel', style: Theme.of(context).textTheme.titleSmall),
        RadioGroup<String>(
          groupValue: mode,
          onChanged: (v) => setState(() => mode = v!),
          child: Column(
            children: [
              level('reminder', 'Solo recordatorio', 'Te avisa y ya.'),
              level(
                'goals',
                'Metas y rachas',
                'Recomendado: metas y rachas, sin logros.',
              ),
              level('game', 'Juego completo', 'Metas, rachas y logros.'),
            ],
          ),
        ),
        if (activity != null)
          ListTile(
            key: const Key('builder-activity'),
            leading: const Icon(Icons.edit_note),
            title: Text('Qué anotas: ${activity!.name}'),
            subtitle: Text(activity!.fields.map((f) => f['label']).join(', ')),
            trailing: IconButton(
              key: const Key('builder-remove-activity'),
              tooltip: 'Quitar actividad',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => activity = null),
            ),
          ),
        if (goal != null)
          ListTile(
            key: const Key('builder-goal'),
            leading: const Icon(Icons.flag_outlined),
            title: Text(
              'Meta: ${goalText(goal!, {for (final f in activity?.fields ?? const []) '${f['key']}': '${f['label']}'})}',
            ),
            trailing: IconButton(
              key: const Key('builder-remove-goal'),
              tooltip: 'Quitar meta',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => goal = null),
            ),
          ),
        const Divider(height: 24),
        SwitchListTile(
          key: const Key('builder-remind'),
          title: const Text('Recordarme'),
          value: remind,
          onChanged: (v) => setState(() => remind = v),
        ),
        if (remind) ...[
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < 7; i++)
                FilterChip(
                  key: Key('builder-day-$i'),
                  label: Text(_dayLetters[i]),
                  selected: days >> i & 1 == 1,
                  onSelected: (on) => setState(
                    () => days = on ? days | (1 << i) : days & ~(1 << i),
                  ),
                ),
            ],
          ),
          ListTile(
            key: const Key('builder-start'),
            title: const Text('Desde'),
            trailing: Text(clockText(start)),
            onTap: () => pick(start, (v) => start = v),
          ),
          ListTile(
            key: const Key('builder-end'),
            title: const Text('Hasta'),
            trailing: Text(clockText(end)),
            onTap: () => pick(end, (v) => end = v),
          ),
          SegmentedButton<String>(
            key: const Key('builder-tone'),
            segments: const [
              ButtonSegment(value: 'neutral', label: Text('Neutro')),
              ButtonSegment(value: 'cheer', label: Text('Motivador')),
            ],
            selected: {tone},
            onSelectionChanged: (v) => setState(() => tone = v.first),
          ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              key: const Key('builder-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('builder-submit'),
          onPressed: submit,
          child: Text(widget.submitLabel),
        ),
      ],
    ),
  );
}

/// The sheet of a proposal: what the companion would be and do.
class CompanionPreviewCard extends StatelessWidget {
  const CompanionPreviewCard({
    super.key,
    required this.draft,
    required this.onCreate,
    required this.onEdit,
    required this.onDiscard,
    this.busy = false,
    this.error,
  });

  final CompanionDraft draft;
  final VoidCallback onCreate, onEdit, onDiscard;
  final bool busy;
  final String? error;

  Map<String, String> get labels => {
    for (final f in draft.activity?.fields ?? const <Map<String, Object>>[])
      '${f['key']}': '${f['label']}',
  };

  @override
  Widget build(BuildContext context) {
    final companion = Companion(
      id: 'preview',
      name: draft.name,
      description: draft.description,
      prompt: '',
      icon: draft.icon,
      color: draft.color,
    );
    final activity = draft.activity;
    return Card(
      key: const Key('creator-preview'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CompanionAvatar(companion: companion),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    draft.name,
                    key: const Key('preview-name'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (draft.description.isNotEmpty) Text(draft.description),
            const SizedBox(height: 8),
            Text(
              'Qué anotas: ${activity == null ? 'lo decides al empezar' : '${activity.name}${activity.fields.isEmpty ? '' : ' (${activity.fields.map((f) => f['label']).join(', ')})'}${draft.instant ? ' · registro puntual' : ''}'}',
              key: const Key('preview-activity'),
            ),
            Text(
              'Meta: ${draft.goal == null ? 'sin meta' : goalText(draft.goal!, labels)}',
              key: const Key('preview-goal'),
            ),
            Text('Nivel: ${draft.levelText}', key: const Key('preview-level')),
            Text(
              'Aviso: ${draft.reminder == null ? 'sin aviso' : reminderText(draft.reminder!)}',
              key: const Key('preview-reminder'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error!,
                  key: const Key('preview-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: const Key('creator-create'),
                  onPressed: busy ? null : onCreate,
                  child: const Text('Crear'),
                ),
                OutlinedButton(
                  key: const Key('creator-edit'),
                  onPressed: busy ? null : onEdit,
                  child: const Text('Editar'),
                ),
                TextButton(
                  key: const Key('creator-discard'),
                  onPressed: busy ? null : onDiscard,
                  child: const Text('Descartar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The creation conversation. It is not saved in any chat: closing the screen
/// forgets it.
class CompanionAssistedScreen extends StatefulWidget {
  const CompanionAssistedScreen({
    super.key,
    required this.creation,
    required this.aiStore,
    this.client,
  });

  final CompanionCreation creation;
  final AiSettingsStore aiStore;
  final AiClient? client;

  @override
  State<CompanionAssistedScreen> createState() =>
      _CompanionAssistedScreenState();
}

class _CompanionAssistedScreenState extends State<CompanionAssistedScreen> {
  static const greeting =
      'Cuéntame qué quieres seguir y te ayudo a crear tu acompañante.';
  final input = TextEditingController();
  final messages = <AiMessage>[];
  final sessionId = const Uuid().v4();
  bool busy = false;
  bool creating = false;
  String? error;
  String? createError;
  CompanionDraft? draft;

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  static String visible(String answer) => answer
      .replaceAll(RegExp('$fenceOpen(?:trackia|gymia)-[a-z-]+[\\s\\S]*?```'), '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || busy) return;
    setState(() {
      busy = true;
      error = null;
      messages.add(AiMessage('user', text));
      input.clear();
    });
    try {
      final config = await widget.aiStore.load();
      if (config == null) {
        throw const ValidationException('No hay una IA conectada.');
      }
      final answer = await (widget.client ?? AiClient()).reply(
        config,
        List.of(messages),
        system: buildCompanionCreationContext(),
        sessionId: sessionId,
      );
      if (!mounted) return;
      setState(() {
        messages.add(AiMessage('assistant', answer));
        if (mentionsBlock(answer, 'companion')) {
          final proposal = parseCompanionBlock(answer);
          if (proposal == null) {
            error = blockRejectedText;
          } else {
            draft = CompanionDraft.fromProposal(proposal);
            createError = null;
          }
        }
      });
    } on ValidationException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'No se pudo completar la conversación. Puedes volver a intentarlo.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create() async {
    final current = draft;
    if (current == null || creating) return;
    setState(() {
      creating = true;
      createError = null;
    });
    try {
      final created = await widget.creation.create(current);
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) {
        setState(
          () => createError = e is ValidationException
              ? e.message
              : 'No se pudo crear el acompañante. No se guardó nada.',
        );
      }
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  Future<void> edit() async {
    final current = draft;
    if (current == null) return;
    final edited = await Navigator.of(context).push<CompanionDraft>(
      MaterialPageRoute(
        builder: (_) => CompanionBuilderScreen(initial: current),
      ),
    );
    if (edited != null && mounted) setState(() => draft = edited);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear con ayuda de la IA')),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(greeting, key: Key('creator-greeting')),
                ),
              ),
              for (final m in messages)
                if (visible(m.text).isNotEmpty)
                  Align(
                    alignment: m.role == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ChatMessageBody(
                          text: visible(m.text),
                          assistant: m.role != 'user',
                        ),
                      ),
                    ),
                  ),
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    error!,
                    key: const Key('creator-ai-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (draft != null)
                CompanionPreviewCard(
                  draft: draft!,
                  busy: creating,
                  error: createError,
                  onCreate: create,
                  onEdit: edit,
                  onDiscard: () => setState(() => draft = null),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('creator-input'),
                    controller: input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => send(),
                    decoration: const InputDecoration(hintText: 'Escribe aquí'),
                  ),
                ),
                IconButton(
                  key: const Key('creator-send'),
                  tooltip: 'Enviar',
                  onPressed: busy ? null : send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
