import 'dart:async';
import 'package:flutter/material.dart';
import '../application/ai_availability.dart';
import '../data/ai_settings_store.dart';
import '../data/companion_store.dart';
import '../data/progress_repository.dart';
import '../domain/companion.dart';
import 'ai_settings.dart';
import 'companion_style.dart';

class CompanionDashboard extends StatefulWidget {
  const CompanionDashboard({
    super.key,
    required this.profileId,
    required this.onOpen,
    this.onSettings,
    this.availability,
    this.progress,
    this.onCompanionSettings,
    this.onRemindersChanged,
  });
  final String profileId;
  final void Function(Companion) onOpen;

  /// Opens the app-wide settings. Without it the dashboard shows no gear.
  final VoidCallback? onSettings;

  /// Injectable for tests; by default it reads the profile's AI configuration.
  final AiAvailability? availability;

  /// Deletes a companion's settings and reminders along with it.
  final ProgressRepository? progress;

  /// Opens «Modo y avisos» of a companion; without it the menu has no entry.
  final void Function(Companion)? onCompanionSettings;

  /// Told after reminders change here (a resume or a deleted companion), so
  /// the phone gets a fresh snapshot.
  final VoidCallback? onRemindersChanged;

  @override
  State<CompanionDashboard> createState() => _CompanionDashboardState();
}

