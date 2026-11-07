part of '../assistant_chat.dart';

/// Google Sheets: reading, proposals and the sync queue of the chat.
extension _ChatSheet on _AssistantChatScreenState {
  Future<void> refreshLiveSheet() async {
    await sheetTaskDone?.future;
    if (!mounted) return;
    try {
      final fresh = await sheets.refresh();
      final config = await sheets.service.connection();
      final jobs = await sheets.jobs();
      sheetConnectionForAi = config == null
          ? null
          : {
              'name': config['name'],
              'title': config['title'],
              'automatic': config['automatic'],
              'allowOverwrite': config['allowOverwrite'],
              'layout': config['layout'],
            };
      pendingSheetsForAi = [
        for (final j in jobs)
          if (j['status'] != 'sent' &&
              j['id'] == config?['id'] &&
              j['subject'] == config?['subject'] &&
              j['sheetId'] == config?['sheetId'])
            {
              'workoutId': j['workoutId'],
              'status': j['status'],
              'questionOrError': j['lastError'],
            },
      ];
      if (mounted && fresh != null) {
        update(() {
          sheetContext = fresh;
          sheetReadWarning = null;
        });
      }
    } catch (e) {
      if (mounted) {
        update(
          () => sheetReadWarning =
              'No se pudo leer Google ahora. La copia es de ${sheetContext?.loadedAt.toIso8601String() ?? "fecha desconocida"}; no presentes sus datos como actuales. ${sheetError(e)}',
        );
      }
    }
  }

  String sheetError(Object error) => error is PlatformException
      ? error.message ?? error.code
      : error is ValidationException
      ? error.message
      : error is SheetClarification
      ? error.question
      : 'Comprueba la conexión con Google.';

  Future<void> saveSheetReply(String text) async {
    if (!mounted) return;
    messages.add(
      AiMessage('assistant', text, recordedAt: widget.controller.now()),
    );
    await persist();
    if (mounted) {
      update(() {});
      scheduleScrollToLatest();
    }
  }

  String sheetConversation() => transcript
      .where((m) => m.role != 'event')
      .toList()
      .reversed
      .take(10)
      .toList()
      .reversed
      .map(
        (m) =>
            '${m.role}: ${m.text.replaceAll(hiddenBlockPattern, "")}',
      )
      .join('\n');

  Future<void> synchronizeSheet(String id) async {
    try {
      final receipt = await sheets.synchronize(
        id,
        guidance: sheetConversation(),
      );
      if (!mounted) return;
      sheetQuestionWorkoutId = null;
      if (receipt != null) await saveSheetReply(receipt);
      await reloadSheet();
    } on SheetClarification catch (e) {
      sheetQuestionWorkoutId = id;
      await saveSheetReply(e.question);
    } catch (e) {
      await saveSheetReply(
        'El envío a Google Sheets sigue pendiente. ${sheetError(e)} Los datos del móvil se conservan.',
      );
    }
  }

  Future<void> editSheetFromChat(String answer) async {
    final latestUser = messages.reversed
        .where((m) => m.role == 'user')
        .firstOrNull;
    if (latestUser == null) return;
    final editKey = answer.hashCode.toString();
    if (await effectAlreadyApplied('sheet-edit', editKey)) {
      await saveSheetReply(
        'Esa edición de Google Sheets ya se había aplicado con este mensaje; no se repitió.',
      );
      return;
    }
    // Un acompañante importado trae instrucciones de terceros: antes de
    // tocar la hoja se confirma celda por celda (T063).
    final confirm = requiresActionConfirmation
        ? (SheetEditPreview preview) async {
            if (!mounted) return false;
            final l = appText(context);
            return confirmImportedAction(
              title: l.importedTrustSheetTitle,
              lines: [
                l.importedTrustSheetTarget(preview.sheetName, preview.tab),
                for (final c in preview.cells)
                  l.importedTrustCellLine(
                    c.cell,
                    c.before.isEmpty ? l.importedTrustEmptyValue : c.before,
                    c.after,
                  ),
              ],
            );
          }
        : null;
    // Mientras Google no confirme, el resultado es incierto (también si la app
    // se cierra a mitad); solo la confirmación lo convierte en hecho.
    await recordEffect(
      'sheet-edit',
      editKey,
      'Editar la hoja de Google Sheets',
      status: EffectStatus.uncertain,
    );
    try {
      final receipt = await sheets.directEdit(
        answer,
        '$sessionId:${messages.length}:${latestUser.text}',
        confirm: confirm,
      );
      await recordEffect(
        'sheet-edit',
        editKey,
        'Edité la hoja de Google Sheets',
      );
      if (!mounted) return;
      await saveSheetReply(receipt);
      await reloadSheet();
    } on SheetEditCancelled {
      await settleEffect('sheet-edit', editKey, EffectStatus.failed);
      if (!mounted) return;
      await recordCancelledAction(appText(context).importedTrustCancelledSheet);
    } catch (e) {
      await saveSheetReply(
        'No se pudo confirmar la edición en Google Sheets. ${sheetError(e)} Comprueba la hoja antes de reintentar.',
      );
    }
  }

