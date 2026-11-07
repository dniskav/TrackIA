import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trackia/application/companion_creation.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/ai_settings_store.dart';
import 'package:trackia/data/companion_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/data/welcome_settings_store.dart';
import 'package:trackia/domain/ai_config.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/companion_package.dart';
import 'package:trackia/domain/reminder.dart';
import 'package:trackia/domain/user_profile.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';
import 'package:trackia/ui/app.dart';
import 'package:trackia/ui/companion_share.dart';

/// T062 (specs/005-conversacion-memoria): a companion is exported to a
/// `.trackia` file and imported back in the real app as a NEW companion.
///
/// Real on the emulator: SQLite, secure storage, `GymApp`, the dashboard's
/// «Importar acompañante» (`import-companion`) and the import screen.
///
/// Limits (documented on purpose):
/// - The export is driven through a small host `MaterialApp` that calls
///   `shareCompanionPackage` with an injected `share`. The settings screen
///   (`share-companion`) passes no `share`, so from the full app the system
///   share sheet would open and the file could not be captured. The host uses
///   the same localization and theme. Its file-building path is the real one.
/// - The original companion is created with `CompanionCreation` directly, not
///   with the manual creator form.
/// - Forbidden-field and future-version packages are built in the test with
///   the real gzip/base64url format; the rest of the validation matrix lives in
///   `test/companion_import_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Real I/O (SQLite, secure storage, files) needs real time while the widget
  /// clock is faked. Same approach as `test/helpers/real_io.dart`.
  Future<void> realIo(WidgetTester tester, [int rounds = 60]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
    }
    await tester.pump();
  }

  /// The JSON inside a `.trackia` text, without going through the model.
  String jsonOf(String text) => utf8.decode(
    gzip.decode(base64Url.decode(base64Url.normalize(text))),
  );

  Map<String, Object?> rawJson(String text) =>
      jsonDecode(jsonOf(text)) as Map<String, Object?>;

  /// Every key at any depth.
  Iterable<String> keysDeep(Object? value) sync* {
    if (value is Map) {
      for (final e in value.entries) {
        yield e.key as String;
        yield* keysDeep(e.value);
      }
    } else if (value is List) {
      for (final e in value) {
        yield* keysDeep(e);
      }
    }
  }

  /// Text in the same format as a `.trackia` file, built from raw JSON.
  String packageText(Object json) => base64Url
      .encode(gzip.encode(utf8.encode(jsonEncode(json))))
      .replaceAll('=', '');

  testWidgets(
    'export then import creates a new companion, without identity or secrets',
    (tester) async {
      const profileId = 'qa-companion-package';
      const secret = 'sk-no-debe-viajar-t062';
      const storage = FlutterSecureStorage();
      const store = CompanionStore(profileId: profileId);
      final aiStore = AiSettingsStore(profileId: profileId);
      final l = lookupAppLocalizations(const Locale('es'));
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('gymia-companion-package-qa-'),
      ))!;
      final folder = Directory('${dir.path}/share');
      await tester.runAsync(() => folder.create());
      final repo = (await tester.runAsync(
        () => SqliteWorkoutRepository.open(path: '${dir.path}/package.sqlite'),
      ))!;
      final controller = WorkoutController(repo, profileId: profileId);
      final creation = CompanionCreation(
        store: store,
        progress: repo.progress,
        templates: repo.templates,
      );

      Future<List<String>> ids() async => [
        for (final c in (await store.load())) c.id,
      ];

      Widget shareHost(Companion companion, void Function(XFile) onShared) =>
          MaterialApp(
            theme: gymTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('es'),
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: Center(
                      child: FilledButton(
                        key: const Key('share-host-open'),
                        onPressed:
                            () => shareCompanionPackage(
                              context,
                              companion: companion,
                              temporaryDirectory: () async => folder,
                              share: (
                                files, {
                                subject,
                                text,
                                sharePositionOrigin,
                              }) async {
                                onShared(files.single);
                              },
                            ),
                        child: const Text('Compartir'),
                      ),
                    ),
                  ),
            ),
          );

      try {
        // Start from a clean profile (the companion key may hold a previous run).
        await tester.runAsync(() => storage.delete(key: store.key));
        WelcomeSettings.instance.offeredThisLaunch = true;

        // (1) A companion with its own instructions and colour, plus reminder
        // texts. The secret AI key must never reach the package.
        final original = (await tester.runAsync(() async {
          final created = await creation.create(
            const CompanionDraft(
              name: 'Lectura',
              description: 'Libros y notas',
              prompt: 'Tono sereno y breve. Pregunta qué libro leo hoy.',
              icon: 'book',
              color: 'teal',
            ),
          );
          final withCopy = created.copyWith(
            reminderCopy: const ReminderTemplates(
              windowStart: ['Hora de leer un rato'],
              lastCall: ['Aún estás a tiempo de leer'],
              inactive: [],
            ),
          );
          await store.upsert(withCopy);
          await aiStore.save(
            const AiConfig(
              service: AiService.custom,
              protocol: AiProtocol.chatCompletions,
              baseUrl: 'https://example.test/v1',
              model: 'test',
              apiKey: secret,
            ),
          );
          return withCopy;
        }))!;
        expect(original.id, 'lectura');

        // (2) Export: confirm the share dialog; the file is captured, not sent.
        final shared = Completer<XFile>();
        await tester.pumpWidget(
          shareHost(original, (file) {
            if (!shared.isCompleted) shared.complete(file);
          }),
        );
        await tester.tap(find.byKey(const Key('share-host-open')));
        await tester.pumpAndSettle();
        expect(find.text(l.packageShareTitle), findsOneWidget);
        await tester.tap(find.byKey(const Key('share-companion-confirm')));
        for (var i = 0; i < 60 && !shared.isCompleted; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(shared.isCompleted, isTrue, reason: 'nothing was shared');
        final file = await shared.future;
        expect(file.name, 'Lectura.trackia');

        // (3) What travels: only the allowed fields, no identity, no secrets.
        final text =
            (await tester.runAsync(() => File(file.path).readAsString()))!;
        final package = CompanionPackage.decode(text);
        expect(package.name, 'Lectura');
        expect(package.icon, 'book');
        expect(package.color, 'teal');
        expect(package.description, 'Libros y notas');
        expect(
          package.instructions,
          'Tono sereno y breve. Pregunta qué libro leo hoy.',
        );
        expect(package.mode, 'reminder');
        expect(package.reminders?.windowStart, ['Hora de leer un rato']);
        expect(package.reminders?.lastCall, ['Aún estás a tiempo de leer']);

        final raw = rawJson(text);
        expect(raw.keys.toSet(), {
          ...CompanionPackage.allowedKeys,
          'format',
          'checksum',
        });
        expect(
          keysDeep(raw).where(
            (k) => CompanionPackage.forbiddenKeys.contains(k.toLowerCase()),
          ),
          isEmpty,
        );
        expect(jsonOf(text).contains(secret), isFalse);
        expect(tester.takeException(), isNull);

        // (4) Import in the real app: dashboard → Importar acompañante.
        await tester.pumpWidget(GymApp(controller: controller));
        await realIo(tester);
        await tester.pumpAndSettle();
        final beforeIds = await tester.runAsync(ids);
        expect(beforeIds, contains('lectura'));

        await tester.tap(find.byKey(const Key('import-companion')));
        await tester.pumpAndSettle();

        // Hostile pastes create nothing: block text, future version, and a
        // package carrying a forbidden key (an API key).
        Future<void> pasteAndPreview(String pasted) async {
          await tester.enterText(find.byKey(const Key('import-paste')), pasted);
          await tester.tap(find.byKey(const Key('import-preview')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('import-error')), findsOneWidget);
          expect(find.byKey(const Key('import-save')), findsNothing);
        }

        await pasteAndPreview(
          '```trackia-companion\n$text\n```',
        );
        await pasteAndPreview(
          packageText({...raw, 'format': 'trackia-companion/2'}),
        );
        await pasteAndPreview(
          packageText({...raw, 'apiKey': secret}),
        );
        expect(await tester.runAsync(ids), beforeIds);

        // The valid package: preview, then save as a new companion.
        await tester.enterText(find.byKey(const Key('import-paste')), text);
        await tester.tap(find.byKey(const Key('import-preview')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('import-error')), findsNothing);
        expect(find.byKey(const Key('import-external-notice')), findsOneWidget);
        final nameField = tester.widget<TextField>(
          find.byKey(const Key('import-name')),
        );
        expect(nameField.controller!.text, 'Lectura');

        await tester.tap(find.byKey(const Key('import-save')));
        await realIo(tester, 120);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('import-save')), findsNothing);

        // (5) Two companions with different ids; the copy is in reminder mode,
        // with no goal and no active reminder; the original did not change.
        await tester.runAsync(() async {
          final all = await store.load();
          final copy = all.singleWhere((c) => c.id == 'lectura-2');
          final first = all.singleWhere((c) => c.id == 'lectura');
          expect(
            all.where((c) => c.id == 'lectura' || c.id == 'lectura-2').length,
            2,
          );
          expect(copy.id, isNot(first.id));
          expect(copy.name, 'Lectura');
          expect(copy.description, 'Libros y notas');
          expect(copy.prompt, original.prompt);
          expect(copy.icon, 'book');
          expect(copy.color, 'teal');
          expect(copy.reminderCopy?.windowStart, ['Hora de leer un rato']);

          expect((await repo.progress.settings('lectura-2')).game, isFalse);
          expect(await repo.progress.activeGoal('lectura-2'), isNull);
          expect(await repo.progress.reminderFor('lectura-2'), isNull);

          expect(first.name, original.name);
          expect(first.description, original.description);
          expect(first.prompt, original.prompt);
          expect(first.icon, original.icon);
          expect(first.color, original.color);
          expect(first.reminderCopy?.lastCall, ['Aún estás a tiempo de leer']);
          expect((await repo.progress.settings('lectura')).game, isFalse);
          expect(await repo.progress.activeGoal('lectura'), isNull);
        });
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        controller.dispose();
        await tester.runAsync(() async {
          await storage.delete(key: store.key);
          await storage.delete(
            key: profileStorageKey('trackia.ai.config.v1', profileId),
          );
          await repo.close();
          await dir.delete(recursive: true);
        });
      }
    },
  );
}
