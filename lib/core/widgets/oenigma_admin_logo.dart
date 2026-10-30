import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/utils/app_colors.dart';

enum LogoSize { compact, medium, large, hero }

/// Logo Oficial Vetorial e Moderna do O Enigma (Painel Admin)
/// Criada sob medida com bússola tática estelar, anéis holográficos e tipografia premium.
class OEnigmaAdminLogo extends StatelessWidget {
  final LogoSize size;
  final bool isVertical;
  final bool showBadge;
  final String? customSubtitle;

  const OEnigmaAdminLogo({
    super.key,
    this.size = LogoSize.large,
    this.isVertical = false,
    this.showBadge = true,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final double emblemSize = switch (size) {
      LogoSize.compact => 36.0,
      LogoSize.medium => 48.0,
      LogoSize.large => 64.0,
      LogoSize.hero => 88.0,
    };

    final double titleFontSize = switch (size) {
      LogoSize.compact => 15.0,
      LogoSize.medium => 18.0,
      LogoSize.large => 22.0,
      LogoSize.hero => 28.0,
    };

    final double subtitleFontSize = switch (size) {
      LogoSize.compact => 9.0,
      LogoSize.medium => 10.0,
      LogoSize.large => 11.0,
      LogoSize.hero => 12.0,
    };

    final emblemWidget = _OEnigmaEmblem(size: emblemSize);

    final typographyWidget = Column(
      crossAxisAlignment:
          isVertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'O ENIGMA',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.amareloVale.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.amareloVale.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                'ADM',
                style: GoogleFonts.poppins(
                  color: AppColors.amareloVale,
                  fontSize: subtitleFontSize + 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          customSubtitle ?? 'CENTRAL DE COMANDO & GESTÃO',
          style: GoogleFonts.inter(
            color: AppColors.cinzaMedio,
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
        if (showBadge && size == LogoSize.hero) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.verdeVale.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.verdeVale,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Terminal Seguro • v2.0',
                  style: GoogleFonts.inter(
                    color: AppColors.verdeVale,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          emblemWidget,
          SizedBox(height: size == LogoSize.hero ? 18 : 12),
          typographyWidget,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblemWidget,
        const SizedBox(width: 14),
        typographyWidget,
      ],
    );
  }
}

/// Emblema tático estelar desenhado via CustomPainter (100% vetorial e nítido)
class _OEnigmaEmblem extends StatelessWidget {
  final double size;

  const _OEnigmaEmblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.verdeVale.withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.amareloVale.withValues(alpha: 0.20),
            blurRadius: size * 0.2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _EmblemPainter(),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Fundo Gradiente Escuro
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF14262A),
          const Color(0xFF0A1316),
          const Color(0xFF060B0C),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Anel Externo Verde-Vale
    final outerRingPaint = Paint()
      ..color = AppColors.verdeVale.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.width * 0.035);
    canvas.drawCircle(center, radius * 0.92, outerRingPaint);

    // 3. Anel Interno Amarelo-Vale Pontilhado/Fino
    final innerRingPaint = Paint()
      ..color = AppColors.amareloVale.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.width * 0.02);
    canvas.drawCircle(center, radius * 0.72, innerRingPaint);

    // 4. Marcadores Cardeais (N, S, L, O)
    final tickPaint = Paint()
      ..color = AppColors.verdeValeLight.withValues(alpha: 0.7)
      ..strokeWidth = math.max(1.2, size.width * 0.025)
      ..strokeCap = StrokeCap.round;

    final tickLen = radius * 0.14;
    // Top
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.88),
      Offset(center.dx, center.dy - radius * 0.88 + tickLen),
      tickPaint,
    );
    // Bottom
    canvas.drawLine(
      Offset(center.dx, center.dy + radius * 0.88),
      Offset(center.dx, center.dy + radius * 0.88 - tickLen),
      tickPaint,
    );
    // Left
    canvas.drawLine(
      Offset(center.dx - radius * 0.88, center.dy),
      Offset(center.dx - radius * 0.88 + tickLen, center.dy),
      tickPaint,
    );
    // Right
    canvas.drawLine(
      Offset(center.dx + radius * 0.88, center.dy),
      Offset(center.dx + radius * 0.88 - tickLen, center.dy),
      tickPaint,
    );

    // 5. Estrela da Bússola / Pontas do Enigma (Losango Facetado)
    final starRadius = radius * 0.58;
    final starRadiusMinor = radius * 0.18;

    // Ponta Norte (Dourada / Amarelo Vale)
    final northPath = Path()
      ..moveTo(center.dx, center.dy - starRadius)
      ..lineTo(center.dx + starRadiusMinor, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final northPaint = Paint()..color = AppColors.amareloVale;
    canvas.drawPath(northPath, northPaint);

    final northLeftPath = Path()
      ..moveTo(center.dx, center.dy - starRadius)
      ..lineTo(center.dx - starRadiusMinor, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final northLeftPaint = Paint()..color = AppColors.amareloValeDark;
    canvas.drawPath(northLeftPath, northLeftPaint);

    // Ponta Sul (Verde Vale)
    final southPath = Path()
      ..moveTo(center.dx, center.dy + starRadius)
      ..lineTo(center.dx + starRadiusMinor, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final southPaint = Paint()..color = AppColors.verdeVale;
    canvas.drawPath(southPath, southPaint);

    final southLeftPath = Path()
      ..moveTo(center.dx, center.dy + starRadius)
      ..lineTo(center.dx - starRadiusMinor, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final southLeftPaint = Paint()..color = AppColors.verdeValeDark;
    canvas.drawPath(southLeftPath, southLeftPaint);

    // Ponta Leste (Horizontal Direita)
    final eastPath = Path()
      ..moveTo(center.dx + starRadius, center.dy)
      ..lineTo(center.dx, center.dy - starRadiusMinor)
      ..lineTo(center.dx, center.dy)
      ..close();
    final eastPaint = Paint()..color = AppColors.verdeValeLight.withValues(alpha: 0.9);
    canvas.drawPath(eastPath, eastPaint);

    final eastBottomPath = Path()
      ..moveTo(center.dx + starRadius, center.dy)
      ..lineTo(center.dx, center.dy + starRadiusMinor)
      ..lineTo(center.dx, center.dy)
      ..close();
    final eastBottomPaint = Paint()..color = AppColors.verdeVale;
    canvas.drawPath(eastBottomPath, eastBottomPaint);

    // Ponta Oeste (Horizontal Esquerda)
    final westPath = Path()
      ..moveTo(center.dx - starRadius, center.dy)
      ..lineTo(center.dx, center.dy - starRadiusMinor)
      ..lineTo(center.dx, center.dy)
      ..close();
    final westPaint = Paint()..color = AppColors.cinzaMedio;
    canvas.drawPath(westPath, westPaint);

    final westBottomPath = Path()
      ..moveTo(center.dx - starRadius, center.dy)
      ..lineTo(center.dx, center.dy + starRadiusMinor)
      ..lineTo(center.dx, center.dy)
      ..close();
    final westBottomPaint = Paint()..color = const Color(0xFF2C3E42);
    canvas.drawPath(westBottomPath, westBottomPaint);

    // 6. Núcleo de Diamante / Cristal Central
    final coreRadius = radius * 0.16;
    final corePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, AppColors.amareloVale, AppColors.verdeVale],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, corePaint);

    final coreBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.width * 0.02);
    canvas.drawCircle(center, coreRadius, coreBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
