import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trackia/application/ai_availability.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/ai_client.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/ui/activity_focus.dart' show ActivityChooser;
import 'package:trackia/ui/assistant_chat.dart';
import 'package:trackia/ui/theme.dart';

/// R3 of specs/004-trackia-experience/quickstart.md: build and record two
/// activities by hand with no AI at all. Real UI, SQLite and secure storage on
/// Android; no provider is contacted (the config key is empty on purpose).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a free and an instant activity are recorded without AI', (
    tester,
  ) async {
    const storage = FlutterSecureStorage();
    for (final key in const [
      'gymia.ai.config.v1',
      'gymia.ai.config.v1.verified',
      'gymia.ai.chat.v1',
    ]) {
      await storage.delete(key: key);
    }
    final dir = await Directory.systemTemp.createTemp('trackia-r3-');
    final dbPath = '${dir.path}/r3.sqlite';

    final repo = await SqliteWorkoutRepository.open(path: dbPath);
    var c = WorkoutController(repo);
    await c.refresh();

    Future<void> mount() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: gymTheme,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: AssistantChatScreen(
            controller: c,
            client: AiClient(
              transport: (_, __, ___) => throw StateError('Sin IA no envía'),
            ),
            availability: AiAvailability(),
            focusMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    int byTypeChooser() {
      try {
        return find.byType(ActivityChooser).evaluate().length;
      } catch (_) {
        return -1;
      }
    }

    Future<void> waitUntil(bool Function() done, [String? tag]) async {
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (!done() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(done(), isTrue, reason: 'la condición se cumplió a tiempo');
    }

    /// Scrolls a key into view the way activity_builder_test does.
    Future<void> reveal(WidgetTester t, String key) async {
      final target = find.byKey(Key(key));
      if (target.evaluate().isNotEmpty) {
        await t.ensureVisible(target);
        await t.pump();
        return;
      }
      await waitUntil(
        () => find.byType(Scrollable).evaluate().isNotEmpty,
        'scrollable',
      );
      final list = find.byType(Scrollable).first;
      await t.scrollUntilVisible(target, 300, scrollable: list, maxScrolls: 40);
      await t.pump();
    }

    Future<void> buildActivity({
      required String name,
      required String rhythm,
      required List<(String label, String unit, String type)> fields,
    }) async {
      await tester.pumpAndSettle();
      await waitUntil(
        () => find.byKey(const Key('new-activity')).evaluate().isNotEmpty,
        'bar',
      );
      await tester.ensureVisible(find.byKey(const Key('new-activity')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-activity')));
      await tester.pump(const Duration(milliseconds: 100));
      await waitUntil(() => byTypeChooser() == 1, 'chooser');
      final nueva = find.descendant(
        of: find.byType(ActivityChooser),
        matching: find.text('Nueva actividad'),
      );
      // Con plantillas guardadas queda fuera del primer viewport.
      await tester.ensureVisible(nueva);
      await tester.pumpAndSettle();
      await tester.tap(nueva);
      await tester.pumpAndSettle();
      await waitUntil(
        () => find.byKey(const Key('builder-name')).evaluate().isNotEmpty,
        'builder',
      );
      await tester.enterText(find.byKey(const Key('builder-name')), name);
      final rhythmButton = find.byKey(Key(rhythm));
      await tester.ensureVisible(rhythmButton);
      await tester.pumpAndSettle();
      await tester.tap(rhythmButton);
      await tester.pumpAndSettle();
      for (final (label, unit, type) in fields) {
        await reveal(tester, 'builder-add-field');
        await tester.tap(find.byKey(const Key('builder-add-field')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('field-label')), label);
        if (unit.isNotEmpty) {
          await tester.enterText(find.byKey(const Key('field-unit')), unit);
        }
        if (type != 'number') {
          await tester.tap(find.byKey(const Key('field-type')));
          await tester.pumpAndSettle();
          await waitUntil(
            () => find.text('Texto').evaluate().isNotEmpty,
            'type menu',
          );
          await tester.tap(find.text('Texto').last);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const Key('field-submit')));
        await tester.pumpAndSettle();
      }
      await reveal(tester, 'builder-submit');
      await tester.tap(find.byKey(const Key('builder-submit')));
      await tester.pumpAndSettle();
      await waitUntil(
        () =>
            c.focus?.definition.name == name ||
            find.byKey(const Key('record-submit')).evaluate().isNotEmpty,
        'prepared',
      );
    }

    /// The real IME keeps insets > 0 after entering text, which switches the
    /// panel to compact mode and hides the quick counters. Close it explicitly.
    Future<void> hideKeyboard() async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 150));
      await waitUntil(() {
        final scaffold = find.byType(Scaffold).evaluate();
        if (scaffold.isEmpty) return true;
        return MediaQuery.of(
              tester.element(find.byType(Scaffold).first),
            ).viewInsets.bottom ==
            0;
      }, 'teclado');
    }

    try {
      await mount();
      // «Leer»: rhythm Libre with Páginas (number/sum) and Libro (text).
      await buildActivity(
        name: 'Leer',
        rhythm: 'rhythm-free',
        fields: const [('Páginas', 'páginas', 'number'), ('Libro', '', 'text')],
      );

      // Iniciar → 18 quick taps on Páginas → Parar.
      await hideKeyboard();
      await tester.tap(find.byKey(const Key('activity-start-stop')));
      await tester.pumpAndSettle();
      await waitUntil(() => c.focus?.running != null && !c.busy, 'run');
      final inc = find.byKey(const Key('counter-inc-paginas'));
      await waitUntil(() => inc.evaluate().isNotEmpty, 'counter');
      for (var i = 0; i < 18; i++) {
        await tester.ensureVisible(inc);
        await tester.tap(inc);
        await tester.pump(const Duration(milliseconds: 50));
      }
      // Wait out the 3 s consolidation timer, then stop.
      await Future<void>.delayed(const Duration(milliseconds: 3500));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('activity-start-stop')));
      await tester.tap(find.byKey(const Key('activity-start-stop')));
      await tester.pumpAndSettle();
      await waitUntil(() => c.focus?.running == null && !c.busy);
      // The activity stays focused with its intervals until «Terminar».
      await waitUntil(
        () => find.byKey(const Key('finish-activity')).evaluate().isNotEmpty,
        'finish',
      );
      await tester.ensureVisible(find.byKey(const Key('finish-activity')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('finish-activity')));
      await tester.pumpAndSettle();
      // The end dialog asks for the closing time; accept the default.
      await waitUntil(
        () => find.text('Guardar').evaluate().isNotEmpty,
        'end dialog',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      await waitUntil(
        () =>
            c.focus == null &&
            find.byKey(const Key('new-activity')).evaluate().isNotEmpty,
        'idle',
      );

      // «Beber agua»: Puntual with Vasos (number/sum).
      await buildActivity(
        name: 'Beber agua',
        rhythm: 'rhythm-instant',
        fields: const [('Vasos', 'vasos', 'number')],
      );
      // Elegir una plantilla Puntual ya abre la hoja de registro; si no quedó
      // abierta, el botón «Registrar» de la barra idle la abre.
      await tester.pumpAndSettle();
      if (find.byKey(const Key('record-vasos')).evaluate().isEmpty) {
        await waitUntil(
          () => find.byKey(const Key('record-instant')).evaluate().isNotEmpty,
          'instant',
        );
        await tester.ensureVisible(find.byKey(const Key('record-instant')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('record-instant')));
        await tester.pumpAndSettle();
      }
      await waitUntil(
        () => find.byKey(const Key('record-vasos')).evaluate().isNotEmpty,
        'hoja',
      );
      await tester.enterText(find.byKey(const Key('record-vasos')), '1');
      await tester.tap(find.byKey(const Key('record-submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Registrado'), findsWidgets);

      // The recorded quantity is one message with the burst, not a total.
      final leer = (await tester.runAsync(
        () => repo.loadActivities(),
      ))!.where((a) => a.definition.companionId == 'gymbro').toList();
      final pages = leer
          .firstWhere((a) => a.definition.name == 'Leer')
          .messages
          .where((m) => m.metrics['paginas'] is num)
          .map((m) => m.metrics['paginas'] as num);
      expect(pages.fold<num>(0, (num a, num b) => a + b) as int, 18);
      final agua = (await tester.runAsync(
        () => repo.templates.list(companionId: 'gymbro'),
      ))!;
      expect(
        agua.map((t) => t.definition.name),
        containsAll(['Leer', 'Beber agua']),
      );

      // Full restart over the same database keeps the data.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final saved = await repo.templates.list(companionId: 'gymbro');
      await repo.close();
      c.dispose();
      await tester.pump();
      final repo2 = await SqliteWorkoutRepository.open(path: dbPath);
      final c2 = WorkoutController(repo2);
      await c2.refresh();
      final again = (await repo2.loadActivities())
          .where((a) => a.definition.companionId == 'gymbro')
          .toList();
      final pages2 = again
          .firstWhere((a) => a.definition.name == 'Leer')
          .messages
          .where((m) => m.metrics['paginas'] is num)
          .map((m) => m.metrics['paginas'] as num);
      expect(pages2.fold<num>(0, (num a, num b) => a + b) as int, 18);
      expect(saved.map((t) => t.definition.name), contains('Leer'));
      await repo2.close();
      await dir.delete(recursive: true);
    } finally {
      for (final key in const [
        'gymia.ai.config.v1',
        'gymia.ai.config.v1.verified',
        'gymia.ai.chat.v1',
      ]) {
        await storage.delete(key: key);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 6)));
}
