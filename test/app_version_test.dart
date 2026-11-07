import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:trackia/application/app_version.dart';
import 'package:trackia/application/locale_settings.dart';
import 'package:trackia/data/welcome_settings_store.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';
import 'package:trackia/ui/welcome.dart';

WelcomeSettings _memory() {
  final values = <String, String>{};
  return WelcomeSettings(
    read: (key) async => values[key],
    write: (key, value) async => values[key] = value,
  );
}

Widget _app(Widget home, {Locale locale = const Locale('es')}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await LocaleSettings.instance.select('es');
  });

  group('loadAppVersion', () {
    test('une versión y número de compilación', () async {
      PackageInfo.setMockInitialValues(
        appName: 'TrackIA',
        packageName: 'com.gymia.app',
        version: '0.3.33',
        buildNumber: '36',
        buildSignature: '',
      );
      expect(await loadAppVersion(), '0.3.33 (36)');
    });

    test('sin número de compilación solo da la versión', () async {
      PackageInfo.setMockInitialValues(
        appName: 'TrackIA',
        packageName: 'com.gymia.app',
        version: '0.3.33',
        buildNumber: '',
        buildSignature: '',
      );
      expect(await loadAppVersion(), '0.3.33');
    });
  });

  testWidgets('Ayuda y bienvenida muestra la versión', (tester) async {
    final settings = _memory();
    await settings.load();
    await tester.pumpWidget(
      _app(
        WelcomeHelpScreen(
          settings: settings,
          versionLoader: () async => '0.3.33 (36)',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app-version')), findsOneWidget);
    expect(find.text('Versión 0.3.33 (36)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la bienvenida muestra la versión al pie', (tester) async {
    final settings = _memory();
    await settings.load();
    await tester.pumpWidget(
      _app(
        WelcomeScreen(
          settings: settings,
          versionLoader: () async => '0.3.33 (36)',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Versión 0.3.33 (36)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en inglés y árabe se traduce la etiqueta', (tester) async {
    final settings = _memory();
    await settings.load();
    for (final entry in {
      'en': 'Version 1.0 (2)',
      'ar': 'الإصدار 1.0 (2)',
    }.entries) {
      await LocaleSettings.instance.select(entry.key);
      await tester.pumpWidget(
        _app(
          WelcomeHelpScreen(
            settings: settings,
            versionLoader: () async => '1.0 (2)',
          ),
          locale: Locale(entry.key),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
    }
  });

  testWidgets('sin versión no se muestra nada ni se rompe', (tester) async {
    final settings = _memory();
    await settings.load();
    for (final loader in <AppVersionLoader>[
      () async => '',
      () async => throw StateError('sin plataforma'),
    ]) {
      await tester.pumpWidget(
        _app(WelcomeHelpScreen(settings: settings, versionLoader: loader)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app-version')), findsNothing);
    }
  });
}
