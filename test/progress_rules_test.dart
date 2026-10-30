import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/domain/progress.dart';
import 'package:trackia/domain/workout.dart';

void main() {
  final pages = {
    'source': 'field',
    'field': 'paginas',
    'aggregate': 'sum',
    'per': 'day',
  };

  group('Metric', () {
    test('valid metrics round-trip', () {
      for (final json in [
        pages,
        {'source': 'time', 'per': 'week'},
        {'source': 'sessions', 'per': 'total'},
        {
          'source': 'field',
          'field': 'libro',
          'aggregate': 'distinct',
          'per': 'total',
        },
        {
          'source': 'field',
          'field': 'x',
          'aggregate': 'countTrue',
          'per': 'session',
        },
      ]) {
        expect(Metric.fromJson(json).toJson(), json);
      }
    });

    test('rejects what the schema does not allow', () {
      void bad(Object? json) => expect(
        () => Metric.fromJson(json),
        throwsA(isA<ValidationException>()),
      );
      bad('texto');
      bad({...pages, 'extra': 1});
      bad({...pages, 'source': 'otro'});
      bad({...pages, 'per': 'mes'});
      bad({...pages, 'aggregate': 'median'});
      bad({'source': 'field', 'per': 'day', 'aggregate': 'sum'}); // no field
      bad({'source': 'field', 'field': 'x', 'per': 'day'}); // no aggregate
      bad({'source': 'time', 'field': 'x', 'per': 'day'}); // field on time
      bad({'source': 'sessions', 'aggregate': 'sum', 'per': 'day'});
      bad({'source': 'time'}); // no per
      bad({...pages, 'field': 5});
    });
  });

  group('GoalRule', () {
    Map<String, Object?> goal({
      Object? period = 'day',
      Object? target = 20,
      Object? minimum,
      Object? metric,
    }) => {
      'metric': metric ?? pages,
      'period': period,
      'target': target,
      if (minimum != null) 'minimum': minimum,
    };

    test('a valid goal with a minimum', () {
      final rule = GoalRule.fromJson(goal(minimum: 5));
      expect(rule.target, 20);
      expect(rule.minimum, 5);
      final progress = GoalProgress(
        value: 7,
        target: rule.target,
        minimum: rule.minimum,
      );
      expect(progress.met, isFalse);
      expect(progress.minimumMet, isTrue);
      expect(GoalRule.fromJson(rule.toJson()).toJson(), rule.toJson());
    });

    test('the metric must be measured over the goal period', () {
      expect(
        () => GoalRule.fromJson(goal(period: 'week')),
        throwsA(isA<ValidationException>()),
      );
      expect(
        GoalRule.fromJson(
          goal(period: 'week', metric: {...pages, 'per': 'week'}),
        ).period,
        'week',
      );
    });

    test('out-of-range and extra values are rejected', () {
      void bad(Map<String, Object?> json) => expect(
        () => GoalRule.fromJson(json),
        throwsA(isA<ValidationException>()),
      );
      bad(goal(target: 0));
      bad(goal(target: -3));
      bad(goal(target: 'veinte'));
      bad(goal(minimum: 0));
      bad(goal(minimum: 21)); // above the target
      bad(goal(minimum: 'poco'));
      bad(goal(period: 'month'));
      bad({...goal(), 'origin': 'user'});
    });

    test('an invalid proposal is dropped whole', () {
      expect(GoalRule.tryParse(goal(target: 0)), isNull);
      expect(GoalRule.tryParse(null), isNull);
      expect(GoalRule.tryParse(goal()), isNotNull);
    });
  });

  group('AchievementRule', () {
    test('threshold and streak rules', () {
      final threshold = AchievementRule.fromJson({
        'kind': 'threshold',
        'metric': {...pages, 'per': 'total'},
        'threshold': 100,
      });
      expect(threshold.kind, 'threshold');
      expect(threshold.threshold, 100);
      expect(
        AchievementRule.fromJson(threshold.toJson()).toJson(),
        threshold.toJson(),
      );
      final streak = AchievementRule.fromJson({
        'kind': 'streak',
        'threshold': 7,
      });
      expect(streak.metric, isNull);
      expect(streak.toJson(), {'kind': 'streak', 'threshold': 7});
    });

    test('invalid rules are rejected', () {
      void bad(Object? json) => expect(
        () => AchievementRule.fromJson(json),
        throwsA(isA<ValidationException>()),
      );
      bad({'kind': 'streak', 'threshold': 0});
      bad({'kind': 'streak', 'threshold': -1});
      bad({'kind': 'streak', 'threshold': 'siete'});
      bad({'kind': 'streak', 'threshold': 7, 'metric': pages});
      bad({'kind': 'threshold', 'threshold': 5}); // no metric
      bad({'kind': 'threshold', 'metric': pages, 'threshold': 5, 'x': 1});
      bad({'kind': 'magic', 'threshold': 5});
      bad(<String, Object?>{});
      expect(
        AchievementRule.tryParse({'kind': 'streak', 'threshold': 0}),
        isNull,
      );
    });
  });

  test('the goal progress fraction never leaves 0 to 1', () {
    expect(const GoalProgress(value: 50, target: 20).fraction, 1);
    expect(const GoalProgress(value: 0, target: 20).fraction, 0);
    expect(const GoalProgress(value: 5, target: 20).fraction, 0.25);
  });
}
