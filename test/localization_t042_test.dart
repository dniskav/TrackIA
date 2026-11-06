import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/welcome_settings_store.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';
import 'package:trackia/ui/welcome.dart';

void main() {
  testWidgets('Arabic welcome uses Arabic text and right-to-left direction', (
    tester,
  ) async {
    final settings = WelcomeSettings(
      read: (_) async => null,
      write: (_, __) async {},
    );
    await settings.load();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: WelcomeScreen(settings: settings),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('مرحبًا بك'), findsNWidgets(2));
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('welcome-progress'))),
      ),
      TextDirection.rtl,
    );
  });
}
