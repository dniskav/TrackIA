import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/rest_notifications.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory dir;
  late SqliteWorkoutRepository repo;
  late WorkoutController controller;
  late RestNotificationController notifier;
  late List<MethodCall> calls;
  late Map<String, Object?> status;
  Object? Function(MethodCall)? override;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('trackia-alarm-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/db.sqlite',
    );
    controller = WorkoutController(repo);
    calls = [];
    override = null;
    status = {
      'enabled': true,
      'granted': true,
      'exact': true,
      'alarmStyle': true,
      'dnd': false,
      'dndFilter': 1,
      'alarmChannelBlocked': false,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RestNotificationController.channel, (
          call,
        ) async {
          calls.add(call);
          final custom = override?.call(call);
          if (custom != null) return custom;
          return call.method == 'status' ? status : null;
        });
    notifier = RestNotificationController(controller);
  });

  tearDown(() async {
    notifier.dispose();
    controller.dispose();
    await repo.close();
    await dir.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RestNotificationController.channel, null);
  });

  test('status exposes alarm style and Do Not Disturb state', () async {
    await notifier.initialize();
    expect(notifier.alarmStyle, isTrue);
    expect(notifier.dnd, isFalse);
    expect(notifier.alarmChannelBlocked, isFalse);

    status = {...status, 'alarmStyle': false, 'dnd': true, 'dndFilter': 2};
    await notifier.initialize();
    expect(notifier.alarmStyle, isFalse);
    expect(notifier.dnd, isTrue);
    expect(notifier.dndFilter, 2);

    status = {...status, 'alarmChannelBlocked': true};
    await notifier.initialize();
    expect(notifier.alarmChannelBlocked, isTrue);
  });

  test('an older native bridge without the new keys keeps safe defaults', () async {
    status = {'enabled': true, 'granted': true, 'exact': true};
    await notifier.initialize();
    expect(notifier.alarmStyle, isTrue);
    expect(notifier.dnd, isFalse);
    expect(notifier.alarmChannelBlocked, isFalse);
  });

  test('setAlarmStyle calls the bridge and updates state', () async {
    await notifier.initialize();
    await notifier.setAlarmStyle(false);
    final call = calls.lastWhere((c) => c.method == 'setAlarmStyle');
    expect(call.arguments, {'enabled': false});
    expect(notifier.alarmStyle, isFalse);
  });

  test('a failed setAlarmStyle keeps the previous value and reports it', () async {
    await notifier.initialize();
    override = (call) {
      if (call.method == 'setAlarmStyle') {
        throw PlatformException(code: 'REST_NOTIFICATION');
      }
      return null;
    };
    await notifier.setAlarmStyle(false);
    expect(notifier.alarmStyle, isTrue);
    expect(notifier.error, isNotNull);
  });

  test('testAlarm schedules the test notice and reports the result', () async {
    await notifier.initialize();
    override = (call) => call.method == 'testAlarm' ? true : null;
    expect(await notifier.testAlarm(), isTrue);
    expect(notifier.testStatus, contains('5 segundos'));
    expect(calls.map((c) => c.method), contains('testAlarm'));

    override = (call) => call.method == 'testAlarm' ? false : null;
    expect(await notifier.testAlarm(), isFalse);
    expect(notifier.testStatus, contains('Activa los avisos'));
  });

  test('settings shortcuts call the matching native methods', () async {
    await notifier.initialize();
    await notifier.openChannelSettings('alarm');
    await notifier.openDndSettings();
    expect(
      calls.where((c) => c.method == 'openChannelSettings').single.arguments,
      {'channel': 'alarm'},
    );
    expect(calls.map((c) => c.method), contains('openDndSettings'));
  });

  test('a missing native plugin never breaks the controller', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RestNotificationController.channel, (
          call,
        ) async {
          throw MissingPluginException();
        });
    await notifier.initialize();
    expect(notifier.supported, isFalse);
    await notifier.setAlarmStyle(false);
    expect(await notifier.testAlarm(), isFalse);
    await notifier.openDndSettings();
  });
}
