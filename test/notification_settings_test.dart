import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/application/rest_notifications.dart';
import 'package:gymia/application/workout_controller.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/ui/notification_settings.dart';
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

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('trackia-notify-ui-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/db.sqlite',
    );
    controller = WorkoutController(repo);
    calls = [];
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
          if (call.method == 'status') return status;
          if (call.method == 'test' || call.method == 'testAlarm') return true;
          if (call.method == 'enable') return true;
          return null;
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

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(notifications: notifier),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> methods() => calls.map((c) => c.method).toList();

  testWidgets('the Do Not Disturb banner appears only when it is active', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('notify-dnd-banner')), findsNothing);
    expect(find.text('Avisos'), findsOneWidget);

    status = {...status, 'dnd': true, 'dndFilter': 2};
    await notifier.initialize();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notify-dnd-banner')), findsOneWidget);
    expect(find.text('No molestar está activo'), findsOneWidget);
    expect(find.textContaining('suenan como alarma'), findsOneWidget);
  });

  testWidgets('total silence is explained instead of promising sound', (
    tester,
  ) async {
    status = {...status, 'dnd': true, 'dndFilter': 3};
    await open(tester);
    expect(find.textContaining('Silencio total'), findsWidgets);
    expect(find.textContaining('suenan como alarma'), findsNothing);
  });

  testWidgets('each switch and button calls the matching bridge method', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('notify-alarm-style')));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'setAlarmStyle').single.arguments, {
      'enabled': false,
    });

    await tester.ensureVisible(find.byKey(const Key('notify-test')));
    await tester.tap(find.byKey(const Key('notify-test')));
    await tester.pumpAndSettle();
    expect(methods(), contains('test'));

    await tester.ensureVisible(find.byKey(const Key('notify-test-alarm')));
    await tester.tap(find.byKey(const Key('notify-test-alarm')));
    await tester.pumpAndSettle();
    expect(methods(), contains('testAlarm'));
    expect(find.textContaining('5 segundos'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('notify-open-dnd')));
    await tester.tap(find.byKey(const Key('notify-open-dnd')));
    await tester.pumpAndSettle();
    expect(methods(), contains('openDndSettings'));

    await tester.tap(find.byKey(const Key('notify-enabled')));
    await tester.pumpAndSettle();
    expect(methods(), contains('enable'));
  });

  testWidgets('a blocked alarm channel offers the channel settings', (
    tester,
  ) async {
    status = {...status, 'alarmChannelBlocked': true};
    await open(tester);
    await tester.tap(find.byKey(const Key('notify-channel-blocked')));
    await tester.pumpAndSettle();
    expect(
      calls.where((c) => c.method == 'openChannelSettings').single.arguments,
      {'channel': 'alarm'},
    );
  });

  testWidgets('without the Android bridge the screen says so', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RestNotificationController.channel, (
          call,
        ) async {
          throw MissingPluginException();
        });
    await open(tester);
    expect(find.textContaining('solo están disponibles en Android'), findsOne);
    expect(find.byKey(const Key('notify-alarm-style')), findsNothing);
  });
}
