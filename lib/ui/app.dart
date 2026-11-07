import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/generated/app_localizations.dart';
import '../application/locale_settings.dart';
import '../application/workout_controller.dart';
import '../domain/workout.dart';
import 'theme.dart';
import '../data/theme_settings.dart';
import '../data/welcome_settings_store.dart';
import 'welcome.dart';
import 'data_transfer.dart';
import 'assistant_chat.dart';
import 'companions.dart';
import 'companion_settings.dart';
import 'progress_screen.dart';
import '../application/progress_service.dart';
import '../application/reminder_scheduler.dart';
import '../data/companion_store.dart';
import '../data/ai_settings_store.dart';
import 'settings.dart';
import '../domain/companion.dart';
import 'gym_home.dart';
export 'gym_home.dart';
export 'gym_widgets.dart';
export 'theme.dart' show gymTheme;

class GymApp extends StatelessWidget {
  const GymApp({super.key, required this.controller});
  final WorkoutController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ThemeSettings.instance,
    builder: (context, _) => ListenableBuilder(
      listenable: LocaleSettings.instance,
      builder: (context, _) => MaterialApp(
        title: 'TrackIA',
        debugShowCheckedModeBanner: false,
        theme: gymLightTheme,
        darkTheme: gymTheme,
        themeMode: ThemeSettings.instance.mode,
        locale: LocaleSettings.instance.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: GymRoot(controller: controller),
      ),
    ),
  );
}

class GymRoot extends StatefulWidget {
  const GymRoot({super.key, required this.controller});
  final WorkoutController controller;
  @override
  State<GymRoot> createState() => _TrackiaRootState();
}

class _TrackiaRootState extends State<GymRoot> {
  static const _importChannel = MethodChannel('com.gymia.app/import');
  bool takingImport = false;
  bool showingWelcome = false;
  String? activeCompanionId;

  /// Keeps the phone's reminders in step with what the user records.
  late final ProgressService? progressService =
      widget.controller.progress == null
      ? null
      : ProgressService(progress: widget.controller.progress!);

