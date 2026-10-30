import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/domain/reminder.dart';
import 'package:trackia/domain/workout.dart';

void main() {
  // Thursday of ISO week 2026-W44.
  final now = DateTime(2026, 10, 29, 21);

  ReminderEntry entry({
    String companionId = 'lectura',
    String name = 'Lectura',
    String tone = 'neutral',
    String? lastActivityDate = '2026-10-28',
    int streak = 0,
    String? goalText,
    String? minimumText,
    String? weekId = '2026-W44',
    int weekCount = 0,
    int? weekTarget,
    ReminderTemplates? custom,
  }) => ReminderEntry(
    id: 'r1',
    companionId: companionId,
    companionName: name,
    days: 127,
    windowStartMin: 21 * 60,
    windowEndMin: 23 * 60,
    lastCallMin: 22 * 60 + 30,
    tone: tone,
    paused: false,
    lastDoneDate: lastActivityDate,
    lastActivityDate: lastActivityDate,
    streak: streak,
    goalText: goalText,
    minimumText: minimumText,
    weekId: weekId,
    weekCount: weekCount,
    weekTarget: weekTarget,
    templates: ReminderTemplates.defaults(
      tone: tone,
      companionId: companionId,
      custom: custom,
    ),
  );

  String start(ReminderEntry e) =>
      renderReminder(e, ReminderKind.windowStart, now);
  String last(ReminderEntry e) => renderReminder(e, ReminderKind.lastCall, now);

  group('start of the window', () {
    test('neutral uses the goal when there is one, else the plain text', () {
      expect(
        start(entry(goalText: '20 páginas')),
        'Es buen momento para tu actividad. Meta de hoy: 20 páginas.',
      );
      expect(start(entry()), 'Es buen momento para tu actividad.');
    });

    test('cheer names the companion and the goal', () {
      expect(
        start(entry(tone: 'cheer', goalText: '20 páginas')),
        'Lectura te espera: hoy toca 20 páginas.',
      );
      expect(start(entry(tone: 'cheer')), 'Lectura te espera hoy.');
    });

    test(
      'inactive copy appears only when the last activity is older than yesterday',
      () {
        expect(
          start(entry(lastActivityDate: '2026-10-26')),
          'Llevas 3 días sin registrar.',
        );
        expect(
          start(entry(lastActivityDate: '2026-10-27')),
          'Llevas 2 días sin registrar.',
        );
        // Yesterday and today are not inactive.
        expect(
          start(entry(lastActivityDate: '2026-10-28')),
          contains('buen momento'),
        );
        expect(
          start(entry(lastActivityDate: '2026-10-29')),
          contains('buen momento'),
        );
        // Never recorded anything: nothing to count from.
        expect(start(entry(lastActivityDate: null)), contains('buen momento'));
      },
    );

    test('cheer inactive copy', () {
      expect(
        start(entry(tone: 'cheer', lastActivityDate: '2026-10-25')),
        'Llevamos 4 días sin vernos. ¿Algo corto hoy?',
      );
    });

    test('GymBro has its own cheer text; neutral and others do not', () {
      const gymbro =
          'Amigo, llevamos 4 días sin entrenar. Vamos a movernos un poco.';
      expect(
        start(
          entry(
            companionId: 'gymbro',
            name: 'GymBro',
            tone: 'cheer',
            lastActivityDate: '2026-10-25',
          ),
        ),
        gymbro,
      );
      expect(
        start(
          entry(
            companionId: 'gymbro',
            name: 'GymBro',
            lastActivityDate: '2026-10-25',
          ),
        ),
        'Llevas 4 días sin registrar.',
      );
      expect(
        start(entry(tone: 'cheer', lastActivityDate: '2026-10-25')),
        isNot(gymbro),
      );
    });
  });

  group('last call', () {
    test('neutral prefers the minimum, then the weekly gap, then plain', () {
      expect(
        last(entry(minimumText: '5 páginas', weekTarget: 5, weekCount: 3)),
        'Aún estás a tiempo hoy. Con 5 páginas basta.',
      );
      expect(
        last(entry(weekTarget: 5, weekCount: 3)),
        'Te faltan 2 esta semana.',
      );
      expect(last(entry()), 'Aún estás a tiempo hoy.');
    });

    test('cheer needs both minimum and streak for the first text', () {
      expect(
        last(entry(tone: 'cheer', minimumText: '5 páginas', streak: 6)),
        'Última llamada: con 5 páginas mantienes tu racha de 6 días.',
      );
      // Minimum without a streak falls to the weekly text, then the plain one.
      expect(
        last(
          entry(
            tone: 'cheer',
            minimumText: '5 páginas',
            weekTarget: 5,
            weekCount: 1,
          ),
        ),
        'No pierdas la racha: te faltan 4 esta semana.',
      );
      expect(
        last(entry(tone: 'cheer', minimumText: '5 páginas')),
        'Última llamada para hoy.',
      );
    });

    test('a week that already met its target has nothing missing', () {
      expect(
        last(entry(weekTarget: 3, weekCount: 3)),
        'Aún estás a tiempo hoy.',
      );
      expect(
        last(entry(weekTarget: 3, weekCount: 5)),
        'Aún estás a tiempo hoy.',
      );
    });

    test('a stale week counts the whole target as missing', () {
      expect(
        last(entry(weekId: '2026-W43', weekTarget: 4, weekCount: 4)),
        'Te faltan 4 esta semana.',
      );
    });

    test('a zero streak is not a marker value', () {
      expect(
        last(entry(tone: 'cheer', minimumText: '5 páginas', streak: 0)),
        'Última llamada para hoy.',
      );
    });

    test('inactivity does not change the last call', () {
      expect(
        last(entry(lastActivityDate: '2026-10-20')),
        'Aún estás a tiempo hoy.',
      );
    });
  });

  group('custom copy', () {
    test('replaces only the lists it provides', () {
      final custom = ReminderTemplates(
        windowStart: const ['{nombre}: a leer {meta}', 'A leer'],
        lastCall: const [],
        inactive: const [],
      );
      final e = entry(goalText: '10 páginas', custom: custom);
      expect(start(e), 'Lectura: a leer 10 páginas');
      expect(last(e), 'Aún estás a tiempo hoy.');
    });

    test('markers without value never leak into the text', () {
      final e = entry(
        custom: ReminderTemplates(
          windowStart: const ['Hoy {meta} y {racha}'],
          lastCall: const ['x'],
          inactive: const ['y'],
        ),
      );
      // No template has all its markers: the last one is used as written.
      expect(start(e), 'Hoy  y ');
    });
  });

  test('the ISO week id follows the standard', () {
    expect(isoWeekId(DateTime(2026, 10, 29)), '2026-W44');
    expect(isoWeekId(DateTime(2021, 1, 3)), '2020-W53');
    expect(isoWeekId(DateTime(2024, 12, 30)), '2025-W01');
    expect(isoWeekId(DateTime(2026, 1, 1)), '2026-W01');
  });

  test('the local day is zero-padded', () {
    expect(reminderDay(DateTime(2026, 3, 4, 23, 59)), '2026-03-04');
  });

  test('the snapshot entry carries every field of the contract', () {
    final json = entry(
      goalText: '20 páginas',
      minimumText: '5 páginas',
      streak: 6,
      weekTarget: 5,
      weekCount: 3,
    ).toJson();
    expect(
      json.keys,
      containsAll([
        'id',
        'companionId',
        'companionName',
        'days',
        'windowStartMin',
        'windowEndMin',
        'lastCallMin',
        'tone',
        'paused',
        'lastDoneDate',
        'lastActivityDate',
        'streak',
        'goalText',
        'minimumText',
        'weekId',
        'weekCount',
        'weekTarget',
        'templates',
      ]),
    );
    expect((json['templates'] as Map).keys, {
      'windowStart',
      'lastCall',
      'inactive',
    });
  });

  group('Reminder', () {
    Reminder make({
      int days = 127,
      int start = 600,
      int end = 700,
      int? lastCall,
    }) => Reminder(
      id: 'r',
      companionId: 'lectura',
      days: days,
      windowStartMin: start,
      windowEndMin: end,
      lastCallMin: lastCall,
    );

    test('days map from Monday (bit 0) to Sunday (bit 6)', () {
      final weekdays = make(days: 0x1F);
      for (var d = DateTime.monday; d <= DateTime.friday; d++) {
        expect(weekdays.scheduledOn(d), isTrue);
      }
      expect(weekdays.scheduledOn(DateTime.saturday), isFalse);
      expect(weekdays.scheduledOn(DateTime.sunday), isFalse);
      expect(weekdays.daysPerWeek, 5);
      expect(make().daysPerWeek, 7);
    });

    test('invalid windows are rejected', () {
      expect(() => make(days: 0), throwsA(isA<ValidationException>()));
      expect(() => make(start: 700), throwsA(isA<ValidationException>()));
      expect(() => make(lastCall: 600), throwsA(isA<ValidationException>()));
      expect(() => make(lastCall: 650), returnsNormally);
    });
  });
}
