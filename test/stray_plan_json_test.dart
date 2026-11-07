import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/domain/block_names.dart';
import 'package:trackia/domain/sheet_sync.dart';
import 'package:trackia/domain/workout.dart';
import 'package:trackia/ui/chat_message.dart';

const _raw =
    'La sesión del 05/11 no existe aún en la hoja.\n\n'
    'Nota: en Pec Fly marcaste 15 kg.\n\n'
    '```json\n{"resumen":"Sesión del 2026-11-05","writes":[{"cell":"A111","value":17}]}\n```\n\n'
    'Nota: en Chest Press no queda claro si 60 kg es carga total.';

void main() {
  group('stripStrayPlanJson', () {
    test('quita el JSON de plan con claves no reconocidas y conserva el texto', () {
      final out = stripStrayPlanJson(_raw);
      expect(out, isNot(contains('resumen')));
      expect(out, isNot(contains('```')));
      expect(out, contains('Nota: en Pec Fly marcaste 15 kg.'));
      expect(out, contains('Nota: en Chest Press no queda claro'));
    });

    test('quita también el bloque sin etiqueta de lenguaje', () {
      const text = 'Hola\n```\n{"summary":"x","writes":[]}\n```\nAdiós';
      expect(stripStrayPlanJson(text), isNot(contains('summary')));
    });

    test('conserva bloques de código normales y texto sin bloques', () {
      const code = 'Ejemplo:\n```json\n{"nombre":"Ana","edad":3}\n```';
      expect(stripStrayPlanJson(code), code);
      const dart = 'Mira:\n```dart\nvoid main() {}\n```';
      expect(stripStrayPlanJson(dart), dart);
      expect(stripStrayPlanJson('solo texto'), 'solo texto');
    });
  });

  group('SheetSyncPlan.parse', () {
    final snapshot = <String, dynamic>{};

    test('una aclaración con JSON suelto se muestra sin el JSON', () {
      expect(
        () => SheetSyncPlan.parse(_raw, snapshot),
        throwsA(
          isA<SheetClarification>().having(
            (e) => e.question,
            'texto',
            allOf(isNot(contains('resumen')), contains('Nota: en Pec Fly')),
          ),
        ),
      );
    });

    test('si solo hay JSON suelto no se muestra nada en crudo', () {
      const only = '```json\n{"resumen":"x","writes":[]}\n```';
      expect(
        () => SheetSyncPlan.parse(only, snapshot),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  testWidgets('el mensaje del asistente no dibuja el JSON suelto', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ChatMessageBody(text: _raw, assistant: true)),
      ),
    );
    await tester.pump();
    expect(find.textContaining('resumen', findRichText: true), findsNothing);
    expect(
      find.textContaining('Nota: en Pec Fly', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
