import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymia/application/rest_notifications.dart';
import 'package:gymia/application/workout_controller.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/domain/activity.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  test('Android delivers activity and rest deadlines', () async {
    final dir = await Directory.systemTemp.createTemp('trackia-alarm-qa-');
    final repo = await SqliteWorkoutRepository.open(
      path: '${dir.path}/qa.sqlite',
    );
    final controller = WorkoutController(repo);
    final notifier = RestNotificationController(controller);
    try {
      await controller.refresh();
      await notifier.initialize();
      if (!notifier.enabled || !notifier.granted) {
        await notifier.toggle(true);
      }
      expect(notifier.granted, isTrue, reason: notifier.error);
      final id = await repo.prepareActivity(
        ActivityDefinition(
          name: 'Pomodoro prueba',
          activitySeconds: 3,
          restSeconds: 3,
          targetCycles: 4,
          companionId: 'enfoque',
        ),
      );
      await controller.refresh();
      await controller.run(() => repo.startInterval(id));
      await Future<void>.delayed(const Duration(seconds: 1));
      final scheduled = await RestNotificationController.channel
          .invokeMapMethod<String, dynamic>('status');
      expect(
        (scheduled?['scheduledActivityEnd'] as num).toInt(),
        greaterThan(0),
      );
      await Future<void>.delayed(const Duration(seconds: 5));
      var status = await RestNotificationController.channel
          .invokeMapMethod<String, dynamic>('status');
      expect(status?['lastDeliveredId'], id);
      final activityEnd = (status?['lastDeliveredEnd'] as num).toInt();
      await controller.run(() => repo.stopInterval(id));
      await Future<void>.delayed(const Duration(seconds: 1));
      status = await RestNotificationController.channel
          .invokeMapMethod<String, dynamic>('status');
      expect(
        (status?['scheduledRestEnd'] as num).toInt(),
        greaterThan(activityEnd),
      );
      await Future<void>.delayed(const Duration(seconds: 8));
      status = await RestNotificationController.channel
          .invokeMapMethod<String, dynamic>('status');
      expect(status?['lastDeliveredId'], id);
      expect(
        (status?['lastDeliveredEnd'] as num).toInt(),
        greaterThan(activityEnd),
      );
    } finally {
      notifier.dispose();
      controller.dispose();
      await repo.close();
      await dir.delete(recursive: true);
      await RestNotificationController.channel.invokeMethod<void>('cancel');
    }
  });
}