class _CompanionDashboardState extends State<CompanionDashboard>
    with WidgetsBindingObserver {
  late final store = CompanionStore(profileId: widget.profileId);
  late final AiAvailability availability =
      widget.availability ??
      AiAvailability(store: AiSettingsStore(profileId: widget.profileId));
  List<Companion> companions = [];
  Set<String> pausedIds = {};
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(availability.check(acceptRecentVerification: true));
    refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(availability.check(acceptRecentVerification: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.availability == null) availability.dispose();
    super.dispose();
  }

  Future<void> connectAi() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiSettingsScreen(profileId: widget.profileId),
      ),
    );
    if (mounted) {
      unawaited(availability.check(acceptRecentVerification: true));
    }
  }

  /// Shown until the assistant is verified, so configuring it never requires
  /// opening a companion first.
  Widget aiCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (title, body, action) = switch (availability.status) {
      AiAvailabilityStatus.unconfigured => (
        'IA sin conectar',
        'Elige un proveedor y un modelo.',
        'Conectar',
      ),
      AiAvailabilityStatus.unverified => (
        'IA sin verificar',
        'Prueba la conexión para activar el asistente.',
        'Verificar',
      ),
      _ => (
        'IA no disponible',
        'Revisa el proveedor y vuelve a probar.',
        'Revisar',
      ),
    };
    return Container(
      key: const Key('ai-not-connected'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.power_off_outlined, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          FilledButton(
            onPressed: connectAi,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> refresh() async {
    try {
      final loaded = await store.load();
      if (mounted) {
        setState(() {
          companions = loaded;
          loading = false;
          error = null;
        });
      }
      // The pause marks arrive after the list, so a slow database never
      // delays the companions themselves.
      unawaited(loadPaused(loaded));
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'No se pudieron cargar los acompañantes: $e';
        });
      }
    }
  }

  Future<void> loadPaused(List<Companion> loaded) async {
    final progress = widget.progress;
    if (progress == null) return;
    final paused = <String>{};
    for (final c in loaded) {
      try {
        if ((await progress.reminderFor(c.id))?.paused ?? false) {
          paused.add(c.id);
        }
      } catch (_) {
        // A companion whose reminder cannot be read is simply not shown paused.
      }
    }
    if (mounted) setState(() => pausedIds = paused);
  }

  Future<void> resume(Companion companion) async {
    await widget.progress?.setPaused(companion.id, paused: false);
    widget.onRemindersChanged?.call();
    await refresh();
  }

  Future<void> edit([Companion? original]) async {
    final result = await showDialog<Companion>(
      context: context,
      builder: (_) => _CompanionEditor(original: original),
    );
    if (result == null) return;
    try {
      await store.upsert(result);
      await refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    }
  }

  Future<void> remove(Companion companion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar ${companion.name}?'),
        content: const Text(
          'Se borrarán su chat, archivos y conexión local de Sheets. La hoja de Google y los registros de actividad no se borrarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.progress?.deleteCompanion(companion.id);
      await store.delete(companion.id);
      widget.onRemindersChanged?.call();
      await refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo borrar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('TrackIA'),
      actions: [
        if (widget.onSettings != null)
          IconButton(
            key: const Key('dashboard-settings'),
            tooltip: 'Ajustes',
            onPressed: widget.onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      key: const Key('companion-create'),
      onPressed: () => edit(),
      icon: const Icon(Icons.add),
      label: const Text('Crear acompañante'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: TextButton(onPressed: refresh, child: Text(error!)),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
            children: [
              Text(
                'Tus acompañantes',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Elige con quién trabajar. Cada uno conserva su conversación y puede usar una hoja o pestaña de Google distinta.',
              ),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: availability,
                builder: (context, _) => switch (availability.status) {
                  AiAvailabilityStatus.ready ||
                  AiAvailabilityStatus.checking => const SizedBox.shrink(),
                  _ => aiCard(context),
                },
              ),
              if (companions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aún no tienes acompañantes. Crea uno para empezar.',
                    ),
                  ),
                ),
              for (final companion in companions)
                Card(
                  key: Key('companion-${companion.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CompanionAvatar(companion: companion),
                      title: Text(companion.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(companion.description),
                          if (pausedIds.contains(companion.id))
                            Row(
                              key: Key('paused-${companion.id}'),
                              children: [
                                const Icon(
                                  Icons.pause_circle_outline,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                const Flexible(
                                  child: Text('Recordatorios en pausa'),
                                ),
                                TextButton(
                                  key: Key('resume-${companion.id}'),
                                  onPressed: () => resume(companion),
                                  child: const Text('Reanudar'),
                                ),
                              ],
                            ),
                        ],
                      ),
                      onTap: () => widget.onOpen(companion),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Opciones de ${companion.name}',
                        onSelected: (choice) => switch (choice) {
                          'edit' => edit(companion),
                          'settings' => widget.onCompanionSettings?.call(
                            companion,
                          ),
                          _ => remove(companion),
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          if (widget.onCompanionSettings != null)
                            const PopupMenuItem(
                              key: Key('menu-companion-settings'),
                              value: 'settings',
                              child: Text('Modo y avisos'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Borrar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
  );
}

class _CompanionEditor extends StatefulWidget {
  const _CompanionEditor({this.original});
  final Companion? original;

  @override
  State<_CompanionEditor> createState() => _CompanionEditorState();
}

class _CompanionEditorState extends State<_CompanionEditor> {
  late final name = TextEditingController(text: widget.original?.name ?? '');
  late final description = TextEditingController(
    text: widget.original?.description ?? '',
  );
  late final prompt = TextEditingController(
    text: widget.original?.prompt ?? '',
  );
  late String icon = widget.original?.icon ?? 'sparkles';
  late String color = widget.original?.color ?? 'teal';

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    prompt.dispose();
    super.dispose();
  }

  void save() {
    try {
      final original = widget.original;
      final value = original == null
          ? Companion.custom(
              name: name.text,
              prompt: prompt.text,
            ).copyWith(description: description.text, icon: icon, color: color)
          : original.copyWith(
              name: name.text,
              description: description.text,
              prompt: prompt.text,
              icon: icon,
              color: color,
            );
      Navigator.pop(context, value);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.original == null ? 'Crear acompañante' : 'Editar acompañante',
    ),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: description,
              maxLength: 120,
              decoration: const InputDecoration(labelText: '¿Para qué sirve?'),
            ),
            TextField(
              controller: prompt,
              maxLines: 8,
              maxLength: 8000,
              decoration: const InputDecoration(
                labelText: 'Instrucciones para la IA (opcional)',
                helperText: 'Se usan cuando conectes un proveedor.',
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Icono',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final entry in companionIcons.entries)
                  IconButton(
                    key: Key('icon-${entry.key}'),
                    tooltip: entry.key,
                    isSelected: icon == entry.key,
                    onPressed: () => setState(() => icon = entry.key),
                    icon: Icon(entry.value),
                    selectedIcon: Icon(
                      entry.value,
                      color: companionColor(context, color),
                    ),
                    style: IconButton.styleFrom(
                      side: icon == entry.key
                          ? BorderSide(
                              color: companionColor(context, color),
                              width: 2,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Color',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final id in Companion.colorIds)
                  IconButton(
                    key: Key('color-$id'),
                    tooltip: id,
                    isSelected: color == id,
                    onPressed: () => setState(() => color = id),
                    icon: Icon(
                      Icons.circle,
                      color: companionColor(context, id),
                    ),
                    selectedIcon: Icon(
                      Icons.check_circle,
                      color: companionColor(context, id),
                    ),
                  ),
              ],
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
      FilledButton(onPressed: save, child: const Text('Guardar')),
    ],
  );
}
