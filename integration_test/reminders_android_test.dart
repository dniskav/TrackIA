import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymia/domain/reminder.dart';

/// R6 of specs/004-trackia-experience/quickstart.md, the part that runs inside
/// the app: a snapshot with a window one minute away posts a notice on
/// `trackia_reminders_v1`, and the same reminder already done today posts none.
/// Real Android alarms, receiver and notification; no AI.
///
/// Needs POST_NOTIFICATIONS for the test package:
///   adb shell pm grant PAQUETE android.permission.POST_NOTIFICATIONS
/// The reboot step is checked from outside (see docs/0.3.32-RECORDATORIOS.md).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.gymia.app/reminders');

  Map<String, Object?> entry(
    String id, {
    required int startMin,
    required int endMin,
    String? lastDoneDate,
    int? lastCallMin,
    int days = 127,
  }) => ReminderEntry(
    id: id,
    companionId: 'lectura',
    companionName: 'Lectura',
    days: days,
    windowStartMin: startMin,
    windowEndMin: endMin,
    lastCallMin: lastCallMin,
    tone: 'cheer',
    paused: false,
    lastDoneDate: lastDoneDate,
    lastActivityDate: lastDoneDate,
    templates: ReminderTemplates.defaults(
      tone: 'cheer',
      companionId: 'lectura',
    ),
  ).toJson();

  Future<Map<String, dynamic>> status() async => Map<String, dynamic>.from(
    (await channel.invokeMapMethod<String, dynamic>('status'))!,
  );

  testWidgets('a due reminder posts one notice; a done day posts none', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Prueba de recordatorios'))),
      ),
    );
    await tester.runAsync(() async {
      final limit = DateTime.now().add(const Duration(seconds: 60));
      while ((await status())['permitted'] != true) {
        if (DateTime.now().isAfter(limit)) {
          throw StateError(
            'Concede POST_NOTIFICATIONS al paquete de prueba antes de ejecutar esta prueba.',
          );
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      final now = DateTime.now();
      // Keep the window inside one day: a test run near midnight would roll over.
      final minute = now.hour * 60 + now.minute;
      if (minute > 1380) {
        throw StateError('Ejecuta esta prueba antes de las 23:00.');
      }
      final today = reminderDay(now);
      final profile = 'r6-${now.millisecondsSinceEpoch}';
      final due = 'due-${now.millisecondsSinceEpoch}';
      final done = 'done-${now.millisecondsSinceEpoch}';
      final snapshot = {
        'version': 1,
        'profileId': profile,
        'generatedAt': now.millisecondsSinceEpoch,
        'reminders': [
          entry(due, startMin: minute + 1, endMin: minute + 15),
          entry(
            done,
            startMin: minute + 1,
            endMin: minute + 15,
            lastDoneDate: today,
          ),
        ],
      };
      expect(
        await channel.invokeMethod<bool>('sync', {
          'snapshot': jsonEncode(snapshot),
        }),
        isTrue,
      );
      expect((await status())['scheduled'], greaterThanOrEqualTo(2));

      // The window is inexact (up to 10 minutes); wait for the first notice.
      final deadline = DateTime.now().add(const Duration(minutes: 13));
      while (DateTime.now().isBefore(deadline)) {
        final posted = Map<String, dynamic>.from(
          (await status())['postedToday'] as Map,
        );
        if (posted[due] != null) break;
        await Future<void>.delayed(const Duration(seconds: 5));
      }
      final posted = Map<String, dynamic>.from(
        (await status())['postedToday'] as Map,
      );
      expect(
        posted[due],
        1,
        reason: 'el recordatorio pendiente publicó un aviso',
      );
      // Same window, but the day was already done: nothing is posted.
      expect(posted.containsKey(done), isFalse);

      // Next occurrence stays scheduled (tomorrow), and clearing removes them.
      expect((await status())['scheduled'], greaterThanOrEqualTo(2));
      // Leaves time to send BOOT_COMPLETED from outside and inspect the alarms:
      //   adb shell am broadcast -a android.intent.action.BOOT_COMPLETED -p PAQUETE
      //   adb shell dumpsys alarm | grep PAQUETE
      await Future<void>.delayed(const Duration(seconds: 25));
      expect((await status())['scheduled'], greaterThanOrEqualTo(2));
      await channel.invokeMethod<bool>('clear', {'profileId': profile});
    });
  });
}
