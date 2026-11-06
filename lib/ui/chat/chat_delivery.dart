part of '../assistant_chat.dart';

/// SQLite v7 delivery bridge for the active transcript. The legacy path in
/// `chat_send.dart` remains intact for chats without a [ChatStore].
extension _ChatDelivery on _AssistantChatScreenState {
  Future<void> initializeMessageDelivery() async {
    try {
      final repository = widget.messageRevisionRepository;
      if (repository != null) {
        messageRevisions = repository;
      } else if (widget.chatStore != null) {
        messageRevisions = await MessageRevisionRepository.fromChatStore(
          widget.chatStore!,
          FeatureScope(profileId: profileId, companionId: companionId),
        );
      }
      if (messageRevisions != null) {
        messageDelivery = MessageDeliveryService(messageRevisions!);
      }
    } catch (_) {
      deliveryInitializationFailed = true;
      error =
          'No se pudo abrir la cola durable del chat. No se enviarán mensajes por un almacenamiento alternativo.';
    }
  }

  AiMessage restoreTranscriptMessage(Map<String, dynamic> raw) {
    final message = AiMessage.fromStorage(raw);
    messages.add(message);
    final id = raw['id'];
    final revisionId = raw['currentRevisionId'];
    if (message.role == 'user' && id is String && revisionId is String) {
      outgoingMessageIds[message] = id;
      outgoingRevisionIds[message] = revisionId;
      outgoingRevisionTexts[message] =
          raw['revisionText'] as String? ?? message.text;
      if (raw['deliverySchema'] == 1) durableTranscriptIds.add(id);
      final delivery = raw['delivery'];
      if (delivery is String) {
        try {
          deliveryStates[id] = MessageDelivery.values.byName(delivery);
        } on ArgumentError {
          // v7 remains authoritative; an unknown mirror is rebuilt below.
        }
      }
    }
    final responseTo = raw['responseTo'];
    final responseRevision = raw['responseRevisionId'];
    if (message.role == 'assistant' &&
        responseTo is String &&
        responseRevision is String) {
      responseLinks[message] = (
        messageId: responseTo,
        revisionId: responseRevision,
      );
    }
    return message;
  }

  void restoreComposerDraft(Map<String, dynamic> json) {
    if (json['composerDraft'] is! Map || companionFocus != null) return;
    final draft = AiMessage.fromStorage(
      Map<String, dynamic>.from(json['composerDraft'] as Map),
    );
    input.text = draft.text;
    attachment = draft.attachment;
  }

  void restoreLegacyPending(Map<String, dynamic> json) {
    if (pending == null) restoreComposerDraft(json);
    if (pending != null && companionFocus == null) {
      input.text = pending!;
      attachment = messages.lastOrNull?.attachment;
      error = 'Tu mensaje quedó guardado sin respuesta. Puedes volver a enviarlo.';
    }
  }

