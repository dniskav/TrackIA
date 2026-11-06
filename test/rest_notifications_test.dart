import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/application/rest_notifications.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/activity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test(
    'temporary Android block preserves the notification preference',
    () async {
      final dir = await Directory.systemTemp.createTemp('trackia-permission-');
      final repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/db.sqlite',
      );
      final controller = WorkoutController(repo);
      final calls = <String>[];
      var granted = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(RestNotificationController.channel, (
            call,
          ) async {
            calls.add(call.method);
            return call.method == 'status'
                ? {'enabled': true, 'granted': granted, 'exact': true}
                : null;
          });
      final notifier = RestNotificationController(controller);
      addTearDown(() async {
        notifier.dispose();
        controller.dispose();
        await repo.close();
        await dir.delete(recursive: true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(RestNotificationController.channel, null);
      });
      await repo.prepareActivity(ActivityDefinition(name: 'Pomodoro'));
      await controller.refresh();
      await notifier.initialize();
      expect(notifier.enabled, isTrue);
      expect(notifier.granted, isFalse);
      expect(notifier.error, isNotNull);
      expect(calls, isNot(contains('prepared')));
      granted = true;
      await notifier.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(notifier.enabled, isTrue);
      expect(notifier.granted, isTrue);
      expect(calls, contains('prepared'));
    },
  );
  test(
    'one durable rest alarm updates with adjustment and switches to running controls',
    () async {
      final dir = await Directory.systemTemp.createTemp('gymia-notification-');
      var now = DateTime(2026, 10, 8, 10);
      final repo = await SqliteWorkoutRepository.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/db.sqlite',
        clock: () => now,
      );
      final c = WorkoutController(repo, clock: () => now);
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(RestNotificationController.channel, (
            call,
          ) async {
            calls.add(call);
            return call.method == 'status'
                ? {'enabled': true, 'granted': true, 'exact': true}
                : null;
          });
      final notifier = RestNotificationController(c);
      addTearDown(() async {
        notifier.dispose();
        c.dispose();
        await repo.close();
        await dir.delete(recursive: true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(RestNotificationController.channel, null);
      });
      await repo.prepareActivity(
        ActivityDefinition(name: 'Press', restSeconds: 120),
      );
      await c.refresh();
      await notifier.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await c.run(() => repo.startInterval(c.focus!.id));
      now = now.add(const Duration(seconds: 30));
      await c.run(() => repo.stopInterval(c.focus!.id));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(calls.last.method, 'schedule');
      expect(
        calls.last.arguments['end'],
        now.add(const Duration(seconds: 120)).millisecondsSinceEpoch,
      );
      final scheduled = calls.where((v) => v.method == 'schedule').length;
      await c.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(calls.where((v) => v.method == 'schedule').length, scheduled);
      await c.run(
        () => repo.setActivityRest(c.focus!.id, 90, updateActiveRest: true, expectedRestEndsAt: c.focus!.restEndsAt),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        calls.last.arguments['end'],
        now.add(const Duration(seconds: 90)).millisecondsSinceEpoch,
      );
      now = now.add(const Duration(seconds: 20));
      await c.run(() => repo.startInterval(c.focus!.id));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(calls.last.method, 'running');
    },
  );
  test('timed Pomodoro schedules activity and rest deadlines', () async {
    final dir = await Directory.systemTemp.createTemp('trackia-pomodoro-');
    var now = DateTime(2026, 10, 21, 10);
    final repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/db.sqlite',
      clock: () => now,
    );
    final controller = WorkoutController(repo, clock: () => now);
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RestNotificationController.channel, (
          call,
        ) async {
          calls.add(call);
          return call.method == 'status'
              ? {'enabled': true, 'granted': true, 'exact': true}
              : true;
        });
    final notifier = RestNotificationController(controller);
    addTearDown(() async {
      notifier.dispose();
      controller.dispose();
      await repo.close();
      await dir.delete(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(RestNotificationController.channel, null);
    });
    await repo.prepareActivity(
      ActivityDefinition(
        name: 'Estudio',
        activitySeconds: 1500,
        restSeconds: 300,
        targetCycles: 4,
      ),
    );
    await controller.refresh();
    await notifier.initialize();
    await controller.run(() => repo.startInterval(controller.focus!.id));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final running = calls.lastWhere((call) => call.method == 'running');
    expect(
      running.arguments['end'],
      now.add(const Duration(minutes: 25)).millisecondsSinceEpoch,
    );
    now = now.add(const Duration(minutes: 25));
    await controller.run(() => repo.stopInterval(controller.focus!.id));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final rest = calls.lastWhere((call) => call.method == 'schedule');
    expect(
      rest.arguments['end'],
      now.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
    );
  });
}
