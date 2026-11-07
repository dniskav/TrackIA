import 'package:flutter/material.dart';

import '../application/localization.dart';
import '../application/memory_import_preview.dart';
import '../data/companion_memory_repository.dart';
import '../data/memory_google_drive.dart';
import '../data/memory_snapshot.dart';
import '../domain/companion.dart';
import '../domain/companion_memory.dart';

/// Consulta, edición, confirmación y borrado de la memoria de un acompañante,
/// más la copia opcional en la nube (T027, T031).
///
/// Borrar en local (borrado lógico) y borrar en la nube son operaciones
/// distintas: ninguna hace la otra. Las acciones de nube solo se habilitan con
/// un [transport] y una [accountId]; no hay llamadas automáticas.
class CompanionMemoryScreen extends StatefulWidget {
  const CompanionMemoryScreen({
    super.key,
    required this.repository,
    required this.companion,
    this.transport,
    this.accountId,
    this.clock,
  });

  /// Ya limitado al perfil; la pantalla lo usa solo para este [companion].
  final CompanionMemoryRepository repository;
  final Companion companion;
  final MemoryCloudTransport? transport;

  /// Cuenta de Google conectada, si la hay.
  final String? accountId;
  final DateTime Function()? clock;

  @override
  State<CompanionMemoryScreen> createState() => _CompanionMemoryScreenState();
}

class _CompanionMemoryScreenState extends State<CompanionMemoryScreen> {
  List<CompanionMemory> memories = const [];
  bool loading = true;
  bool busy = false;
  String? error;
  String? notice;
  String? cloudNotice;
  int? cloudRevision;
  DateTime? cloudUpdatedAt;

  String get companionId => widget.companion.id;
  String get profileId => widget.repository.profileId;
  DateTime now() => (widget.clock ?? DateTime.now)();
  String? get account {
    final value = widget.accountId?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  bool get cloudAvailable => widget.transport != null;
  bool get cloudReady => cloudAvailable && account != null;
  MemoryGoogleDriveService get cloud =>
      MemoryGoogleDriveService(widget.transport!, clock: widget.clock);

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    try {
      final list = await widget.repository.list(companionId: companionId);
      if (!mounted) return;
      setState(() {
        memories = list;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = appText(context).memoryLoadError;
      });
    }
  }

  String formatDate(DateTime date) {
    final local = date.toLocal();
    final loc = MaterialLocalizations.of(context);
    return '${loc.formatShortDate(local)} '
        '${loc.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  DateTime stamp(CompanionMemory memory) {
    final t = now();
    return t.isBefore(memory.updatedAt) ? memory.updatedAt : t;
  }

