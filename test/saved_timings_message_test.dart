import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/domain/activity.dart';
import 'package:gymia/ui/assistant_chat.dart';

void main() {
  final definition = ActivityDefinition(
    name: 'Plancha',
    restSeconds: 60,
    activitySeconds: 30,
    targetCycles: 4,
  );

  test('lo no propuesto se toma de la definición actual', () {
    expect(
      savedTimingsMessage(definition, {'restSeconds': 90}),
      'Tiempos guardados en la actividad: 0:30 por tramo, 1:30 de descanso, '
      '4 ciclos. Los avisos se enviarán si Android los permite.',
    );
  });

  test('sin duración ni ciclos se omite lo que no existe', () {
    final open = ActivityDefinition(name: 'Libre', restSeconds: 45);
    expect(
      savedTimingsMessage(open, {}),
      'Tiempos guardados en la actividad: sin límite por tramo, 0:45 de '
      'descanso. Los avisos se enviarán si Android los permite.',
    );
  });
}
