import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/ui/theme.dart';
import 'package:trackia/ui/timer_ring.dart';

Widget _host(Widget child, [ThemeData? theme]) => MaterialApp(
  theme: theme ?? gymTheme,
  home: Scaffold(body: Center(child: child)),
);

TimerRingPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(TimerRing),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((p) => p.painter)
    .whereType<TimerRingPainter>()
    .single;

void main() {
  group('progress', () {
    test('is null without a total or with a non-positive total', () {
      expect(TimerRing.progressOf(const Duration(seconds: 5), null), isNull);
      expect(TimerRing.progressOf(const Duration(seconds: 5), Duration.zero), isNull);
    });

    test('is the elapsed share, clamped between 0 and 1', () {
      const total = Duration(minutes: 25);
      expect(TimerRing.progressOf(Duration.zero, total), 0);
      expect(TimerRing.progressOf(const Duration(minutes: 5), total), closeTo(0.2, 1e-9));
      expect(TimerRing.progressOf(const Duration(minutes: 40), total), 1);
      expect(TimerRing.progressOf(const Duration(seconds: -3), total), 0);
    });
  });

  group('label', () {
    test('formats minutes, seconds and hours', () {
      expect(TimerRing.format(const Duration(seconds: 5)), '00:05');
      expect(TimerRing.format(const Duration(minutes: 14, seconds: 5)), '14:05');
      expect(TimerRing.format(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
      expect(TimerRing.format(const Duration(seconds: -4)), '00:00');
    });

    testWidgets('a countdown shows the remaining time', (tester) async {
      await tester.pumpWidget(_host(const TimerRing(
        elapsed: Duration(minutes: 10, seconds: 55),
        total: Duration(minutes: 25),
      )));
      expect(find.text('14:05'), findsOneWidget);
    });

    testWidgets('a stopwatch shows the elapsed time and draws no arc', (tester) async {
      await tester.pumpWidget(_host(const TimerRing(
        elapsed: Duration(minutes: 3, seconds: 9),
      )));
      expect(find.text('03:09'), findsOneWidget);
      expect(_painter(tester).progress, isNull);
    });

    testWidgets('the time uses tabular figures and has a semantic label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const TimerRing(
        elapsed: Duration(minutes: 10, seconds: 55),
        total: Duration(minutes: 25),
      )));
      final text = tester.widget<Text>(find.text('14:05'));
      expect(text.style!.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(find.bySemanticsLabel('Tiempo: 14:05'), findsOneWidget);
      handle.dispose();
    });
  });

  group('painting', () {
    testWidgets('the arc follows the elapsed share', (tester) async {
      await tester.pumpWidget(_host(const TimerRing(
        elapsed: Duration(minutes: 5),
        total: Duration(minutes: 25),
      )));
      expect(_painter(tester).progress, closeTo(0.2, 1e-9));
    });

    for (final theme in [gymTheme, gymLightTheme]) {
      testWidgets('paints in ${theme.brightness.name} mode', (tester) async {
        await tester.pumpWidget(_host(
          const TimerRing(elapsed: Duration(minutes: 5), total: Duration(minutes: 25)),
          theme,
        ));
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(TimerRing)), const Size(132, 132));
      });
    }

    test('repaints only when something visible changes', () {
      const a = TimerRingPainter(
        progress: 0.2, track: Colors.grey, mark: Colors.blue,
      );
      const same = TimerRingPainter(
        progress: 0.2, track: Colors.grey, mark: Colors.blue,
      );
      const moved = TimerRingPainter(
        progress: 0.3, track: Colors.grey, mark: Colors.blue,
      );
      expect(a.shouldRepaint(same), isFalse);
      expect(a.shouldRepaint(moved), isTrue);
    });
  });
}
