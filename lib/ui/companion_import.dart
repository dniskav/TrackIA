import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../application/companion_creation.dart';
import '../application/companion_package_import.dart';
import '../application/localization.dart';
import '../data/companion_store.dart';
import '../domain/companion.dart';
import '../domain/companion_package.dart';
import '../domain/workout.dart';
import '../l10n/generated/app_localizations.dart';
import 'companion_style.dart';

/// «Importar acompañante»: reads a `.trackia` file or pasted text, shows a
/// complete, editable preview and saves a NEW companion only when confirmed
/// (FR-018, FR-019). Pops with the created [Companion], or null.
class CompanionImportScreen extends StatefulWidget {
  const CompanionImportScreen({
    super.key,
    required this.store,
    required this.creation,
    this.takenIds = const [],
    this.pickFile,
  });

  final CompanionStore store;
  final CompanionCreation creation;

  /// Ids already used; the new companion's identity is free among them.
  final Iterable<String> takenIds;

  /// Injectable for tests: returns the bytes of the chosen file, or null.
  final Future<List<int>?> Function()? pickFile;

  @override
  State<CompanionImportScreen> createState() => _CompanionImportScreenState();
}

class _CompanionImportScreenState extends State<CompanionImportScreen> {
  final paste = TextEditingController();
  final name = TextEditingController();
  final description = TextEditingController();
  final prompt = TextEditingController();
  CompanionImportPreview? preview;
  String icon = 'sparkles';
  String color = 'teal';
  CompanionPackageException? problem;
  String? message;
  bool busy = false;

  @override
  void dispose() {
    paste.dispose();
    name.dispose();
    description.dispose();
    prompt.dispose();
    super.dispose();
  }

