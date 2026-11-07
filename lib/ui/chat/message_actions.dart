part of '../assistant_chat.dart';

String _onlyLastEditable(BuildContext context) =>
    appText(context).chatMsgOnlyLastEditable;

/// Accessible, ID-based actions for durable user messages.
extension _MessageActions on _AssistantChatScreenState {
  /// Burbuja de chat estilo mensajería: el usuario a la derecha con el color
  /// de acento y el asistente a la izquierda en tono neutro.
  Widget messageBubble(AiMessage message) {
    final isUser = message.role == 'user';
    final scheme = Theme.of(context).colorScheme;
    final id = outgoingMessageIds[message];
    final bubble = assistantBubbleColors(
      companionColor(context, widget.companion?.color ?? 'orange'),
      scheme,
    );
    final VoidCallback? toggle = isUser && id != null
        ? () => toggleMessageActions(id)
        : null;
    const big = Radius.circular(18);
    const small = Radius.circular(4);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.84,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Material(
            key: Key(isUser ? 'bubble-user' : 'bubble-assistant'),
            color: isUser ? userBubbleColor : bubble.fill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: big,
                topRight: big,
                bottomLeft: isUser ? big : small,
                bottomRight: isUser ? small : big,
              ),
              side: isUser
                  ? BorderSide.none
                  : BorderSide(color: bubble.border, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: id == null ? null : Key('message-tap-$id'),
              onTap: toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: isUser ? userBubbleTextColor : scheme.onSurface,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChatMessageBody(
                        text: message.text,
                        assistant: message.role == 'assistant',
                        onTap: toggle,
                      ),
                      messageDeliveryDetails(message),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void toggleMessageActions(String id) => update(() {
    if (!expandedMessageIds.remove(id)) expandedMessageIds.add(id);
  });

  Widget messageDeliveryDetails(AiMessage message) {
    final id = outgoingMessageIds[message];
    if (id == null || message.role != 'user') {
      return const SizedBox.shrink();
    }
    final state = deliveryStates[id] ?? MessageDelivery.pending;
    final label = switch (state) {
      MessageDelivery.pending => appText(context).chatMsgPending,
      MessageDelivery.sending => appText(context).chatMsgSending,
      MessageDelivery.answered => appText(context).chatMsgAnswered,
      MessageDelivery.failed => appText(context).chatMsgFailed,
      MessageDelivery.uncertain =>
        appText(context).chatMsgUncertain,
    };
    // Los detalles solo existen en mensajes del usuario (burbuja de acento).
    final muted = userBubbleTextColor.withValues(alpha: 0.8);
    final stateText = Text(
      label,
      key: Key('delivery-state-$id'),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
    );
    if (!expandedMessageIds.contains(id)) {
      // Los iconos se muestran al tocar el mensaje. Un problema de entrega
      // (pendiente, fallido, incierto) sí queda visible para no ocultarlo.
      if (state == MessageDelivery.answered) return const SizedBox.shrink();
      return Padding(padding: const EdgeInsets.only(top: 6), child: stateText);
    }
    Widget action(
      Key key,
      IconData icon,
      String tooltip,
      VoidCallback? onTap, {
      String? whyDisabled,
    }) {
      final button = IconButton(
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
      if (whyDisabled == null) return button;
      // Deshabilitado, pero al tocarlo se muestra el motivo.
      return GestureDetector(
        key: Key('${(key as ValueKey<String>).value}-why'),
        behavior: HitTestBehavior.opaque,
        onTap: () => update(() => error = whyDisabled),
        child: button,
      );
    }

    final isLast = identical(message, lastUserMessage);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        children: [
          action(
            Key('edit-message-$id'),
            Icons.edit_outlined,
            isLast ? appText(context).edit : _onlyLastEditable(context),
            isLast && !busy && state != MessageDelivery.sending
                ? () => editDurableMessage(message)
                : null,
            whyDisabled: isLast ? null : _onlyLastEditable(context),
          ),
          action(
            Key('history-message-$id'),
            Icons.history,
            appText(context).chatMsgHistory,
            busy ? null : () => showDurableMessageHistory(id),
          ),
          action(
            Key('resend-message-$id'),
            Icons.refresh,
            appText(context).chatMsgResend,
            !busy && aiReady && MessageDeliveryPolicy.canRetry(state)
                ? () => send(retryMessageId: id)
                : null,
          ),
          Padding(padding: const EdgeInsets.only(left: 6), child: stateText),
        ],
      ),
    );
  }

  Future<void> editDurableMessage(AiMessage message) async {
    final repository = messageRevisions;
    final id = outgoingMessageIds[message];
    if (repository == null || id == null) return;
    if (!identical(message, lastUserMessage)) {
      update(() => error = _onlyLastEditable(context));
      return;
    }
    final l = appText(context);
    final item = await repository.loadItem(id);
    if (!mounted) return;
    if (item == null || item.message.chatId != sessionId) return;
    // El controller vive dentro del diálogo (_EditMessageDialog): se destruye
    // cuando su árbol se desmonta, no antes (evitaba '_dependents.isEmpty').
    final sendBlocker = !aiReady
        ? appText(context).chatMsgAiNotReady
        : busy
        ? appText(context).chatMsgSendInProgress
        : null;
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (dialogContext) => _EditMessageDialog(
        initialText: item.revision.text,
        sendBlocker: sendBlocker,
      ),
    );
    final edited = result?.text;
    if (result == null || edited == null) return;
    if (!mounted) return;
    try {
      final latest = await repository.loadItem(id);
      if (latest == null || latest.revision.id != item.revision.id) {
        throw ValidationException(
          l.chatMsgChangedWhileEditing,
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
      if (result.send && !busy && aiReady) {
        update(() => error = null);
        // Decisión de contexto: send(retryMessageId) manda al modelo la
        // revisión vigente (la editada) y, como la respuesta anterior está
        // enlazada a otra revisión, sendDurable la saca del historial (la
        // marca obsoleta, sin borrar nada), la incluye dentro de una nota de
        // edición para el modelo y deja una línea de evento. La nueva
        // respuesta se enlaza a la nueva revisión.
        await send(retryMessageId: id);
      } else {
        update(
          () => error = result.send
              ? appText(context).chatMsgSaveNotSent
              : appText(context).chatMsgSavedOnly,
        );
      }
    } on ValidationException catch (e) {
      update(() => error = e.message);
    } on ArgumentError {
      update(() => error = appText(context).chatMsgLengthError);
    } catch (_) {
      update(
        () => error = appText(context).chatMsgEditError,
      );
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
          title: Text(appText(context).chatMsgHistoryTitle),
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
                          revision.id == loaded.message.currentRevisionId
                              ? appText(context).chatMsgVersionCurrent(revision.revision)
                              : appText(context).chatMsgVersion(revision.revision),
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
              child: Text(appText(context).chatMsgClose),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) update(() => error = appText(context).chatMsgHistoryError);
    }
  }
}

class _EditResult {
  const _EditResult(this.text, {required this.send});
  final String text;
  final bool send;
}

/// Diálogo de edición con su propio controller (creado en initState y
/// destruido en dispose) para no liberarlo mientras el TextField se anima.
class _EditMessageDialog extends StatefulWidget {
  const _EditMessageDialog({required this.initialText, this.sendBlocker});
  final String initialText;
  final String? sendBlocker;

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController editor = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    editor.dispose();
    super.dispose();
  }

  void close({required bool send}) =>
      Navigator.pop(context, _EditResult(editor.text, send: send));

  @override
  Widget build(BuildContext context) {
    final blocker = widget.sendBlocker;
    return AlertDialog(
      title: Text(appText(context).chatMsgEditTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('edit-message-input'),
            controller: editor,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            maxLength: MessageRevision.maxTextLength,
            decoration: InputDecoration(
              labelText: appText(context).chatMsgEditLabel,
              helperText: appText(context).chatMsgEditHelper,
            ),
          ),
          if (blocker != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                appText(context).chatMsgSendBlocked(blocker),
                key: const Key('edit-send-blocker'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel-edit-message'),
          onPressed: () => Navigator.pop(context),
          child: Text(appText(context).cancel),
        ),
        TextButton(
          key: const Key('save-edit-message'),
          onPressed: () => close(send: false),
          child: Text(appText(context).save),
        ),
        FilledButton(
          key: const Key('save-send-edit-message'),
          onPressed: blocker == null ? () => close(send: true) : null,
          child: Text(appText(context).chatMsgSaveAndSend),
        ),
      ],
    );
  }
}
