import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/application/reminder_scheduler.dart';
import 'package:gymia/data/sqlite_workout_repository.dart';
import 'package:gymia/domain/activity.dart';
import 'package:gymia/domain/companion.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late SqliteWorkoutRepository repo;
  late DateTime now;
  late List<({String method, Map<String, Object?> args})> calls;
  late List<Companion> companions;
  Object? failure;

  ReminderScheduler make({bool supported = true}) => ReminderScheduler(
    progress: repo.progress,
    companions: () async => companions,
    clock: () => now,
    supported: supported,
    invoke: (method, args) async {
      calls.add((method: method, args: args));
      if (failure != null) throw failure!;
      return true;
    },
  );

  Map<String, Object?> lastSnapshot() =>
      jsonDecode(calls.last.args['snapshot'] as String) as Map<String, Object?>;

  List<Map<String, dynamic>> entries() =>
      List<Map<String, dynamic>>.from(lastSnapshot()['reminders'] as List);

  setUp(() async {
    now = DateTime(2026, 10, 29, 9);
    calls = [];
    failure = null;
    companions = [
      Companion(id: 'lectura', name: 'Lectura', description: '', prompt: ''),
      Companion(id: 'enfoque', name: 'Enfoque', description: '', prompt: ''),
    ];
    dir = await Directory.systemTemp.createTemp('trackia-scheduler-');
    repo = await SqliteWorkoutRepository.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/test.sqlite',
      clock: () => now,
    );
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  Future<void> remind(
    String companionId, {
    int days = 127,
    int? lastCall = 22 * 60 + 30,
    Map<String, Object?>? minimum,
    String tone = 'neutral',
  }) => repo.progress.saveReminder(
    companionId: companionId,
    days: days,
    windowStartMin: 21 * 60,
    windowEndMin: 23 * 60,
    lastCallMin: lastCall,
    tone: tone,
    minimum: minimum,
  );

  Future<void> record(String companionId, {String text = 'Hoy'}) =>
      repo.observations.record(
        companionId: companionId,
        definition: ActivityDefinition(
          name: 'Leer',
          repeated: false,
          restSeconds: 0,
          companionId: companionId,
        ),
        original: text,
      );

  test('sends a version 1 snapshot with the reminder and its facts', () async {
    await remind(
      'lectura',
      tone: 'cheer',
      minimum: {'metric': 'paginas', 'label': 'páginas', 'value': 5},
    );
    now = DateTime(2026, 10, 29, 10);
    await record('lectura');
    await make().sync();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'sync');
    final snapshot = lastSnapshot();
    expect(snapshot['version'], 1);
    expect(snapshot['profileId'], 'local');
    expect(snapshot['generatedAt'], now.millisecondsSinceEpoch);
    final r = entries().single;
    expect(r['companionId'], 'lectura');
    expect(r['companionName'], 'Lectura');
    expect(r['days'], 127);
    expect(r['windowStartMin'], 1260);
    expect(r['windowEndMin'], 1380);
    expect(r['lastCallMin'], 1350);
    expect(r['tone'], 'cheer');
    expect(r['paused'], isFalse);
    expect(r['lastDoneDate'], '2026-10-29');
    expect(r['streak'], 1);
    expect(r['minimumText'], '5 páginas');
    expect(r['weekId'], '2026-W44');
    expect(r['weekCount'], 1);
    expect(r['weekTarget'], 7);
    expect((r['templates'] as Map).keys, {
      'windowStart',
      'lastCall',
      'inactive',
    });
  });

  test(
    'streak counts consecutive done days, ending today or yesterday',
    () async {
      await remind('lectura');
      for (final day in [26, 27, 28]) {
        now = DateTime(2026, 10, day, 9);
        await record('lectura');
      }
      now = DateTime(2026, 10, 29, 9);
      await make().sync();
      // Today is still open: the streak runs to yesterday.
      expect(entries().single['streak'], 3);
      expect(entries().single['lastDoneDate'], '2026-10-28');

      await record('lectura');
      await make().sync();
      expect(entries().single['streak'], 4);
      expect(entries().single['weekCount'], 4);
    },
  );

  test('only active reminders of known companions are included', () async {
    await remind('lectura');
    await remind('enfoque');
    await repo.progress.saveReminder(
      companionId: 'salud',
      days: 127,
      windowStartMin: 600,
      windowEndMin: 700,
    );
    await repo.progress.saveReminder(
      companionId: 'enfoque',
      days: 127,
      windowStartMin: 600,
      windowEndMin: 700,
      enabled: false,
    );
    await make().sync();
    // «salud» has no companion, «enfoque» is switched off.
    expect(entries().map((e) => e['companionId']), ['lectura']);
  });

  group('7-day pause', () {
    test('seven scheduled days without a session pause it', () async {
      await remind('lectura');
      now = DateTime(2026, 11, 4, 9); // six days missed (Oct 29 … Nov 3)
      await make().sync();
      expect(entries().single['paused'], isFalse);

      now = DateTime(2026, 11, 5, 9); // seven days missed
      await make().sync();
      expect(entries().single['paused'], isTrue);
      expect((await repo.progress.reminderFor('lectura'))!.paused, isTrue);
    });

    test('days the reminder is not scheduled do not count', () async {
      await remind('lectura', days: 0x1F); // Monday to Friday
      // Thu Oct 29 … Fri Nov 6: six weekdays missed before Nov 6.
      now = DateTime(2026, 11, 6, 9);
      await make().sync();
      expect(entries().single['paused'], isFalse);
      // Friday Nov 6 was the seventh weekday; with all days scheduled the
      // reminder would have paused on Nov 5.
      now = DateTime(2026, 11, 7, 9);
      await make().sync();
      expect(entries().single['paused'], isTrue);
    });

    test('a session before the gap resets the count', () async {
      await remind('lectura');
      now = DateTime(2026, 11, 3, 9);
      await record('lectura');
      now = DateTime(2026, 11, 9, 9); // six missed since Nov 3
      await make().sync();
      expect(entries().single['paused'], isFalse);
    });

    test('a session recorded after the pause resumes it', () async {
      await remind('lectura');
      now = DateTime(2026, 11, 6, 9);
      await make().sync();
      expect(entries().single['paused'], isTrue);

      await record('lectura');
      await make().sync();
      expect(entries().single['paused'], isFalse);
      expect((await repo.progress.reminderFor('lectura'))!.paused, isFalse);
    });

    test('«Reanudar» restarts the count instead of pausing again', () async {
      await remind('lectura');
      now = DateTime(2026, 11, 6, 9);
      await make().sync();
      expect(entries().single['paused'], isTrue);

      await repo.progress.setPaused('lectura', paused: false);
      await make().sync();
      expect(entries().single['paused'], isFalse);

      // Six more days without a session: still active; the seventh pauses.
      now = DateTime(2026, 11, 12, 9);
      await make().sync();
      expect(entries().single['paused'], isFalse);
      now = DateTime(2026, 11, 13, 9);
      await make().sync();
      expect(entries().single['paused'], isTrue);
    });
  });

  test('schedule folds a burst of changes into one sync', () async {
    await remind('lectura');
    final scheduler = make();
    for (var i = 0; i < 5; i++) {
      scheduler.schedule(const Duration(milliseconds: 20));
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(calls, hasLength(1));
    expect(scheduler.syncs, 1);
    scheduler.dispose();
  });

  test(
    'it follows its source: one sync per burst, none after dispose',
    () async {
      await remind('lectura');
      final source = ValueNotifier(0);
      final scheduler = make()..attach(source);
      // A value saved, a stop and a finish in a row.
      source.value = 1;
      source.value = 2;
      source.value = 3;
      expect(calls, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 2300));
      expect(calls.where((c) => c.method == 'sync'), hasLength(1));

      scheduler.dispose();
      source.value = 4;
      await Future<void>.delayed(const Duration(milliseconds: 2300));
      expect(calls.where((c) => c.method == 'sync'), hasLength(1));
    },
  );

  test('an unsupported platform sends nothing', () async {
    await remind('lectura');
    await make(supported: false).sync();
    await make(supported: false).clear();
    expect(calls, isEmpty);
  });

  test('native failures never break the app', () async {
    await remind('lectura');
    failure = PlatformException(code: 'denied');
    await make().sync();
    failure = MissingPluginException();
    await make().sync();
    await make().clear();
    expect(calls.where((c) => c.method == 'sync'), hasLength(2));
  });

  test('clear removes this profile from the phone', () async {
    await make().clear();
    expect(calls.single.method, 'clear');
    expect(calls.single.args, {'profileId': 'local'});
  });

  test('minimum text covers sessions, time and fields', () {
    expect(ReminderScheduler.minimumText(null), isNull);
    expect(
      ReminderScheduler.minimumText({'metric': 'sessions', 'value': 1}),
      '1 sesión',
    );
    expect(
      ReminderScheduler.minimumText({'metric': 'sessions', 'value': 2}),
      '2 sesiones',
    );
    expect(
      ReminderScheduler.minimumText({'metric': 'time', 'value': 10}),
      '10 min',
    );
    expect(
      ReminderScheduler.minimumText({'metric': 'paginas', 'value': 5}),
      '5 paginas',
    );
    expect(
      ReminderScheduler.minimumText({'metric': 'km', 'value': 2.5}),
      '2.5 km',
    );
  });

  group('tapped reminder', () {
    test(
      'the pending open is read once and ignored without a native side',
      () async {
        final answers = <Object?>[
          {'profileId': 'local', 'companionId': 'lectura'},
          null,
          {'profileId': 'local'},
          'basura',
        ];
        final scheduler = ReminderScheduler(
          progress: repo.progress,
          companions: () async => companions,
          supported: true,
          invoke: (method, args) async {
            expect(method, 'pendingOpen');
            return answers.removeAt(0);
          },
        );
        final first = await scheduler.takePendingOpen();
        expect(first, (profileId: 'local', companionId: 'lectura'));
        expect(await scheduler.takePendingOpen(), isNull);
        expect(await scheduler.takePendingOpen(), isNull);
        expect(await scheduler.takePendingOpen(), isNull);
        expect(await make(supported: false).takePendingOpen(), isNull);
      },
    );

    test('only a companion of the current profile is opened', () {
      expect(
        ReminderScheduler.resolveOpen(
          (profileId: 'local', companionId: 'enfoque'),
          currentProfileId: 'local',
          companions: companions,
        )?.id,
        'enfoque',
      );
      // Another profile: stay on the dashboard.
      expect(
        ReminderScheduler.resolveOpen(
          (profileId: 'otro', companionId: 'enfoque'),
          currentProfileId: 'local',
          companions: companions,
        ),
        isNull,
      );
      // A companion that no longer exists.
      expect(
        ReminderScheduler.resolveOpen(
          (profileId: 'local', companionId: 'borrado'),
          currentProfileId: 'local',
          companions: companions,
        ),
        isNull,
      );
    });
  });
}
