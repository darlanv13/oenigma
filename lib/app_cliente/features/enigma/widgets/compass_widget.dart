import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

    // Controlador da animação de varredura do radar
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.redAccent, size: 28),
            const SizedBox(height: 10),
            Text(
              'Permissão de Localização Necessária',
              style: GoogleFonts.orbitron(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Ative o GPS para sincronizar o sonar e a bússola com o alvo.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
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
            const CircularProgressIndicator(color: Color(0xFF00E5FF)),
            const SizedBox(height: 16),
            Text(
              'SINCRONIZANDO SONAR...',
              style: GoogleFonts.orbitron(
                color: const Color(0xFF00E5FF),
                fontSize: 13,
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

    // Diferença angular (-180 a +180) para o cálculo de Lock-on
    double diffDegrees = (bearing - _currentHeading) % 360;
    if (diffDegrees > 180) diffDegrees -= 360;
    if (diffDegrees < -180) diffDegrees += 360;
    final bool isLockedOn = diffDegrees.abs() <= 14.0;

    // Haptic feedback quando trava a mira no alvo
    if (isLockedOn && !_wasLockedOn) {
      _wasLockedOn = true;
      HapticFeedback.selectionClick();
    } else if (!isLockedOn && _wasLockedOn) {
      _wasLockedOn = false;
    }

    final double radarSize = widget.isCompact ? 200.0 : 255.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top HUD: Timer & Azimute
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.durationSeconds > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: GoogleFonts.orbitron(
                        color: Colors.redAccent,
                        fontSize: 13,
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
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(FontAwesomeIcons.compass, color: Color(0xFF00E5FF), size: 12),
                  const SizedBox(width: 6),
                  Text(
                    '${_currentHeading.toInt()}° ${_getCardinalDirection(_currentHeading)}',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Radar 360° com efeito metálico e display holográfico
        Center(
          child: Container(
            width: radarSize,
            height: radarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E282A),
              boxShadow: [
                BoxShadow(
                  color: isLockedOn
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.7),
                  blurRadius: isLockedOn ? 24 : 14,
                  spreadRadius: isLockedOn ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: (isLockedOn ? const Color(0xFF00E5FF) : Colors.white).withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                ),
              ],
              border: Border.all(
                color: isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFF4A5B60),
                width: isLockedOn ? 6 : 5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ClipOval(
                child: AnimatedBuilder(
                  animation: _scannerController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: DragonRadarPainter(
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

        // Barra de Orientação Direcional (Lock-On / Vire à Direita / Vire à Esquerda)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isLockedOn
                ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLockedOn ? const Color(0xFF00E5FF) : Colors.white24,
              width: isLockedOn ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                isLockedOn
                    ? FontAwesomeIcons.crosshairs
                    : (diffDegrees > 0 ? FontAwesomeIcons.arrowRight : FontAwesomeIcons.arrowLeft),
                color: isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFFF3A522),
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                isLockedOn
                    ? '🎯 ALVO NA MIRA (LOCK-ON) • AVANCE NESTA DIREÇÃO'
                    : (diffDegrees > 0
                        ? 'GIRE PARA A DIREITA (${diffDegrees.toInt()}°)'
                        : 'GIRE PARA A ESQUERDA (${(-diffDegrees).toInt()}°)'),
                style: GoogleFonts.orbitron(
                  color: isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFFF3A522),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Visor Digital de Distância com Estilo Cyberpunk
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F11),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFF88C928),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFF88C928))
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
                color: isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFF88C928),
                size: 14,
              ),
              const SizedBox(width: 10),
              Text(
                '${distance.toStringAsFixed(0)} METROS',
                style: GoogleFonts.orbitron(
                  color: isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFF88C928),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
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
// CUSTOM PAINTER - Radar Holográfico Tático 360°
// ---------------------------------------------------------
class DragonRadarPainter extends CustomPainter {
  final double scannerAngle;
  final double targetAngle;
  final double distance;
  final bool isLockedOn;

  DragonRadarPainter({
    required this.scannerAngle,
    required this.targetAngle,
    required this.distance,
    this.isLockedOn = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Fundo do Radar com Gradiente Tático
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: isLockedOn
            ? const [Color(0xFF0B3338), Color(0xFF04171A)]
            : const [Color(0xFF1B381C), Color(0xFF0D1D0F)],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Grade Cibernética (Grid Lines & Círculos Concéntricos)
    final gridPaint = Paint()
      ..color = (isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFFB5E655)).withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const int lines = 6;
    final double step = size.width / lines;
    for (int i = 1; i < lines; i++) {
      canvas.drawLine(
        Offset(step * i, 0),
        Offset(step * i, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, step * i),
        Offset(size.width, step * i),
        gridPaint,
      );
    }

    // Círculos de Distância Concéntricos
    canvas.drawCircle(center, radius * 0.33, gridPaint);
    canvas.drawCircle(center, radius * 0.66, gridPaint);
    canvas.drawCircle(center, radius * 0.95, gridPaint);

    // Linhas Cardinais (Cruzeta)
    final crossPaint = Paint()
      ..color = (isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFFB5E655)).withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);

    // 3. Alvo (Target)
    const double maxRadarRange = 400.0;
    final double displayRadius = distance > maxRadarRange
        ? radius * 0.88
        : (distance / maxRadarRange) * (radius * 0.85);

    final double targetX = center.dx + displayRadius * math.cos(targetAngle - math.pi / 2);
    final double targetY = center.dy + displayRadius * math.sin(targetAngle - math.pi / 2);
    final targetOffset = Offset(targetX, targetY);

    // Feixe Direcional se estiver em Lock-On
    if (isLockedOn) {
      final lockBeamPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, targetOffset, lockBeamPaint);

      // Círculo de mira sobre o alvo
      final lockRingPaint = Paint()
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(targetOffset, 16, lockRingPaint);
    }

    // Glow e Ponto do Alvo
    final glowPaint = Paint()
      ..color = (isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFFF3A522)).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(targetOffset, 12, glowPaint);

    final dotPaint = Paint()
      ..color = isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFFFFD700);
    canvas.drawCircle(targetOffset, 7, dotPaint);

    final centerDotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(targetOffset, 2.5, centerDotPaint);

    // 4. Scanner de Varredura (Sweep Holográfico)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          (isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFF88C928)).withValues(alpha: 0.05),
          (isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFFE8FFB7)).withValues(alpha: 0.45),
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

    // Linha frontal do scanner
    final scannerLinePaint = Paint()
      ..color = (isLockedOn ? const Color(0xFF00E5FF) : const Color(0xFFE8FFB7)).withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final lineEndX = center.dx + radius * math.cos(scannerAngle - math.pi / 2);
    final lineEndY = center.dy + radius * math.sin(scannerAngle - math.pi / 2);
    canvas.drawLine(center, Offset(lineEndX, lineEndY), scannerLinePaint);

    // 5. Jogador / Navegador (Triângulo Central)
    final playerPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - 12);
    path.lineTo(center.dx - 8, center.dy + 8);
    path.lineTo(center.dx, center.dy + 4);
    path.lineTo(center.dx + 8, center.dy + 8);
    path.close();

    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, playerPaint);
  }

  @override
  bool shouldRepaint(covariant DragonRadarPainter oldDelegate) {
    return oldDelegate.scannerAngle != scannerAngle ||
        oldDelegate.targetAngle != targetAngle ||
        oldDelegate.distance != distance ||
        oldDelegate.isLockedOn != isLockedOn;
  }
}
