part of '../assistant_chat.dart';

/// Game mode in the chat: progress state, trackia-* cards and proposals.
extension _ChatGame on _AssistantChatScreenState {
  /// One decision point: an imported companion carries third-party
  /// instructions, so its actions need an explicit confirmation (T063).
  bool get requiresActionConfirmation => widget.companion?.isImported == true;

  /// Dialog shared by the confirmations of imported companions.
  Future<bool> confirmImportedAction({
    required String title,
    required List<String> lines,
  }) async {
    final l = appText(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        key: const Key('imported-action-dialog'),
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.importedTrustWarning),
              const SizedBox(height: 12),
              for (final line in lines) Text(line),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('imported-action-cancel'),
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('imported-action-confirm'),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l.importedTrustConfirm),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Leaves a neutral `event` line in the chat for a declined action.
  Future<void> recordCancelledAction(String text) => activityEdited(text);

  /// [automatic] is the accept that follows the model's answer without a tap;
  /// the card button is already an explicit user action.
  Future<void> acceptProposal({bool automatic = false}) async {
    if (!aiReady) return;
    final selected = proposal;
    if (selected == null) return;
    if (automatic && requiresActionConfirmation) {
      final l = appText(context);
      final ok = await confirmImportedAction(
        title: l.importedTrustActivityTitle,
        lines: [
          selected.name,
          l.importedTrustActivityRest(selected.restSeconds),
          if (selected.activitySeconds != null)
            l.importedTrustActivityDuration(selected.activitySeconds!),
          if (selected.targetSets != null)
            l.importedTrustActivityTargetSets(selected.targetSets!),
          if (selected.fields.isNotEmpty)
            l.importedTrustActivityFields(
              selected.fields.map((f) => f['label']).join(' · '),
            ),
        ],
      );
      if (!ok) {
        if (mounted) update(() => proposal = null);
        if (mounted) {
          await recordCancelledAction(
            appText(context).importedTrustCancelledActivity(selected.name),
          );
        }
        return;
      }
      if (!mounted) return;
    }
    if (widget.controller.focus != null) {
      if (mounted) {
        update(
          () => error =
              appText(context).chatGameFocusOpen,
        );
      }
      return;
    }
    if (await effectAlreadyApplied('activity', selected.name)) {
      if (mounted) update(() => proposal = null);
      return;
    }
    final ok = await widget.controller.run(() async {
      await widget.controller.activityRepository!.prepareActivity(
        selected.forCompanion(companionId),
      );
    });
    if (ok) {
      await recordEffect(
        'activity',
        selected.name,
        'Preparé la actividad «${selected.name}»',
      );
    }
    if (mounted) {
      update(() {
        if (ok) {
          proposal = null;
        } else {
          error =
              widget.controller.error ??
              appText(context).chatGamePrepareError;
        }
      });
    }
  }

  /// Aplica lo propuesto en la tarjeta FR-023; sigue siendo un cambio de
  /// origen assistant («Aplicar» lo confirma).
  Future<void> applyLockedProposal() async {
    final card = lockedProposals;
    final activity = companionFocus;
    if (card == null || activity == null) return;
    final values = {for (final p in card) p.property: p.proposedValue};
    final lockedKey = lockedTimingKey(values);
    update(() => lockedProposals = null);
    final result = await runTracked(
      () => widget.controller.activityRepository!.setActivityTiming(
        activity.id,
        activitySeconds:
            values['activitySeconds'] ?? activity.definition.activitySeconds,
        restSeconds: values['restSeconds'] ?? activity.definition.restSeconds,
        targetCycles:
            values['targetCycles'] ?? activity.definition.targetCycles,
        source: 'assistant',
      ),
    );
    final applied = result.done;
    if (!applied) {
      await settleEffect(
        'timing',
        lockedKey,
        result.uncertain ? EffectStatus.uncertain : EffectStatus.failed,
      );
    }
    final descanso = values['restSeconds'] ?? activity.definition.restSeconds;
    if (applied) {
      await recordEffect(
        'timing',
        lockedKey,
        'Cambié los tiempos de «${activity.definition.name}» tras tu confirmación',
      );
    }
    await saveSheetReply(
      applied
          ? 'Aplicado: ${descanso ~/ 60}:${(descanso % 60).toString().padLeft(2, '0')} de descanso.'
          : 'No se pudo aplicar la propuesta. Revisa la actividad.',
    );
  }

