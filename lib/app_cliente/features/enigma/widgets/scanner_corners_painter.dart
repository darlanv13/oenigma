import 'package:flutter/material.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';

export 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';

/// CustomPainter para desenhar cantoneiras de artefatos antigos e molduras de relíquias.
/// Mantém compatibilidade total com o nome de classe legado ScannerCornersPainter.
class ScannerCornersPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final bool showStuds;

  const ScannerCornersPainter({
    required this.color,
    this.cornerLength = 22.0,
    this.strokeWidth = 2.0,
    this.showStuds = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final painter = RelicCornerPainter(
      color: color,
      cornerLength: cornerLength,
      strokeWidth: strokeWidth,
      showStuds: showStuds,
    );
    painter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant ScannerCornersPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showStuds != showStuds;
  }
}
