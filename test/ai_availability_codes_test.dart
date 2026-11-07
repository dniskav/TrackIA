import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  const config = AiConfig(
    service: AiService.custom,
    protocol: AiProtocol.chatCompletions,
    baseUrl: 'https://example.test/v1',
    model: 'beam-free',
    apiKey: 'fake-key',
  );

  AppLocalizations l(String code) => lookupAppLocalizations(Locale(code));

  test('checking, unconfigured and unverified expose codes and Spanish text', () async {
    final a = AiAvailability();
    addTearDown(a.dispose);
    expect(a.notice, AiNotice.checking);
    expect(a.text(l('es')), 'Comprobando IA…');
    await a.check();
    expect(a.notice, AiNotice.unconfigured);
    expect(
      a.text(l('es')),
      'Configura tu proveedor y modelo para usar el asistente. Puedes cargar tus datos antes.',
    );
    expect(a.settingsText(l('es')), 'Sin conectar');
    await const AiSettingsStore().save(config);
    await a.check();
    expect(a.notice, AiNotice.unverified);
    expect(
      a.text(l('es')),
      'Verifica la conexión del modelo para habilitar el asistente y las actividades.',
    );
    expect(a.settingsText(l('es')), 'Sin verificar');
  });

  test('verified carries the model and settings keeps its short label', () async {
    final a = AiAvailability();
    addTearDown(a.dispose);
    await const AiSettingsStore().save(config);
    await const AiSettingsStore().markVerified(config);
    await a.check();
    expect(a.notice, AiNotice.verified);
    expect(a.detail, 'beam-free');
    expect(a.text(l('es')), 'IA verificada · beam-free');
    expect(a.settingsText(l('es')), 'Verificada · beam-free');
    expect(a.settingsText(l('en')), contains('beam-free'));
    expect(a.settingsText(l('ar')), contains('beam-free'));
  });

  test('failure after a request maps to a code in es, en and ar', () async {
    final a = AiAvailability()..failed();
    addTearDown(a.dispose);
    expect(a.notice, AiNotice.requestFailed);
    expect(
      a.text(l('es')),
      'La última solicitud falló. Puedes reintentar con el mismo modelo; tus registros se conservan.',
    );
    for (final code in ['es', 'en', 'ar']) {
      expect(a.text(l(code)), isNotEmpty);
    }
    expect(a.text(l('en')), isNot(a.text(l('es'))));
    expect(a.text(l('ar')), isNot(a.text(l('es'))));
  });
}
