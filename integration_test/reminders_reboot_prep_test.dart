import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trackia/domain/reminder.dart';

/// Prepares the reboot step of R6 (T064/T065): schedules one reminder and
/// leaves it scheduled. Run it with `--no-uninstall`, reboot the phone and
/// compare `adb shell dumpsys alarm | grep PAQUETE` before and after.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.gymia.app/reminders');

  testWidgets('one reminder is left scheduled for the reboot check', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Prueba de reinicio'))),
    );
    await tester.runAsync(() async {
      final now = DateTime.now();
      final minute = now.hour * 60 + now.minute;
      if (minute > 1300) {
        throw StateError('Ejecuta esta prueba antes de las 21:40.');
      }
      final snapshot = {
        'version': 1,
        'profileId': 'reboot-qa',
        'generatedAt': now.millisecondsSinceEpoch,
        'reminders': [
          ReminderEntry(
            id: 'reboot-${now.millisecondsSinceEpoch}',
            companionId: 'lectura',
            companionName: 'Lectura',
            days: 127,
            windowStartMin: minute + 40,
            windowEndMin: minute + 55,
            tone: 'cheer',
            paused: false,
            templates: ReminderTemplates.defaults(
              tone: 'cheer',
              companionId: 'lectura',
            ),
          ).toJson(),
        ],
      };
      expect(
        await channel.invokeMethod<bool>('sync', {
          'snapshot': jsonEncode(snapshot),
        }),
        isTrue,
      );
      final status = Map<String, dynamic>.from(
        (await channel.invokeMapMethod<String, dynamic>('status'))!,
      );
      expect(status['scheduled'], greaterThanOrEqualTo(1));
    });
  });
}
