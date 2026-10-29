import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/data/companion_store.dart';
import 'package:gymia/domain/companion.dart';
import 'package:gymia/ui/companions.dart';

void main() {
  testWidgets('dashboard selects, edits and deletes a companion', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    Companion? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: CompanionDashboard(
          profileId: 'local',
          onOpen: (value) => opened = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('companion-gymbro')));
    expect(opened?.id, 'gymbro');

    await tester.tap(find.byTooltip('Opciones de GymBro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Mi GymBro',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Instrucciones y personalidad'),
      'Háblame de forma breve.',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final saved = (await const CompanionStore(profileId: 'local').load()).first;
    expect(saved.name, 'Mi GymBro');
    expect(saved.prompt, 'Háblame de forma breve.');
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Opciones de Mi GymBro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('companion-gymbro')), findsNothing);
    expect((await const CompanionStore(profileId: 'local').load()).length, 3);
  });
}
