import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// The TrackIA logo (open clock ring with marks and a gradient arrow) drawn
/// with theme colors, so it works on dark backgrounds without a white box.
class TrackiaMark extends StatelessWidget {
  const TrackiaMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'TrackIA',
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: TrackiaMarkPainter(ring: dark ? brandTealLight : brandTeal),
        ),
      ),
    );
  }
}

class TrackiaMarkPainter extends CustomPainter {
  const TrackiaMarkPainter({required this.ring});

  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(0.46 * s, 0.56 * s);
    final radius = 0.36 * s;
    const gap = 0.30;
    const towardTip = Offset(0.7071, -0.7071);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = ring;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 4 + gap,
      2 * math.pi - 2 * gap,
      false,
      stroke..strokeWidth = 0.085 * s,
    );
    stroke.strokeWidth = 0.045 * s;
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final d = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + d * (0.30 * s), center + d * (0.22 * s), stroke);
    }

    final start = center;
    final shaftEnd = center + towardTip * (0.40 * s);
    final shader = LinearGradient(
      colors: brandGradient.colors,
    ).createShader(Rect.fromPoints(shaftEnd, start));
    canvas.drawLine(
      start,
      shaftEnd,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.075 * s
        ..shader = shader,
    );
    final tip = center + towardTip * (0.60 * s);
    const perpendicular = Offset(0.7071, 0.7071);
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        shaftEnd.dx + perpendicular.dx * 0.13 * s,
        shaftEnd.dy + perpendicular.dy * 0.13 * s,
      )
      ..lineTo(
        shaftEnd.dx - perpendicular.dx * 0.13 * s,
        shaftEnd.dy - perpendicular.dy * 0.13 * s,
      )
      ..close();
    canvas.drawPath(head, Paint()..color = brandOrange);
  }

  @override
  bool shouldRepaint(TrackiaMarkPainter old) => old.ring != ring;
}
