import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/application/ai_availability.dart';
import 'package:gymia/application/progress_service.dart';
import 'package:gymia/application/workout_controller.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/domain/activity.dart';
import 'package:gymia/ui/assistant_chat.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/real_io.dart';

/// Research D15: after five done days in a row a reminder companion offers
/// game mode, once, with «Activar», «Ahora no» and «No volver a sugerir».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController controller;
  late ProgressService service;
  late DateTime now;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    now = DateTime(2026, 10, 29, 9);
    dir = await Directory.systemTemp.createTemp('trackia-suggestion-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
    controller = WorkoutController(repo, clock: () => now);
    service = ProgressService(progress: repo.progress, clock: () => now);
  });
  tearDown(() async {
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
  });

  /// One point record on each of the [days] days ending [end] (inclusive).
  Future<void> record(List<int> days) async {
    final at = now;
    for (final day in days) {
      now = DateTime(2026, 10, day, 12);
      await repo.observations.record(
        companionId: 'gymbro',
        definition: ActivityDefinition(
          name: 'Algo',
          repeated: false,
          restSeconds: 0,
        ),
        original: 'Hecho',
      );
    }
    now = at;
  }

  group('when to offer it', () {
    test('five days in a row, ending today or yesterday', () async {
      await record([25, 26, 27, 28, 29]);
      expect(await service.gameSuggestionDue('gymbro'), isTrue);
      now = DateTime(2026, 10, 30, 9); // today still open: ends yesterday
      expect(await service.gameSuggestionDue('gymbro'), isTrue);
      now = DateTime(2026, 10, 31, 9); // a missed day breaks it
      expect(await service.gameSuggestionDue('gymbro'), isFalse);
    });

    test('four days are not enough, and a gap restarts the count', () async {
      await record([26, 27, 28, 29]);
      expect(await service.gameSuggestionDue('gymbro'), isFalse);
      await record([
        20,
        21,
        22,
        24,
        25,
      ]); // 23 is missing: 24..29 is six, but see below
      expect(await service.gameSuggestionDue('gymbro'), isTrue);
    });

    test('free days do not count here: a single miss breaks the run', () async {
      await record([24, 25, 27, 28, 29]); // the 26th is missing
      expect(await service.gameSuggestionDue('gymbro'), isFalse);
    });

    test(
      'never in game mode, and never again after «No volver a sugerir»',
      () async {
        await record([25, 26, 27, 28, 29]);
        await service.dismissGameSuggestion('gymbro');
        await service.dismissGameSuggestion('gymbro'); // idempotent
        expect(await service.gameSuggestionDue('gymbro'), isFalse);
        expect((await repo.progress.settings('gymbro')).dismissedSuggestions, [
          'game',
        ]);
        // Another companion is not affected.
        expect(
          (await repo.progress.settings('enfoque')).dismissedSuggestions,
          isEmpty,
        );

        final other = ProgressService(
          progress: repo.progress,
          clock: () => now,
        );
        expect(await other.gameSuggestionDue('gymbro'), isFalse);
      },
    );

    test('«Activar» moves the companion to game mode', () async {
      await record([25, 26, 27, 28, 29]);
      await service.activateGame('gymbro');
      expect((await repo.progress.settings('gymbro')).game, isTrue);
      expect(await service.gameSuggestionDue('gymbro'), isFalse);
    });
  });

  group('the card in the chat', () {
    Future<void> openChat(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AssistantChatScreen(
            controller: controller,
            progressService: service,
            availability: AiAvailability(),
          ),
        ),
      );
      await realIo(tester, 30);
    }

    testWidgets('it appears after five days with its fixed text', (
      tester,
    ) async {
      await tester.runAsync(() => record([25, 26, 27, 28, 29]));
      await openChat(tester);
      expect(find.byKey(const Key('game-suggestion')), findsOneWidget);
      expect(
        find.text(
          'Llevas varios días seguidos cumpliendo. ¿Quieres activar el modo Juego para ver metas, rachas y logros?',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('it does not appear with fewer days', (tester) async {
      await tester.runAsync(() => record([27, 28, 29]));
      await openChat(tester);
      expect(find.byKey(const Key('game-suggestion')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('«Ahora no» hides it for now; it can come back', (
      tester,
    ) async {
      await tester.runAsync(() => record([25, 26, 27, 28, 29]));
      await openChat(tester);
      await tester.tap(find.byKey(const Key('suggest-later')));
      await tester.pump();
      expect(find.byKey(const Key('game-suggestion')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await realIo(tester, 5);
      await openChat(tester);
      expect(find.byKey(const Key('game-suggestion')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('«No volver a sugerir» is remembered', (tester) async {
      await tester.runAsync(() => record([25, 26, 27, 28, 29]));
      await openChat(tester);
      await tester.tap(find.byKey(const Key('suggest-never')));
      await realIo(tester, 20);
      expect(find.byKey(const Key('game-suggestion')), findsNothing);
      expect(
        (await tester.runAsync(
          () => repo.progress.settings('gymbro'),
        ))!.dismissedSuggestions,
        ['game'],
      );
      await tester.pumpWidget(const SizedBox());
      await realIo(tester, 5);
      await openChat(tester);
      expect(find.byKey(const Key('game-suggestion')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('«Activar» turns game mode on and says so', (tester) async {
      await tester.runAsync(() => record([25, 26, 27, 28, 29]));
      await openChat(tester);
      await tester.tap(find.byKey(const Key('suggest-activate')));
      await realIo(tester, 40);
      expect(find.byKey(const Key('game-suggestion')), findsNothing);
      expect(
        find.text('Modo Juego activado. Verás tus metas, rachas y logros.'),
        findsOneWidget,
      );
      expect(
        (await tester.runAsync(() => repo.progress.settings('gymbro')))!.game,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a companion already in game mode is not offered it', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await record([25, 26, 27, 28, 29]);
        await service.activateGame('gymbro');
      });
      await openChat(tester);
      expect(find.byKey(const Key('game-suggestion')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
