part of '../assistant_chat.dart';

/// Sending a message and recording activities from the chat.
extension _ChatSend on _AssistantChatScreenState {
  /// A point record made from the activity bar shows up as a chat line.
  Future<void> instantRecorded(String text) async {
    messages.add(
      AiMessage('assistant', text, recordedAt: widget.controller.now()),
    );
    if (mounted) update(() {});
    await persist();
  }

  /// A manual edit is kept in the chat as a neutral `event` line (FR-024); it
  /// is never sent to the provider as a message, only summarised in the context.
  Future<void> activityEdited(String text) async {
    messages.add(AiMessage('event', text, recordedAt: widget.controller.now()));
    if (mounted) update(() {});
    await persist();
  }

  /// «Sesión terminada» in game mode, with the records and achievements the
  /// activity brought (FR-035).
  Future<void> activityFinished(FocusActivity activity) async {
    final service = widget.progressService;
    if (service == null) return;
    try {
      final delta = await service.afterChange(
        companionId,
        companionName: widget.companion?.name ?? 'GymBro',
        fields: activity.definition.fields,
        activityId: activity.id,
      );
      unawaited(refreshProgress());
      final settings = await service.progress.settings(companionId);
      if (!settings.game || !mounted) return;
      var seconds = 0;
      for (final i in activity.intervals) {
        if (i.endedAt != null) {
          seconds += i.endedAt!.difference(i.startedAt).inSeconds;
        }
      }
      await showActivitySummary(
        context,
        name: activity.definition.name,
        duration: Duration(seconds: seconds),
        delta: delta,
      );
    } catch (_) {
      // A summary that cannot be calculated never blocks finishing.
    }
  }

