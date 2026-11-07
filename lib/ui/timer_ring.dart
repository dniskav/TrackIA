import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../application/localization.dart';
import 'theme.dart';

/// The activity clock drawn like the app icon: a ring with the four clock
/// marks and a progress arc in the brand gradient. With a [total] it counts
/// down and fills; without one it is a plain stopwatch with no arc.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.elapsed,
    this.total,
    this.size = 132,
  });

  final Duration elapsed;
  final Duration? total;
  final double size;

  /// Share of [total] already elapsed, or null when there is no countdown.
  static double? progressOf(Duration elapsed, Duration? total) {
    if (total == null || total <= Duration.zero) return null;
    return (elapsed.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);
  }

  static String format(Duration value) {
    final seconds = math.max(value.inSeconds, 0);
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = total == null ? elapsed : total! - elapsed;
    final label = format(remaining);
    return Semantics(
      label: appText(context).restScreenTimerLabel(label),
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: TimerRingPainter(
            progress: progressOf(elapsed, total),
            track: ringTrackColor(theme.brightness),
            mark: theme.colorScheme.primary,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * 26 / 132,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TimerRingPainter extends CustomPainter {
  const TimerRingPainter({
    required this.progress,
    required this.track,
    required this.mark,
  });

  final double? progress;
  final Color track, mark;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 132;
    final center = size.center(Offset.zero);
    final radius = 52 * k;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * k
      ..color = track;
    canvas.drawCircle(center, radius, ring);

    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k
      ..strokeCap = StrokeCap.round
      ..color = mark;
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (40 * k),
        center + direction * (34 * k),
        tick,
      );
    }

    final share = progress;
    if (share == null || share <= 0) return;
    final sweep = 2 * math.pi * share;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * k
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        endAngle: sweep,
        colors: brandGradient.colors,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(TimerRingPainter old) =>
      old.progress != progress || old.track != track || old.mark != mark;
}
