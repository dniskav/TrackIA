import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/application/progress_engine.dart';
import 'package:gymia/domain/observation.dart';
import 'package:gymia/domain/progress.dart';

void main() {
  // Thursday 2026-10-29, ISO week 2026-W44 (Monday is 2026-10-26).
  const today = '2026-10-29';

  ProgressSession session(String id, String day, {int seconds = 0}) =>
      ProgressSession(id: id, day: day, seconds: seconds, activityId: id);

  ProgressValue value(String sessionId, String day, String field, Object v) =>
      ProgressValue(sessionId: sessionId, day: day, field: field, value: v);

  Metric field(String key, String aggregate, String per) =>
      Metric(source: 'field', field: key, aggregate: aggregate, per: per);

  group('metrics', () {
    final data = ProgressData(
      typedFields: const {'paginas', 'libro', 'hecho', 'nota'},
      sessions: [
        session('a', '2026-10-27', seconds: 600),
        session('b', '2026-10-29', seconds: 1800),
        session('c', '2026-10-29', seconds: 300),
        session('d', '2026-10-20', seconds: 3600),
      ],
      values: [
        value('a', '2026-10-27', 'paginas', 10),
        value('b', '2026-10-29', 'paginas', 25),
        value('c', '2026-10-29', 'paginas', 5),
        value('d', '2026-10-20', 'paginas', 40),
        value('b', '2026-10-29', 'libro', 'Dune'),
        value('c', '2026-10-29', 'libro', 'Dune'),
        value('d', '2026-10-20', 'libro', 'Emma'),
        value('b', '2026-10-29', 'hecho', true),
        value('c', '2026-10-29', 'hecho', false),
        value('d', '2026-10-20', 'hecho', true),
        value('b', '2026-10-29', 'nota', 'x'),
      ],
    );

    double of(Metric m, [String at = today]) => metricValue(m, data, at: at);

    test('every way of counting a field', () {
      expect(of(field('paginas', 'sum', 'total')), 80);
      expect(of(field('paginas', 'max', 'total')), 40);
      expect(of(field('paginas', 'avg', 'total')), 20);
      expect(of(field('libro', 'distinct', 'total')), 2);
      expect(of(field('hecho', 'countTrue', 'total')), 2);
    });

    test('per day, per week, per session and in total', () {
      expect(of(field('paginas', 'sum', 'day')), 30);
      expect(of(field('paginas', 'sum', 'day'), '2026-10-27'), 10);
      expect(of(field('paginas', 'sum', 'day'), '2026-10-28'), 0);
      // The week of the 29th runs Monday 26 to Sunday 1: the 20th is out.
      expect(of(field('paginas', 'sum', 'week')), 40);
      expect(of(field('paginas', 'sum', 'week'), '2026-10-20'), 40);
      // Per session: the best single session.
      expect(of(field('paginas', 'sum', 'session')), 40);
      expect(of(field('paginas', 'avg', 'day')), 15);
    });

    test('time adds only the seconds of the period', () {
      expect(of(Metric.time('total')), 6300);
      expect(of(Metric.time('day')), 2100);
      expect(of(Metric.time('week')), 2700);
      expect(of(Metric.time('session')), 3600);
    });

    test('sessions count every session of the period', () {
      expect(of(Metric.sessions('total')), 4);
      expect(of(Metric.sessions('day')), 2);
      expect(of(Metric.sessions('week')), 3);
      expect(of(Metric.sessions('session')), 1);
    });

    test('a field with nothing recorded is 0, and 0 differs from absent', () {
      expect(of(field('sin_datos', 'sum', 'total')), 0);
      expect(of(field('sin_datos', 'avg', 'total')), 0);
      expect(of(field('sin_datos', 'max', 'total')), 0);
      final withZero = ProgressData(
        typedFields: const {'p'},
        sessions: [session('a', today), session('b', today)],
        values: [value('a', today, 'p', 0), value('b', today, 'p', 10)],
      );
      // The recorded zero takes part in the average; an absent value would not.
      expect(metricValue(field('p', 'avg', 'total'), withZero, at: today), 5);
    });

    test('legacy fields without a type are ignored', () {
      final legacy = ProgressData(
        typedFields: const {},
        sessions: [session('a', today)],
        values: [value('a', today, 'weight_kg', 80)],
      );
      expect(
        metricValue(field('weight_kg', 'sum', 'total'), legacy, at: today),
        0,
      );
    });

    test('values of the wrong shape never count', () {
      final odd = ProgressData(
        typedFields: const {'p', 'h'},
        sessions: [session('a', today)],
        values: [
          value('a', today, 'p', 'muchas'),
          value('a', today, 'p', 3),
          value('a', today, 'h', 'sí'),
        ],
      );
      expect(metricValue(field('p', 'sum', 'total'), odd, at: today), 3);
      expect(metricValue(field('h', 'countTrue', 'total'), odd, at: today), 0);
    });
  });

  group('goals', () {
    final data = ProgressData(
      typedFields: const {'paginas'},
      sessions: [session('a', today), session('b', '2026-10-27')],
      values: [
        value('a', today, 'paginas', 8),
        value('b', '2026-10-27', 'paginas', 30),
      ],
    );
    final daily = GoalRule(
      metric: field('paginas', 'sum', 'day'),
      period: 'day',
      target: 20,
      minimum: 5,
    );

    test('progress, target and minimum', () {
      final p = goalProgress(daily, data, at: today);
      expect(p.value, 8);
      expect(p.met, isFalse);
      expect(p.minimumMet, isTrue);
      expect(goalProgress(daily, data, at: '2026-10-27').met, isTrue);
      expect(goalProgress(daily, data, at: '2026-10-28').value, 0);
    });

    test('a weekly goal adds the week', () {
      final weekly = GoalRule(
        metric: field('paginas', 'sum', 'week'),
        period: 'week',
        target: 50,
      );
      final p = goalProgress(weekly, data, at: today);
      expect(p.value, 38);
      expect(p.met, isFalse);
      expect(p.minimumMet, isFalse);
    });

    test('a day is done by the target, by the minimum, or by any record', () {
      expect(fulfilledDays(data, goal: daily), {today, '2026-10-27'});
      final strict = GoalRule(
        metric: field('paginas', 'sum', 'day'),
        period: 'day',
        target: 20,
      );
      expect(fulfilledDays(data, goal: strict), {'2026-10-27'});
      expect(fulfilledDays(data), {today, '2026-10-27'});
      final weekly = GoalRule(
        metric: field('paginas', 'sum', 'week'),
        period: 'week',
        target: 50,
      );
      // A weekly goal does not judge single days: any record does.
      expect(fulfilledDays(data, goal: weekly), {today, '2026-10-27'});
    });
  });

  group('streak', () {
    Set<String> days(List<int> octDays) => {
      for (final d in octDays) '2026-10-${d.toString().padLeft(2, '0')}',
    };

    StreakResult run(List<int> done, {int free = 1, String at = today}) =>
        streak(days(done), today: at, freeDays: free);

    test('no data is no streak', () {
      final r = run([]);
      expect([r.current, r.best], [0, 0]);
    });

    test('consecutive days up to yesterday; today open never breaks', () {
      expect(run([26, 27, 28]).current, 3);
      // Today (29) done adds one.
      expect(run([26, 27, 28, 29]).current, 4);
    });

    test('a missing day inside a week is free, the second one breaks', () {
      // Week 26 Mon … 1 Nov Sun. Missing Tue 27 is the first of the week: free.
      expect(run([26, 28], free: 1).current, 2);
      // Missing Tue 27 and Wed 28: the second breaks, so only Thu... today open.
      expect(run([26], free: 1, at: '2026-10-29').current, 0);
      expect(run([26, 29], free: 1).current, 1);
    });

    test('the allowance is per ISO week', () {
      // 21 (Wed) missing in the previous week, 28 (Wed) missing this week:
      // each week forgives its own first miss.
      final done = [19, 20, 22, 23, 24, 25, 26, 27, 29];
      final r = run(done);
      // The 21st and the 28th are each the first miss of their week.
      expect(r.current, 9);
      expect(r.best, 9);
    });

    test('no free days breaks at the first miss', () {
      expect(run([26, 27, 29], free: 0).current, 1);
      expect(run([26, 27, 28], free: 0).current, 3);
    });

    test('two free days forgive two misses a week', () {
      expect(run([26, 29], free: 2).current, 2);
      expect(run([26], free: 2).current, 1);
    });

    test('the best streak survives a later break', () {
      // 5 consecutive days long ago, then a gap, then 2 days.
      final r = streak(
        days([1, 2, 3, 4, 5, 27, 28]),
        today: today,
        freeDays: 0,
      );
      expect(r.best, 5);
      expect(r.current, 2);
    });

    test('the allowance used this week is reported', () {
      final r = run([26, 28]);
      expect(r.freeDaysUsedThisWeek, 1);
      expect(run([26, 27, 28]).freeDaysUsedThisWeek, 0);
    });

    test('days are kept as stored: a trip east does not rewrite them', () {
      // Done on 28 and 29 in the original zone; the phone now says it is the
      // 30th. Nothing is rewritten and today (open) breaks nothing.
      expect(run([28, 29], at: '2026-10-30').current, 2);
    });
  });

  group('unlocking', () {
    final data = ProgressData(
      typedFields: const {'paginas'},
      sessions: [
        for (var i = 0; i < 12; i++) session('s$i', '2026-10-${10 + i}'),
      ],
      values: [
        for (var i = 0; i < 12; i++)
          value('s$i', '2026-10-${10 + i}', 'paginas', 10),
      ],
    );

    Achievement achievement(String id, AchievementRule rule) => Achievement(
      id: id,
      companionId: 'lectura',
      rule: rule,
      ruleHash: id,
      title: id,
      icon: 'trophy',
      origin: 'generated',
    );

    test('only rules whose value reaches the threshold unlock', () {
      final pages = field('paginas', 'sum', 'total');
      final candidates = [
        achievement(
          'p100',
          AchievementRule.threshold(metric: pages, threshold: 100),
        ),
        achievement(
          'p121',
          AchievementRule.threshold(metric: pages, threshold: 121),
        ),
        achievement(
          's10',
          AchievementRule.threshold(
            metric: Metric.sessions('total'),
            threshold: 10,
          ),
        ),
        achievement('streak7', AchievementRule.streak(threshold: 7)),
        achievement('streak30', AchievementRule.streak(threshold: 30)),
      ];
      final unlocked = {
        for (final u in newUnlocks(candidates, data, today: today, freeDays: 1))
          u.achievement.id: u.value,
      };
      expect(unlocked.keys.toSet(), {'p100', 's10', 'streak7'});
      expect(unlocked['p100'], 120);
      expect(unlocked['s10'], 12);
    });

    test('an unlocked achievement is not unlocked again', () {
      final rule = AchievementRule.threshold(
        metric: Metric.sessions('total'),
        threshold: 1,
      );
      final done = Achievement(
        id: 'x',
        companionId: 'lectura',
        rule: rule,
        ruleHash: 'x',
        title: 'x',
        icon: 'first',
        origin: 'generated',
        unlock: AchievementUnlock(
          achievementId: 'x',
          unlockedAt: DateTime(2026, 10, 1),
          value: 1,
        ),
      );
      expect(newUnlocks([done], data, today: today, freeDays: 1), isEmpty);
    });

    test('property: nothing unlocks unless the computed value reaches it', () {
      final random = Random(2026);
      const fields = ['a', 'b', 'c'];
      const aggregates = ['sum', 'max', 'avg', 'distinct', 'countTrue'];
      const periods = ['session', 'day', 'week', 'total'];
      for (var round = 0; round < 500; round++) {
        final sessions = <ProgressSession>[];
        final values = <ProgressValue>[];
        final count = random.nextInt(20);
        for (var i = 0; i < count; i++) {
          final day =
              '2026-10-${(1 + random.nextInt(29)).toString().padLeft(2, '0')}';
          sessions.add(session('s$i', day, seconds: random.nextInt(4000)));
          for (final f in fields) {
            if (random.nextBool()) {
              final kind = random.nextInt(3);
              values.add(
                value(
                  's$i',
                  day,
                  f,
                  kind == 0
                      ? random.nextInt(50)
                      : kind == 1
                      ? random.nextBool()
                      : 'v${random.nextInt(5)}',
                ),
              );
            }
          }
        }
        final random500 = ProgressData(
          sessions: sessions,
          values: values,
          typedFields: fields.toSet(),
        );
        final candidates = <Achievement>[];
        for (var r = 0; r < 12; r++) {
          final threshold = (1 + random.nextInt(200)).toDouble();
          final rule = switch (random.nextInt(4)) {
            0 => AchievementRule.streak(
              threshold: 1 + random.nextInt(10).toDouble(),
            ),
            1 => AchievementRule.threshold(
              metric: Metric(source: 'time', per: periods[random.nextInt(4)]),
              threshold: threshold,
            ),
            2 => AchievementRule.threshold(
              metric: Metric(
                source: 'sessions',
                per: periods[random.nextInt(4)],
              ),
              threshold: 1 + random.nextInt(15).toDouble(),
            ),
            _ => AchievementRule.threshold(
              metric: field(
                fields[random.nextInt(3)],
                aggregates[random.nextInt(5)],
                periods[random.nextInt(4)],
              ),
              threshold: threshold,
            ),
          };
          candidates.add(achievement('r$r', rule));
        }
        final free = random.nextInt(4);
        final unlocks = newUnlocks(
          candidates,
          random500,
          today: today,
          freeDays: free,
        );
        final unlockedIds = {for (final u in unlocks) u.achievement.id};
        final best = streak(
          fulfilledDays(random500),
          today: today,
          freeDays: free,
        ).best;
        for (final c in candidates) {
          final rule = c.rule;
          final computed = rule.kind == 'streak'
              ? best.toDouble()
              : metricValue(rule.metric!, random500, at: today);
          expect(
            unlockedIds.contains(c.id),
            computed >= rule.threshold,
            reason: 'ronda $round, regla ${rule.toJson()}, valor $computed',
          );
        }
        for (final u in unlocks) {
          expect(u.value >= u.achievement.rule.threshold, isTrue);
        }
      }
    });

    test('property: adding data never lowers a total', () {
      final random = Random(7);
      var sessions = <ProgressSession>[];
      var previous = 0.0;
      for (var i = 0; i < 100; i++) {
        sessions = [
          ...sessions,
          session(
            's$i',
            '2026-10-${(1 + random.nextInt(28)).toString().padLeft(2, '0')}',
            seconds: random.nextInt(900),
          ),
        ];
        final total = metricValue(
          Metric.time('total'),
          ProgressData(sessions: sessions),
          at: today,
        );
        expect(total >= previous, isTrue);
        previous = total;
      }
    });
  });

  group('generated achievements', () {
    final fields = [
      {
        'key': 'paginas',
        'label': 'Páginas',
        'unit': '',
        'type': 'number',
        'aggregate': 'sum',
      },
      {
        'key': 'libro',
        'label': 'Libro',
        'unit': '',
        'type': 'text',
        'aggregate': 'distinct',
        'countPlural': 'libros distintos',
      },
      {
        'key': 'ejercicio',
        'label': 'Ejercicio',
        'unit': '',
        'type': 'boolean',
        'aggregate': 'countTrue',
        'countSingular': 'día de ejercicio',
        'countPlural': 'días de ejercicio',
      },
      {
        'key': 'peso',
        'label': 'Peso',
        'unit': 'kg',
        'type': 'number',
        'aggregate': 'max',
      },
      {
        'key': 'media',
        'label': 'Ánimo',
        'unit': '',
        'type': 'scale',
        'aggregate': 'avg',
      },
      {'key': 'notas', 'label': 'Notas', 'unit': ''}, // legacy
    ];
    final generated = generateAchievements(
      companionName: 'Lectura',
      fields: fields,
    );
    List<String> titles(String prefix) => [
      for (final g in generated)
        if (g.title.startsWith(prefix) || g.title.contains(prefix)) g.title,
    ];

    test('universal families', () {
      expect(titles('Primera vez'), ['Primera vez']);
      expect(titles('sesiones'), [
        '10 sesiones',
        '50 sesiones',
        '100 sesiones',
      ]);
      expect(titles('h en Lectura'), [
        '1 h en Lectura',
        '10 h en Lectura',
        '50 h en Lectura',
        '100 h en Lectura',
      ]);
      expect(titles('Racha de'), [
        'Racha de 3 días',
        'Racha de 7 días',
        'Racha de 30 días',
        'Racha de 100 días',
      ]);
    });

    test('field families use the label and a Spanish thousands separator', () {
      expect(titles('páginas'), [
        '10 páginas',
        '100 páginas',
        '500 páginas',
        '1.000 páginas',
        '5.000 páginas',
      ]);
      expect(titles('libros distintos'), [
        '3 libros distintos',
        '10 libros distintos',
        '25 libros distintos',
      ]);
      expect(titles('ejercicio'), [
        '1 día de ejercicio',
        '5 días de ejercicio',
        '25 días de ejercicio',
      ]);
    });

    test('max, avg and legacy fields generate nothing', () {
      expect(
        generated.where((g) => g.title.toLowerCase().contains('peso')),
        isEmpty,
      );
      expect(
        generated.where((g) => g.title.toLowerCase().contains('ánimo')),
        isEmpty,
      );
      expect(
        generated.where((g) => g.title.toLowerCase().contains('notas')),
        isEmpty,
      );
    });

    test('without a custom plural a distinct field says how many', () {
      final plain = generateAchievements(
        companionName: 'X',
        fields: [
          {
            'key': 'lugar',
            'label': 'Lugar',
            'unit': '',
            'type': 'text',
            'aggregate': 'distinct',
          },
          {
            'key': 'hecho',
            'label': 'Hecho',
            'unit': '',
            'type': 'boolean',
            'aggregate': 'countTrue',
          },
        ],
      );
      expect(
        plain.map((g) => g.title),
        containsAll(['Lugar: 3 distintos', 'Hecho: 1', 'Hecho: 5']),
      );
    });

    test('hashes are stable and never repeat', () {
      final again = generateAchievements(
        companionName: 'Lectura',
        fields: fields,
      );
      expect(again.map((g) => g.ruleHash), generated.map((g) => g.ruleHash));
      expect(generated.map((g) => g.ruleHash).toSet().length, generated.length);
    });

    test('every generated rule validates and has a known icon', () {
      for (final g in generated) {
        expect(
          AchievementRule.fromJson(g.rule.toJson()).toJson(),
          g.rule.toJson(),
        );
        expect(Achievement.icons, contains(g.icon));
      }
    });

    test('thousands are written the Spanish way', () {
      expect(formatCount(999), '999');
      expect(formatCount(1000), '1.000');
      expect(formatCount(1234567), '1.234.567');
    });
  });

  test('the local day helper matches the stored days', () {
    expect(Observation.dayOf(DateTime(2026, 10, 29, 23, 59)), today);
  });
}
