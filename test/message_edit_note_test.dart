import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/message_edit_note.dart';

void main() {
  test('la nota incluye versiones, respuesta previa, efectos y reglas', () {
    final note = buildEditNote(
      previous: (number: 1, text: 'Hice 10'),
      current: (number: 2, text: 'Hice 12'),
      previousReply: 'Anotado',
      effectsSummary: 'Efectos ya aplicados por la respuesta anterior: X.',
    );
    expect(note, contains('«Hice 10»'));
    expect(note, contains('«Hice 12»'));
    expect(note, contains('Tu respuesta anterior a la versión 1: «Anotado»'));
    expect(note, contains('Efectos ya aplicados por la respuesta anterior: X.'));
    expect(note, contains('ambiguo'));
    expect(note, contains('Nunca repitas'));
    expect(note, contains('EMPEZAR mencionando de forma explícita el cambio'));
  });

  test('trunca la respuesta larga y avisa si no hay efectos ni respuesta', () {
    final long = buildEditNote(
      previous: (number: 1, text: 'a'),
      current: (number: 2, text: 'b'),
      previousReply: 'x' * 3000,
    );
    expect(long, contains('[respuesta truncada]'));
    expect(long, isNot(contains('x' * 1501)));
    expect(long, contains('Efectos ya aplicados: ninguno registrado.'));
    final none = buildEditNote(
      previous: (number: 1, text: 'a'),
      current: (number: 2, text: 'b'),
    );
    expect(none, contains('No hay respuesta anterior tuya'));
  });
}
