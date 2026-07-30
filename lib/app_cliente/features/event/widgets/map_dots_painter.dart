import 'package:flutter/material.dart';
import 'dart:math';

class MapDotsPainter extends CustomPainter {
  final Color dotColor;

  MapDotsPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    _drawRadialPattern(canvas, Offset(size.width * 0.2, size.height * 0.4), size.width * 0.3, paint);
    _drawRadialPattern(canvas, Offset(size.width * 0.7, size.height * 0.8), size.width * 0.2, paint);
    _drawRadialPattern(canvas, Offset(size.width * 0.9, size.height * 0.2), size.width * 0.25, paint);
  }

  void _drawRadialPattern(Canvas canvas, Offset center, double radius, Paint paint) {
    const double step = 20.0;
    for (double r = step; r < radius; r += step) {
      double circumference = 2 * pi * r;
      int numDots = (circumference / step).floor();
      for (int i = 0; i < numDots; i++) {
        double angle = (i * 2 * pi) / numDots;
        double x = center.dx + r * cos(angle);
        double y = center.dy + r * sin(angle);
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
