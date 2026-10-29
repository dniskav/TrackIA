import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'alarm_style_android_test.dart' as alarm_style;
import 'appearance_android_test.dart' as appearance;
import 'chat_activity_flow_test.dart' as chat_flow;
import 'chat_scroll_android_test.dart' as chat_scroll;
import 'profile_isolation_android_test.dart' as isolation;
import 'reminders_android_test.dart' as reminders;
import 'rest_notification_android_test.dart' as rest;
import 'routine_flow_test.dart' as routine;
import 'trackia_large_media_test.dart' as large_media;
import 'transfer_flow_test.dart' as transfer;
import 'workout_flow_test.dart' as workout;

/// All the Android integration tests that need no Google or ChatGPT account,
/// in one app, so a phone that asks to confirm every USB install is asked
/// only once. Not part of the regular suite.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('large media', large_media.main);
  group('profile isolation', isolation.main);
  group('appearance', appearance.main);
  group('chat scroll', chat_scroll.main);
  group('chat activity flow', chat_flow.main);
  group('routine flow', routine.main);
  group('workout flow', workout.main);
  group('transfer flow', transfer.main);
  group('alarm style', alarm_style.main);
  group('rest notification', rest.main);
  group('reminders', reminders.main);
}
