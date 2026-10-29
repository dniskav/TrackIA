import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/domain/assistant_blocks.dart';

/// Rule 7 of contracts/assistant-blocks.md for every block: valid, each
/// required key missing, an extra key, lower and upper limits, two blocks and
/// broken JSON.
void main() {
  String block(String kind, Object? json) =>
      'Texto antes.\n```trackia-$kind\n${jsonEncode(json)}\n```\nTexto después.';

  final metric = {
    'source': 'field',
    'field': 'paginas',
    'aggregate': 'sum',
    'per': 'day',
  };

  group('trackia-goal', () {
    Map<String, Object?> goal({Object? target = 20, Object? minimum = 5}) => {
      'metric': metric,
      'period': 'day',
      'target': target,
      if (minimum != null) 'minimum': minimum,
    };

    test('a valid goal', () {
      final g = parseGoalBlock(block('goal', goal()))!;
      expect([g.rule.target, g.rule.minimum, g.rule.period], [20, 5, 'day']);
      expect(g.activityKey, isNull);
      expect(
        parseGoalBlock(block('goal', goal(minimum: null)))!.rule.minimum,
        isNull,
      );
    });

    test('every required key is needed', () {
      for (final key in ['metric', 'period', 'target']) {
        expect(
          parseGoalBlock(block('goal', goal()..remove(key))),
          isNull,
          reason: key,
        );
      }
    });

    test('an extra key rejects the whole block', () {
      expect(
        parseGoalBlock(block('goal', {...goal(), 'origin': 'assistant'})),
        isNull,
      );
      expect(
        parseGoalBlock(block('goal', {...goal(), 'profileId': 'x'})),
        isNull,
      );
    });

    test(
      'limits: target above 0 and up to 100000; minimum above 0 and below target',
      () {
        expect(parseGoalBlock(block('goal', goal(target: 0))), isNull);
        expect(parseGoalBlock(block('goal', goal(target: -1))), isNull);
        expect(
          parseGoalBlock(block('goal', goal(target: 100000, minimum: null))),
          isNotNull,
        );
        expect(
          parseGoalBlock(block('goal', goal(target: 100001, minimum: null))),
          isNull,
        );
        expect(parseGoalBlock(block('goal', goal(minimum: 0))), isNull);
        expect(
          parseGoalBlock(block('goal', goal(minimum: 20))),
          isNull,
        ); // not below
        expect(parseGoalBlock(block('goal', goal(minimum: 19.5))), isNotNull);
        expect(parseGoalBlock(block('goal', goal(target: 'veinte'))), isNull);
      },
    );

    test('the metric must be measured over the period', () {
      expect(
        parseGoalBlock(block('goal', {...goal(), 'period': 'week'})),
        isNull,
      );
    });

    test('the activity must exist in the companion', () {
      final withKey = {...goal(), 'activityKey': 'leer'};
      expect(
        parseGoalBlock(
          block('goal', withKey),
          activityKeys: {'leer'},
        )!.activityKey,
        'leer',
      );
      expect(
        parseGoalBlock(block('goal', withKey), activityKeys: {'otra'}),
        isNull,
      );
      expect(
        parseGoalBlock(block('goal', {...goal(), 'activityKey': 3})),
        isNull,
      );
    });

    test('two blocks, broken JSON, a non-object and no block', () {
      expect(
        parseGoalBlock(
          '${block('goal', goal())}\n${block('goal', goal(target: 30))}',
        ),
        isNull,
      );
      expect(parseGoalBlock('```trackia-goal\n{no json\n```'), isNull);
      expect(parseGoalBlock(block('goal', [1, 2])), isNull);
      expect(parseGoalBlock('Solo texto'), isNull);
    });
  });

  group('trackia-achievement', () {
    Map<String, Object?> achievement({
      Object? title = '100 páginas',
      Object? threshold = 100,
    }) => {
      'title': title,
      'rule': {
        'kind': 'threshold',
        'metric': {...metric, 'per': 'total'},
        'threshold': threshold,
      },
    };

    test('a valid achievement gets a default icon', () {
      final a = parseAchievementBlock(block('achievement', achievement()))!;
      expect(a.title, '100 páginas');
      expect(a.rule.threshold, 100);
      expect(a.icon, 'trophy');
      final streak = parseAchievementBlock(
        block('achievement', {
          'title': 'Una semana',
          'rule': {'kind': 'streak', 'threshold': 7},
        }),
      )!;
      expect(streak.icon, 'streak');
      expect(
        parseAchievementBlock(
          block('achievement', {...achievement(), 'icon': 'record'}),
        )!.icon,
        'record',
      );
    });

    test('title and rule are required; extra keys are rejected', () {
      for (final key in ['title', 'rule']) {
        expect(
          parseAchievementBlock(
            block('achievement', achievement()..remove(key)),
          ),
          isNull,
        );
      }
      expect(
        parseAchievementBlock(
          block('achievement', {...achievement(), 'extra': 1}),
        ),
        isNull,
      );
    });

    test(
      'limits: title 1 to 60 characters; threshold above 0 and up to 1000000',
      () {
        expect(
          parseAchievementBlock(block('achievement', achievement(title: ''))),
          isNull,
        );
        expect(
          parseAchievementBlock(
            block('achievement', achievement(title: '   ')),
          ),
          isNull,
        );
        expect(
          parseAchievementBlock(
            block('achievement', achievement(title: 'a' * 60)),
          ),
          isNotNull,
        );
        expect(
          parseAchievementBlock(
            block('achievement', achievement(title: 'a' * 61)),
          ),
          isNull,
        );
        expect(
          parseAchievementBlock(
            block('achievement', achievement(threshold: 0)),
          ),
          isNull,
        );
        expect(
          parseAchievementBlock(
            block('achievement', achievement(threshold: 1000000)),
          ),
          isNotNull,
        );
        expect(
          parseAchievementBlock(
            block('achievement', achievement(threshold: 1000001)),
          ),
          isNull,
        );
      },
    );

    test('an unknown icon, a bad rule or an unknown activity rejects it', () {
      expect(
        parseAchievementBlock(
          block('achievement', {...achievement(), 'icon': 'dragon'}),
        ),
        isNull,
      );
      expect(
        parseAchievementBlock(
          block('achievement', {
            'title': 'x',
            'rule': {'kind': 'magic', 'threshold': 1},
          }),
        ),
        isNull,
      );
      expect(
        parseAchievementBlock(
          block('achievement', {...achievement(), 'activityKey': 'nada'}),
          activityKeys: {'leer'},
        ),
        isNull,
      );
    });

    test('two blocks and broken JSON', () {
      expect(
        parseAchievementBlock(
          '${block('achievement', achievement())}${block('achievement', achievement())}',
        ),
        isNull,
      );
      expect(parseAchievementBlock('```trackia-achievement\n{\n```'), isNull);
    });
  });

  group('trackia-reminder-copy', () {
    test('a valid copy keeps only the lists it gives', () {
      final c = parseReminderCopyBlock(
        block('reminder-copy', {
          'windowStart': ['{nombre} te espera: hoy toca {meta}.', 'A leer.'],
          'lastCall': ['Con {minimo} basta, llevas {racha} días.'],
        }),
      )!;
      expect(c.windowStart, hasLength(2));
      expect(c.lastCall, hasLength(1));
      expect(c.inactive, isEmpty);
    });

    test(
      'an empty block, an unknown list or an unknown marker is rejected',
      () {
        expect(
          parseReminderCopyBlock(block('reminder-copy', <String, Object?>{})),
          isNull,
        );
        expect(
          parseReminderCopyBlock(
            block('reminder-copy', {
              'otra': ['x'],
            }),
          ),
          isNull,
        );
        expect(
          parseReminderCopyBlock(
            block('reminder-copy', {
              'windowStart': ['Hola {usuario}'],
            }),
          ),
          isNull,
        );
        expect(
          parseReminderCopyBlock(
            block('reminder-copy', {
              'windowStart': ['Hola {'],
            }),
          ),
          isNull,
        );
        expect(
          parseReminderCopyBlock(
            block('reminder-copy', {
              'windowStart': ['Hola {dias} y {faltan}'],
            }),
          ),
          isNotNull,
        );
      },
    );

    test('limits: 1 to 5 texts of 1 to 140 characters', () {
      expect(
        parseReminderCopyBlock(
          block('reminder-copy', {'inactive': <String>[]}),
        ),
        isNull,
      );
      expect(
        parseReminderCopyBlock(
          block('reminder-copy', {'inactive': List.filled(5, 'x')}),
        ),
        isNotNull,
      );
      expect(
        parseReminderCopyBlock(
          block('reminder-copy', {'inactive': List.filled(6, 'x')}),
        ),
        isNull,
      );
      expect(
        parseReminderCopyBlock(
          block('reminder-copy', {
            'inactive': [''],
          }),
        ),
        isNull,
      );
      expect(
        parseReminderCopyBlock(
          block('reminder-copy', {
            'inactive': ['a' * 140],
          }),
        ),
        isNotNull,
      );
      expect(
        parseReminderCopyBlock(
          block('reminder-copy', {
            'inactive': ['a' * 141],
          }),
        ),
        isNull,
      );
      expect(
        parseReminderCopyBlock(
          block('reminder-copy', {'inactive': 'no es lista'}),
        ),
        isNull,
      );
    });

    test('two blocks and broken JSON', () {
      final one = block('reminder-copy', {
        'inactive': ['x'],
      });
      expect(parseReminderCopyBlock('$one$one'), isNull);
      expect(
        parseReminderCopyBlock('```trackia-reminder-copy\n[\n```'),
        isNull,
      );
    });
  });

  group('trackia-companion', () {
    Map<String, Object?> companion() => {
      'name': 'Lectura',
      'description': 'Leer cada día',
      'prompt': 'Sé breve.',
      'icon': 'book',
      'color': 'violet',
      'mode': 'game',
      'activity': {
        'name': 'Leer',
        'repeated': false,
        'restSeconds': 0,
        'instant': false,
        'fields': [
          {
            'key': 'paginas',
            'label': 'Páginas',
            'unit': '',
            'type': 'number',
            'aggregate': 'sum',
          },
        ],
      },
      'goal': {'metric': metric, 'period': 'day', 'target': 20, 'minimum': 5},
      'reminder': {
        'days': ['mon', 'tue', 'wed', 'thu', 'fri'],
        'start': '21:00',
        'end': '23:00',
        'lastCall': '22:30',
        'tone': 'cheer',
      },
    };

    test('a full proposal', () {
      final p = parseCompanionBlock(block('companion', companion()))!;
      expect(p.name, 'Lectura');
      expect(p.mode, 'game');
      expect(p.levelText, 'Juego completo');
      expect(p.icon, 'book');
      expect(p.activity!.name, 'Leer');
      expect(p.activity!.fields.single['key'], 'paginas');
      expect(p.instant, isFalse);
      expect(p.goal!.rule.target, 20);
      expect(p.reminder!.days, 0x1F);
      expect(
        [p.reminder!.startMin, p.reminder!.endMin, p.reminder!.lastCallMin],
        [1260, 1380, 1350],
      );
      expect(p.reminder!.tone, 'cheer');
    });

    test('only name and mode are required', () {
      final p = parseCompanionBlock(
        block('companion', {'name': 'Calma', 'mode': 'reminder'}),
      )!;
      expect(p.description, '');
      expect(p.prompt, '');
      expect([
        p.activity,
        p.goal,
        p.reminder,
        p.icon,
        p.color,
      ], everyElement(isNull));
      expect(p.levelText, 'Solo recordatorio');
      for (final key in ['name', 'mode']) {
        expect(
          parseCompanionBlock(block('companion', companion()..remove(key))),
          isNull,
          reason: key,
        );
      }
    });

    test('the three levels', () {
      for (final entry in {
        'reminder': 'Solo recordatorio',
        'goals': 'Metas y rachas',
        'game': 'Juego completo',
      }.entries) {
        final p = parseCompanionBlock(
          block('companion', {'name': 'X', 'mode': entry.key}),
        )!;
        expect(p.levelText, entry.value);
      }
      expect(
        parseCompanionBlock(block('companion', {'name': 'X', 'mode': 'otro'})),
        isNull,
      );
    });

    test('an extra key rejects the whole block, even nested', () {
      expect(
        parseCompanionBlock(block('companion', {...companion(), 'id': 'x'})),
        isNull,
      );
      expect(
        parseCompanionBlock(
          block('companion', {...companion(), 'origin': 'assistant'}),
        ),
        isNull,
      );
      final nested = companion();
      (nested['activity'] as Map)['userSet'] = ['name'];
      expect(parseCompanionBlock(block('companion', nested)), isNull);
      final goal = companion();
      (goal['goal'] as Map)['origin'] = 'x';
      expect(parseCompanionBlock(block('companion', goal)), isNull);
      final rem = companion();
      (rem['reminder'] as Map)['enabled'] = true;
      expect(parseCompanionBlock(block('companion', rem)), isNull);
    });

    test('limits of the text fields', () {
      String with0(String key, Object? value) =>
          block('companion', {...companion(), key: value});
      expect(parseCompanionBlock(with0('name', '')), isNull);
      expect(parseCompanionBlock(with0('name', 'a' * 40)), isNotNull);
      expect(parseCompanionBlock(with0('name', 'a' * 41)), isNull);
      expect(parseCompanionBlock(with0('description', 'a' * 80)), isNotNull);
      expect(parseCompanionBlock(with0('description', 'a' * 81)), isNull);
      expect(parseCompanionBlock(with0('prompt', 'a' * 2000)), isNotNull);
      expect(parseCompanionBlock(with0('prompt', 'a' * 2001)), isNull);
      expect(parseCompanionBlock(with0('icon', 'dragon')), isNull);
      expect(parseCompanionBlock(with0('color', 'rosa')), isNull);
      expect(parseCompanionBlock(with0('name', 7)), isNull);
    });

    test('the reminder follows the window rules', () {
      String rem(Map<String, Object?> change) {
        final c = companion();
        c['reminder'] = {...(c['reminder'] as Map<String, Object?>), ...change};
        return block('companion', c);
      }

      expect(parseCompanionBlock(rem({'days': <String>[]})), isNull);
      expect(
        parseCompanionBlock(
          rem({
            'days': ['mon', 'mon'],
          }),
        ),
        isNull,
      );
      expect(
        parseCompanionBlock(
          rem({
            'days': ['lunes'],
          }),
        ),
        isNull,
      );
      expect(
        parseCompanionBlock(
          rem({
            'days': ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
          }),
        ),
        isNotNull,
      );
      expect(parseCompanionBlock(rem({'start': '25:00'})), isNull);
      expect(parseCompanionBlock(rem({'start': '9:00'})), isNull);
      expect(
        parseCompanionBlock(rem({'start': '23:00', 'end': '21:00'})),
        isNull,
      );
      expect(
        parseCompanionBlock(rem({'end': '24:00', 'lastCall': '23:30'})),
        isNotNull,
      );
      expect(
        parseCompanionBlock(rem({'lastCall': '21:00'})),
        isNull,
      ); // not after the start
      expect(
        parseCompanionBlock(rem({'lastCall': '23:00'})),
        isNull,
      ); // not before the end
      expect(parseCompanionBlock(rem({'tone': 'loud'})), isNull);
      for (final key in ['days', 'start', 'end', 'tone']) {
        final c = companion();
        (c['reminder'] as Map).remove(key);
        expect(parseCompanionBlock(block('companion', c)), isNull, reason: key);
      }
    });

    test(
      'the activity and the goal inside are validated like their own blocks',
      () {
        final bad = companion();
        (bad['activity'] as Map)['restSeconds'] = 99999;
        expect(parseCompanionBlock(block('companion', bad)), isNull);
        final notInstant = companion();
        (notInstant['activity'] as Map)['instant'] = 'sí';
        expect(parseCompanionBlock(block('companion', notInstant)), isNull);
        final goal = companion();
        (goal['goal'] as Map)['target'] = 0;
        expect(parseCompanionBlock(block('companion', goal)), isNull);
        final point = companion();
        (point['activity'] as Map)['instant'] = true;
        expect(parseCompanionBlock(block('companion', point))!.instant, isTrue);
      },
    );

    test('two blocks and broken JSON', () {
      final one = block('companion', {'name': 'X', 'mode': 'reminder'});
      expect(parseCompanionBlock('$one$one'), isNull);
      expect(
        parseCompanionBlock('```trackia-companion\n{"name":\n```'),
        isNull,
      );
    });
  });

  test('a reply can carry one block of each kind', () {
    final both =
        '${block('goal', {'metric': metric, 'period': 'day', 'target': 20})}\n'
        '${block('reminder-copy', {
          'inactive': ['x'],
        })}';
    expect(parseGoalBlock(both), isNotNull);
    expect(parseReminderCopyBlock(both), isNotNull);
    expect(mentionsBlock(both, 'goal'), isTrue);
    expect(mentionsBlock(both, 'achievement'), isFalse);
  });

  test('the rejection text is fixed', () {
    expect(blockRejectedText, 'La propuesta no es válida y no se aplicó.');
  });
}
