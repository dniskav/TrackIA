import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/welcome_settings_store.dart';
import 'package:trackia/ui/trackia_mark.dart';
import 'package:trackia/ui/welcome.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ({WelcomeSettings settings, Map<String, String> values}) memoryStore() {
    final values = <String, String>{};
    return (
      settings: WelcomeSettings(
        read: (key) async => values[key],
        write: (key, value) async => values[key] = value,
      ),
      values: values,
    );
  }

  Future<void> launch(WidgetTester tester, WelcomeSettings settings) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => FilledButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WelcomeScreen(settings: settings),
                        ),
                      ),
                  child: const Text('Abrir'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('swiping changes slides and updates the page indicators', (
    tester,
  ) async {
    final store = memoryStore();
    await store.settings.load();
    await launch(tester, store.settings);

    expect(find.byKey(const Key('welcome-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('welcome-dot-5')), findsOneWidget);
    expect(find.text('Paso 1 de 6'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('welcome-pages')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 6'), findsOneWidget);
    expect(find.text('Habla o escribe'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('welcome-pages')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 6'), findsOneWidget);
    expect(find.byKey(const Key('welcome-trackia-logo')), findsOneWidget);
    expect(find.text('Bienvenido'), findsOneWidget);
  });

  for (final finishAtEnd in [false, true]) {
    for (final suppress in [false, true]) {
      testWidgets(
        '${finishAtEnd ? 'Empezar' : 'Omitir'} with suppress=$suppress survives three loads',
        (tester) async {
          final store = memoryStore();
          await store.settings.load();
          await launch(tester, store.settings);
          expect(find.text('Paso 1 de 6'), findsOneWidget);
          if (suppress) {
            await tester.tap(find.byKey(const Key('welcome-never-again')));
            await tester.pump();
          }
          if (finishAtEnd) {
            for (var step = 1; step < 6; step++) {
              await tester.tap(find.byKey(const Key('welcome-next')));
              await tester.pumpAndSettle();
              expect(find.text('Paso ${step + 1} de 6'), findsOneWidget);
            }
            await tester.tap(find.text('Empezar'));
          } else {
            await tester.tap(find.text('Omitir'));
          }
          await tester.pumpAndSettle();
          expect(find.byType(WelcomeScreen), findsNothing);
          for (var launchIndex = 0; launchIndex < 3; launchIndex++) {
            final reloaded = WelcomeSettings(
              read: (key) async => store.values[key],
              write: (key, value) async => store.values[key] = value,
            );
            await reloaded.load();
            expect(reloaded.autoShow, !suppress);
            expect(reloaded.seenVersion, WelcomeSettings.contentVersion);
            expect(reloaded.completedAt, isNotNull);
          }
        },
      );
    }
  }

  testWidgets('system Back discards an unconfirmed checkbox; help can reopen', (
    tester,
  ) async {
    final store = memoryStore();
    await store.settings.load();
    await launch(tester, store.settings);
    await tester.tap(find.byKey(const Key('welcome-never-again')));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(store.settings.autoShow, isTrue);
    expect(store.values, isEmpty);
    await store.settings.select(false);
    await tester.pumpWidget(
      MaterialApp(home: WelcomeHelpScreen(settings: store.settings)),
    );
    await tester.tap(find.text('Ver bienvenida'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(store.settings.autoShow, isFalse);
  });

  testWidgets(
    'failed write keeps the screen open and does not claim suppression',
    (tester) async {
      final settings = WelcomeSettings(
        read: (_) async => null,
        write: (_, __) async => throw StateError('offline storage'),
      );
      await settings.load();
      await launch(tester, settings);
      await tester.tap(find.byKey(const Key('welcome-never-again')));
      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo guardar la elección'), findsOneWidget);
      expect(settings.autoShow, isTrue);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
    },
  );

  testWidgets('slides fit small displays with large text in both themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final store = memoryStore();
      await store.settings.load();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            themeMode: mode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: WelcomeScreen(settings: store.settings),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Omitir'), findsOneWidget);
    }
  });

  group('automatic entry', () {
    Future<({WelcomeSettings settings, Map<String, String> values})> open(
      WidgetTester tester, {
      required bool preselect,
    }) async {
      final store = memoryStore();
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(
            settings: store.settings,
            preselectNeverAgain: preselect,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return store;
    }

    bool checked(WidgetTester tester) =>
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('welcome-never-again')))
            .value!;

    testWidgets('starts checked and skipping stops it from reappearing', (
      tester,
    ) async {
      final store = await open(tester, preselect: true);
      expect(checked(tester), isTrue);
      await tester.tap(find.byKey(const Key('welcome-skip')));
      await tester.pumpAndSettle();
      expect(store.settings.autoShow, isFalse);
    });

    testWidgets('unchecking keeps the guide for the next launch', (tester) async {
      final store = await open(tester, preselect: true);
      await tester.tap(find.byKey(const Key('welcome-never-again')));
      await tester.pump();
      expect(checked(tester), isFalse);
      await tester.tap(find.byKey(const Key('welcome-skip')));
      await tester.pumpAndSettle();
      expect(store.settings.autoShow, isTrue);
    });

    testWidgets('the manual entry still reflects the saved preference', (
      tester,
    ) async {
      await open(tester, preselect: false);
      expect(checked(tester), isFalse);
    });
  });

  testWidgets('the first slide draws the logo with theme colors, not an image', (
    tester,
  ) async {
    final store = memoryStore();
    for (final theme in [ThemeData.dark(), ThemeData.light()]) {
      await tester.pumpWidget(
        MaterialApp(theme: theme, home: WelcomeScreen(settings: store.settings)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('welcome-trackia-logo')), findsOneWidget);
      expect(find.byType(TrackiaMark), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    }
  });
}