  void openProgress(Companion companion) {
    final service = progressService;
    if (service == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProgressScreen(service: service, companion: companion),
      ),
    );
  }

  late final ReminderScheduler? reminders = widget.controller.progress == null
      ? null
      : ReminderScheduler(
          progress: widget.controller.progress!,
          companions: () =>
              CompanionStore(profileId: widget.controller.profileId).load(),
          doneDays: progressService!.doneDays,
          // Las frases por defecto siguen el idioma activo de la app.
          phrases: () => reminderPhrasesFor(
            lookupAppLocalizations(
              Locale(LocaleSettings.instance.assistantLanguage),
            ),
          ),
        );

  /// A tapped reminder opens that companion's chat; one of another profile
  /// leaves the app on the dashboard.
  Future<void> _openFromReminder() async {
    final scheduler = reminders;
    if (scheduler == null || !mounted) return;
    final pending = await scheduler.takePendingOpen();
    if (pending == null || !mounted) return;
    final companion = ReminderScheduler.resolveOpen(
      pending,
      currentProfileId: widget.controller.profileId,
      companions: await CompanionStore(
        profileId: widget.controller.profileId,
      ).load(),
    );
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (companion != null) openCompanion(companion);
  }

  /// Las frases de los recordatorios van en el snapshot que ya tiene Android:
  /// al cambiar de idioma hay que reenviarlo.
  void _languageChanged() => unawaited(reminders?.sync());

  void openCompanionSettings(Companion companion) {
    final progress = widget.controller.progress;
    if (progress == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanionSettingsScreen(
          progress: progress,
          store: CompanionStore(profileId: widget.controller.profileId),
          companion: companion,
          scheduler: reminders,
          aiStore: AiSettingsStore(profileId: widget.controller.profileId),
          // Sin adaptador de Google Drive (T030) las acciones de nube salen
          // deshabilitadas; la memoria local ya se puede consultar y editar.
          memory: widget.controller.companionMemory,
          templates: widget.controller.templates,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_maybeWelcome);
    LocaleSettings.instance.addListener(_languageChanged);
    reminders?.attach(widget.controller);
    // Attachments no chat refers to any more (a deleted companion) go away.
    unawaited(widget.controller.chats?.gcMedia());
    unawaited(reminders?.sync());
    _importChannel.setMethodCallHandler((call) async {
      if (call.method == 'importReady') await _takeIncomingImport();
    });
    ReminderScheduler.channel.setMethodCallHandler((call) async {
      if (call.method == 'openAvailable') await _openFromReminder();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _takeIncomingImport();
      _maybeWelcome();
      await _openFromReminder();
    });
  }

  void _maybeWelcome() {
    if (!mounted ||
        showingWelcome ||
        takingImport ||
        !WelcomeSettings.instance.loaded ||
        widget.controller.focus != null ||
        !WelcomeSettings.instance.autoShow ||
        WelcomeSettings.instance.offeredThisLaunch) {
      return;
    }
    WelcomeSettings.instance.offeredThisLaunch = true;
    showingWelcome = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const WelcomeScreen(preselectNeverAgain: true),
        ),
      );
      showingWelcome = false;
    });
    // The dashboard does not rebuild when an activity ends. Request a frame
    // so the deferred route opens even if nothing else changes visually.
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _takeIncomingImport() async {
    if (takingImport || !mounted) return;
    takingImport = true;
    try {
      while (mounted) {
        final file = await _importChannel.invokeMapMethod<String, dynamic>(
          'takePendingImport',
        );
        if (file == null) break;
        final bytes = file['bytes'];
        if (bytes is! Uint8List) {
          throw const ValidationException(
            'No se pudo leer la copia compartida.',
          );
        }
        if (!mounted) break;
        await openImportDocument(
          context,
          widget.controller,
          bytes,
          name: file['name'] as String? ?? 'Hoja cargada',
          companionId: activeCompanionId ?? 'gymbro',
        );
      }
    } on MissingPluginException {
      // The shared-file channel is provided by Android only.
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'No se pudo abrir la copia compartida.'),
          ),
        );
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      takingImport = false;
      _maybeWelcome();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_maybeWelcome);
    LocaleSettings.instance.removeListener(_languageChanged);
    reminders?.dispose();
    _importChannel.setMethodCallHandler(null);
    ReminderScheduler.channel.setMethodCallHandler(null);
    super.dispose();
  }

  Route<void> companionRoute(Companion companion) => MaterialPageRoute<void>(
    builder: (_) => AssistantChatScreen(
      key: ValueKey(companion.id),
      controller: widget.controller,
      chatStore: widget.controller.chats,
      companion: companion,
      focusMode: true,
      onSwitchCompanion: switchCompanion,
      onCompanionSettings: () => openCompanionSettings(companion),
      progressService: progressService,
      onProgress: () => openProgress(companion),
      onRemindersChanged: () => unawaited(reminders?.sync()),
      onTraining: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GymHome(
            controller: widget.controller,
            onAssistant: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      onData: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DataTransferScreen(
            controller: widget.controller,
            companionId: companion.id,
          ),
        ),
      ),
    ),
  );

  void openCompanion(Companion companion) {
    activeCompanionId = companion.id;
    Navigator.of(context).push(companionRoute(companion)).then((_) {
      // A replacement already set the new companion: do not clear it.
      if (activeCompanionId == companion.id) activeCompanionId = null;
    });
  }

  /// Picking another companion in the chat title replaces the chat, so back
  /// returns to the dashboard instead of stacking one chat per switch.
  void switchCompanion(Companion companion) {
    activeCompanionId = companion.id;
    Navigator.of(context).pushReplacement(companionRoute(companion)).then((_) {
      if (activeCompanionId == companion.id) activeCompanionId = null;
    });
  }

  @override
  Widget build(BuildContext context) => CompanionDashboard(
    profileId: widget.controller.profileId,
    progress: widget.controller.progress,
    templates: widget.controller.templates,
    onCompanionSettings: openCompanionSettings,
    progressService: progressService,
    onProgress: openProgress,
    onRemindersChanged: () => unawaited(reminders?.sync()),
    onOpen: openCompanion,
    onSettings: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(controller: widget.controller),
      ),
    ),
  );
}
