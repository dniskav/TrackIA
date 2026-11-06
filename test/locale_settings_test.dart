import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/locale_settings.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';

void main() {
  test('waiting messages are varied and localized for es, en, and ar', () {
    for (final locale in const [Locale('es'), Locale('en'), Locale('ar')]) {
      final l = lookupAppLocalizations(locale);
      final phrases = [
        l.waitingPhraseOne,
        l.waitingPhraseTwo,
        l.waitingPhraseThree,
        l.waitingPhraseFour,
      ];
      expect(phrases.toSet(), hasLength(4), reason: locale.languageCode);
      expect(phrases.every((phrase) => phrase.trim().isNotEmpty), isTrue);
    }
  });

  group('LocaleSettings', () {
    test(
      'defaults to the platform locale and reloads a saved language',
      () async {
        final values = <String, String>{};
        Future<String?> read(String key) async => values[key];
        Future<void> write(String key, String value) async =>
            values[key] = value;

        final settings = LocaleSettings(read: read, write: write);
        await settings.load();
        expect(settings.preference, 'system');
        expect(settings.locale, isNull);

        await settings.select('ar');
        expect(settings.locale?.languageCode, 'ar');
        expect(values[LocaleSettings.storageKey], 'ar');

        final restored = LocaleSettings(read: read, write: write);
        await restored.load();
        expect(restored.preference, 'ar');
        expect(restored.locale?.languageCode, 'ar');
      },
    );

    test(
      'accepts only system, es, en, and ar; unknown stored values fall back',
      () async {
        final values = <String, String>{LocaleSettings.storageKey: 'fr'};
        final settings = LocaleSettings(
          read: (key) async => values[key],
          write: (key, value) async => values[key] = value,
        );
        await settings.load();
        expect(settings.preference, 'system');

        for (final language in ['es', 'en', 'ar', 'system']) {
          await settings.select(language);
          expect(settings.preference, language);
        }
        await expectLater(settings.select('fr'), throwsArgumentError);
      },
    );
  });
}
