import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/domain/progress.dart';
import 'package:trackia/ui/activity_summary.dart';
import 'package:trackia/ui/theme.dart';

void main() {
  Achievement achievement(String title, String icon, String hash) =>
      Achievement(
        id: hash,
        companionId: 'lectura',
        rule: AchievementRule.streak(threshold: 3),
        ruleHash: hash,
        title: title,
        icon: icon,
        origin: 'generated',
      );

  Future<void> show(WidgetTester tester, ProgressDelta delta) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showActivitySummary(
              context,
              name: 'Leer',
              duration: const Duration(minutes: 20),
              delta: delta,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('without news it says so and still closes the session', (
    tester,
  ) async {
    await show(tester, const ProgressDelta());
    expect(find.text('Sesión terminada'), findsOneWidget);
    expect(find.text('Leer · 20 min'), findsOneWidget);
    expect(find.byKey(const Key('summary-ring')), findsOneWidget);
    expect(find.byKey(const Key('summary-empty')), findsOneWidget);
    expect(find.byKey(const Key('summary-record-0')), findsNothing);
    await tester.tap(find.byKey(const Key('summary-close')));
    await tester.pumpAndSettle();
    expect(find.text('Sesión terminada'), findsNothing);
  });

  testWidgets('records and several new achievements are listed', (
    tester,
  ) async {
    // Several unlocks at once once crashed the sheet with duplicate keys.
    await show(
      tester,
      ProgressDelta(
        records: const [
          ProgressRecord('Sesión más larga', 25, unit: 'min'),
          ProgressRecord('Récord de páginas', 1250),
        ],
        unlocked: [
          achievement('100 páginas', 'count', 'a'),
          achievement('Racha de 3 días', 'streak', 'b'),
          achievement('1 h en Lectura', 'time', 'c'),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('summary-empty')), findsNothing);
    expect(find.text('Sesión más larga'), findsOneWidget);
    expect(find.text('25 min'), findsOneWidget);
    expect(find.text('1.250'), findsOneWidget);
    expect(find.text('100 páginas'), findsOneWidget);
    expect(find.text('Racha de 3 días'), findsOneWidget);
    expect(find.text('Logro nuevo'), findsNWidgets(3));
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  test('durations read naturally', () {
    expect(durationText(const Duration(seconds: 45)), '45 s');
    expect(durationText(const Duration(minutes: 20)), '20 min');
    expect(durationText(const Duration(minutes: 60)), '1 h');
    expect(durationText(const Duration(minutes: 95)), '1 h 35 min');
  });

  test('every icon id has an icon', () {
    for (final id in Achievement.icons) {
      expect(achievementIcon(id), isNot(Icons.help));
    }
  });
}