  Future<void> restoreDurableDelivery(Map<String, dynamic> json) async {
    final repository = messageRevisions!;
    // Only records written by this bridge are recovered. Historical payload
    // messages are not assigned synthetic delivery states.
    for (final message in messages.toList(growable: false)) {
      final id = outgoingMessageIds[message];
      if (id == null ||
          !durableTranscriptIds.contains(id) ||
          await repository.load(id) != null) {
        continue;
      }
      final revisionId = outgoingRevisionIds[message]!;
      final createdAt = message.recordedAt ?? widget.controller.now();
      final media = message.attachment;
      await repository.create(
        Message(
          id: id,
          profileId: profileId,
          companionId: companionId,
          chatId: sessionId,
          createdAt: createdAt,
          currentRevisionId: revisionId,
          attachmentRefs: [
            if (media != null) ChatStore.hashOf(media.bytes),
          ],
        ),
        MessageRevision(
          id: revisionId,
          messageId: id,
          revision: 1,
          text: outgoingRevisionTexts[message]!,
          createdAt: createdAt,
        ),
      );
    }

    await messageDelivery!.openScope(chatId: sessionId);
    final items = await repository.chatMessages(sessionId);
    if (items.isEmpty) {
      restoreLegacyPending(json);
      return;
    }
    deliveryStates.clear();
    for (final item in items) {
      deliveryStates[item.message.id] = item.message.delivery;
      final index = messages.indexWhere(
        (message) => outgoingMessageIds[message] == item.message.id,
      );
      if (index >= 0) {
        replaceOutgoingFromItem(messages[index], item);
      } else {
        final restored = AiMessage(
          'user',
          durableDisplayText(item.revision.text, null),
          recordedAt: item.message.createdAt,
        );
        messages.add(restored);
        registerOutgoing(restored, item);
      }
    }
    syncPendingFromDelivery();
    if (pending == null && !hasDeliveryBacklog) restoreComposerDraft(json);
    if (hasDeliveryBacklog) {
      error = deliveryStates.values.contains(MessageDelivery.uncertain)
          ? 'Hay un envío con resultado incierto. No se reenviará automáticamente; revisa el historial antes de decidir.'
          : 'Tienes mensajes guardados sin respuesta. Usa Reenviar cuando quieras; no se enviarán automáticamente.';
    }
  }

  String durableDisplayText(String text, AiAttachment? media) =>
      media == null ? text : '$text\n[Adjunto enviado: ${media.name}]';

  void registerOutgoing(AiMessage message, MessageDeliveryItem item) {
    outgoingMessageIds[message] = item.message.id;
    outgoingRevisionIds[message] = item.revision.id;
    outgoingRevisionTexts[message] = item.revision.text;
    durableTranscriptIds.add(item.message.id);
    deliveryStates[item.message.id] = item.message.delivery;
  }

  AiMessage replaceOutgoingFromItem(
    AiMessage previous,
    MessageDeliveryItem item,
  ) {
    final index = messages.indexOf(previous);
    final replacement = AiMessage(
      'user',
      durableDisplayText(item.revision.text, previous.attachment),
      attachment: previous.attachment,
      recordedAt: previous.recordedAt ?? item.message.createdAt,
    );
    if (index >= 0) messages[index] = replacement;
    outgoingMessageIds.remove(previous);
    outgoingRevisionIds.remove(previous);
    outgoingRevisionTexts.remove(previous);
    registerOutgoing(replacement, item);
    return replacement;
  }

  void syncPendingFromDelivery() {
    pending = null;
    for (final message in messages) {
      final id = outgoingMessageIds[message];
      if (id == null) continue;
      final state = deliveryStates[id];
      if (state == MessageDelivery.pending || state == MessageDelivery.failed) {
        pending = outgoingRevisionTexts[message] ?? message.text;
        return;
      }
    }
  }

  Map<String, dynamic> messageStorage(AiMessage message) {
    final result = message.forStorage();
    final id = outgoingMessageIds[message];
    if (id != null) {
      result.addAll({
        'deliverySchema': 1,
        'id': id,
        'chatId': sessionId,
        'currentRevisionId': outgoingRevisionIds[message],
        'revisionText': outgoingRevisionTexts[message],
        'delivery': (deliveryStates[id] ?? MessageDelivery.pending).name,
      });
    }
    final response = responseLinks[message];
    if (response != null) {
      result['responseTo'] = response.messageId;
      result['responseRevisionId'] = response.revisionId;
    }
    return result;
  }

  void clearDeliveryMetadata() {
    outgoingMessageIds.clear();
    outgoingRevisionIds.clear();
    outgoingRevisionTexts.clear();
    durableTranscriptIds.clear();
    responseLinks.clear();
    deliveryStates.clear();
    pending = null;
  }

