import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-wide language preference. `system` follows the platform locale.
class LocaleSettings extends ChangeNotifier {
  LocaleSettings({
    Future<String?> Function(String)? read,
    Future<void> Function(String, String)? write,
  }) : _read = read ?? ((key) => const FlutterSecureStorage().read(key: key)),
       _write =
           write ??
           ((key, value) =>
               const FlutterSecureStorage().write(key: key, value: value));

  static final instance = LocaleSettings();
  static const storageKey = 'trackia.locale.preference.v1';
  static const supportedLanguages = <String>{'system', 'es', 'en', 'ar'};

  final Future<String?> Function(String) _read;
  final Future<void> Function(String, String) _write;

  String preference = 'system';
  bool busy = false;
  bool loaded = false;

  /// `null` lets Flutter resolve the system locale.
  Locale? get locale => preference == 'system' ? null : Locale(preference);

  /// Language used for assistant replies. The stored choice is loaded during
  /// bootstrap; when it is `system`, follow the platform locale using the same
  /// supported-language fallback as the app.
  String get assistantLanguage {
    if (preference == 'es' || preference == 'en' || preference == 'ar') {
      return preference;
    }
    try {
      final systemCode =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      return supportedLanguages.contains(systemCode) ? systemCode : 'es';
    } catch (_) {
      return 'es';
    }
  }

  Future<void> load() async {
    final saved = await _read(storageKey);
    preference = supportedLanguages.contains(saved) ? saved! : 'system';
    loaded = true;
    notifyListeners();
  }

  Future<void> select(String next) async {
    if (!supportedLanguages.contains(next)) {
      throw ArgumentError.value(next, 'next', 'Unsupported language choice');
    }
    if (busy) throw StateError('The language preference is being saved.');
    if (preference == next) return;
    busy = true;
    notifyListeners();
    try {
      await _write(storageKey, next);
      preference = next;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
