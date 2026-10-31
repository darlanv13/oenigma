import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter para desenhar cantoneiras de relíquia antiga,
/// inspiradas em artefatos de templos perdidos (estilo Indiana Jones / Tomb Raider).
class RelicCornerPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final bool showStuds;

  const RelicCornerPainter({
    required this.color,
    this.cornerLength = 22.0,
    this.strokeWidth = 2.0,
    this.showStuds = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final l = cornerLength;
    final studSize = math.max(2.5, strokeWidth * 1.4);

    // 1. Canto Superior Esquerdo
    canvas.drawLine(const Offset(0, 0), Offset(l, 0), strokePaint);
    canvas.drawLine(const Offset(0, 0), Offset(0, l), strokePaint);
    // Chanfro decorativo interno
    canvas.drawLine(Offset(l * 0.45, 0), Offset(0, l * 0.45), strokePaint);
    if (showStuds) {
      canvas.drawCircle(Offset(studSize + 1, studSize + 1), studSize, fillPaint);
    }

    // 2. Canto Superior Direito
    canvas.drawLine(Offset(w, 0), Offset(w - l, 0), strokePaint);
    canvas.drawLine(Offset(w, 0), Offset(w, l), strokePaint);
    canvas.drawLine(Offset(w - l * 0.45, 0), Offset(w, l * 0.45), strokePaint);
    if (showStuds) {
      canvas.drawCircle(Offset(w - studSize - 1, studSize + 1), studSize, fillPaint);
    }

    // 3. Canto Inferior Esquerdo
    canvas.drawLine(Offset(0, h), Offset(l, h), strokePaint);
    canvas.drawLine(Offset(0, h), Offset(0, h - l), strokePaint);
    canvas.drawLine(Offset(l * 0.45, h), Offset(0, h - l * 0.45), strokePaint);
    if (showStuds) {
      canvas.drawCircle(Offset(studSize + 1, h - studSize - 1), studSize, fillPaint);
    }

    // 4. Canto Inferior Direito
    canvas.drawLine(Offset(w, h), Offset(w - l, h), strokePaint);
    canvas.drawLine(Offset(w, h), Offset(w, h - l), strokePaint);
    canvas.drawLine(Offset(w - l * 0.45, h), Offset(w, h - l * 0.45), strokePaint);
    if (showStuds) {
      canvas.drawCircle(Offset(w - studSize - 1, h - studSize - 1), studSize, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RelicCornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showStuds != showStuds;
  }
}

