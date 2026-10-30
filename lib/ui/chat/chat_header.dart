part of '../assistant_chat.dart';

/// App bar of the chat: companion title, switcher and menu.
extension _ChatHeader on _AssistantChatScreenState {
  /// Companion icon and name; tapping it switches to another companion.
  Widget companionTitle(BuildContext context) {
    final current = widget.companion ?? Companion.suggestions.first;
    return InkWell(
      key: const Key('companion-switcher'),
      borderRadius: BorderRadius.circular(8),
      onTap: switchCompanion,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompanionAvatar(companion: current, radius: 14),
            const SizedBox(width: 8),
            Flexible(
              child: Text(current.name, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }

  Future<void> switchCompanion() async {
    final current = widget.companion ?? Companion.suggestions.first;
    final List<Companion> all;
    try {
      all = await CompanionStore(profileId: profileId).load();
    } catch (_) {
      if (mounted) {
        update(() => error = 'No se pudieron cargar los acompañantes.');
      }
      return;
    }
    if (!mounted) return;
    final chosen = await showModalBottomSheet<Companion>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in all)
              ListTile(
                key: Key('switch-to-${c.id}'),
                leading: CompanionAvatar(companion: c),
                title: Text(c.name),
                subtitle: c.description.isEmpty ? null : Text(c.description),
                trailing: c.id == current.id ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(sheetContext, c),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && chosen.id != current.id) {
      widget.onSwitchCompanion?.call(chosen);
    }
  }

  PopupMenuItem<String> menuItem(
    String key,
    String value,
    IconData icon,
    String label, {
    bool enabled = true,
    String? detail,
  }) => PopupMenuItem<String>(
    key: Key(key),
    value: value,
    enabled: enabled,
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (detail != null)
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );

  /// Actions of this companion's chat. App-wide settings live in Ajustes.
  Widget chatMenu() => PopupMenuButton<String>(
    key: const Key('chat-menu'),
    tooltip: 'Más opciones',
    onSelected: onMenu,
    itemBuilder: (_) => [
      if (widget.onTraining != null)
        menuItem(
          'menu-training',
          'training',
          Icons.history,
          'Rutinas e historial',
          enabled: aiReady,
        ),
      if (widget.onProgress != null)
        menuItem(
          'menu-progress',
          'progress',
          Icons.emoji_events_outlined,
          'Progreso',
        ),
      if (widget.onCompanionSettings != null)
        menuItem(
          'menu-companion-settings',
          'companion-settings',
          Icons.tune,
          'Modo y avisos',
        ),
      menuItem(
        'menu-sheet-sync',
        'sheet-sync',
        Icons.cloud_upload_outlined,
        'Enviar a Google Sheets',
        enabled: !busy && !voiceStarting,
      ),
      menuItem(
        'archive-chat',
        'archive',
        Icons.archive_outlined,
        'Archivar chat',
        enabled: canArchive,
      ),
      menuItem(
        'menu-archives',
        'archives',
        Icons.inventory_2_outlined,
        'Chats archivados',
        enabled: !busy,
      ),
      menuItem(
        'menu-sheet',
        'sheet',
        Icons.table_chart_outlined,
        'Hoja cargada',
      ),
      if (canCloseDay)
        menuItem(
          'menu-close-day',
          'close-day',
          Icons.flag_outlined,
          'Finalizar día',
        ),
      if (!canRecord && recoverablePreparation != null)
        menuItem(
          'menu-recover',
          'recover',
          Icons.restore,
          'Recuperar preparación',
          detail: recoverablePreparation!.definition.name,
        ),
    ],
  );

  void onMenu(String value) {
    switch (value) {
      case 'training':
        widget.onTraining?.call();
      case 'companion-settings':
        widget.onCompanionSettings?.call();
      case 'progress':
        widget.onProgress?.call();
      case 'sheet-sync':
        unawaited(openSheetSync());
      case 'archive':
        unawaited(archiveChat());
      case 'archives':
        unawaited(openArchives());
      case 'sheet':
        unawaited(manageSheet());
      case 'close-day':
        unawaited(closeDay());
      case 'recover':
        final a = recoverablePreparation;
        if (a == null) return;
        unawaited(
          widget.controller.run(
            () => widget.controller.activityRepository!
                .resumeActivityPreparation(a.id),
          ),
        );
    }
  }
}