  List<AiMessage> durableHistory(AiMessage outgoing, String outgoingId) {
    final candidates = messages
        .where((message) => message != outgoing && message.role != 'event')
        .toList(growable: false);
    final recentStart = candidates.length > 20 ? candidates.length - 20 : 0;
    final history = <AiMessage>[];
    for (var index = 0; index < candidates.length; index++) {
      final message = candidates[index];
      final id = outgoingMessageIds[message];
      final state = id == null ? null : deliveryStates[id];
      final unresolved = id != outgoingId &&
          state != null &&
          state != MessageDelivery.answered;
      if (index >= recentStart || unresolved) history.add(message);
    }
    if (history.isNotEmpty && history.first.role == 'assistant') {
      history.removeAt(0);
    }
    return history;
  }

  Future<void> sendDurable({
    String? retry,
    bool includeAttachment = true,
    String? retryMessageId,
  }) async {
    final repository = messageRevisions!;
    if (!aiReady) return;
    final previousPending = pending;
    final retryBubble = retryMessageId == null
        ? null
        : messages
              .where((message) => outgoingMessageIds[message] == retryMessageId)
              .firstOrNull;
    if (retryMessageId != null && retryBubble == null) return;
    final media = includeAttachment
        ? (retryBubble?.attachment ?? attachment)
        : null;
    final typed = retry ?? input.text.trim();
    final text = retryBubble == null
        ? (typed.isEmpty && media != null
              ? 'Ayúdame a interpretar este adjunto en el contexto del entrenamiento.'
              : typed)
        : '';
    if (busy || listening || (retryBubble == null && text.isEmpty)) return;
    if (retryBubble == null && text.length > 8000) {
      update(() => error = 'El mensaje supera 8000 caracteres.');
      return;
    }

    AiMessage? outgoing = retryBubble;
    MessageDeliveryItem? item;
    if (retryMessageId != null) {
      item = await repository.loadItem(retryMessageId);
      if (item == null || item.message.chatId != sessionId) {
        update(() => error = 'El mensaje pertenece a otro chat y no se enviará aquí.');
        return;
      }
      if (!MessageDeliveryPolicy.canRetry(item.message.delivery)) {
        update(() => error = 'Este mensaje no es seguro de reenviar.');
        return;
      }
    }

    update(() {
      busy = true;
      error = null;
      deferredArchive = null;
      partialReply = '';
    });
    scrollToLatest();
    var attemptStarted = false;
    var dispatched = false;
    try {
      if (outgoing == null) {
        final last = messages.lastOrNull;
        final display = durableDisplayText(text, media);
        final reuse = previousPending == text &&
            last?.role == 'user' &&
            last?.text == display &&
            last?.attachment?.mime == media?.mime &&
            listEquals(last?.attachment?.bytes, media?.bytes);
        if (reuse) outgoing = last;
      }

      if (outgoing == null) {
        final id = const Uuid().v4();
        final revisionId = const Uuid().v4();
        final createdAt = widget.controller.now();
        item = MessageDeliveryItem(
          message: Message(
            id: id,
            profileId: profileId,
            companionId: companionId,
            chatId: sessionId,
            createdAt: createdAt,
            currentRevisionId: revisionId,
            attachmentRefs: [
              if (media != null) ChatStore.hashOf(media.bytes),
            ],
          ),
          revision: MessageRevision(
            id: revisionId,
            messageId: id,
            revision: 1,
            text: text,
            createdAt: createdAt,
          ),
        );
        await repository.create(item.message, item.revision);
        outgoing = AiMessage(
          'user',
          durableDisplayText(text, media),
          attachment: media,
          recordedAt: createdAt,
        );
        registerOutgoing(outgoing, item);
        messages.add(outgoing);
      } else {
        final id = outgoingMessageIds[outgoing];
        if (id == null) {
          // A v6 pending bubble becomes durable only on this explicit retry.
          final newId = const Uuid().v4();
          final revisionId = const Uuid().v4();
          final createdAt = outgoing.recordedAt ?? widget.controller.now();
          item = MessageDeliveryItem(
            message: Message(
              id: newId,
              profileId: profileId,
              companionId: companionId,
              chatId: sessionId,
              createdAt: createdAt,
              currentRevisionId: revisionId,
              attachmentRefs: [
                if (media != null) ChatStore.hashOf(media.bytes),
              ],
            ),
            revision: MessageRevision(
              id: revisionId,
              messageId: newId,
              revision: 1,
              text: text,
              createdAt: createdAt,
            ),
          );
          await repository.create(item.message, item.revision);
          registerOutgoing(outgoing, item);
        } else {
          item = await repository.loadItem(id);
          if (item == null) throw StateError('Falta el mensaje durable.');
        }
      }
      syncPendingFromDelivery();
      await persist();
      if (mounted) update(() {});

      final config = await aiStore.load();
      if (config == null) {
        throw const ValidationException(
          'Configura el proveedor con el botón de ajustes para empezar.',
        );
      }
      await refreshLiveSheet();
      if (!mounted) return;

      final current = item;
      final attempt = await messageDelivery!.begin(
        current.message.id,
        expectedRevisionId: current.revision.id,
      );
      if (attempt == null) {
        final latest = await repository.loadItem(current.message.id);
        if (latest != null) {
          replaceOutgoingFromItem(outgoing, latest);
        }
        syncPendingFromDelivery();
        await persist();
        throw const ValidationException(
          'El mensaje ya cambió de estado; no se hizo otro envío.',
        );
      }
      attemptStarted = true;
      item = attempt;
      replaceOutgoingFromItem(outgoing, attempt);
      outgoing = messages
          .where((message) => outgoingMessageIds[message] == attempt.message.id)
          .first;
      syncPendingFromDelivery();
      await persist();

      final expectedTargetActivity = widget.focusMode ? companionFocus : null;
      String answer;
      try {
        dispatched = true;
        answer = await replyWithArchives(
          config,
          [
            ...durableHistory(outgoing, attempt.message.id),
            AiMessage('user', attempt.revision.text, attachment: media),
          ],
          system: contextForAi(),
          sessionId: sessionId,
          onText: receiveText,
        );
      } on ValidationException catch (e) {
        await failDurableAttempt(attempt, acceptanceKnown: false);
        error = e.message;
        if (media == null) availability.failed();
        return;
      } catch (_) {
        await failDurableAttempt(attempt, acceptanceKnown: false);
        error =
            'El resultado del envío es incierto. No se reenviará automáticamente; comprueba si llegó una respuesta.';
        if (media == null) availability.failed();
        return;
      }

      final answerStatus = await messageDelivery!.answer(
        attempt.message.id,
        expectedRevisionId: attempt.revision.id,
      );
      if (answerStatus == MessageAnswerStatus.superseded) {
        final latest = await repository.loadItem(attempt.message.id);
        if (latest != null) deliveryStates[latest.message.id] = latest.message.delivery;
      } else {
        deliveryStates[attempt.message.id] = MessageDelivery.answered;
      }
      await appendDurableAnswer(attempt, answer, answerStatus);
      if (!mounted) return;

      try {
        await aiStore.markVerified(config);
      } catch (_) {
        // The response is already durable; verification can be checked later.
      }
      if (answerStatus != MessageAnswerStatus.superseded) {
        if (widget.focusMode &&
            !hasBlock(answer, 'sheet-edit') &&
            !hasBlock(answer, 'activity-target')) {
          proposal = ActivityDefinition.proposal(answer);
        }
        if (retry == null && retryMessageId == null) input.clear();
        if (includeAttachment && retryMessageId == null) attachment = null;
        if (answerStatus == MessageAnswerStatus.recorded) {
          if (widget.focusMode && proposal != null && !canRecord && aiReady) {
            await acceptProposal();
          }
          await handleCompletedActions(
            answer,
            expectedTargetActivity: expectedTargetActivity,
          );
        }
        recalledArchive = null;
      }
    } on ValidationException catch (e) {
      if (attemptStarted && !dispatched) {
        await failDurableAttempt(item!, acceptanceKnown: true);
      }
      error = e.message;
    } catch (_) {
      if (attemptStarted && !dispatched) {
        await failDurableAttempt(item!, acceptanceKnown: true);
      }
      error =
          'No se pudo completar la conversación. El mensaje permanece guardado; no se hará un reenvío automático.';
    } finally {
      if (mounted) {
        update(() {
          busy = false;
          partialReply = '';
        });
        scheduleScrollToLatest();
        unawaited(resumeDeferredArchive());
        unawaited(runSheetQueue());
      }
    }
  }

