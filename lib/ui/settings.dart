import 'package:flutter/material.dart';
import '../application/ai_availability.dart';
import '../application/rest_notifications.dart';
import '../application/workout_controller.dart';
import '../application/locale_settings.dart';
import '../application/localization.dart';
import '../l10n/generated/app_localizations.dart';
import '../data/ai_settings_store.dart';
import '../data/profile_store.dart';
import '../data/theme_settings.dart';
import 'accounts.dart';
import 'ai_settings.dart';
import 'appearance.dart';
import 'data_transfer.dart';
import 'notification_settings.dart';
import 'welcome.dart';

/// App-wide settings, reachable from the dashboard without opening a
/// companion. Each row shows the current state of what it opens.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    this.availability,
    this.notifications,
  });

  final WorkoutController controller;
  final AiAvailability? availability;
  final RestNotificationController? notifications;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AiAvailability availability =
      widget.availability ??
      AiAvailability(
        store: AiSettingsStore(profileId: widget.controller.profileId),
      );
  late final RestNotificationController notifications =
      widget.notifications ?? RestNotificationController(widget.controller);
  final theme = ThemeSettings.instance;
  final profiles = ProfileStore.instance;
  final localeSettings = LocaleSettings.instance;

  @override
  void initState() {
    super.initState();
    availability.check(acceptRecentVerification: true);
    notifications.initialize();
  }

  @override
  void dispose() {
    if (widget.availability == null) availability.dispose();
    if (widget.notifications == null) notifications.dispose();
    super.dispose();
  }

  Future<void> open(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    // The AI provider or the notice preference may have changed.
    if (!mounted) return;
    availability.check(acceptRecentVerification: true);
    notifications.initialize();
  }

  String get aiState => switch (availability.status) {
    AiAvailabilityStatus.ready => availability.message.replaceFirst(
      'IA verificada',
      appText(context).verified,
    ),
    AiAvailabilityStatus.unconfigured => appText(context).notConnected,
    AiAvailabilityStatus.unverified => appText(context).notVerified,
    AiAvailabilityStatus.unavailable => appText(context).unavailable,
    AiAvailabilityStatus.checking => appText(context).checking,
  };

  String appearanceState(AppLocalizations l) => switch (theme.mode) {
    ThemeMode.system => l.automatic,
    ThemeMode.light => l.light,
    ThemeMode.dark => l.dark,
  };

  Widget section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Widget row({
    required Key key,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget screen,
  }) => ListTile(
    key: key,
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => open(screen),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appText(context).settings)),
    body: ListenableBuilder(
      listenable: Listenable.merge([
        availability,
        notifications,
        theme,
        profiles,
        localeSettings,
      ]),
      builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          section(context, appText(context).assistant),
          row(
            key: const Key('settings-ai'),
            icon: Icons.auto_awesome_outlined,
            title: appText(context).artificialIntelligence,
            subtitle: aiState,
            screen: AiSettingsScreen(
              profileId: widget.controller.profileId,
              progress: widget.controller.progress,
            ),
          ),
          section(context, appText(context).yourData),
          row(
            key: const Key('settings-account'),
            icon: Icons.account_circle_outlined,
            title: appText(context).accountAndData,
            subtitle: profiles.active?.email ?? appText(context).localProfile,
            screen: const AccountsScreen(),
          ),
          row(
            key: const Key('settings-transfer'),
            icon: Icons.folder_open_outlined,
            title: appText(context).exportImport,
            screen: DataTransferScreen(controller: widget.controller),
          ),
          section(context, appText(context).appSection),
          if (notifications.supported)
            row(
              key: const Key('settings-notices'),
              icon: Icons.notifications_active_outlined,
              title: appText(context).notices,
              subtitle: notifications.enabled
                  ? appText(context).enabled
                  : appText(context).disabled,
              screen: NotificationSettingsScreen(notifications: notifications),
            ),
          row(
            key: const Key('settings-appearance'),
            icon: Icons.palette_outlined,
            title: appText(context).appearance,
            subtitle: appearanceState(appText(context)),
            screen: const AppearanceScreen(),
          ),
          row(
            key: const Key('settings-help'),
            icon: Icons.help_outline_rounded,
            title: appText(context).helpWelcome,
            screen: const WelcomeHelpScreen(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButtonFormField<String>(
              key: const Key('settings-language'),
              initialValue: localeSettings.preference,
              decoration: InputDecoration(
                labelText: appText(context).languagePreference,
              ),
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(appText(context).languageSystem),
                ),
                DropdownMenuItem(
                  value: 'es',
                  child: Text(appText(context).languageSpanish),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(appText(context).languageEnglish),
                ),
                DropdownMenuItem(
                  value: 'ar',
                  child: Text(appText(context).languageArabic),
                ),
              ],
              onChanged: localeSettings.busy
                  ? null
                  : (value) {
                      if (value != null) localeSettings.select(value);
                    },
            ),
          ),
        ],
      ),
    ),
  );
}
