import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/data/welcome_settings_store.dart';
import 'package:trackia/ui/app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/real_io.dart';

/// The pieces built in phases 5–9 are reachable from the real app, not only
/// when a screen is mounted directly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  testWidgets(
    'a companion chat reaches progress, mode and notices from the app',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      WelcomeSettings.instance.offeredThisLaunch = true;
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('trackia-wiring-'),
      ))!;
      final repo = (await tester.runAsync(
        () => SqliteWorkoutRepository.open(
          factory: databaseFactoryFfi,
          path: '${dir.path}/t.sqlite',
        ),
      ))!;
      final controller = WorkoutController(repo);
      await tester.runAsync(controller.refresh);
      await tester.pumpWidget(GymApp(controller: controller));
      await realIo(tester, 30);

      await tester.tap(find.byKey(const Key('companion-gymbro')));
      await realIo(tester, 30);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const Key('chat-menu')));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('menu-progress')), findsOneWidget);
      expect(find.byKey(const Key('menu-companion-settings')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await realIo(tester, 10);
      controller.dispose();
      await tester.runAsync(() async {
        await repo.close();
        await dir.delete(recursive: true);
      });
    },
  );
}
