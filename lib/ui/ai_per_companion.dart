import 'package:flutter/material.dart';

import '../data/ai_settings_store.dart';
import '../data/companion_store.dart';
import '../data/progress_repository.dart';
import '../domain/ai_config.dart';
import '../domain/companion.dart';
import '../domain/workout.dart';
import '../application/localization.dart';

/// «Por acompañante» (US11): each companion uses the profile's AI setup or
/// its own model of the same provider. Credentials are never edited here.
class AiPerCompanionSection extends StatefulWidget {
  const AiPerCompanionSection({
    super.key,
    required this.profileId,
    required this.progress,
  });

  final String profileId;
  final ProgressRepository progress;

  @override
  State<AiPerCompanionSection> createState() => _AiPerCompanionSectionState();
}

class _AiPerCompanionSectionState extends State<AiPerCompanionSection> {
  List<Companion> companions = [];
  Map<String, AiOverride?> overrides = {};
  AiConfig? defaults;
  bool loaded = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final all = await CompanionStore(profileId: widget.profileId).load();
      final config = await AiSettingsStore(
        profileId: widget.profileId,
      ).loadDefault();
      final found = <String, AiOverride?>{};
      for (final c in all) {
        found[c.id] = (await widget.progress.settings(c.id)).aiOverride;
      }
      if (!mounted) return;
      setState(() {
        companions = all;
        overrides = found;
        defaults = config;
        loaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loaded = true;
          error = appText(context).aiPerReadError;
        });
      }
    }
  }

  String describe(AiOverride? value) =>
      value == null
          ? appText(context).aiPerDefault
          : '${value.model} · ${value.service.label}';

  Future<void> edit(Companion companion) async {
    final base = defaults;
    if (base == null) return;
    final current = overrides[companion.id];
    final result = await showDialog<_Choice>(
      context: context,
      builder: (context) => _ModelDialog(
        companion: companion,
        service: base.service,
        initial: current?.service == base.service ? current!.model : base.model,
      ),
    );
    if (result == null) return;
    try {
      final settings = await widget.progress.settings(companion.id);
      final next = result.useDefault
          ? null
          : AiOverride(service: base.service, model: result.model);
      await widget.progress.saveSettings(
        next == null
            ? settings.copyWith(clearAiOverride: true)
            : settings.copyWith(aiOverride: next),
      );
      if (!mounted) return;
      setState(() {
        overrides[companion.id] = next;
        error = null;
      });
    } on ValidationException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = appText(context).aiPerSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded || (companions.isEmpty && error == null)) {
      return const SizedBox.shrink();
    }
    return Column(
      key: const Key('ai-per-companion'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Text(appText(context).aiPerTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          defaults == null
              ? appText(context).aiPerNoProvider
              : appText(context).aiPerHelp,
        ),
        for (final c in companions)
          ListTile(
            key: Key('ai-override-${c.id}'),
            contentPadding: EdgeInsets.zero,
            title: Text(c.name),
            subtitle: Text(describe(overrides[c.id])),
            trailing: const Icon(Icons.chevron_right),
            enabled: defaults != null,
            onTap: defaults == null ? null : () => edit(c),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

class _Choice {
  const _Choice.save(this.model) : useDefault = false;
  const _Choice.useDefault() : model = '', useDefault = true;
  final String model;
  final bool useDefault;
}

class _ModelDialog extends StatefulWidget {
  const _ModelDialog({
    required this.companion,
    required this.service,
    required this.initial,
  });

  final Companion companion;
  final AiService service;
  final String initial;

  @override
  State<_ModelDialog> createState() => _ModelDialogState();
}

class _ModelDialogState extends State<_ModelDialog> {
  late final controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(appText(context).aiPerDialogTitle(widget.companion.name)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appText(context).aiPerDialogHelp(widget.service.label),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('ai-override-model'),
          controller: controller,
          decoration: InputDecoration(labelText: appText(context).aiModelLabel),
        ),
      ],
    ),
    actions: [
      TextButton(
        key: const Key('ai-override-default'),
        onPressed: () => Navigator.pop(context, const _Choice.useDefault()),
        child: Text(appText(context).aiPerUseDefault),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(appText(context).cancel),
      ),
      FilledButton(
        key: const Key('ai-override-save'),
        onPressed: () => Navigator.pop(context, _Choice.save(controller.text)),
        child: Text(appText(context).save),
      ),
    ],
  );
}
