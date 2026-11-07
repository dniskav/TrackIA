import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
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

Widget _app(Widget home, Locale locale) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

/// Monta una pantalla con el texto escalado (fuente grande) a tamaño de
/// teléfono. Se parte de `MediaQueryData.fromView` para conservar el tamaño
/// lógico: un `MediaQueryData(textScaler: …)` pelado tendría tamaño cero.
Widget _scaledApp(Widget home, Locale locale, WidgetTester tester) => _app(
  MediaQuery(
    data: MediaQueryData.fromView(
      tester.view,
    ).copyWith(textScaler: const TextScaler.linear(2.0)),
    child: home,
  ),
  locale,
);

const _locales = [Locale('es'), Locale('en'), Locale('ar')];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  void phoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('dirección del texto (RTL)', () {
    for (final entry in {
      'es': TextDirection.ltr,
      'en': TextDirection.ltr,
      'ar': TextDirection.rtl,
    }.entries) {
      testWidgets('Ayuda en ${entry.key} usa ${entry.value}', (
        tester,
      ) async {
        final settings = _memory();
        await settings.load();
        await tester.pumpWidget(
          _app(
            WelcomeHelpScreen(
              settings: settings,
              versionLoader: () async => '1.0 (2)',
            ),
            Locale(entry.key),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(WelcomeHelpScreen));
        expect(Directionality.of(context), entry.value);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('fuente grande (texto al 200 %) sin desbordes', () {
    for (final locale in _locales) {
      testWidgets('WelcomeScreen en ${locale.languageCode}', (tester) async {
        phoneSize(tester);
        final settings = _memory();
        await settings.load();
        await tester.pumpWidget(
          _scaledApp(
            WelcomeScreen(
              settings: settings,
              versionLoader: () async => '1.0 (2)',
            ),
            locale,
            tester,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('WelcomeHelpScreen en ${locale.languageCode}', (
        tester,
      ) async {
        phoneSize(tester);
        final settings = _memory();
        await settings.load();
        await tester.pumpWidget(
          _scaledApp(
            WelcomeHelpScreen(
              settings: settings,
              versionLoader: () async => '1.0 (2)',
            ),
            locale,
            tester,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('patrones de fecha por idioma', () {
    final getters = <String, String Function(AppLocalizations)>{
      'datePatternLongWeekday': (l) => l.datePatternLongWeekday,
      'datePatternLongDateTime': (l) => l.datePatternLongDateTime,
      'datePatternShortDateTime': (l) => l.datePatternShortDateTime,
      'datePatternShortDate': (l) => l.datePatternShortDate,
      'datePatternNumericDate': (l) => l.datePatternNumericDate,
      'datePatternNumericDateTime': (l) => l.datePatternNumericDateTime,
      'datePatternNumericDateTimeSeconds': (l) =>
          l.datePatternNumericDateTimeSeconds,
      'datePatternPaddedDateTime': (l) => l.datePatternPaddedDateTime,
    };
    final date = DateTime(2026, 11, 7, 18, 5, 9);

    String format(String pattern, String locale) =>
        DateFormat(pattern, locale).format(date);

    test('cada patrón formatea texto no vacío en es, en y ar', () async {
      for (final locale in ['es', 'en', 'ar']) {
        final l = lookupAppLocalizations(Locale(locale));
        for (final name in getters.keys) {
          final pattern = getters[name]!(l);
          expect(pattern, isNotEmpty, reason: '$locale.$name');
          expect(format(pattern, locale), isNotEmpty, reason: '$locale.$name');
        }
      }
    });

    test('es y en producen textos distintos para cada patrón', () {
      final es = lookupAppLocalizations(const Locale('es'));
      final en = lookupAppLocalizations(const Locale('en'));
      for (final name in getters.keys) {
        final spanish = format(getters[name]!(es), 'es');
        final english = format(getters[name]!(en), 'en');
        expect(spanish, isNot(equals(english)), reason: name);
      }
    });

    test('el día de la semana en español es «sábado, 7 de noviembre»', () {
      final pattern = lookupAppLocalizations(
        const Locale('es'),
      ).datePatternLongWeekday;
      expect(
        format(pattern, 'es').toLowerCase(),
        'sábado, 7 de noviembre',
      );
    });
  });

  group('semántica de la versión', () {
    for (final entry in {
      'es': 'Versión 1.0 (2)',
      'en': 'Version 1.0 (2)',
      'ar': 'الإصدار 1.0 (2)',
    }.entries) {
      testWidgets('Ayuda expone la versión a lectores de pantalla (${entry.key})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final settings = _memory();
        await settings.load();
        await tester.pumpWidget(
          _app(
            WelcomeHelpScreen(
              settings: settings,
              versionLoader: () async => '1.0 (2)',
            ),
            Locale(entry.key),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(entry.value),
          findsOneWidget,
          reason: entry.key,
        );
        handle.dispose();
      });
    }
  });
}