  Future<void> failDurableAttempt(
    MessageDeliveryItem attempt, {
    required bool acceptanceKnown,
  }) async {
    final state = await messageDelivery!.failure(
      attempt.message.id,
      expectedRevisionId: attempt.revision.id,
      acceptanceKnown: acceptanceKnown,
    );
    if (state != null) deliveryStates[attempt.message.id] = state;
    syncPendingFromDelivery();
    if (mounted) {
      await persist();
    } else {
      await persistDetachedDelivery(attempt.message.chatId, attempt.message.id);
    }
  }

  Future<void> appendDurableAnswer(
    MessageDeliveryItem attempt,
    String answer,
    MessageAnswerStatus status,
  ) async {
    if (!mounted) {
      await persistDetachedAnswer(attempt, answer, status);
      return;
    }
    final exists = responseLinks.values.any(
      (link) =>
          link.messageId == attempt.message.id &&
          link.revisionId == attempt.revision.id,
    );
    if (!exists) {
      final response = AiMessage(
        'assistant',
        answer,
        recordedAt: widget.controller.now(),
      );
      responseLinks[response] = (
        messageId: attempt.message.id,
        revisionId: attempt.revision.id,
      );
      messages.add(response);
    }
    syncPendingFromDelivery();
    try {
      await persist();
    } catch (_) {
      error = 'La respuesta llegó, pero no se pudo guardar la conversación en el móvil.';
    }
  }