  Future<List<int>?> _pick() async {
    final custom = widget.pickFile;
    if (custom != null) return custom();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['trackia', 'txt'],
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > CompanionPackageLimits.maxEncodedChars * 2) {
      throw const CompanionPackageException(
        CompanionPackageProblem.tooLarge,
        'El archivo es demasiado grande.',
      );
    }
    if (file.bytes != null) return file.bytes!;
    if (file.path == null) return null;
    return File(file.path!).readAsBytes();
  }

  void _show(CompanionImportPreview p) {
    name.text = p.draft.name;
    description.text = p.draft.description;
    prompt.text = p.draft.prompt;
    setState(() {
      preview = p;
      icon = p.draft.icon ?? 'sparkles';
      color = p.draft.color ?? 'teal';
      problem = null;
      message = null;
    });
  }

  void _fail(CompanionPackageException e) => setState(() {
    preview = null;
    problem = e;
    message = null;
  });

  Future<void> pickFile() async {
    if (busy) return;
    try {
      final bytes = await _pick();
      if (bytes == null || !mounted) return;
      _show(
        CompanionPackageImport.previewBytes(
          bytes,
          takenIds: widget.takenIds,
        ),
      );
    } on CompanionPackageException catch (e) {
      if (mounted) _fail(e);
    } catch (_) {
      if (mounted) {
        setState(() {
          preview = null;
          problem = null;
          message = appText(context).packageImportFileError;
        });
      }
    }
  }

  void showPreview() {
    try {
      _show(
        CompanionPackageImport.preview(paste.text, takenIds: widget.takenIds),
      );
    } on CompanionPackageException catch (e) {
      _fail(e);
    }
  }

  void cancel() => Navigator.of(context).pop();

  Future<void> save() async {
    final p = preview;
    if (p == null || busy) return;
    final clean = name.text.trim();
    if (clean.isEmpty || clean.length > CompanionPackageLimits.nameChars) {
      setState(() => message = appText(context).creatorNameLength);
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    final strings = appText(context);
    try {
      // The text is edited by hand: app blocks never reach the instructions.
      final instructions = CompanionPackage.stripAppBlocks(
        prompt.text,
      ).text.trim();
      final draft = p.draft.copyWith(
        name: clean,
        description: description.text.trim(),
        prompt: instructions,
        icon: icon,
        color: color,
        mode: 'reminder',
      );
      var created = await widget.creation.create(draft);
      final copy = p.reminderCopy;
      if (copy != null) {
        try {
          created = created.copyWith(reminderCopy: copy);
          await widget.store.upsert(created);
        } catch (_) {
          // Without its copy the companion is not what was previewed.
          try {
            await widget.creation.progress.deleteCompanion(created.id);
          } catch (_) {}
          await widget.store.delete(created.id);
          rethrow;
        }
      }
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) {
        setState(
          () => message = e is ValidationException
              ? e.message
              : strings.packageImportSaveFailed,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String problemText(CompanionPackageProblem p) {
    final l = appText(context);
    return switch (p) {
      CompanionPackageProblem.empty => l.packageImportProblemEmpty,
      CompanionPackageProblem.tooLarge => l.packageImportProblemTooLarge,
      CompanionPackageProblem.badEncoding => l.packageImportProblemBadEncoding,
      CompanionPackageProblem.badCompression =>
        l.packageImportProblemBadCompression,
      CompanionPackageProblem.tooLargeExpanded =>
        l.packageImportProblemTooLargeExpanded,
      CompanionPackageProblem.malformed => l.packageImportProblemMalformed,
      CompanionPackageProblem.notAPackage => l.packageImportProblemNotAPackage,
      CompanionPackageProblem.unsupportedVersion =>
        l.packageImportProblemUnsupportedVersion,
      CompanionPackageProblem.checksumMismatch =>
        l.packageImportProblemChecksumMismatch,
      CompanionPackageProblem.forbiddenField =>
        l.packageImportProblemForbiddenField,
      CompanionPackageProblem.unknownField =>
        l.packageImportProblemUnknownField,
      CompanionPackageProblem.missingField =>
        l.packageImportProblemMissingField,
      CompanionPackageProblem.invalidField =>
        l.packageImportProblemInvalidField,
    };
  }

  String warningText(ImportWarning w) {
    final l = appText(context);
    return switch (w.kind) {
      ImportWarningKind.appBlocksRemoved =>
        l.packageImportWarningAppBlocksRemoved(w.count),
      ImportWarningKind.modeReset => l.packageImportWarningModeReset(
        w.detail,
      ),
      ImportWarningKind.extraTemplatesNotApplied =>
        l.packageImportWarningExtraTemplates(w.count),
      ImportWarningKind.suspiciousInstructions =>
        l.packageImportWarningSuspicious,
      ImportWarningKind.instructionsEmpty =>
        l.packageImportWarningInstructionsEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = appText(context);
    final scheme = Theme.of(context).colorScheme;
    final p = preview;
    return Scaffold(
      appBar: AppBar(title: Text(l.packageImportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p == null) ..._source(l) else ..._preview(l, scheme, p),
          if (problem != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                key: const Key('import-error'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    problemText(problem!.problem),
                    style: TextStyle(color: scheme.error),
                  ),
                  if (problem!.field != null)
                    Text(
                      l.packageImportProblemField(problem!.field!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                message!,
                key: const Key('import-message'),
                style: TextStyle(color: scheme.error),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _source(AppLocalizations l) => [
    Text(l.packageImportIntro),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      key: const Key('import-pick-file'),
      onPressed: pickFile,
      icon: const Icon(Icons.folder_open),
      label: Text(l.packageImportPickFile),
    ),
    const SizedBox(height: 12),
    TextField(
      key: const Key('import-paste'),
      controller: paste,
      minLines: 3,
      maxLines: 6,
      decoration: InputDecoration(
        labelText: l.packageImportPasteLabel,
        border: const OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 12),
    FilledButton(
      key: const Key('import-preview'),
      onPressed: showPreview,
      child: Text(l.packageImportPreviewButton),
    ),
  ];

  List<Widget> _preview(AppLocalizations l, ColorScheme scheme, CompanionImportPreview p) {
    final activity = p.draft.activity;
    final copy = p.reminderCopy;
    return [
      Card(
        key: const Key('import-external-notice'),
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.packageImportExternalNotice,
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (p.warnings.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          l.packageImportWarningsTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final w in p.warnings)
          ListTile(
            key: Key('import-warning-${w.kind.name}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text(warningText(w)),
          ),
      ],
      const SizedBox(height: 8),
      Text(l.packageImportModeNote, key: const Key('import-mode-note')),
      const SizedBox(height: 12),
      TextField(
        key: const Key('import-name'),
        controller: name,
        maxLength: CompanionPackageLimits.nameChars,
        decoration: InputDecoration(labelText: l.companionName),
      ),
      TextField(
        key: const Key('import-description'),
        controller: description,
        maxLength: CompanionPackageLimits.descriptionChars,
        decoration: InputDecoration(labelText: l.companionPurpose),
      ),
      TextField(
        key: const Key('import-prompt'),
        controller: prompt,
        minLines: 4,
        maxLines: 10,
        maxLength: CompanionPackageLimits.instructionsChars,
        decoration: InputDecoration(labelText: l.companionInstructions),
      ),
      const SizedBox(height: 8),
      Text(l.icon, style: Theme.of(context).textTheme.labelLarge),
      Wrap(
        spacing: 4,
        children: [
          for (final e in companionIcons.entries)
            IconButton(
              key: Key('import-icon-${e.key}'),
              tooltip: e.key,
              isSelected: icon == e.key,
              icon: Icon(e.value),
              selectedIcon: Icon(e.value, color: companionColor(context, color)),
              onPressed: () => setState(() => icon = e.key),
            ),
        ],
      ),
      Text(l.color, style: Theme.of(context).textTheme.labelLarge),
      Wrap(
        spacing: 4,
        children: [
          for (final id in Companion.colorIds)
            IconButton(
              key: Key('import-color-$id'),
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
      if (activity != null) ...[
        const Divider(height: 24),
        Text(
          l.packageImportActivityTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        ListTile(
          key: const Key('import-activity'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_note),
          title: Text(activity.name),
          subtitle: Text(
            l.packageImportActivityFields(
              activity.fields.map((f) => f['label']).join(', '),
            ),
          ),
        ),
        if (activity.instructions.isNotEmpty)
          Text(activity.instructions, key: const Key('import-activity-text')),
      ],
      if (copy != null) ...[
        const Divider(height: 24),
        Text(
          l.packageImportRemindersTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        _copyList(l.packageImportReminderWindowStart, copy.windowStart),
        _copyList(l.packageImportReminderLastCall, copy.lastCall),
        _copyList(l.packageImportReminderInactive, copy.inactive),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('import-cancel'),
              onPressed: busy ? null : cancel,
              child: Text(l.cancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              key: const Key('import-save'),
              onPressed: busy ? null : save,
              child: Text(l.packageImportSave),
            ),
          ),
        ],
      ),
      if (busy) const LinearProgressIndicator(),
    ];
  }

  Widget _copyList(String title, List<String> texts) => texts.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              for (final t in texts) Text('• $t'),
            ],
          ),
        );
}