  Future<bool> askConfirm({
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    final l = appText(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            key: const Key('memory-dialog-cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('memory-dialog-confirm'),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ---- Local operations ----

  Future<void> edit(CompanionMemory memory) async {
    final l = appText(context);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => _EditMemoryDialog(initial: memory.content),
    );
    if (text == null || text == memory.content || !mounted) return;
    await guarded(() async {
      await widget.repository.revise(
        memory.id,
        companionId: companionId,
        at: stamp(memory),
        content: text,
      );
      notice = l.memoryEdited;
    });
  }

  Future<void> confirmPending(CompanionMemory memory) {
    final l = appText(context);
    return guarded(() async {
      await widget.repository.confirm(
        memory.id,
        companionId: companionId,
        at: stamp(memory),
      );
      notice = l.memoryConfirmed;
    });
  }

  Future<void> deleteLocal(CompanionMemory memory) async {
    final l = appText(context);
    final ok = await askConfirm(
      title: l.memoryDeleteLocalTitle,
      body: l.memoryDeleteLocalBody,
      action: l.memoryDeleteLocalAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await guarded(() async {
      await widget.repository.delete(
        memory.id,
        companionId: companionId,
        at: stamp(memory),
      );
      notice = l.memoryDeletedLocal;
    });
  }

  Future<void> guarded(Future<void> Function() action) async {
    final l = appText(context);
    if (busy) return;
    setState(() {
      busy = true;
      notice = null;
      error = null;
    });
    try {
      await action();
      final list = await widget.repository.list(companionId: companionId);
      if (mounted) setState(() => memories = list);
    } catch (_) {
      if (mounted) setState(() => error = l.memoryActionError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  // ---- Cloud operations ----

  String describe(MemoryCloudResult result, String okText) {
    final l = appText(context);
    return switch (result.status) {
      MemoryCloudStatus.success => okText,
      MemoryCloudStatus.notFound => l.memoryCloudNotFound,
      MemoryCloudStatus.conflict => l.memoryCloudConflict,
      MemoryCloudStatus.uncertain => l.memoryCloudUncertain,
      MemoryCloudStatus.cancelled => l.memoryCloudCancelled,
      MemoryCloudStatus.permissionDenied => l.memoryCloudDenied,
      MemoryCloudStatus.failed => l.memoryCloudFailed,
    };
  }

  Future<void> cloudOp(Future<void> Function(String account) action) async {
    final id = account;
    if (busy || !cloudReady || id == null) return;
    setState(() {
      busy = true;
      cloudNotice = null;
    });
    try {
      await action(id);
    } catch (_) {
      if (mounted) {
        setState(() => cloudNotice = appText(context).memoryCloudFailed);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void adopt(MemoryCloudResult result) {
    if (result.revision != null) cloudRevision = result.revision;
    if (result.updatedAt != null) cloudUpdatedAt = result.updatedAt;
  }

  Future<void> saveCloud() => cloudOp((id) async {
    final l = appText(context);
    final active = memories
        .where((m) => m.status == MemoryStatus.active)
        .toList();
    final ok = await askConfirm(
      title: l.memoryCloudSaveTitle,
      body: l.memoryCloudSaveBody(id, active.length),
      action: l.memoryCloudSave,
    );
    if (!ok || !mounted) return;
    final result = await cloud.save(
      accountId: id,
      snapshot: MemorySnapshot(
        profileId: profileId,
        companionId: companionId,
        memories: active,
      ),
      knownRevision: cloudRevision,
    );
    if (!mounted) return;
    setState(() {
      if (result.succeeded) adopt(result);
      cloudNotice = describe(result, l.memoryCloudSaved(id));
    });
  });

  Future<void> loadCloud() => cloudOp((id) async {
    final l = appText(context);
    final result = await cloud.load(
      accountId: id,
      profileId: profileId,
      companionId: companionId,
    );
    if (!mounted) return;
    final snapshot = result.snapshot;
    if (!result.succeeded || snapshot == null) {
      setState(() => cloudNotice = describe(result, ''));
      return;
    }
    adopt(result);
    final existing = await widget.repository.list(
      companionId: companionId,
      includeDeleted: true,
    );
    final MemoryImportPreview preview;
    try {
      preview = MemoryImportPreview.build(
        snapshot: snapshot,
        targetProfileId: profileId,
        targetCompanionId: companionId,
        existing: existing,
      );
    } catch (_) {
      if (mounted) setState(() => cloudNotice = l.memoryCloudFailed);
      return;
    }
    if (!mounted) return;
    final apply = await showPreview(id, result, preview);
    if (!apply || !mounted) {
      setState(() => cloudNotice = l.memoryCloudLoadCancelled);
      return;
    }
    for (final memory in preview.toAdd) {
      await widget.repository.create(
        id: memory.id,
        companionId: companionId,
        content: memory.content,
        source: memory.source,
        sourceMessageId: memory.sourceMessageId,
        at: memory.createdAt,
      );
    }
    final list = await widget.repository.list(companionId: companionId);
    if (!mounted) return;
    setState(() {
      memories = list;
      cloudNotice = l.memoryCloudLoaded(preview.toAdd.length);
    });
  });

  Future<bool> showPreview(
    String id,
    MemoryCloudResult result,
    MemoryImportPreview preview,
  ) async {
    final l = appText(context);
    final result0 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('memory-import-preview'),
        title: Text(l.memoryPreviewTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.memoryPreviewFrom(id, formatDate(result.updatedAt!))),
              const SizedBox(height: 8),
              Text(
                l.memoryPreviewAdd(preview.toAdd.length),
                key: const Key('memory-preview-add'),
              ),
              for (final m in preview.toAdd) Text('+ ${m.content}'),
              const SizedBox(height: 4),
              Text(
                l.memoryPreviewSkip(preview.skipped.length),
                key: const Key('memory-preview-skip'),
              ),
              const SizedBox(height: 4),
              Text(
                l.memoryPreviewConflict(preview.conflicts.length),
                key: const Key('memory-preview-conflict'),
              ),
              for (final c in preview.conflicts)
                Text('! ${c.local.content} → ${c.incoming.content}'),
              if (preview.hasConflicts) Text(l.memoryPreviewConflictHelp),
              if (!preview.hasChanges) ...[
                const SizedBox(height: 8),
                Text(l.memoryPreviewNothing),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('memory-dialog-cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          if (preview.hasChanges)
            FilledButton(
              key: const Key('memory-dialog-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.memoryPreviewApply),
            ),
        ],
      ),
    );
    return result0 == true;
  }

  Future<void> deleteCloud() => cloudOp((id) async {
    final l = appText(context);
    // Primero se inspecciona (solo lectura) para mostrar qué se va a borrar.
    final current = await cloud.load(
      accountId: id,
      profileId: profileId,
      companionId: companionId,
    );
    if (!mounted) return;
    if (!current.succeeded || current.revision == null) {
      setState(() => cloudNotice = describe(current, ''));
      return;
    }
    adopt(current);
    final ok = await askConfirm(
      title: l.memoryCloudDeleteTitle,
      body: l.memoryCloudDeleteBody(id, formatDate(current.updatedAt!)),
      action: l.memoryCloudDelete,
      destructive: true,
    );
    if (!ok || !mounted) {
      if (mounted) setState(() => cloudNotice = l.memoryCloudDeleteCancelled);
      return;
    }
    final result = await cloud.delete(
      accountId: id,
      profileId: profileId,
      companionId: companionId,
      knownRevision: current.revision!,
    );
    if (!mounted) return;
    setState(() {
      if (result.succeeded) {
        cloudRevision = null;
        cloudUpdatedAt = null;
      }
      cloudNotice = describe(result, l.memoryCloudDeleted(id));
    });
  });

  // ---- UI ----

  String statusLabel(CompanionMemory m) {
    final l = appText(context);
    final status = m.status == MemoryStatus.pendingConfirmation
        ? l.memoryStatusPending
        : l.memoryStatusActive;
    final source = switch (m.source) {
      MemorySource.explicit => l.memorySourceExplicit,
      MemorySource.inferred => l.memorySourceInferred,
      MemorySource.userEdited => l.memorySourceEdited,
    };
    return '$status · $source · ${formatDate(m.updatedAt)}';
  }

  Widget memoryTile(CompanionMemory m) {
    final l = appText(context);
    final pending = m.status == MemoryStatus.pendingConfirmation;
    return Card(
      key: Key('memory-item-${m.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.content, key: Key('memory-text-${m.id}')),
            const SizedBox(height: 4),
            Text(
              statusLabel(m),
              key: Key('memory-meta-${m.id}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Wrap(
              spacing: 8,
              children: [
                if (pending)
                  FilledButton.tonal(
                    key: Key('memory-confirm-${m.id}'),
                    onPressed: busy ? null : () => confirmPending(m),
                    child: Text(l.memoryConfirm),
                  ),
                TextButton(
                  key: Key('memory-edit-${m.id}'),
                  onPressed: busy ? null : () => edit(m),
                  child: Text(l.memoryEdit),
                ),
                TextButton(
                  key: Key('memory-delete-${m.id}'),
                  onPressed: busy ? null : () => deleteLocal(m),
                  child: Text(l.memoryDeleteLocalAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget cloudBlock() {
    final l = appText(context);
    final theme = Theme.of(context);
    return Card(
      key: const Key('memory-cloud'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.memoryCloudTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l.memoryCloudHelp),
            const SizedBox(height: 8),
            if (!cloudAvailable)
              Text(
                l.memoryCloudUnavailable,
                key: const Key('memory-cloud-unavailable'),
              )
            else if (account == null)
              Text(
                l.memoryCloudNoAccount,
                key: const Key('memory-cloud-no-account'),
              )
            else ...[
              Text(
                l.memoryCloudAccount(account!),
                key: const Key('memory-cloud-account'),
              ),
              if (cloudRevision != null && cloudUpdatedAt != null)
                Text(
                  l.memoryCloudLastCopy(
                    formatDate(cloudUpdatedAt!),
                    cloudRevision!,
                  ),
                  key: const Key('memory-cloud-last'),
                ),
            ],
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  key: const Key('memory-cloud-save'),
                  onPressed: busy || !cloudReady ? null : saveCloud,
                  child: Text(l.memoryCloudSave),
                ),
                FilledButton.tonal(
                  key: const Key('memory-cloud-load'),
                  onPressed: busy || !cloudReady ? null : loadCloud,
                  child: Text(l.memoryCloudLoad),
                ),
                OutlinedButton(
                  key: const Key('memory-cloud-delete'),
                  onPressed: busy || !cloudReady ? null : deleteCloud,
                  child: Text(l.memoryCloudDelete),
                ),
              ],
            ),
            if (cloudNotice != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  cloudNotice!,
                  key: const Key('memory-cloud-status'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = appText(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.memoryTitle(widget.companion.name))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l.memoryIntro),
                const SizedBox(height: 12),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      error!,
                      key: const Key('memory-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (notice != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(notice!, key: const Key('memory-notice')),
                  ),
                if (memories.isEmpty)
                  Text(l.memoryEmpty, key: const Key('memory-empty'))
                else
                  for (final m in memories) memoryTile(m),
                const SizedBox(height: 16),
                cloudBlock(),
              ],
            ),
    );
  }
}

/// Diálogo de edición; es dueño de su controlador para liberarlo con seguridad.
class _EditMemoryDialog extends StatefulWidget {
  const _EditMemoryDialog({required this.initial});
  final String initial;

  @override
  State<_EditMemoryDialog> createState() => _EditMemoryDialogState();
}

class _EditMemoryDialogState extends State<_EditMemoryDialog> {
  late final controller = TextEditingController(text: widget.initial);
  String? problem;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = appText(context);
    return AlertDialog(
      title: Text(l.memoryEditTitle),
      content: TextField(
        key: const Key('memory-edit-field'),
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 8,
        decoration: InputDecoration(
          labelText: l.memoryEditLabel,
          errorText: problem,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('memory-edit-cancel'),
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('memory-edit-save'),
          onPressed: () {
            final value = controller.text.trim();
            if (value.isEmpty) {
              setState(() => problem = l.memoryEditEmpty);
            } else if (value.length > CompanionMemory.maxContentLength) {
              setState(() => problem = l.memoryEditTooLong);
            } else {
              Navigator.pop(context, value);
            }
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