  Future<void> persistDetachedDelivery(String chatId, String messageId) async {
    final state = await archiveStore.active();
    if (state == null || state['sessionId'] != chatId) return;
    final rawMessages = (state['messages'] as List)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    for (final raw in rawMessages) {
      if (raw['id'] == messageId) raw['delivery'] = deliveryStates[messageId]?.name;
    }
    state['messages'] = rawMessages;
    final queue = await messageRevisions!.queue(chatId);
    state['pending'] = queue.firstOrNull?.revision.text;
    await archiveStore.saveActive(state);
  }

  Future<void> persistDetachedAnswer(
    MessageDeliveryItem attempt,
    String answer,
    MessageAnswerStatus status,
  ) async {
    final state = await archiveStore.active();
    if (state == null || state['sessionId'] != attempt.message.chatId) return;
    final rawMessages = (state['messages'] as List)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    final exists = rawMessages.any(
      (raw) =>
          raw['responseTo'] == attempt.message.id &&
          raw['responseRevisionId'] == attempt.revision.id,
    );
    if (!exists) {
      rawMessages.add({
        'role': 'assistant',
        'content': answer,
        'recordedAt': widget.controller.now().toIso8601String(),
        'responseTo': attempt.message.id,
        'responseRevisionId': attempt.revision.id,
      });
    }
    if (status != MessageAnswerStatus.superseded) {
      for (final raw in rawMessages) {
        if (raw['id'] == attempt.message.id) raw['delivery'] = 'answered';
      }
    }
    state['messages'] = rawMessages;
    final queue = await messageRevisions!.queue(attempt.message.chatId);
    state['pending'] = queue.firstOrNull?.revision.text;
    await archiveStore.saveActive(state);
  }
}
