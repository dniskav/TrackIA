import 'package:flutter/material.dart';
import '../application/localization.dart';
import '../l10n/generated/app_localizations.dart';
import '../data/welcome_settings_store.dart';
import '../application/app_version.dart';
import 'app_version_label.dart';
import 'trackia_mark.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.settings,
    this.preselectNeverAgain = false,
    this.versionLoader,
  });

  final WelcomeSettings? settings;

  /// Para pruebas: cómo se obtiene la versión que se muestra al pie.
  final AppVersionLoader? versionLoader;

  /// The automatic entry starts with «No volver a mostrar» checked, so the
  /// guide appears once unless the user chooses to keep it. The manual entry
  /// reflects the saved preference instead.
  final bool preselectNeverAgain;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final WelcomeSettings settings =
      widget.settings ?? WelcomeSettings.instance;
  final PageController pages = PageController();
  int index = 0;
  late bool doNotShowAgain = widget.preselectNeverAgain || !settings.autoShow;
  bool saving = false;

  List<({IconData icon, String title, String body})> slides(
    AppLocalizations l,
  ) => [
    (
      icon: Icons.auto_awesome_outlined,
      title: l.welcomeSlide1Title,
      body: l.welcomeSlide1Body,
    ),
    (
      icon: Icons.chat_bubble_outline,
      title: l.welcomeSlide2Title,
      body: l.welcomeSlide2Body,
    ),
    (
      icon: Icons.play_circle_outline,
      title: l.welcomeSlide3Title,
      body: l.welcomeSlide3Body,
    ),
    (
      icon: Icons.save_outlined,
      title: l.welcomeSlide4Title,
      body: l.welcomeSlide4Body,
    ),
    (
      icon: Icons.people_outline_rounded,
      title: l.welcomeSlide5Title,
      body: l.welcomeSlide5Body,
    ),
    (
      icon: Icons.notifications_active_outlined,
      title: l.welcomeSlide6Title,
      body: l.welcomeSlide6Body,
    ),
  ];

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  Future<void> finish(AppLocalizations l) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await settings.select(!doNotShowAgain, completed: true);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.welcomeSaveErrorTitle),
          content: Text(l.welcomeSaveErrorBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.retry),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.continueWithoutSaving),
            ),
          ],
        ),
      );
      if (leave == true && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = appText(context);
    final slides = this.slides(l);
    return Scaffold(
      appBar: AppBar(title: Text(l.welcomeTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l.welcomeStep(index + 1, slides.length),
                  key: const Key('welcome-progress'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const Key('welcome-pages'),
                controller: pages,
                itemCount: slides.length,
                onPageChanged: (next) => setState(() => index = next),
                itemBuilder: (context, i) {
                  final slide = slides[i];
                  return SingleChildScrollView(
                    key: ValueKey('welcome-slide-$i'),
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        if (i == 0)
                          const TrackiaMark(
                            key: Key('welcome-trackia-logo'),
                            size: 120,
                          )
                        else
                          Icon(
                            slide.icon,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        const SizedBox(height: 24),
                        Text(
                          slide.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.body,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (i) {
                  final active = i == index;
                  return Semantics(
                    label: l.welcomeStep(i + 1, slides.length),
                    selected: active,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        key: Key('welcome-dot-$i'),
                        duration: const Duration(milliseconds: 180),
                        width: active ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(
              height: 148,
              child: SingleChildScrollView(
                child: CheckboxListTile(
                  key: const Key('welcome-never-again'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(l.welcomeNeverAgain),
                  subtitle: Text(l.welcomeNeverAgainHelp),
                  value: doNotShowAgain,
                  onChanged: saving
                      ? null
                      : (value) =>
                            setState(() => doNotShowAgain = value ?? false),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                overflowSpacing: 4,
                children: [
                  TextButton(
                    key: const Key('welcome-skip'),
                    onPressed: saving ? null : () => finish(l),
                    child: Text(l.skip),
                  ),
                  if (index > 0)
                    TextButton(
                      key: const Key('welcome-back'),
                      onPressed: saving
                          ? null
                          : () => pages.previousPage(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            ),
                      child: Text(l.previous),
                    ),
                  FilledButton(
                    key: const Key('welcome-next'),
                    onPressed: saving
                        ? null
                        : index == slides.length - 1
                        ? () => finish(l)
                        : () => pages.nextPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          ),
                    child: Text(index == slides.length - 1 ? l.start : l.next),
                  ),
                ],
              ),
            ),
            AppVersionLabel(loader: widget.versionLoader),
          ],
        ),
      ),
    );
  }
}

class WelcomeHelpScreen extends StatelessWidget {
  const WelcomeHelpScreen({super.key, this.settings, this.versionLoader});
  final WelcomeSettings? settings;

  /// Para pruebas: cómo se obtiene la versión que se muestra al pie.
  final AppVersionLoader? versionLoader;

  @override
  Widget build(BuildContext context) {
    final l = appText(context);
    final preference = settings ?? WelcomeSettings.instance;
    return Scaffold(
      appBar: AppBar(title: Text(l.welcomeHelpTitle)),
      body: ListenableBuilder(
        listenable: preference,
        builder: (context, _) => ListView(
          children: [
            SwitchListTile(
              key: const Key('welcome-auto-show'),
              title: Text(l.welcomeAutoShow),
              subtitle: Text(l.devicePreferenceSaved),
              value: preference.autoShow,
              onChanged: preference.busy
                  ? null
                  : (value) async {
                      try {
                        await preference.select(value);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.savePreferenceError)),
                          );
                        }
                      }
                    },
            ),
            ListTile(
              leading: const Icon(Icons.slideshow_outlined),
              title: Text(l.showWelcome),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WelcomeScreen(
                    settings: preference,
                    versionLoader: versionLoader,
                  ),
                ),
              ),
            ),
            AppVersionLabel(loader: versionLoader),
          ],
        ),
      ),
    );
  }
}
