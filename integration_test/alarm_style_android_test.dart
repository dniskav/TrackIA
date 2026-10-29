import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Posts one end-of-rest notice with "Tratar como alarma" on and one with it
/// off. The delivery channel is inspected from outside with
/// `adb shell dumpsys notification --noredact`; see
/// specs/004-trackia-experience/quickstart.md → R1.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.gymia.app/rest-notifications');

  testWidgets('end of rest uses the alarm channel only when alarm style is on', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Prueba de aviso como alarma'))),
      ),
    );
    await tester.runAsync(() async {
      final limit = DateTime.now().add(const Duration(seconds: 60));
      while (true) {
        final status = await channel.invokeMapMethod<String, dynamic>('status');
        if (status?['granted'] == true && status?['exact'] == true) break;
        if (DateTime.now().isAfter(limit)) {
          throw StateError(
            'Concede POST_NOTIFICATIONS y alarmas exactas al paquete de prueba antes de ejecutar esta prueba.',
          );
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      expect(
        await channel.invokeMethod<bool>('enable', {'enabled': true}),
        isTrue,
      );
      final initial = await channel.invokeMapMethod<String, dynamic>('status');
      expect(initial?.containsKey('alarmStyle'), isTrue);
      expect(initial?.containsKey('dnd'), isTrue);
      expect(initial?['alarmChannelBlocked'], isFalse);

      Future<void> deliver(String id, bool alarm) async {
        await channel.invokeMethod<bool>('setAlarmStyle', {'enabled': alarm});
        final status = await channel.invokeMapMethod<String, dynamic>('status');
        expect(status?['alarmStyle'], alarm);
        final end =
            DateTime.now().add(const Duration(seconds: 6)).millisecondsSinceEpoch;
        await channel.invokeMethod<void>('schedule', {
          'id': id,
          'end': end,
          'name': 'Prueba $id',
          'profileId': 'local',
        });
        // Leaves time for adb to inspect the delivered notification.
        await Future<void>.delayed(const Duration(seconds: 18));
        final result = await channel.invokeMapMethod<String, dynamic>('status');
        expect(result?['lastDeliveredId'], id);
        expect(result?['lastDeliveredEnd'], end);
      }

      await deliver('alarma-activada', true);
      await deliver('alarma-desactivada', false);
      expect(await channel.invokeMethod<bool>('testAlarm'), isTrue);
      await Future<void>.delayed(const Duration(seconds: 12));
    });
  });
}
