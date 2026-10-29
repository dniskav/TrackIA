import 'package:flutter_test/flutter_test.dart';

/// Lets real I/O (SQLite, files) finish while the widget clock is faked, so a
/// following `pumpAndSettle` does not wait on a load that can never complete.
/// It alternates frames and real waiting: a route built by a frame only starts
/// its I/O after that frame, and each awaited step of a chain of database
/// calls needs another frame to continue.
Future<void> realIo(WidgetTester tester, [int rounds = 60]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
  }
  await tester.pump();
}