  void sheetActivityChanged() {
    if (!widget.controller.busy) unawaited(runSheetQueue());
  }

  Future<void> runSheetQueue() async {
    if (!mounted ||
        busy ||
        listening ||
        sheetTaskRunning ||
        sheets.busy ||
        widget.controller.busy ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    sheetTaskRunning = true;
    sheetTaskDone = Completer<void>();
    try {
      await sheets.enqueueCompleted();
      final config = await sheets.service.connection();
      if (config == null || config['automatic'] != true) return;
      final jobs = await sheets.jobs();
      final job = jobs
          .where(
            (j) =>
                j['status'] == 'pending' &&
                j['id'] == config['id'] &&
                j['sheetId'] == config['sheetId'] &&
                j['subject'] == config['subject'] &&
                (j['retryAfter'] == null ||
                    !DateTime.parse(
                      j['retryAfter'] as String,
                    ).isAfter(DateTime.now())),
          )
          .firstOrNull;
      if (job == null) return;
      await synchronizeSheet(job['workoutId'] as String);
    } catch (e) {
      // A profile switch or local storage failure must not create a false receipt.
      if (mounted) update(() => sheetReadWarning = sheetError(e));
    } finally {
      sheetTaskRunning = false;
      sheetTaskDone?.complete();
      sheetTaskDone = null;
    }
  }

  Future<void> reloadSheet() async {
    try {
      final saved = await sheetStore.load();
      if (mounted) update(() => sheetContext = saved);
    } catch (_) {
      if (mounted) {
        update(() => error = appText(context).chatSheetReloadError);
      }
    }
  }

  Future<void> chooseSheet() async {
    if (busy) return;
    if (profileId == 'local') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AccountsScreen()));
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      update(
        () =>
            error = appText(context).chatSheetAndroidOnly,
      );
      return;
    }
    if (speech.isListening) await speech.stop();
    if (!mounted) return;
    update(() => listening = false);
    final selected = await Navigator.of(context).push<SheetContext>(
      MaterialPageRoute(
        builder: (_) => GoogleSheetsImportScreen(
          controller: widget.controller,
          forAssistant: true,
          loadOnly: !aiReady,
        ),
      ),
    );
    if (selected != null && mounted) await useSheet(selected);
  }

  Future<void> useSheet(SheetContext sheet) async {
    update(() {
      busy = true;
      error = null;
    });
    try {
      await sheetStore.save(sheet);
      if (!mounted) return;
      update(() {
        sheetContext = sheet;
        busy = false;
      });
      if (aiReady) await analyzeSheet();
    } catch (_) {
      if (mounted) {
        update(
          () => error =
              appText(context).chatSheetSaveError,
        );
      }
    } finally {
      if (mounted) update(() => busy = false);
    }
  }

  Future<void> analyzeSheet() async {
    final sheet = sheetContext;
    if (sheet == null || !aiReady || busy || canRecord) return;
    await send(
      retry:
          'He cargado la hoja «${sheet.name}», pestaña «${sheet.title}». Lee las celdas del contexto: identifica su estructura y cómo están anotadas las actividades, series, variantes y notas. Dame un resumen breve de los últimos entrenamientos según sus fechas y señala cualquier ambigüedad. Cita las filas que uses. No crees ni modifiques registros.',
      includeAttachment: false,
    );
    if (!mounted || error != null || !sameSheet(sheetContext, sheet)) return;
    if (!sameSheet(await sheetStore.load(), sheet)) return;
    final interpreted = sheet.interpreted();
    try {
      await sheetStore.save(interpreted);
      if (mounted && sameSheet(sheetContext, sheet)) {
        update(() => sheetContext = interpreted);
      }
    } catch (_) {
      if (mounted) {
        update(
          () => error =
              appText(context).chatSheetInterpretPending,
        );
      }
    }
  }

  Future<void> refreshSheet() async {
    final previous = sheetContext;
    if (busy || previous == null) return;
    if (speech.isListening) await speech.stop();
    if (!mounted) return;
    update(() {
      busy = true;
      listening = false;
      error = null;
    });
    try {
      const channel = MethodChannel('com.gymia.app/google-sheets');
      await ProfileStore.instance.authorizeSheets(profileId: profileId);
      if (!mounted) return;
      final rows = await channel.invokeListMethod<dynamic>('read', {
        'id': previous.id,
        'title': previous.title,
        'expectedSubject': ProfileStore.instance.active?.subject,
      });
      if (!mounted) return;
      await useSheet(
        SheetContext(
          id: previous.id,
          name: previous.name,
          title: previous.title,
          loadedAt: DateTime.now(),
          rows: [
            for (final row in rows ?? [])
              [for (final cell in row as List) cell.toString()],
          ],
        ),
      );
    } on PlatformException catch (e) {
      if (mounted) {
        update(
          () => error =
              e.message ??
              appText(context).chatSheetRefreshError,
        );
      }
    } on ValidationException catch (e) {
      if (mounted) update(() => error = e.message);
    } catch (_) {
      if (mounted) {
        update(
          () => error =
              appText(context).chatSheetRefreshError,
        );
      }
    } finally {
      if (mounted) {
        update(() => busy = false);
        if (error != null) scheduleScrollToLatest();
      }
    }
  }

  Future<void> manageSheet() async {
    final sheet = sheetContext;
    if (sheet == null) {
      await chooseSheet();
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sheet.name),
        content: Text(
          appText(context).chatSheetDialogBody(
            sheet.title,
            sheet.rows.length,
            DateFormat('d/M/yyyy HH:mm').format(sheet.loadedAt.toLocal()),
            sheet.interpretationPending
                ? appText(context).chatSheetStatusPending
                : appText(context).chatSheetStatusAnalyzed,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'remove'),
            child: Text(appText(context).chatSheetRemove),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'change'),
            child: Text(appText(context).chatSheetChange),
          ),
          if (sheet.source == 'google')
            FilledButton(
              onPressed: () => Navigator.pop(context, 'refresh'),
              child: Text(appText(context).chatSheetRefresh),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'refresh') await refreshSheet();
    if (choice == 'change') await chooseSheet();
    if (choice == 'remove') {
      try {
        await sheetStore.delete();
        if (mounted) update(() => sheetContext = null);
      } catch (_) {
        if (mounted) {
          update(() => error = appText(context).chatSheetRemoveError);
        }
      }
    }
  }

  Future<void> openSheetSync({Map<String, dynamic>? directive}) async {
    if (speech.isListening) await speech.stop();
    if (!mounted) return;
    update(() => listening = false);
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SheetSyncScreen(
          controller: widget.controller,
          companionId: companionId,
          client: widget.client,
          workoutId: directive?['workoutId'] as String?,
          create: directive?['create'] as bool? ?? false,
          name: directive?['name'] as String?,
        ),
      ),
    );
    if (result != null && mounted) {
      messages.add(
        AiMessage('assistant', result, recordedAt: widget.controller.now()),
      );
      await persist();
      await reloadSheet();
      update(() {});
    }
  }
}
