import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trackia/application/workout_controller.dart';
import 'package:trackia/data/profile_store.dart';
import 'package:trackia/data/sqlite_workout_repository.dart';
import 'package:trackia/domain/sheet_context.dart';
import 'package:trackia/domain/user_profile.dart';
import 'package:trackia/ui/google_sheets_import.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.gymia.app/google-sheets');
  const profile = UserProfile(
    subject: 'integration-qa',
    email: 'qa@example.test',
  );

  testWidgets(
    'controlled account connects, selects tab, previews and confirms',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await ProfileStore.instance.load();
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ProfileStore.channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'connectIdentity' => profile.toJson(),
              'authorize' => true,
              'disconnect' => null,
              'list' => {
                'files': [
                  {'id': 'fixture-file', 'name': 'Hoja sintética'},
                ],
                'nextPageToken': '',
              },
              'tabs' => ['Entrenamientos'],
              'read' => [
                ['Fecha', 'Ejercicio'],
                ['2026-11-05', 'Sentadilla'],
              ],
              _ => throw StateError('Unexpected Sheets call ${call.method}'),
            };
          });

      final dir = await Directory.systemTemp.createTemp('gymia-sheet-flow-');
      final repo = await SqliteWorkoutRepository.open(
        path: '${dir.path}/flow.sqlite',
      );
      final controller = WorkoutController(repo, profileId: profile.id);
      Object? result;
      await ProfileStore.instance.connect();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed:
                        () => Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder:
                                    (_) => GoogleSheetsImportScreen(
                                      controller: controller,
                                      forAssistant: true,
                                    ),
                              ),
                            )
                            .then((value) => result = value),
                    child: const Text('Iniciar'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Iniciar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hoja sintética'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrenamientos'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cargar y analizar'));
      await tester.tap(find.text('Cargar y analizar'));
      await tester.pumpAndSettle();

      expect(result, isA<SheetContext>());
      expect((result as SheetContext).rows.last, ['2026-11-05', 'Sentadilla']);
      expect(
        calls.map((c) => c.method),
        containsAllInOrder(['authorize', 'list', 'tabs', 'read']),
      );
      expect(
        calls
            .where((c) => c.method == 'read')
            .single
            .arguments['expectedSubject'],
        profile.subject,
      );

      await ProfileStore.instance.useLocal();
      controller.dispose();
      await repo.close();
      await dir.delete(recursive: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ProfileStore.channel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      FlutterSecureStorage.setMockInitialValues({});
    },
  );
}
