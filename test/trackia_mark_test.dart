import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/ui/theme.dart';
import 'package:trackia/ui/trackia_mark.dart';

void main() {
  for (final theme in [gymTheme, gymLightTheme]) {
    testWidgets('paints in ${theme.brightness.name} mode with the right teal', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: Center(child: TrackiaMark(size: 96))),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(TrackiaMark)), const Size(96, 96));
      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(TrackiaMark),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((p) => p.painter)
          .whereType<TrackiaMarkPainter>()
          .single;
      expect(
        painter.ring,
        theme.brightness == Brightness.dark ? brandTealLight : brandTeal,
      );
    });
  }

  testWidgets('has a semantic label and scales to a small size', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: gymTheme,
        home: const Scaffold(body: Center(child: TrackiaMark(size: 32))),
      ),
    );
    expect(find.bySemanticsLabel('TrackIA'), findsOneWidget);
    expect(tester.getSize(find.byType(TrackiaMark)), const Size(32, 32));
    handle.dispose();
  });

  test('repaints only when the ring color changes', () {
    const a = TrackiaMarkPainter(ring: Colors.teal);
    const same = TrackiaMarkPainter(ring: Colors.teal);
    const other = TrackiaMarkPainter(ring: Colors.blue);
    expect(a.shouldRepaint(same), isFalse);
    expect(a.shouldRepaint(other), isTrue);
  });
}
