import 'package:flutter/widgets.dart';
import '../l10n/generated/app_localizations.dart';

/// Reads the active catalog, with Spanish as a safe fallback for embedders
/// that mount a screen without the app's localization delegates.
AppLocalizations appText(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('es'));

String googleSheetsError(BuildContext context, String code, String? fallback) {
  final text = appText(context);
  if (Localizations.of<AppLocalizations>(context, AppLocalizations) == null &&
      fallback != null) {
    return fallback;
  }
  return switch (code) {
    'GOOGLE_AUTH_REQUIRED' => text.sheetsErrorExpired,
    'GOOGLE_FORBIDDEN' || 'GOOGLE_WRITE_REQUIRED' => text.sheetsErrorPermission,
    'GOOGLE_ACCOUNT_MISMATCH' ||
    'GOOGLE_ACCOUNT_CHANGED' => text.sheetsErrorAccount,
    'GOOGLE_NOT_FOUND' => text.sheetsErrorNotFound,
    'GOOGLE_RATE_LIMIT' => text.sheetsErrorRateLimit,
    'GOOGLE_NETWORK' => text.sheetsErrorNetwork,
    'GOOGLE_TOO_LARGE' => text.sheetsErrorTooLarge,
    'GOOGLE_BUSY' => text.sheetsErrorBusy,
    'GOOGLE_SYNC' || 'GOOGLE_SERVER' => text.sheetsErrorGeneric,
    _ => fallback ?? text.sheetsGoogleError,
  };
}
