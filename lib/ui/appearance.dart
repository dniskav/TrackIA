import 'package:flutter/material.dart';
import '../application/localization.dart';
import '../data/theme_settings.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key, this.settings});
  final ThemeSettings? settings;
  @override
  Widget build(BuildContext context) {
    final preference = settings ?? ThemeSettings.instance;
    return Scaffold(
      appBar: AppBar(title: Text(appText(context).appearance)),
      body: ListenableBuilder(
        listenable: preference,
        builder: (context, _) => RadioGroup<ThemeMode>(
          groupValue: preference.mode,
          onChanged: (value) async {
            if (value == null || preference.busy) return;
            try {
              await preference.select(value);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(appText(context).appearanceSaveError)),
                );
              }
            }
          },
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(appText(context).appearanceIntro),
              ),
              for (final mode in ThemeMode.values)
                RadioListTile<ThemeMode>(
                  key: ValueKey('theme-${mode.name}'),
                  title: Text(switch (mode) {
                    ThemeMode.system => appText(context).automatic,
                    ThemeMode.light => appText(context).light,
                    ThemeMode.dark => appText(context).dark,
                  }),
                  subtitle: mode == ThemeMode.system
                      ? Text(appText(context).appearanceSystemHint)
                      : null,
                  value: mode,
                  enabled: !preference.busy,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
