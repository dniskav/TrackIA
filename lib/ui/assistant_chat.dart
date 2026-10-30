import 'rule_text.dart';
import 'game_proposal_cards.dart';
import '../domain/reminder.dart';
import '../domain/assistant_blocks.dart';
import '../application/progress_engine.dart'
    show GeneratedAchievement, ruleHash;
import '../data/chat_store.dart';
import '../application/progress_service.dart';
import 'activity_summary.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../application/assistant_context.dart';
import '../application/workout_controller.dart';
import '../application/ai_availability.dart';
import '../application/rest_notifications.dart';
import '../data/ai_client.dart';
import '../data/ai_settings_store.dart';
import '../data/sheet_context_store.dart';
import 'proposal_card.dart';
import '../domain/sheet_context.dart';
import '../domain/workout.dart';
import '../domain/ai_config.dart';
import '../domain/block_names.dart';
import 'ai_settings.dart';
import 'google_sheets_import.dart';
import 'data_transfer.dart';
import 'session_control.dart';
import 'activity_focus.dart';
import 'chat_message.dart';
import '../domain/activity.dart';
import '../data/profile_store.dart';
import 'accounts.dart';
import '../data/chat_archive_store.dart';
import 'archived_chats.dart';
import 'sheet_sync.dart';
import '../domain/sheet_sync.dart';
import '../application/sheet_automation.dart';
import '../data/companion_store.dart';
import '../domain/companion.dart';
import 'companion_style.dart';

part 'chat/chat_send.dart';
part 'chat/chat_header.dart';

part 'chat/chat_archive.dart';
part 'chat/chat_attachments.dart';

part 'chat/chat_game.dart';
part 'chat/chat_sheet.dart';

/// Mensaje de confirmación tras guardar tiempos propuestos por la IA. Lo no
/// propuesto se toma de la definición actual de la actividad.
@visibleForTesting
String savedTimingsMessage(
  ActivityDefinition definition,
  Map<String, int> proposal,
) {
  String clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  final activitySeconds =
      proposal['activitySeconds'] ?? definition.activitySeconds;
  final restSeconds = proposal['restSeconds'] ?? definition.restSeconds;
  final targetCycles = proposal['targetCycles'] ?? definition.targetCycles;
  final duration = activitySeconds == null
      ? 'sin límite'
      : clock(activitySeconds);
  final cycles = targetCycles == null ? '' : ', $targetCycles ciclos';
  return 'Tiempos guardados en la actividad: $duration por tramo, '
      '${clock(restSeconds)} de descanso$cycles. '
      'Los avisos se enviarán si Android los permite.';
}