  Future<void> sendFocus() async {
    final a = companionFocus;
    final media = attachment;
    if (a == null ||
        (input.text.trim().isEmpty && media == null) ||
        busy ||
        listening) {
      return;
    }
    final text = input.text.trim().isEmpty
        ? 'Interpreta el adjunto de esta actividad.'
        : input.text;
    if (text.length > 8000) {
      update(() => error = 'El registro supera 8000 caracteres.');
      return;
    }
    final interval = a.intervals.lastOrNull?.id;
    update(() {
      busy = true;
      error = null;
      deferredArchive = null;
      partialReply = '';
    });
    scrollToLatest();
    try {
      final messageId = await captureFocusInput();
      if (messageId == null) return;
      await widget.controller.refresh();
      final local = compactStrengthMetrics(text, a.definition);
      if (media == null && local.isNotEmpty) {
        final stored = widget.controller.activities
            .where((item) => item.id == a.id)
            .firstOrNull;
        final ended = stored?.intervals
            .where((item) => item.id == interval)
            .firstOrNull
            ?.endedAt;
        await widget.controller.activityRepository!.recordActivityMessage(
          a.id,
          '${formatWeight(((local['weight_kg'] as num) * 100).round())} kg × ${local['reps']}${local['failure'] == true ? ' · fallo' : ''}${ended == null ? ' · anotado' : ' · fin ${DateFormat('HH:mm:ss').format(ended.toLocal())}'}',
          role: 'assistant',
          intervalId: interval,
        );
        await widget.controller.refresh();
        return;
      }
      final config = await aiStore.load();
      if (!aiReady) {
        error =
            'Registro guardado en el móvil. La IA no está disponible para interpretarlo.';
        return;
      }
      if (config == null) {
        throw const ValidationException(
          'Registro guardado en el móvil. Configura el proveedor para consultar al asistente.',
        );
      }
      final activityHistory = a.messages
          .where((m) => !archivedActivityMessageIds.contains(m.id))
          .toList()
          .reversed
          .take(12)
          .toList()
          .reversed
          .map((m) => AiMessage(m.role, m.text))
          .toList();
      final history = [
        ...messages
            .where((m) => m.role != 'event')
            .skip(messages.length > 12 ? messages.length - 12 : 0),
        ...activityHistory,
      ];
      if (history.firstOrNull?.role == 'assistant') history.removeAt(0);
      await refreshLiveSheet();
      if (!mounted) return;
      final answer = await replyWithArchives(
        config,
        [...history, AiMessage('user', text, attachment: media)],
        system:
            '${contextForAi()}\nEl último mensaje del usuario corresponde a la actividad ${a.id}, tramo ${interval ?? 'sin iniciar'}. Interpreta ese mensaje aunque la pantalla actual haya cambiado. Si contiene resultados claros, añade un bloque trackia-result con JSON: {"metrics": {"clave_de_campo": valor_numérico_booleano_o_texto}}. Para una métrica nueva explícita de este mensaje puedes añadir "fields": [{"key":"clave_de_campo","label":"Etiqueta","unit":"unidad"}]. Mantén significado/unidad de los campos existentes; no los renombres. No inventes valores o métricas no expresadas, ni uses cifras de otros mensajes; en los campos que se suman anota solo la cantidad de este mensaje, nunca un total acumulado; objetivos y sugerencias no son resultados. Si una cifra o unidad es ambigua, pregunta en lugar de estructurarla. Las observaciones se conservan en el original; comenta lo pertinente brevemente.',
        sessionId: sessionId,
        onText: receiveText,
      );
      await aiStore.markVerified(config);
      final block = RegExp(
        r'```trackia-result\s*\n([\s\S]*?)```',
      ).allMatches(answer).toList();
      if (block.length == 1) {
        try {
          final result =
              jsonDecode(block.single.group(1)!) as Map<String, dynamic>;
          if (result.keys.toSet().difference({'metrics', 'fields'}).isEmpty &&
              result['metrics'] is Map<String, dynamic>) {
            await widget.controller.activityRepository!
                .interpretActivityMessage(
                  messageId,
                  result['metrics'] as Map<String, dynamic>,
                  fields: (result['fields'] as List? ?? [])
                      .map((f) => Map<String, Object>.from(f as Map))
                      .toList(),
                );
          }
        } on ValidationException {
          /* Keep original and reply when interpretation is invalid. */
        } on FormatException {
          /* A malformed block cannot alter the original. */
        } on TypeError {
          /* Unsupported output remains conversational text. */
        }
      }
      await widget.controller.activityRepository!.recordActivityMessage(
        a.id,
        answer,
        role: 'assistant',
        intervalId: interval,
      );
      await widget.controller.refresh();
      if (mounted) await handleCompletedActions(answer);
      recalledArchive = null;
    } on ValidationException catch (e) {
      error = e.message;
      if (aiReady && media == null) availability.failed();
    } catch (_) {
      error = 'No se pudo consultar al asistente. Revisa el registro local.';
      if (media == null) availability.failed();
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

  Future<void> send({String? retry, bool includeAttachment = true}) async {
    if (widget.focusMode && companionFocus != null && retry == null) {
      await sendFocus();
      return;
    }
    if (!aiReady) return;
    final media = includeAttachment ? attachment : null;
    final typed = retry ?? input.text.trim();
    final text = typed.isEmpty && media != null
        ? 'Ayúdame a interpretar este adjunto en el contexto del entrenamiento.'
        : typed;
    if (busy || listening || text.isEmpty) return;
    if (text.length > 8000) {
      update(() => error = 'El mensaje supera 8000 caracteres.');
      return;
    }
    final previousPending = pending;
    update(() {
      busy = true;
      error = null;
      pending = text;
      deferredArchive = null;
      partialReply = '';
    });
    scrollToLatest();
    try {
      final config = await aiStore.load();
      if (config == null) {
        throw const ValidationException(
          'Configura el proveedor con el botón de ajustes para empezar.',
        );
      }
      final outgoing = AiMessage(
        'user',
        media == null ? text : '$text\n[Adjunto enviado: ${media.name}]',
        attachment: media,
        recordedAt: widget.controller.now(),
      );
      final last = messages.lastOrNull;
      final reuse =
          previousPending == text &&
          last?.role == 'user' &&
          last?.text == outgoing.text &&
          last?.attachment?.mime == media?.mime &&
          listEquals(last?.attachment?.bytes, media?.bytes);
      final previous = reuse
          ? messages.take(messages.length - 1).toList()
          : messages.toList();
      final history = previous
          .where((m) => m.role != 'event')
          .toList()
          .skip(previous.length > 20 ? previous.length - 20 : 0)
          .toList();
      if (!reuse) messages.add(outgoing);
      try {
        await persist();
      } catch (_) {
        if (!reuse) messages.remove(outgoing);
        error =
            'No se pudo guardar el mensaje en el móvil. Conserva el texto y vuelve a intentarlo.';
        return;
      }
      if (mounted) update(() {});
      // Do not begin provider history with an orphan assistant message.
      if (history.isNotEmpty && history.first.role == 'assistant') {
        history.removeAt(0);
      }
      await refreshLiveSheet();
      if (!mounted) return;
      final answer = await replyWithArchives(
        config,
        [...history, AiMessage('user', text, attachment: media)],
        system: contextForAi(),
        sessionId: sessionId,
        onText: receiveText,
      );
      if (!mounted) return;
      if (widget.focusMode && !hasBlock(answer, 'sheet-edit')) {
        proposal = ActivityDefinition.proposal(answer);
      }
      if (widget.focusMode &&
          hasBlock(answer, 'activity') &&
          proposal == null) {
        error =
            'El modelo envió una propuesta incompleta. Pídele que prepare de nuevo el ejercicio para mostrar Iniciar.';
      }
      await aiStore.markVerified(config);
      messages.add(
        AiMessage('assistant', answer, recordedAt: widget.controller.now()),
      );
      try {
        pending = null;
        await persist();
        if (mounted && retry == null) input.clear();
        if (includeAttachment) attachment = null;
        if (widget.focusMode && proposal != null && !canRecord && aiReady) {
          await acceptProposal();
        }
        if (mounted) await handleCompletedActions(answer);
        recalledArchive = null;
      } catch (_) {
        error =
            'La respuesta llegó, pero no se pudo guardar la conversación en el móvil.';
      }
    } on ValidationException catch (e) {
      error = e.message;
      if (media == null) availability.failed();
    } catch (_) {
      error =
          'No se pudo completar la conversación. Puedes volver a intentarlo.';
      if (media == null) availability.failed();
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
}
