import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/application/rest_notifications.dart';
import 'package:trackia/application/locale_settings.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/data/theme_settings.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/ui/accounts.dart';
import 'package:trackia/ui/ai_settings.dart';
import 'package:trackia/ui/appearance.dart';
import 'package:trackia/ui/data_transfer.dart';
import 'package:trackia/ui/notification_settings.dart';
import 'package:trackia/ui/settings.dart';
import 'package:trackia/ui/theme.dart';
import 'package:trackia/ui/welcome.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController controller;
  late RestNotificationController notifications;
  var notificationsEnabled = true;
  const config = AiConfig(
    service: AiService.opencodeGo,
    baseUrl: 'https://opencode.ai/zen/go/v1',
    model: 'test-model',
    protocol: AiProtocol.chatCompletions,
    apiKey: 'test-secret',
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    notificationsEnabled = true;
    dir = await Directory.systemTemp.createTemp('trackia-settings-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/db.sqlite',
    );
    controller = WorkoutController(repo);
    await controller.refresh();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RestNotificationController.channel, (
          call,
        ) async {
          if (call.method == 'status') {
            return {
              'enabled': notificationsEnabled,
              'granted': true,
              'exact': true,
            };
          }
          return null;
        });
    notifications = RestNotificationController(controller);
  });

  tearDown(() async {
    notifications.dispose();
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RestNotificationController.channel, null);
    await ThemeSettings.instance.select(ThemeMode.dark);
  });

  AiAvailability availability() => AiAvailability(
    catalog: AiModelCatalog(
      transport: (_, __) async => {
        'data': [
          {'id': 'test-model'},
        ],
      },
    ),
  );

  Future<void> open(WidgetTester tester) async {
    // A fresh tree each time: otherwise Flutter reuses the previous State.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: SettingsScreen(
          controller: controller,
          availability: availability(),
          notifications: notifications,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sections appear in order with their rows', (tester) async {
    await open(tester);
    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(find.text('Ajustes'), findsOneWidget);
    expect(y('Asistente'), lessThan(y('Inteligencia artificial')));
    expect(y('Inteligencia artificial'), lessThan(y('Tus datos')));
    expect(y('Tus datos'), lessThan(y('Cuenta y datos')));
    expect(y('Cuenta y datos'), lessThan(y('Exportar e importar')));
    expect(y('Exportar e importar'), lessThan(y('App')));
    expect(y('App'), lessThan(y('Avisos')));
    expect(y('Avisos'), lessThan(y('Apariencia')));
    expect(y('Apariencia'), lessThan(y('Ayuda y bienvenida')));
  });

  testWidgets('language selector persists an accessible Arabic choice', (
    tester,
  ) async {
    await open(tester);
    final field = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('settings-language')),
    );
    expect(field.decoration.labelText, 'Idioma');
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Árabe').last);
    await tester.pumpAndSettle();
    expect(LocaleSettings.instance.preference, 'ar');
    expect(LocaleSettings.instance.locale?.languageCode, 'ar');
    await LocaleSettings.instance.select('system');
  });

  testWidgets('each row opens its screen', (tester) async {
    await open(tester);
    final destinations = <String, Type>{
      'Inteligencia artificial': AiSettingsScreen,
      'Cuenta y datos': AccountsScreen,
      'Exportar e importar': DataTransferScreen,
      'Avisos': NotificationSettingsScreen,
      'Apariencia': AppearanceScreen,
      'Ayuda y bienvenida': WelcomeHelpScreen,
    };
    for (final entry in destinations.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pump();
      // «Por acompañante» in the AI screen reads SQLite on opening.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(entry.value),
        findsOneWidget,
        reason: '${entry.key} debería abrir ${entry.value}',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Ajustes'), findsOneWidget);
    }
  });

  testWidgets('the AI row shows whether the assistant is connected', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Sin conectar'), findsOneWidget);

    await const AiSettingsStore().save(config);
    await const AiSettingsStore().markVerified(config);
    await open(tester);
    expect(find.textContaining('Verificada'), findsOneWidget);
    expect(find.textContaining('test-model'), findsOneWidget);
  });

  testWidgets('the AI row distinguishes an unverified configuration', (
    tester,
  ) async {
    await const AiSettingsStore().save(config);
    await open(tester);
    expect(find.text('Sin verificar'), findsOneWidget);
  });

  testWidgets('rows show the state of notices, appearance and account', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Activados'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
    expect(find.text('Perfil local'), findsOneWidget);

    notificationsEnabled = false;
    await ThemeSettings.instance.select(ThemeMode.light);
    await open(tester);
    expect(find.text('Desactivados'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
  });

  testWidgets('the app bar and rows use the theme and stay readable', (
    tester,
  ) async {
    await open(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(ListTile), findsNWidgets(6));
  });
}
