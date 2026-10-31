import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Bússola Dourada do Explorador: Estilo Indiana Jones / Tomb Raider com cores Vale.
class CompassWidget extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;
  final int durationSeconds;
  final VoidCallback onTimeUp;
  final Function(int) onTick;
  final bool isCompact;

  const CompassWidget({
    super.key,
    required this.targetLatitude,
    required this.targetLongitude,
    double? destinationLongitude,
    double? destinationLatitude,
    required this.durationSeconds,
    required this.onTimeUp,
    required this.onTick,
    this.isCompact = false,
  });

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;

  double _currentHeading = 0.0;
  Position? _currentPosition;
  bool _hasPermissions = false;

  late int _remainingSeconds;
  Timer? _countdownTimer;
  bool _wasLockedOn = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;

    // Controlador da rotação da agulha e pulso místico
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _initSensors();
    _startTimer();
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
          widget.onTick(_remainingSeconds);
          if (_remainingSeconds <= 0) {
            timer.cancel();
            widget.onTimeUp();
          }
        });
      }
    });
  }

  Future<void> _initSensors() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) setState(() => _hasPermissions = true);

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).listen((Position position) {
        if (mounted) setState(() => _currentPosition = position);
      });

      FlutterCompass.events?.listen((CompassEvent event) {
        if (mounted && event.heading != null) {
          setState(() => _currentHeading = event.heading!);
        }
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _getCardinalDirection(double heading) {
    final normalized = (heading % 360 + 360) % 360;
    if (normalized >= 337.5 || normalized < 22.5) return 'Norte (N)';
    if (normalized >= 22.5 && normalized < 67.5) return 'Nordeste (NE)';
    if (normalized >= 67.5 && normalized < 112.5) return 'Leste (L)';
    if (normalized >= 112.5 && normalized < 157.5) return 'Sudeste (SE)';
    if (normalized >= 157.5 && normalized < 202.5) return 'Sul (S)';
    if (normalized >= 202.5 && normalized < 247.5) return 'Sudoeste (SO)';
    if (normalized >= 247.5 && normalized < 292.5) return 'Oeste (O)';
    return 'Noroeste (NO)';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation, color: AppColors.danger, size: 28),
            const SizedBox(height: 10),
            Text(
              'Permissão de Localização Necessária',
              style: GoogleFonts.cinzel(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Ative o GPS para sincronizar a bússola dourada com a relíquia.',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_currentPosition == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.amareloVale),
            const SizedBox(height: 16),
            Text(
              'SINTONIZANDO A BÚSSOLA DOURADA...',
              style: GoogleFonts.cinzel(
                color: AppColors.amareloVale,
                fontSize: 12.5,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.targetLatitude,
      widget.targetLongitude,
    );

    final double bearing = Geolocator.bearingBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.targetLatitude,
      widget.targetLongitude,
    );

    final double targetAngle = (bearing - _currentHeading) * (math.pi / 180);

    // Diferença angular (-180 a +180) para detecção de alinhamento
    double diffDegrees = (bearing - _currentHeading) % 360;
    if (diffDegrees > 180) diffDegrees -= 360;
    if (diffDegrees < -180) diffDegrees += 360;
    final bool isLockedOn = diffDegrees.abs() <= 15.0;

    // Efeito tátil e sonoro quando o explorador aponta exatamente para a relíquia
    if (isLockedOn && !_wasLockedOn) {
      _wasLockedOn = true;
      HapticFeedback.selectionClick();
      SoundService.playScan();
    } else if (!isLockedOn && _wasLockedOn) {
      _wasLockedOn = false;
    }

    final double compassSize = widget.isCompact ? 200.0 : 255.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top HUD da Bússola: Ampulheta de Tempo & Azimute
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.durationSeconds > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.amareloVale.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.6), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.hourglassHalf, color: AppColors.amareloVale, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: GoogleFonts.cinzel(
                        color: AppColors.amareloVale,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(FontAwesomeIcons.compass, color: AppColors.verdeVale, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    '${_currentHeading.toInt()}° ${_getCardinalDirection(_currentHeading)}',
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Mostrador da Bússola Dourada em Latão e Obsidiana
        Center(
          child: Container(
            width: compassSize,
            height: compassSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkCardColor,
              boxShadow: [
                BoxShadow(
                  color: isLockedOn
                      ? AppColors.amareloVale.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.7),
                  blurRadius: isLockedOn ? 24 : 14,
                  spreadRadius: isLockedOn ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: (isLockedOn ? AppColors.amareloVale : AppColors.verdeVale).withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                ),
              ],
              border: Border.all(
                color: isLockedOn ? AppColors.amareloVale : AppColors.verdeValeDark,
                width: isLockedOn ? 5 : 4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ClipOval(
                child: AnimatedBuilder(
                  animation: _scannerController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ExpeditionCompassPainter(
                        scannerAngle: _scannerController.value * 2 * math.pi,
                        targetAngle: targetAngle,
                        distance: distance,
                        isLockedOn: isLockedOn,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Barra de Orientação do Explorador
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isLockedOn
                ? AppColors.amareloVale.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLockedOn ? AppColors.amareloVale : Colors.white24,
              width: isLockedOn ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                isLockedOn
                    ? FontAwesomeIcons.bullseye
                    : (diffDegrees > 0 ? FontAwesomeIcons.arrowRight : FontAwesomeIcons.arrowLeft),
                color: isLockedOn ? AppColors.amareloVale : AppColors.verdeVale,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                isLockedOn
                    ? '🧭 ALINHADO COM A RELÍQUIA • AVANCE NESTA DIREÇÃO!'
                    : (diffDegrees > 0
                        ? 'GIRE PARA A DIREITA (${diffDegrees.toInt()}°)'
                        : 'GIRE PARA A ESQUERDA (${(-diffDegrees).toInt()}°)'),
                style: GoogleFonts.cinzel(
                  color: isLockedOn ? AppColors.amareloVale : Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Medidor Rúnico de Distância
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLockedOn ? AppColors.amareloVale : AppColors.verdeVale,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isLockedOn ? AppColors.amareloVale : AppColors.verdeVale)
                    .withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.locationArrow,
                color: isLockedOn ? AppColors.amareloVale : AppColors.verdeVale,
                size: 14,
              ),
              const SizedBox(width: 10),
              Text(
                '${distance.toStringAsFixed(0)} METROS',
                style: GoogleFonts.cinzel(
                  color: isLockedOn ? AppColors.amareloVale : AppColors.verdeVale,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// CUSTOM PAINTER - Rosa dos Ventos da Expedição Antiga
// ---------------------------------------------------------
class ExpeditionCompassPainter extends CustomPainter {
  final double scannerAngle;
  final double targetAngle;
  final double distance;
  final bool isLockedOn;

  ExpeditionCompassPainter({
    required this.scannerAngle,
    required this.targetAngle,
    required this.distance,
    this.isLockedOn = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Fundo de Obsidiana e Latão
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: isLockedOn
            ? const [Color(0xFF28200E), Color(0xFF100C05)]
            : const [Color(0xFF0F2023), Color(0xFF071012)],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Círculos da Rosa dos Ventos & Marcações Antigas
    final dialPaint = Paint()
      ..color = (isLockedOn ? AppColors.amareloVale : AppColors.verdeVale).withValues(alpha: 0.28)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius * 0.35, dialPaint);
    canvas.drawCircle(center, radius * 0.70, dialPaint);
    canvas.drawCircle(center, radius * 0.94, dialPaint);

    // Linhas Cardinais (Cruzeta da Rosa dos Ventos)
    final crossPaint = Paint()
      ..color = (isLockedOn ? AppColors.amareloVale : AppColors.verdeVale).withValues(alpha: 0.35)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(center.dx, radius * 0.1), Offset(center.dx, size.height - radius * 0.1), crossPaint);
    canvas.drawLine(Offset(radius * 0.1, center.dy), Offset(size.width - radius * 0.1, center.dy), crossPaint);

    // Letra N (Norte) no topo
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'N',
        style: GoogleFonts.cinzel(
          color: AppColors.amareloVale,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, 6));

    // 3. Posição da Relíquia Sagrada (Target Gem)
    const double maxRadarRange = 400.0;
    final double displayRadius = distance > maxRadarRange
        ? radius * 0.85
        : (distance / maxRadarRange) * (radius * 0.82);

    final double targetX = center.dx + displayRadius * math.cos(targetAngle - math.pi / 2);
    final double targetY = center.dy + displayRadius * math.sin(targetAngle - math.pi / 2);
    final targetOffset = Offset(targetX, targetY);

    // Feixe Místico se estiver Alinhado (Lock-On)
    if (isLockedOn) {
      final lockBeamPaint = Paint()
        ..color = AppColors.amareloVale.withValues(alpha: 0.4)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, targetOffset, lockBeamPaint);

      final lockRingPaint = Paint()
        ..color = AppColors.amareloVale
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(targetOffset, 16, lockRingPaint);
    }

    // Glow e Gema Sagrada da Relíquia
    final glowPaint = Paint()
      ..color = AppColors.amareloVale.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(targetOffset, 12, glowPaint);

    final dotPaint = Paint()..color = isLockedOn ? AppColors.amareloVale : const Color(0xFFFFD700);
    canvas.drawCircle(targetOffset, 7, dotPaint);

    final centerDotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(targetOffset, 2.5, centerDotPaint);

    // 4. Pulso da Tocha / Varredura da Bússola
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          (isLockedOn ? AppColors.amareloVale : AppColors.verdeVale).withValues(alpha: 0.04),
          (isLockedOn ? AppColors.amareloVale : AppColors.verdeVale).withValues(alpha: 0.35),
        ],
        stops: const [0.0, 0.75, 1.0],
        transform: GradientRotation(scannerAngle - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      true,
      sweepPaint,
    );

    // 5. Agulha Central do Explorador
    final needlePaint = Paint()
      ..color = AppColors.amareloVale
      ..style = PaintingStyle.fill;

    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy - 14);
    needlePath.lineTo(center.dx - 7, center.dy + 8);
    needlePath.lineTo(center.dx, center.dy + 4);
    needlePath.lineTo(center.dx + 7, center.dy + 8);
    needlePath.close();

    canvas.drawShadow(needlePath, Colors.black, 4, true);
    canvas.drawPath(needlePath, needlePaint);
  }

  @override
  bool shouldRepaint(covariant ExpeditionCompassPainter oldDelegate) {
    return oldDelegate.scannerAngle != scannerAngle ||
        oldDelegate.targetAngle != targetAngle ||
        oldDelegate.distance != distance ||
        oldDelegate.isLockedOn != isLockedOn;
  }
}
