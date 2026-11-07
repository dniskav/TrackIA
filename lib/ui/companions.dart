import 'companion_creator.dart';
import 'companion_import.dart';
import 'companion_scan.dart';
import '../application/companion_creation.dart';
import '../data/ai_client.dart';
import '../data/activity_template_repository.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../application/localization.dart';
import '../application/ai_availability.dart';
import '../data/ai_settings_store.dart';
import '../data/companion_store.dart';
import '../application/progress_service.dart';
import '../data/progress_repository.dart';
import '../domain/companion.dart';
import 'ai_settings.dart';
import 'companion_style.dart';
import 'goal_ring.dart';

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
    this.progressService,
    this.onProgress,
    this.templates,
    this.aiClient,
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

  /// Reads the streak and goal of companions in game mode for their card.
  final ProgressService? progressService;

  /// Opens «Progreso» of a companion.
  final void Function(Companion)? onProgress;

  /// Where a new companion's first activity is saved when it is created.
  final ActivityTemplateRepository? templates;

  /// Injectable for tests: the client used by «Crear con ayuda de la IA».
  final AiClient? aiClient;

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
  Map<String, ProgressState> gameStates = {};
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

  /// «Crear acompañante»: by hand or with the AI's help. Without the progress
  /// repository (no database) only the plain editor is offered.
  Future<void> create() async {
    final progress = widget.progress;
    if (progress == null) return edit();
    final made = await Navigator.of(context).push<Companion>(
      MaterialPageRoute(
        builder:
            (_) => CompanionCreatorScreen(
              store: store,
              progress: progress,
              templates: widget.templates,
              availability: availability,
              aiStore: AiSettingsStore(profileId: widget.profileId),
              client: widget.aiClient,
              onOpenAiSettings: connectAi,
            ),
      ),
    );
    if (made == null) return;
    widget.onRemindersChanged?.call();
    await refresh();
  }

  /// «Importar acompañante» (`.trackia` o texto pegado): vista previa y
  /// confirmación antes de guardar nada.
  Future<void> importCompanion() async {
    final progress = widget.progress;
    if (progress == null) return;
    final made = await Navigator.of(context).push<Companion>(
      MaterialPageRoute(
        builder:
            (_) => CompanionImportScreen(
              store: store,
              creation: CompanionCreation(
                store: store,
                progress: progress,
                templates: widget.templates,
              ),
              takenIds: companions.map((c) => c.id),
            ),
      ),
    );
    if (made == null) return;
    widget.onRemindersChanged?.call();
    await refresh();
  }

  /// «Escanear acompañante»: the camera opens only after tapping the button.
  Future<void> scanCompanion() async {
    final progress = widget.progress;
    if (progress == null) return;
    final made = await scanAndImportCompanion(
      context,
      store: store,
      creation: CompanionCreation(
        store: store,
        progress: progress,
        templates: widget.templates,
      ),
      takenIds: companions.map((c) => c.id),
    );
    if (made == null) return;
    widget.onRemindersChanged?.call();
    await refresh();
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
    final l = appText(context);
    final (title, body, action) = switch (availability.status) {
      AiAvailabilityStatus.unconfigured => (
        l.aiNotConnected,
        l.chooseProviderAndModel,
        l.connect,
      ),
      AiAvailabilityStatus.unverified => (
        l.aiNotVerified,
        l.verifyConnectionAssistant,
        l.verify,
      ),
      _ => (l.aiUnavailable, l.reviewProviderRetry, l.review),
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
          error = appText(context).restScreenCompanionsLoadDetail('$e');
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
    await loadGameStates(loaded);
  }

  /// Streak and goal ring for the companions in game mode.
  Future<void> loadGameStates(List<Companion> loaded) async {
    final service = widget.progressService;
    if (service == null) return;
    final states = <String, ProgressState>{};
    for (final c in loaded) {
      try {
        final state = await service.state(c.id);
        if (state.settings.game) states[c.id] = state;
      } catch (_) {
        // A companion whose progress cannot be calculated shows no ring.
      }
    }
    if (mounted) setState(() => gameStates = states);
  }

  /// Ring of the goal and the streak line of a companion in game mode.
  Widget gameLine(Companion companion, ProgressState state) {
    final l = appText(context);
    final goal = state.goalProgress;
    final days = state.streak.current;
    return Padding(
      key: Key('game-${companion.id}'),
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          if (goal != null) ...[
            GoalRing(
              key: Key('ring-${companion.id}'),
              fraction: goal.fraction,
              size: 28,
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.local_fire_department, size: 18),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l.companionStreak(days),
              key: Key('streak-${companion.id}'),
            ),
          ),
          if (widget.onProgress != null)
            IconButton(
              key: Key('progress-${companion.id}'),
              tooltip: l.companionProgress(companion.name),
              icon: const Icon(Icons.emoji_events_outlined),
              onPressed: () => widget.onProgress!(companion),
            ),
        ],
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appText(context).companionSaveError(e))),
        );
      }
    }
  }

  Future<void> remove(Companion companion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(appText(context).companionDeleteTitle(companion.name)),
            content: Text(appText(context).companionDeleteBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(appText(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(appText(context).delete),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appText(context).companionDeleteError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            key: const Key('dashboard-trackia-logo-semantics'),
            container: true,
            image: true,
            label: appText(context).logoDescription,
            child: ExcludeSemantics(
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: OverflowBox(
                  maxWidth: 44,
                  maxHeight: 44,
                  child: Image.asset(
                    'assets/branding/trackia-logo.png',
                    key: const Key('dashboard-trackia-logo'),
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(appText(context).appTitle),
        ],
      ),
      actions: [
        if (widget.progress != null)
          IconButton(
            key: const Key('import-companion'),
            tooltip: appText(context).packageImportTitle,
            onPressed: importCompanion,
            icon: const Icon(Icons.file_download_outlined),
          ),
        if (widget.progress != null)
          IconButton(
            key: const Key('scan-companion'),
            tooltip: appText(context).packageScanTitle,
            onPressed: scanCompanion,
            icon: const Icon(Icons.qr_code_scanner),
          ),
        if (widget.onSettings != null)
          IconButton(
            key: const Key('dashboard-settings'),
            tooltip: appText(context).settings,
            onPressed: widget.onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      key: const Key('companion-create'),
      onPressed: create,
      icon: const Icon(Icons.add),
      label: Text(appText(context).createCompanion),
    ),
    body:
        loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
              child: TextButton(
                onPressed: refresh,
                child: Text(appText(context).companionLoadError),
              ),
            )
            : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
              children: [
                Text(
                  appText(context).companionsTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(appText(context).companionsDescription),
                const SizedBox(height: 20),
                ListenableBuilder(
                  listenable: availability,
                  builder:
                      (context, _) => switch (availability.status) {
                        AiAvailabilityStatus.ready ||
                        AiAvailabilityStatus
                            .checking => const SizedBox.shrink(),
                        _ => aiCard(context),
                      },
                ),
                if (companions.isEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(appText(context).companionsEmpty),
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
                            if (gameStates[companion.id] case final state?)
                              gameLine(companion, state),
                            if (pausedIds.contains(companion.id))
                              Row(
                                key: Key('paused-${companion.id}'),
                                children: [
                                  const Icon(
                                    Icons.pause_circle_outline,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      appText(context).remindersPaused,
                                    ),
                                  ),
                                  TextButton(
                                    key: Key('resume-${companion.id}'),
                                    onPressed: () => resume(companion),
                                    child: Text(appText(context).resume),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        onTap: () => widget.onOpen(companion),
                        trailing: PopupMenuButton<String>(
                          tooltip: appText(
                            context,
                          ).companionOptions(companion.name),
                          onSelected:
                              (choice) => switch (choice) {
                                'edit' => edit(companion),
                                'settings' => widget.onCompanionSettings?.call(
                                  companion,
                                ),
                                _ => remove(companion),
                              },
                          itemBuilder:
                              (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(appText(context).edit),
                                ),
                                if (widget.onCompanionSettings != null)
                                  PopupMenuItem(
                                    key: Key('menu-companion-settings'),
                                    value: 'settings',
                                    child: Text(
                                      appText(context).modeAndNotices,
                                    ),
                                  ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(appText(context).delete),
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
      final value =
          original == null
              ? Companion.custom(name: name.text, prompt: prompt.text).copyWith(
                description: description.text,
                icon: icon,
                color: color,
              )
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
  Widget build(BuildContext context) {
    final l = appText(context);
    return AlertDialog(
      title: Text(
        widget.original == null ? l.createCompanionTitle : l.editCompanionTitle,
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
                decoration: InputDecoration(labelText: l.companionName),
              ),
              TextField(
                controller: description,
                maxLength: 120,
                decoration: InputDecoration(labelText: l.companionPurpose),
              ),
              TextField(
                controller: prompt,
                maxLines: 8,
                maxLength: 8000,
                decoration: InputDecoration(
                  labelText: l.companionInstructions,
                  helperText: l.companionInstructionsHelp,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.icon,
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
                        side:
                            icon == entry.key
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
                  l.color,
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
          child: Text(l.cancel),
        ),
        FilledButton(onPressed: save, child: Text(l.save)),
      ],
    );
  }
}