class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({
    super.key,
    required this.controller,
    this.client,
    this.onTraining,
    this.onData,
    this.focusMode = false,
    this.availability,
    this.companion,
    this.onSwitchCompanion,
    this.onCompanionSettings,
    this.progressService,
    this.onProgress,
    this.chatStore,
    this.onRemindersChanged,
  });
  final WorkoutController controller;
  final AiClient? client;
  final VoidCallback? onTraining;
  final Future<void> Function()? onData;
  final bool focusMode;
  final AiAvailability? availability;
  final Companion? companion;

  /// Called when the user picks another companion from the title. The host
  /// decides how to navigate; without it the picker only closes.
  final void Function(Companion)? onSwitchCompanion;

  /// Opens «Modo y avisos» of this chat's companion; without it the menu has
  /// no such entry.
  final VoidCallback? onCompanionSettings;

  /// Evaluates goals and achievements after an activity; without it the chat
  /// shows no summary and adds no progress to the context.
  final ProgressService? progressService;

  /// Opens «Progreso» of this chat's companion.
  final VoidCallback? onProgress;

  /// Where this chat and its archives are kept (SQLite and files, FR-040). The
  /// app passes it; without it the chat uses the old secure-storage keys.
  final ChatStore? chatStore;

  /// Told after reminder texts change, so the phone gets a fresh snapshot.
  final VoidCallback? onRemindersChanged;
  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen>
    with WidgetsBindingObserver {
  /// `setState` for the extensions in `chat/`, which cannot call it directly.
  void update(VoidCallback fn) => setState(fn);

  late final profileId = widget.controller.profileId;
  late final companionId = widget.companion?.id ?? 'gymbro';
  late final sheetStore = SheetContextStore(
    profileId: profileId,
    companionId: companionId,
  );
  // The companion's own model (US11), if it has one; the key is the profile's.
  // Read once on opening: sending a message must not wait on the database.
  AiOverride? aiOverride;
  late final Future<void> aiOverrideReady = readAiOverride();
  late final aiStore = AiSettingsStore(
    profileId: profileId,
    exception: () async {
      // Normally already read; never hold the message back for long.
      await aiOverrideReady.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {},
      );
      return aiOverride;
    },
  );

  Future<void> readAiOverride() async {
    try {
      aiOverride =
          (await widget.controller.progress?.settings(companionId))?.aiOverride;
    } catch (error) {
      debugPrint('AI override not read: ${error.runtimeType}');
    }
  }
  late final archiveStore = ChatArchiveStore(
    profileId: profileId,
    companionId: companionId,
    chats: widget.chatStore,
  );
  final archivedActivityMessageIds = <String>{};
  List<Map<String, dynamic>> archives = [];
  String carryForward = '';
  Map<String, dynamic>? deferredArchive;
  Map<String, dynamic>? recalledArchive;
  bool userDragging = false;
  final input = TextEditingController();
  final composerFocus = FocusNode();
  bool composing = false;
  bool keyboardWasVisible = false;
  final scroll = ScrollController();
  bool scrollScheduled = false;
  bool followingLatest = true;
  String activityTranscriptRevision = '';
  final messages = <AiMessage>[];
  String sessionId = const Uuid().v4();
  bool busy = true;
  String? error;
  String? pending;
  String partialReply = '';
  final speech = SpeechToText();
  bool listening = false;
  bool voiceStarting = false;
  AiAttachment? attachment;
  SheetContext? sheetContext;
  ActivityDefinition? proposal;
  List<LockedProposal>? lockedProposals;
  String? focusId;
  String preparationDraft = '';
  Timer? draftTimer;
  Future<void> draftTail = Future.value();
  Future<void> captureTail = Future.value();
  int inputRevision = 0;
  final capturedInputs = <String>{};
  late final AiAvailability availability;
  late final RestNotificationController notifications;
  Timer? connectionTimer;
  late final sheets = SheetAutomation(
    widget.controller,
    client: widget.client,
    companionId: companionId,
  );
  bool sheetTaskRunning = false;
  Completer<void>? sheetTaskDone;
  String? sheetReadWarning;
  String? sheetQuestionWorkoutId;
  Map<String, dynamic>? sheetConnectionForAi;
  List<Map<String, dynamic>> pendingSheetsForAi = [];
  bool get aiReady => availability.ready;
  bool ownsActivity(FocusActivity activity) =>
      activity.definition.companionId == companionId;
  Iterable<FocusActivity> get companionActivities =>
      widget.controller.activities.where(ownsActivity);
  FocusActivity? get companionFocus {
    final focus = widget.controller.focus;
    return focus != null && ownsActivity(focus) ? focus : null;
  }

  bool get canRecord => widget.focusMode && companionFocus != null;
  FocusActivity? get recoverablePreparation => companionActivities
      .where(
        (a) =>
            !a.active &&
            a.intervals.isEmpty &&
            a.finishIssues.contains('not_started') &&
            a.workoutId == widget.controller.active?.id,
      )
      .firstOrNull;
  List<AiMessage> get transcript {
    if (!widget.focusMode) return messages;
    return [
      ...messages,
      for (final a in companionActivities)
        for (final m in a.messages)
          if (!archivedActivityMessageIds.contains(m.id))
            AiMessage(m.role, m.text, recordedAt: m.recordedAt),
    ]..sort(
      (a, b) => (a.recordedAt ?? DateTime(1900)).compareTo(
        b.recordedAt ?? DateTime(1900),
      ),
    );
  }

  Future<void> closeDay() async {
    final active = widget.controller.active;
    if (companionId == 'gymbro' &&
        active != null &&
        widget.controller.focus == null) {
      await finishSession(
        context,
        widget.controller,
        active,
        title: 'Finalizar día',
      );
    }
  }

  void availabilityChanged() {
    if (mounted) setState(() {});
  }

  void sheetChanged() => unawaited(reloadSheet());
  bool sameSheet(SheetContext? a, SheetContext? b) =>
      a != null &&
      b != null &&
      jsonEncode(a.toJson()) == jsonEncode(b.toJson());

  Future<void> settings() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AiSettingsScreen(profileId: profileId),
      ),
    );
    if (mounted) {
      setState(() => error = null);
      await availability.check(acceptRecentVerification: true);
    }
  }

  void focusChanged() {
    if (!widget.focusMode || !mounted) return;
    final revision = jsonEncode([
      for (final activity in companionActivities)
        for (final message in activity.messages)
          [message.id, message.text, message.recordedAt.toIso8601String()],
    ]);
    if (revision != activityTranscriptRevision) {
      activityTranscriptRevision = revision;
      scheduleScrollToLatest();
      unawaited(refreshProgress());
    }
    final a = companionFocus;
    if (a?.id == focusId) return;
    if (focusId == null) preparationDraft = input.text;
    draftTimer?.cancel();
    focusId = a?.id;
    inputRevision++;
    input.removeListener(draftChanged);
    input.text = a?.draft ?? preparationDraft;
    input.addListener(draftChanged);
    if (a != null) proposal = null;
    if (lockedProposals != null) lockedProposals = null;
  }

  void draftChanged() {
    inputRevision++;
    if (!widget.focusMode || focusId == null) return;
    draftTimer?.cancel();
    final id = focusId!, text = input.text;
    draftTimer = Timer(
      const Duration(milliseconds: 300),
      () => queueDraft(id, text),
    );
  }

  void composerChanged() {
    final next = composerFocus.hasFocus || input.text.trim().isNotEmpty;
    if (mounted && next != composing) setState(() => composing = next);
  }

  bool get chatInUse =>
      busy ||
      composing ||
      listening ||
      voiceStarting ||
      attachment != null ||
      MediaQuery.viewInsetsOf(context).bottom > 0;

  @override
  void didChangeMetrics() {
    final visible = View.of(context).viewInsets.bottom > 0;
    if (keyboardWasVisible && !visible) composerFocus.unfocus();
    keyboardWasVisible = visible;
    scheduleScrollToLatest();
  }

  /// Periodic checks read encrypted storage and may reach Google Sheets, so
  /// they only run while the app is visible; resuming checks right away.
  void startConnectionTimer() {
    connectionTimer?.cancel();
    connectionTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!busy && !listening) {
        unawaited(availability.check());
        unawaited(runSheetQueue());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startConnectionTimer();
    } else {
      connectionTimer?.cancel();
      connectionTimer = null;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(availability.check());
      unawaited(refreshLiveSheet());
      unawaited(runSheetQueue());
      unawaited(notifications.initialize());
    }
    if (state != AppLifecycleState.resumed &&
        widget.focusMode &&
        focusId != null) {
      draftTimer?.cancel();
      queueDraft(focusId!, input.text);
    }
  }

  void queueDraft(String id, String text) {
    draftTail = draftTail
        .catchError((_) {})
        .then(
          (_) =>
              widget.controller.activityRepository!.setActivityDraft(id, text),
        );
    unawaited(
      draftTail.catchError((_) {
        if (mounted) {
          setState(
            () => error =
                'No se pudo guardar el borrador. Conserva el texto y vuelve a intentarlo.',
          );
        }
      }),
    );
  }

  Future<void> flushFocusInput() async {
    if (speech.isListening) await speech.stop();
    if (mounted) setState(() => listening = false);
    await captureFocusInput();
    await widget.controller.refresh();
  }

  Future<String?> captureFocusInput() {
    final a = companionFocus;
    if (a == null) return Future.value();
    final media = attachment;
    final text = input.text.trim().isEmpty && media != null
        ? 'Interpreta el adjunto de esta actividad.'
        : input.text;
    if (text.trim().isEmpty) return Future.value();
    final revision = inputRevision, token = '${a.id}:$inputRevision';
    final interval = a.intervals.lastOrNull?.id;
    draftTimer?.cancel();
    final task = captureTail.catchError((_) {}).then((_) async {
      if (capturedInputs.contains(token)) return null;
      await draftTail;
      final id = await widget.controller.activityRepository!
          .recordActivityMessage(
            a.id,
            media == null ? text : '$text\n[Adjunto: ${media.name}]',
            intervalId: interval,
            media: media == null
                ? null
                : ActivityMedia(
                    name: media.name,
                    mime: media.mime,
                    bytes: media.bytes,
                  ),
          );
      capturedInputs.add(token);
      if (capturedInputs.length > 100) {
        capturedInputs.remove(capturedInputs.first);
      }
      if (mounted && focusId == a.id && inputRevision == revision) {
        input.clear();
      }
      if (attachment == media) attachment = null;
      return id;
    });
    captureTail = task.then((_) {});
    unawaited(captureTail.catchError((_) {}));
    return task;
  }

  void scrollToLatest() {
    if (mounted) setState(() => followingLatest = true);
    userDragging = false;
    scheduleScrollToLatest();
  }

  void scheduleScrollToLatest() {
    if (!mounted || scrollScheduled) return;
    scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollScheduled = false;
      if (mounted && followingLatest && !userDragging && scroll.hasClients) {
        // Re-evaluate after layout/metrics changes until the actual tail is
        // laid out. Never move a viewport that the user is reading manually.
        if (scroll.position.extentAfter > 0.5) {
          scroll.jumpTo(scroll.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    unawaited(aiOverrideReady);
    input.addListener(composerChanged);
    composerFocus.addListener(composerChanged);
    availability =
        widget.availability ??
        AiAvailability(client: widget.client, store: aiStore);
    notifications = RestNotificationController(
      widget.controller,
      beforeStart: widget.focusMode ? flushFocusInput : null,
    );
    notifications.addListener(availabilityChanged);
    unawaited(notifications.initialize());
    availability.addListener(availabilityChanged);
    SheetContextStore.changes.addListener(sheetChanged);
    unawaited(availability.check());
    unawaited(recoverPhoto());
    startConnectionTimer();
    widget.controller.addListener(sheetActivityChanged);
    WidgetsBinding.instance.addObserver(this);
    if (widget.focusMode) {
      widget.controller.addListener(focusChanged);
      focusChanged();
      input.addListener(draftChanged);
    }
    load();
    unawaited(refreshProgress());
  }

  Future<void> load() async {
    try {
      final json = await archiveStore.active();
      if (!mounted) return;
      if (json != null) {
        sessionId = json['sessionId'] as String;
        sheetQuestionWorkoutId = json['sheetQuestionWorkoutId'] as String?;
        archives = ChatArchiveStore.index(json);
        archivedActivityMessageIds.addAll(
          List<String>.from(json['archivedActivityMessageIds'] as List? ?? []),
        );
        carryForward = json['carryForward'] as String? ?? '';
        if (json['deferredArchive'] is Map) {
          deferredArchive = Map<String, dynamic>.from(
            json['deferredArchive'] as Map,
          );
        }
        messages.addAll(
          (json['messages'] as List).map(
            (m) => AiMessage.fromStorage(Map<String, dynamic>.from(m as Map)),
          ),
        );
        pending = json['pending'] as String?;
        if (pending == null &&
            json['composerDraft'] is Map &&
            companionFocus == null) {
          final draft = AiMessage.fromStorage(
            Map<String, dynamic>.from(json['composerDraft'] as Map),
          );
          input.text = draft.text;
          attachment = draft.attachment;
        }
        if (pending != null && companionFocus == null) {
          input.text = pending!;
          attachment = messages.lastOrNull?.attachment;
          error =
              'Tu mensaje quedó guardado sin respuesta. Puedes volver a enviarlo.';
        }
      }
    } catch (_) {
      if (mounted) error = 'No se pudo recuperar la conversación anterior.';
    } finally {
      try {
        final saved = await sheetStore.load();
        if (mounted) sheetContext = saved;
      } catch (_) {
        if (mounted) {
          error =
              'No se pudo recuperar la hoja guardada. Vuelve a cargarla desde Google Sheets.';
        }
      }
      if (mounted) {
        setState(() => busy = false);
        scrollToLatest();
        unawaited(resumeDeferredArchive());
        unawaited(runSheetQueue());
      }
    }
  }

  Future<void> persist() async {
    final value = jsonEncode(chatState());
    if (utf8.encode(value).length > 20 * 1024 * 1024) {
      throw const ValidationException(
        'El chat supera 20 MB; no se pudo guardar completo.',
      );
    }
    await archiveStore.saveActive(chatState());
  }

  Map<String, dynamic> chatState({bool includeDraft = false}) => {
    'sessionId': sessionId,
    'messages': messages.map((m) => m.forStorage()).toList(),
    'pending': pending,
    'archives': archives,
    'archivedActivityMessageIds': archivedActivityMessageIds.toList(),
    'carryForward': carryForward,
    'deferredArchive': deferredArchive,
    'sheetQuestionWorkoutId': sheetQuestionWorkoutId,
    'composerDraft': includeDraft
        ? AiMessage('user', input.text, attachment: attachment).forStorage()
        : null,
  };

  bool get canArchive =>
      !(busy ||
          listening ||
          voiceStarting ||
          pending != null ||
          transcript.isEmpty);

  bool get canCloseDay =>
      companionId == 'gymbro' &&
      widget.controller.active != null &&
      widget.controller.focus == null;

  /// Streak, today's goal and today's achievements for the AI context; null
  /// outside game mode.
  Map<String, dynamic>? progressContext;

  /// Goal, achievement and reminder-text proposals waiting for a decision.
  List<GameProposalData> gameCards = [];
  bool gameBusy = false;

  /// The offer to switch to game mode (research D15); hidden for this session
  /// with «Ahora no» and for good with «No volver a sugerir».
  bool gameSuggestionDue = false;
  bool suggestionHidden = false;

  /// Up to two of the proposed texts, filled in with this companion's data.
  Future<List<String>> copyExamples(
    ProgressService service,
    ReminderTemplates copy,
    Map<String, String> labels,
  ) async {
    final state = await service.state(companionId);
    final now = widget.controller.now();
    ReminderEntry entry(DateTime lastActivity) => ReminderEntry(
      id: 'example',
      companionId: companionId,
      companionName: widget.companion?.name ?? 'GymBro',
      days: 127,
      windowStartMin: 0,
      windowEndMin: 1,
      tone: 'neutral',
      paused: false,
      streak: state.streak.current,
      goalText: state.goal == null ? null : goalText(state.goal!, labels),
      lastActivityDate: reminderDay(lastActivity),
      templates: ReminderTemplates.defaults(
        tone: 'neutral',
        companionId: companionId,
        custom: copy,
      ),
    );
    final yesterday = now.subtract(const Duration(days: 1));
    final away = now.subtract(const Duration(days: 3));
    return [
      if (copy.windowStart.isNotEmpty)
        renderReminder(entry(yesterday), ReminderKind.windowStart, now),
      if (copy.lastCall.isNotEmpty)
        renderReminder(entry(yesterday), ReminderKind.lastCall, now),
      if (copy.inactive.isNotEmpty)
        renderReminder(entry(away), ReminderKind.windowStart, now),
    ].take(2).toList();
  }

  void ignoreGameCard(GameProposalData card) => setState(
    () => gameCards = [
      for (final c in gameCards)
        if (c != card) c,
    ],
  );

  List<String> get recentEvents => [
    for (final m
        in messages
            .where((m) => m.role == 'event')
            .toList()
            .reversed
            .take(5)
            .toList()
            .reversed)
      m.text,
  ];

  bool get noticesOff =>
      notifications.supported &&
      !(notifications.enabled && notifications.granted);
  VoidCallback? get enableNotices =>
      notifications.busy ? null : () => unawaited(notifications.toggle(true));

  String contextForAi() => buildAssistantContext(
    AssistantContextInput(
      controller: widget.controller,
      companionId: companionId,
      companion: widget.companion,
      companionActivities: companionActivities,
      companionFocus: companionFocus,
      focusMode: widget.focusMode,
      transcriptLength: transcript.length,
      carryForward: carryForward,
      archives: archives,
      recalledArchive: recalledArchive,
      archivedActivityMessageIds: archivedActivityMessageIds,
      sheetContext: sheetContext,
      sheetReadWarning: sheetReadWarning,
      sheetQuestionWorkoutId: sheetQuestionWorkoutId,
      sheetConnectionForAi: sheetConnectionForAi,
      recentEvents: recentEvents,
      progress: progressContext,
      pendingSheetsForAi: pendingSheetsForAi,
    ),
  );

  @override
  void dispose() {
    connectionTimer?.cancel();
    widget.controller.removeListener(sheetActivityChanged);
    notifications.removeListener(availabilityChanged);
    notifications.dispose();
    SheetContextStore.changes.removeListener(sheetChanged);
    availability.removeListener(availabilityChanged);
    if (widget.availability == null) availability.dispose();
    WidgetsBinding.instance.removeObserver(this);
    draftTimer?.cancel();
    if (widget.focusMode) {
      widget.controller.removeListener(focusChanged);
      if (focusId != null) queueDraft(focusId!, input.text);
      input.removeListener(draftChanged);
    }
    if (speech.isListening) speech.cancel();
    input.removeListener(composerChanged);
    composerFocus.removeListener(composerChanged);
    composerFocus.dispose();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: widget.focusMode
            ? companionTitle(context)
            : Text(widget.companion?.name ?? 'TrackIA'),
        actions: widget.focusMode
            ? [chatMenu()]
            : [
                IconButton(
                  tooltip: 'Enviar a Google Sheets',
                  onPressed: busy ? null : () => openSheetSync(),
                  icon: const Icon(Icons.cloud_upload_outlined),
                ),
                IconButton(
                  key: const Key('archive-chat'),
                  tooltip: 'Archivar chat',
                  onPressed: canArchive ? () => archiveChat() : null,
                  icon: const Icon(Icons.archive_outlined),
                ),
                IconButton(
                  tooltip: 'Chats archivados',
                  onPressed: busy ? null : openArchives,
                  icon: const Icon(Icons.inventory_2_outlined),
                ),
                if (widget.onData != null)
                  IconButton(
                    tooltip: 'Tus datos',
                    onPressed: () async {
                      await widget.onData!();
                      if (mounted) await reloadSheet();
                    },
                    icon: const Icon(Icons.folder_open_outlined),
                  ),
                IconButton(
                  tooltip: 'Proveedor de IA',
                  onPressed: busy ? null : settings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!aiReady &&
                canRecord &&
                MediaQuery.viewInsetsOf(context).bottom == 0)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'IA no disponible · puedes parar y guardar notas localmente',
                ),
              ),
            if (!aiReady && !canRecord)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(availability.message),
                    if (availability.status == AiAvailabilityStatus.checking)
                      const LinearProgressIndicator()
                    else
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: settings,
                            child: const Text('Configurar IA'),
                          ),
                          if (availability.status !=
                              AiAvailabilityStatus.unconfigured)
                            TextButton(
                              onPressed: () => availability.check(verify: true),
                              child: const Text(
                                'Verificar conexión · usa tu API',
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            if (!widget.focusMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: widget.focusMode
                      ? ActivityFocusControls(
                          controller: widget.controller,
                          companionId: companionId,
                          flushInput: flushFocusInput,
                          compact: MediaQuery.viewInsetsOf(context).bottom > 0,
                          aiReady: aiReady,
                          hideStart: chatInUse,
                          noticesOff: noticesOff,
                          onEnableNotices: enableNotices,
                          onInstantRecorded: instantRecorded,
                          onActivityEdited: activityEdited,
                          onActivityFinished: activityFinished,
                        )
                      : SessionControl(
                          controller: widget.controller,
                          enabled: aiReady && !busy && !voiceStarting,
                          beforeAction: () async {
                            if (speech.isListening) await speech.stop();
                            if (mounted) {
                              setState(() => listening = false);
                            }
                          },
                          sheetLabel: sheetContext == null
                              ? null
                              : '${sheetContext!.name} / ${sheetContext!.title}',
                        ),
                ),
              ),
            if (!widget.focusMode &&
                widget.onTraining != null &&
                (!widget.focusMode || widget.controller.focus == null) &&
                (!widget.focusMode ||
                    MediaQuery.viewInsetsOf(context).bottom == 0))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) => OutlinedButton.icon(
                    key: const Key('open-training'),
                    onPressed: !aiReady
                        ? null
                        : () async {
                            if (speech.isListening) {
                              await speech.stop();
                            }
                            if (mounted) {
                              setState(() => listening = false);
                              widget.onTraining!();
                            }
                          },
                    icon: const Icon(Icons.fitness_center),
                    label: Text(
                      widget.controller.active == null
                          ? 'Entrenamiento'
                          : 'Entrenamiento · ${widget.controller.active!.name}',
                    ),
                  ),
                ),
              ),
            if (!widget.focusMode &&
                (!widget.focusMode || widget.controller.focus == null) &&
                (!widget.focusMode ||
                    MediaQuery.viewInsetsOf(context).bottom == 0) &&
                (defaultTargetPlatform == TargetPlatform.android ||
                    sheetContext != null))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  key: const Key('assistant-sheet'),
                  onPressed: busy || voiceStarting ? null : manageSheet,
                  icon: const Icon(Icons.table_chart_outlined),
                  label: Text(
                    sheetContext == null
                        ? 'Cargar Google Sheets'
                        : 'Hoja · ${sheetContext!.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Expanded(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) {
                  if (notification.depth == 0 && followingLatest) {
                    scheduleScrollToLatest();
                  }
                  return false;
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.depth != 0) return false;
                    if (notification is ScrollStartNotification &&
                        notification.dragDetails != null) {
                      userDragging = true;
                      if (followingLatest) {
                        setState(() => followingLatest = false);
                      }
                    } else if (notification is ScrollEndNotification &&
                        userDragging) {
                      userDragging = false;
                      final next = notification.metrics.extentAfter <= 24;
                      if (next != followingLatest) {
                        setState(() => followingLatest = next);
                      }
                      if (next) unawaited(resumeDeferredArchive());
                    }
                    return false;
                  },
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: (notification) {
                      if (notification.depth == 0 && !userDragging) {
                        final next =
                            notification.direction == ScrollDirection.idle &&
                            notification.metrics.extentAfter <= 24;
                        if (next != followingLatest) {
                          setState(() => followingLatest = next);
                        }
                      }
                      return false;
                    },
                    child: ListView(
                      key: const Key('assistant-transcript'),
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (sheetContext?.interpretationPending == true &&
                            !canRecord)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Text(
                                  '«${sheetContext!.name}» cargada · pendiente de interpretación. Los datos originales se conservan.',
                                ),
                                if (aiReady)
                                  TextButton(
                                    onPressed: busy ? null : analyzeSheet,
                                    child: const Text(
                                      'Interpretar hoja con IA',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (transcript.isEmpty && companionFocus == null)
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              aiReady
                                  ? '¿Qué te gustaría hacer hoy? Cuéntame y lo organizamos juntos.'
                                  : 'Carga tus datos con + cuando quieras. La IA podrá interpretar su formato cuando esté conectada.',
                            ),
                          ),
                        for (final message in transcript)
                          if (message.role == 'event')
                            Padding(
                              key: const Key('event-line'),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Center(
                                child: Text(
                                  message.text,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            )
                          else
                            Align(
                              alignment: message.role == 'user'
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: ChatMessageBody(
                                    text: message.text,
                                    assistant: message.role == 'assistant',
                                  ),
                                ),
                              ),
                            ),
                        if (proposal != null &&
                            aiReady &&
                            companionFocus == null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    proposal!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${proposal!.repeated ? 'Series / tramos' : 'Actividad continua'} · ${proposal!.restSeconds}s de descanso',
                                  ),
                                  if (proposal!.fields.isNotEmpty)
                                    Text(
                                      proposal!.fields
                                          .map((f) => f['label'])
                                          .join(' · '),
                                    ),
                                  FilledButton(
                                    key: const Key('accept-activity-proposal'),
                                    onPressed: widget.controller.busy
                                        ? null
                                        : acceptProposal,
                                    child: const Text('Preparar'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (lockedProposals != null &&
                            lockedProposals!.isNotEmpty)
                          ProposalCard(
                            proposals: lockedProposals!,
                            onApply: applyLockedProposal,
                            onIgnore: ignoreLockedProposal,
                          ),
                        for (final card in gameCards)
                          GameProposalCard(
                            data: card,
                            busy: gameBusy,
                            onAdd: () => addGameCard(card),
                            onIgnore: () => ignoreGameCard(card),
                          ),
                        if (gameSuggestionDue && !suggestionHidden)
                          GameSuggestionCard(
                            onActivate: activateGameMode,
                            onLater: () =>
                                setState(() => suggestionHidden = true),
                            onNever: neverSuggestGame,
                          ),
                        if (busy && partialReply.isNotEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: ChatMessageBody(
                                text: partialReply,
                                assistant: true,
                              ),
                            ),
                          ),
                        if (busy) ...[
                          const LinearProgressIndicator(),
                          if (partialReply.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Esperando al modelo…'),
                            ),
                        ],
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(error!),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (deferredArchive != null && !followingLatest)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'El asistente archivará este chat cuando vuelvas al final.',
                ),
              ),
            if (!followingLatest)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton.filledTonal(
                    key: const Key('chat-latest'),
                    tooltip: 'Ir al último mensaje',
                    onPressed: returnToLatest,
                    icon: const Icon(Icons.arrow_downward),
                  ),
                ),
              ),
            if (listening &&
                (!widget.focusMode ||
                    MediaQuery.viewInsetsOf(context).bottom == 0))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Escuchando… Revisa el texto y pulsa Enviar.'),
              ),
            if (attachment != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: InputChip(
                  label: Text(
                    attachment!.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  avatar: Icon(
                    attachment!.isImage
                        ? Icons.image_outlined
                        : Icons.audio_file_outlined,
                  ),
                  onDeleted: busy
                      ? null
                      : () => setState(() => attachment = null),
                ),
              ),
            Padding(
              key: const Key('assistant-composer'),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('assistant-attach'),
                    tooltip: 'Adjuntar',
                    onPressed: busy || listening ? null : pickAttachment,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('assistant-input'),
                      controller: input,
                      focusNode: composerFocus,
                      onTapOutside: (_) => composerFocus.unfocus(),
                      enabled:
                          (!busy ||
                              (widget.focusMode && companionFocus != null)) &&
                          (aiReady || canRecord),
                      readOnly: listening || voiceStarting,
                      minLines: 1,
                      maxLines: widget.focusMode
                          ? (MediaQuery.viewInsetsOf(context).bottom > 0
                                ? 1
                                : 2)
                          : 4,
                      decoration: InputDecoration(
                        hintText: aiReady || canRecord
                            ? 'Escribe o dicta tu mensaje…'
                            : 'Conecta tu IA para empezar',
                        suffixIcon: IconButton(
                          key: const Key('assistant-talk'),
                          tooltip: listening
                              ? 'Terminar dictado'
                              : 'Dictar mensaje',
                          onPressed:
                              (!aiReady && !canRecord) ||
                                  voiceStarting ||
                                  (busy && !canRecord)
                              ? null
                              : talk,
                          icon: Icon(
                            listening
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Enviar',
                    onPressed: busy || listening || (!aiReady && !canRecord)
                        ? null
                        : () => send(),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
            if (widget.focusMode)
              ActivityFocusControls(
                controller: widget.controller,
                companionId: companionId,
                flushInput: flushFocusInput,
                aiReady: aiReady,
                hideStart: chatInUse,
                noticesOff: noticesOff,
                onEnableNotices: enableNotices,
                onInstantRecorded: instantRecorded,
                onActivityEdited: activityEdited,
                onActivityFinished: activityFinished,
                compact: MediaQuery.viewInsetsOf(context).bottom > 0,
              ),
            if (notifications.error != null)
              Text(notifications.error!, maxLines: 2),
          ],
        ),
      ),
    ),
  );
}