  /// Clave estable de la propuesta de tiempos fijados por el usuario.
  String lockedTimingKey(Map<String, int?> values) =>
      'locked:${values.entries.map((e) => '${e.key}=${e.value}').join(',')}';

  void ignoreLockedProposal() {
    final card = lockedProposals;
    if (card != null) {
      unawaited(
        settleEffect(
          'timing',
          lockedTimingKey({for (final p in card) p.property: p.proposedValue}),
          EffectStatus.failed,
        ),
      );
    }
    update(() => lockedProposals = null);
    saveSheetReply('Propuesta ignorada; lo fijado por ti sigue igual.');
  }

  Future<void> refreshProgress() async {
    final service = widget.progressService;
    if (service == null) return;
    try {
      final state = await service.state(companionId);
      if (!mounted) return;
      final today = service.today;
      progressContext = state.settings.game
          ? {
              'mode': 'game',
              'currentStreak': state.streak.current,
              'bestStreak': state.streak.best,
              'todayGoal': state.goal == null
                  ? null
                  : {
                      'value': state.goalProgress?.value,
                      'target': state.goal!.target,
                      'met': state.goalProgress?.met,
                      'minimumMet': state.goalProgress?.minimumMet,
                    },
              'unlockedToday': [
                for (final a in state.achievements)
                  if (a.unlock != null &&
                      ProgressService.dayOf(a.unlock!.unlockedAt) == today)
                    a.title,
              ],
            }
          : null;
      final due = state.settings.game
          ? false
          : await service.gameSuggestionDue(companionId);
      if (mounted) update(() => gameSuggestionDue = due);
    } catch (_) {
      // The context simply goes without progress this time.
    }
  }

  Future<Map<String, String>> fieldLabels(ProgressService service) async => {
    for (final f in await service.progress.typedFields(companionId))
      '${f['key']}': '${f['label']}',
  };

  /// The activities of this companion a goal or achievement may refer to.
  Future<Set<String>> activityKeys() async => {
    for (final a in companionActivities) a.definition.activityKey,
    for (final t
        in await widget.controller.templates?.list(companionId: companionId) ??
            const [])
      t.definition.activityKey,
  };

  /// `trackia-goal`, `trackia-achievement` and `trackia-reminder-copy` become
  /// cards in game mode; a rejected block leaves the reply and says so. Nothing
  /// is saved until the user taps «Añadir».
  Future<void> handleGameBlocks(String answer) async {
    final service = widget.progressService;
    if (service == null) return;
    const kinds = ['goal', 'achievement', 'reminder-copy'];
    if (!kinds.any((k) => mentionsBlock(answer, k))) return;
    final l = appText(context);
    final settings = await service.progress.settings(companionId);
    if (!settings.game || !mounted) return;
    final labels = await fieldLabels(service);
    final keys = await activityKeys();
    final cards = <GameProposalData>[];
    var rejected = false;

    if (mentionsBlock(answer, 'goal')) {
      final goal = parseGoalBlock(answer, activityKeys: keys);
      if (goal == null) {
        rejected = true;
      } else {
        cards.add(
          GameProposalData(
            kind: 'goal',
            title: l.chatGameGoalTitle(goalText(goal.rule, labels, l)),
            lines: const [],
            payload: goal,
          ),
        );
      }
    }
    if (mentionsBlock(answer, 'achievement')) {
      final achievement = parseAchievementBlock(answer, activityKeys: keys);
      if (achievement == null) {
        rejected = true;
      } else {
        cards.add(
          GameProposalData(
            kind: 'achievement',
            title: l.chatGameAchievementTitle(achievement.title),
            lines: [ruleText(achievement.rule, labels, l)],
            payload: achievement,
          ),
        );
      }
    }
    if (mentionsBlock(answer, 'reminder-copy')) {
      final copy = parseReminderCopyBlock(answer);
      if (copy == null) {
        rejected = true;
      } else {
        cards.add(
          GameProposalData(
            kind: 'copy',
            title: l.chatGameCopyTitle,
            lines: await copyExamples(service, copy, labels),
            payload: copy,
          ),
        );
      }
    }
    if (rejected) await saveSheetReply(blockRejectedText);
    if (cards.isNotEmpty && mounted) update(() => gameCards = cards);
  }

