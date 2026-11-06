import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/data/ai_model_catalog.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/ui/ai_settings.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/ui/companion_style.dart';
import 'package:trackia/ui/companions.dart';
import 'package:trackia/ui/theme.dart';

void main() {
  testWidgets('dashboard selects, edits and deletes a companion', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    Companion? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: CompanionDashboard(
          profileId: 'local',
          onOpen: (value) => opened = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('companion-gymbro')));
    expect(opened?.id, 'gymbro');

    await tester.tap(find.byTooltip('Opciones de GymBro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Mi GymBro',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Instrucciones para la IA (opcional)'),
      'Háblame de forma breve.',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final saved = (await const CompanionStore(profileId: 'local').load()).first;
    expect(saved.name, 'Mi GymBro');
    expect(saved.prompt, 'Háblame de forma breve.');
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Opciones de Mi GymBro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('companion-gymbro')), findsNothing);
    expect((await const CompanionStore(profileId: 'local').load()).length, 3);
  });

  Future<void> openDashboard(WidgetTester tester, [ThemeData? theme]) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? gymTheme,
        home: CompanionDashboard(profileId: 'local', onOpen: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home shows the TrackIA logo with an accessible name', (
    tester,
  ) async {
    await openDashboard(tester);
    final logo = tester.widget<Image>(
      find.byKey(const Key('dashboard-trackia-logo')),
    );
    expect(
      (logo.image as AssetImage).assetName,
      'assets/branding/trackia-logo.png',
    );
    expect(
      find.byKey(const Key('dashboard-trackia-logo-semantics')),
      findsOneWidget,
    );
    expect(find.text('TrackIA'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const Key('dashboard-trackia-logo-semantics')),
    );
    expect(semantics.label, 'Logotipo de TrackIA');
    expect(semantics.flagsCollection.isImage, isTrue);
  });

  testWidgets('each card shows its companion icon on a tinted circle', (
    tester,
  ) async {
    await openDashboard(tester);
    Icon iconOf(String id) => tester.widget<Icon>(
      find
          .descendant(
            of: find.byKey(Key('companion-$id')),
            matching: find.byType(Icon),
          )
          .first,
    );
    expect(iconOf('gymbro').icon, Icons.fitness_center);
    expect(iconOf('enfoque').icon, Icons.hourglass_top);
    expect(iconOf('calma').icon, Icons.spa);
    expect(iconOf('diario').icon, Icons.menu_book);
    expect(iconOf('gymbro').color, trackiaCompanionColors['orange']!.dark);
    expect(iconOf('enfoque').color, trackiaCompanionColors['teal']!.dark);
    final avatar = tester.widget<CompanionAvatar>(
      find.descendant(
        of: find.byKey(const Key('companion-gymbro')),
        matching: find.byType(CompanionAvatar),
      ),
    );
    expect(avatar.companion.id, 'gymbro');
  });

  testWidgets('light theme uses the darker companion colors', (tester) async {
    await openDashboard(tester, gymLightTheme);
    final icon = tester.widget<Icon>(
      find
          .descendant(
            of: find.byKey(const Key('companion-gymbro')),
            matching: find.byType(Icon),
          )
          .first,
    );
    expect(icon.color, trackiaCompanionColors['orange']!.light);
  });

  testWidgets('the editor chooses an icon and a color for a new companion', (
    tester,
  ) async {
    await openDashboard(tester);
    await tester.tap(find.byKey(const Key('companion-create')));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNothing);
    for (final id in Companion.iconIds) {
      expect(find.byKey(Key('icon-$id')), findsOneWidget, reason: id);
    }
    for (final id in Companion.colorIds) {
      expect(find.byKey(Key('color-$id')), findsOneWidget, reason: id);
    }
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Ciclismo',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Instrucciones para la IA (opcional)'),
      'Registra mis rutas.',
    );
    await tester.ensureVisible(find.byKey(const Key('icon-bike')));
    await tester.tap(find.byKey(const Key('icon-bike')));
    await tester.ensureVisible(find.byKey(const Key('color-violet')));
    await tester.tap(find.byKey(const Key('color-violet')));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final saved = (await const CompanionStore(profileId: 'local').load()).last;
    expect(saved.name, 'Ciclismo');
    expect((saved.icon, saved.color), ('bike', 'violet'));
    final card = find.byKey(Key('companion-${saved.id}'));
    // The list is lazy and the AI card pushes it down: scroll to the new card.
    await tester.scrollUntilVisible(card, 200);
    expect(
      tester
          .widget<Icon>(
            find.descendant(of: card, matching: find.byType(Icon)).first,
          )
          .icon,
      Icons.directions_bike,
    );
  });

  testWidgets('editing keeps the current icon and color selected', (
    tester,
  ) async {
    await openDashboard(tester);
    await tester.tap(find.byTooltip('Opciones de Calma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<IconButton>(find.byKey(const Key('icon-leaf'))).isSelected,
      isTrue,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('color-green')))
          .isSelected,
      isTrue,
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final calma = (await const CompanionStore(profileId: 'local').load())
        .firstWhere((c) => c.id == 'calma');
    expect((calma.icon, calma.color), ('leaf', 'green'));
  });

  group('settings access', () {
    const config = AiConfig(
      service: AiService.opencodeGo,
      baseUrl: 'https://opencode.ai/zen/go/v1',
      model: 'test-model',
      protocol: AiProtocol.chatCompletions,
      apiKey: 'test-secret',
    );
    AiAvailability availability() => AiAvailability(
      catalog: AiModelCatalog(
        transport:
            (_, __) async => {
              'data': [
                {'id': 'test-model'},
              ],
            },
      ),
    );

    Future<void> pump(
      WidgetTester tester, {
      VoidCallback? onSettings,
      AiAvailability? ai,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: gymTheme,
          home: CompanionDashboard(
            profileId: 'local',
            onOpen: (_) {},
            onSettings: onSettings,
            availability: ai ?? availability(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the gear opens settings without opening any companion', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});
      var settings = 0;
      Companion? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: gymTheme,
          home: CompanionDashboard(
            profileId: 'local',
            onOpen: (c) => opened = c,
            onSettings: () => settings++,
            availability: availability(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dashboard-settings')));
      expect(settings, 1);
      expect(opened, isNull);
      expect(find.byTooltip('Ajustes'), findsOneWidget);
    });

    testWidgets('without a settings callback there is no gear', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await pump(tester);
      expect(find.byKey(const Key('dashboard-settings')), findsNothing);
    });

    testWidgets(
      'an unconfigured AI shows the card and Conectar opens its setup',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        await pump(tester);
        expect(find.byKey(const Key('ai-not-connected')), findsOneWidget);
        expect(find.text('IA sin conectar'), findsOneWidget);
        await tester.tap(find.text('Conectar'));
        await tester.pumpAndSettle();
        expect(find.byType(AiSettingsScreen), findsOneWidget);
      },
    );

    testWidgets('a verified AI hides the card', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await const AiSettingsStore().save(config);
      await const AiSettingsStore().markVerified(config);
      await pump(tester);
      expect(find.byKey(const Key('ai-not-connected')), findsNothing);
      expect(find.text('Tus acompañantes'), findsOneWidget);
    });

    testWidgets('a saved but unverified AI still asks to connect', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});
      await const AiSettingsStore().save(config);
      await pump(tester);
      expect(find.byKey(const Key('ai-not-connected')), findsOneWidget);
      expect(find.text('IA sin verificar'), findsOneWidget);
    });

    testWidgets('the card disappears after configuring and coming back', (
      tester,
    ) async {
      FlutterSecureStorage.setMockInitialValues({});
      await pump(tester);
      expect(find.byKey(const Key('ai-not-connected')), findsOneWidget);
      await tester.tap(find.text('Conectar'));
      await tester.pumpAndSettle();
      await const AiSettingsStore().save(config);
      await const AiSettingsStore().markVerified(config);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai-not-connected')), findsNothing);
    });
  });
}
