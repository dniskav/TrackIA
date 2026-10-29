import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// A progress ring: [fraction] of the way round in the brand gradient over a
/// faint track. Complete rings read as achieved.
class GoalRing extends StatelessWidget {
  const GoalRing({
    super.key,
    required this.fraction,
    this.size = 56,
    this.child,
    this.locked = false,
  });

  final double fraction;
  final double size;
  final Widget? child;

  /// A locked achievement draws its progress in the plain primary colour.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoalRingPainter(
          fraction: fraction.clamp(0.0, 1.0),
          track: scheme.onSurface.withValues(alpha: 0.12),
          plain: scheme.primary,
          locked: locked,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  _GoalRingPainter({
    required this.fraction,
    required this.track,
    required this.plain,
    required this.locked,
  });

  final double fraction;
  final Color track, plain;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.11;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (fraction <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (locked) {
      paint.color = plain;
    } else {
      paint.shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: brandGradient.colors,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    }
    canvas.drawArc(arc, -math.pi / 2, math.pi * 2 * fraction, false, paint);
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) =>
      old.fraction != fraction || old.locked != locked || old.track != track;
}
