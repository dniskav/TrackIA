import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/application/workout_controller.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/data/welcome_settings_store.dart';
import 'package:gymia/ui/app.dart';
import 'package:gymia/ui/assistant_chat.dart';
import 'package:gymia/ui/companions.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  testWidgets('switching companion replaces the chat and back reaches the dashboard', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    WelcomeSettings.instance.offeredThisLaunch = true;
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('trackia-switch-'),
    ))!;
    final repo = (await tester.runAsync(
      () => SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/test.sqlite',
      ),
    ))!;
    final controller = WorkoutController(repo);
    await tester.runAsync(controller.refresh);
    await tester.pumpWidget(GymApp(controller: controller));
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    AssistantChatScreen chat() =>
        tester.widget<AssistantChatScreen>(find.byType(AssistantChatScreen));

    await tester.tap(find.byKey(const Key('companion-gymbro')));
    await tester.pumpAndSettle();
    expect(chat().companion?.id, 'gymbro');

    await tester.tap(find.byKey(const Key('companion-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-to-calma')));
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatScreen), findsOneWidget);
    expect(chat().companion?.id, 'calma');

    // The app is localized in Spanish, so pageBack() cannot find «Back».
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(AssistantChatScreen), findsNothing);
    expect(find.byType(CompanionDashboard), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await tester.runAsync(repo.close);
    await tester.runAsync(() => dir.delete(recursive: true));
  });
}