  Future<void> addGameCard(GameProposalData card) async {
    final l = appText(context);
    final service = widget.progressService;
    if (service == null || gameBusy) return;
    update(() => gameBusy = true);
    String result;
    try {
      switch (card.kind) {
        case 'goal':
          final goal = card.payload as GoalProposal;
          await service.progress.saveGoal(
            companionId,
            goal.rule,
            origin: 'assistant',
          );
          await recordEffect(
            'goal',
            goalText(goal.rule, await fieldLabels(service), l),
            'Añadí la meta «${goalText(goal.rule, await fieldLabels(service), l)}»',
          );
          result = 'Meta añadida. La verás en tu progreso.';
        case 'achievement':
          final proposal = card.payload as AchievementProposal;
          // Only the rule is created; an unlock always comes from saved data.
          final added = await service.progress.ensureAchievements(companionId, [
            GeneratedAchievement(
              rule: proposal.rule,
              title: proposal.title,
              icon: proposal.icon,
              ruleHash: ruleHash(proposal.rule),
            ),
          ], origin: 'assistant');
          if (added > 0) {
            await recordEffect(
              'achievement',
              proposal.title,
              'Añadí el logro «${proposal.title}»',
            );
          }
          result = added > 0
              ? 'Logro añadido: ${proposal.title}.'
              : 'Ya tenías un logro con esa regla.';
        default:
          final copy = card.payload as ReminderTemplates;
          final store = CompanionStore(profileId: profileId);
          final current = (await store.load()).firstWhere(
            (c) => c.id == companionId,
          );
          final old = current.reminderCopy;
          List<String> pick(List<String> mine, List<String>? before) =>
              mine.isNotEmpty ? mine : (before ?? const []);
          await store.upsert(
            current.copyWith(
              reminderCopy: ReminderTemplates(
                windowStart: pick(copy.windowStart, old?.windowStart),
                lastCall: pick(copy.lastCall, old?.lastCall),
                inactive: pick(copy.inactive, old?.inactive),
              ),
            ),
          );
          widget.onRemindersChanged?.call();
          await recordEffect(
            'reminder-copy',
            '${copy.windowStart.length}-${copy.lastCall.length}-${copy.inactive.length}',
            'Guardé textos de recordatorio nuevos',
          );
          result = 'Textos de recordatorio guardados.';
      }
    } catch (_) {
      result = 'No se pudo guardar la propuesta.';
    }
    if (!mounted) return;
    update(() {
      gameBusy = false;
      gameCards = [
        for (final c in gameCards)
          if (c != card) c,
      ];
    });
    await saveSheetReply(result);
    unawaited(refreshProgress());
  }

  Future<void> activateGameMode() async {
    final service = widget.progressService;
    if (service == null) return;
    await service.activateGame(companionId);
    if (!mounted) return;
    update(() => gameSuggestionDue = false);
    await saveSheetReply(
      'Modo Juego activado. Verás tus metas, rachas y logros.',
    );
    unawaited(refreshProgress());
  }

  Future<void> neverSuggestGame() async {
    final service = widget.progressService;
    if (service == null) return;
    await service.dismissGameSuggestion(companionId);
    if (mounted) update(() => gameSuggestionDue = false);
  }
}
