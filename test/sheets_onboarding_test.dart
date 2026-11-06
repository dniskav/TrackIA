import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/profile_store.dart';
import 'package:trackia/data/sheet_context_store.dart';
import 'package:trackia/domain/sheet_context.dart';
import 'package:trackia/domain/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.gymia.app/google-sheets');
  const accountA = UserProfile(subject: 'sheets-a', email: 'a@example.test');
  const accountB = UserProfile(subject: 'sheets-b', email: 'b@example.test');
  final profiles = ProfileStore.instance;
  final calls = <MethodCall>[];
  var nextIdentity = accountA;
  var authorizationResult = true;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await profiles.load();
    calls.clear();
    nextIdentity = accountA;
    authorizationResult = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'connectIdentity' => nextIdentity.toJson(),
            'authorize' => authorizationResult,
            'disconnect' => null,
            _ => throw StateError('Unexpected Sheets call ${call.method}'),
          };
        });
  });

  tearDown(() async {
    await profiles.useLocal();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FlutterSecureStorage.setMockInitialValues({});
  });

  SheetContext destination(String id) => SheetContext(
    id: id,
    name: 'Fixture $id',
    title: 'Entrenamientos',
    loadedAt: DateTime(2026, 11, 5),
    rows: [
      ['synthetic'],
    ],
  );

  test(
    'new and existing accounts authorize against their captured profile',
    () async {
      await profiles.connect();
      await profiles.authorizeSheets(profileId: accountA.id);
      expect(calls.last.arguments, {
        'expectedSubject': accountA.subject,
        'email': accountA.email,
      });

      nextIdentity = accountB;
      await profiles.connect();
    nextIdentity = accountA;
      await profiles.connect(expectedSubject: accountA.subject);
      await profiles.authorizeSheets(profileId: accountA.id);
      expect(profiles.activeId, accountA.id);
      expect(calls.last.arguments, {
        'expectedSubject': accountA.subject,
        'email': accountA.email,
      });
      await expectLater(
        profiles.authorizeSheets(profileId: accountB.id),
        throwsFormatException,
      );
    },
  );

  test(
    'denied permission and cancelled selection leave the previous destination untouched',
    () async {
      await profiles.connect();
      const store = SheetContextStore(profileId: 'local');
      await store.save(destination('previous'));
      authorizationResult = false;
      await expectLater(
        profiles.authorizeSheets(profileId: accountA.id),
        throwsFormatException,
      );
      // A cancelled UI selection does not call the store; the saved value remains.
      expect((await store.load())?.id, 'previous');
      expect(calls.map((call) => call.method), [
        'connectIdentity',
        'authorize',
      ]);
    },
  );
}
