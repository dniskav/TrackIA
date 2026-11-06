import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';

void main() {
  test('Sheets and sync labels are available in all supported locales', () {
    final es = lookupAppLocalizations(const Locale('es'));
    final en = lookupAppLocalizations(const Locale('en'));
    final ar = lookupAppLocalizations(const Locale('ar'));

    expect(es.sheetsTitle, 'Tus hojas de Google Sheets');
    expect(en.sheetsTitle, 'Your Google Sheets');
    expect(ar.sheetsTitle, 'جداول بيانات Google الخاصة بك');
    expect(es.syncConnectWrite, 'Conectar Google y permitir escritura');
    expect(en.syncConnectWrite, 'Connect Google and allow writing');
    expect(ar.syncConnectWrite, 'الاتصال بـ Google والسماح بالكتابة');
    expect(es.syncReadConfirmed(3, 'OK'), contains('3 filas'));
    expect(en.syncReadConfirmed(3, 'OK'), contains('3 rows'));
    expect(ar.syncReadConfirmed(3, 'OK'), contains('3'));
  });
}
