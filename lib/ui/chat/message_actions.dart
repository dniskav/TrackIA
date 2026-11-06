part of '../assistant_chat.dart';

/// Accessible, ID-based actions for durable user messages.
extension _MessageActions on _AssistantChatScreenState {
  Widget messageDeliveryDetails(AiMessage message) {
    final id = outgoingMessageIds[message];
    if (id == null || message.role != 'user') {
      return const SizedBox.shrink();
    }
    final state = deliveryStates[id] ?? MessageDelivery.pending;
    final label = switch (state) {
      MessageDelivery.pending => 'Pendiente de envío',
      MessageDelivery.sending => 'Enviando',
      MessageDelivery.answered => 'Respondido',
      MessageDelivery.failed => 'No aceptado; puedes reenviar',
      MessageDelivery.uncertain =>
        'Resultado incierto; reenvío bloqueado hasta revisar',
    };
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget action(Key key, IconData icon, String tooltip, VoidCallback? onTap) =>
        IconButton(
          key: key,
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: onTap,
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          color: muted,
        );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        children: [
          action(
            Key('edit-message-$id'),
            Icons.edit_outlined,
            'Editar',
            busy || state == MessageDelivery.sending
                ? null
                : () => editDurableMessage(message),
          ),
          action(
            Key('history-message-$id'),
            Icons.history,
            'Historial',
            busy ? null : () => showDurableMessageHistory(id),
          ),
          action(
            Key('resend-message-$id'),
            Icons.refresh,
            'Reenviar',
            !busy && aiReady && MessageDeliveryPolicy.canRetry(state)
                ? () => send(retryMessageId: id)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              label,
              key: Key('delivery-state-$id'),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> editDurableMessage(AiMessage message) async {
    final repository = messageRevisions;
    final id = outgoingMessageIds[message];
    if (repository == null || id == null) return;
    final item = await repository.loadItem(id);
    if (!mounted) return;
    if (item == null || item.message.chatId != sessionId) return;
    final editor = TextEditingController(text: item.revision.text);
    final edited = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar mensaje'),
        content: TextField(
          key: const Key('edit-message-input'),
          controller: editor,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          maxLength: MessageRevision.maxTextLength,
          decoration: const InputDecoration(
            labelText: 'Texto corregido',
            helperText: 'La versión original se conserva en el historial.',
          ),
        ),
        actions: [
          TextButton(
            key: const Key('cancel-edit-message'),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('save-edit-message'),
            onPressed: () => Navigator.pop(dialogContext, editor.text),
            child: const Text('Guardar edición'),
          ),
        ],
      ),
    );
    editor.dispose();
    if (edited == null || !mounted) return;
    try {
      final latest = await repository.loadItem(id);
      if (latest == null || latest.revision.id != item.revision.id) {
        throw const ValidationException(
          'El mensaje cambió mientras lo editabas. Revisa el historial.',
        );
      }
      final revision = MessageRevision(
        id: const Uuid().v4(),
        messageId: id,
        revision: latest.revision.revision + 1,
        text: edited,
        createdAt: widget.controller.now(),
        supersedesId: latest.revision.id,
      );
      await repository.append(
        id,
        expectedRevisionId: latest.revision.id,
        revision: revision,
      );
      final updated = MessageDeliveryItem(
        message: Message(
          id: id,
          profileId: profileId,
          companionId: companionId,
          chatId: sessionId,
          createdAt: latest.message.createdAt,
          currentRevisionId: revision.id,
          attachmentRefs: latest.message.attachmentRefs,
        ),
        revision: revision,
      );
      replaceOutgoingFromItem(message, updated);
      syncPendingFromDelivery();
      await persist();
      update(() => error = 'Edición guardada. Usa Reenviar para enviar esta versión.');
    } on ValidationException catch (e) {
      update(() => error = e.message);
    } on ArgumentError {
      update(() => error = 'Escribe un mensaje de 1 a 8000 caracteres.');
    } catch (_) {
      update(() => error = 'No se pudo guardar la edición; el original se conserva.');
    }
  }

  Future<void> showDurableMessageHistory(String id) async {
    final repository = messageRevisions;
    if (repository == null) return;
    try {
      final loaded = await repository.load(id);
      if (loaded == null || !mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Historial de versiones'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final revision in loaded.revisions)
                  Padding(
                    key: Key('message-history-${revision.id}'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Versión ${revision.revision}${revision.id == loaded.message.currentRevisionId ? ' · actual' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SelectableText(revision.text),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) update(() => error = 'No se pudo abrir el historial.');
    }
  }
}
