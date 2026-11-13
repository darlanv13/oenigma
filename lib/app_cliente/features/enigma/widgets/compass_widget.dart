import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/services/decoy_location_service.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Bússola Dourada do Explorador: Usa o sensor de bússola nativo do telefone.
/// O mostrador gira em tempo real com a orientação física do aparelho.
/// Foco visual no instrumento, sem poluição de texto e com timer no canto inferior direito.
class CompassWidget extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;
  final double? destinationLongitude;
  final double? destinationLatitude;
  final int durationSeconds;
  final VoidCallback onTimeUp;
  final Function(int) onTick;
  final bool isCompact;
  final VoidCallback? onExpand;
  final List<DecoyTarget>? targets;
  final bool enableToolTimer;

  const CompassWidget({
    super.key,
    required this.targetLatitude,
    required this.targetLongitude,
    this.destinationLongitude,
    this.destinationLatitude,
    required this.durationSeconds,
    required this.onTimeUp,
    required this.onTick,
    this.isCompact = true,
    this.onExpand,
    this.targets,
    this.enableToolTimer = true,
  });

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  double _currentHeading = 0.0;
  double _manualHeadingOffset = 0.0;
  bool _hasCompassSensor = true;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  late int _remainingSeconds;
  Timer? _countdownTimer;
  bool _wasLockedOn = false;
  int _selectedTargetIndex = 0;

  List<DecoyTarget> get _effectiveTargets {
    if (widget.targets != null && widget.targets!.isNotEmpty) {
      return widget.targets!;
    }
    return [
      DecoyTarget(
        index: 1,
        label: 'Sinal 1',
        latitude: widget.targetLatitude,
        longitude: widget.targetLongitude,
        isReal: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;

    // Pulso suave do anel de trava
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _initHardwareCompassAndGps();
    _startTimer();
  }

  void _startTimer() {
    if (!widget.enableToolTimer || _remainingSeconds <= 0) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        widget.onTick(_remainingSeconds);
        if (_remainingSeconds <= 0) {
          timer.cancel();
          widget.onTimeUp();
        }
      });
    });
  }

  /// Conecta diretamente ao sensor de bússola do telefone e ao GPS
  Future<void> _initHardwareCompassAndGps() async {
    // 1. Posição rápida do cache
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() => _currentPosition = lastKnown);
      }
    } catch (_) {}

    // 2. Stream de posição contínuo
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _positionSubscription?.cancel();
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
            distanceFilter: kIsWeb ? 0 : 1,
          ),
        ).listen(
          (pos) {
            if (mounted) setState(() => _currentPosition = pos);
          },
          onError: (_) {},
        );
      }
    } catch (_) {}

    // 3. Sensor Físico da Bússola do Aparelho (Magnetômetro)
    try {
      if (FlutterCompass.events != null) {
        _compassSubscription?.cancel();
        _compassSubscription = FlutterCompass.events!.listen(
          (event) {
            if (mounted && event.heading != null) {
              setState(() {
                _hasCompassSensor = true;
                _currentHeading = (event.heading! % 360 + 360) % 360;
              });
            }
          },
          onError: (_) {
            if (mounted) setState(() => _hasCompassSensor = false);
          },
        );
      } else {
        if (mounted) setState(() => _hasCompassSensor = false);
      }
    } catch (_) {
      if (mounted) setState(() => _hasCompassSensor = false);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _getCardinalLetters(double heading) {
    final h = (heading % 360 + 360) % 360;
    if (h >= 337.5 || h < 22.5) return 'N';
    if (h >= 22.5 && h < 67.5) return 'NE';
    if (h >= 67.5 && h < 112.5) return 'L';
    if (h >= 112.5 && h < 157.5) return 'SE';
    if (h >= 157.5 && h < 202.5) return 'S';
    if (h >= 202.5 && h < 247.5) return 'SO';
    if (h >= 247.5 && h < 292.5) return 'O';
    return 'NO';
  }

  @override
  Widget build(BuildContext context) {
    final targets = _effectiveTargets;
    if (_selectedTargetIndex >= targets.length) {
      _selectedTargetIndex = 0;
    }
    final currentTarget = targets[_selectedTargetIndex];

    // Cálculos de distância e azimute da relíquia
    double distance = 120.0;
    double targetBearing = 0.0;

    if (_currentPosition != null) {
      distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        currentTarget.latitude,
        currentTarget.longitude,
      );
      targetBearing = Geolocator.bearingBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        currentTarget.latitude,
        currentTarget.longitude,
      );
    }

    final double effectiveHeading = (_currentHeading + _manualHeadingOffset) % 360;

    // Diferença angular entre a orientação do telefone e a relíquia
    double diffDegrees = (targetBearing - effectiveHeading) % 360;
    if (diffDegrees > 180) diffDegrees -= 360;
    if (diffDegrees < -180) diffDegrees += 360;
    final bool isLockedOn = diffDegrees.abs() <= 15.0;

    if (isLockedOn && !_wasLockedOn) {
      _wasLockedOn = true;
      HapticFeedback.selectionClick();
      SoundService.playScan();
    } else if (!isLockedOn && _wasLockedOn) {
      _wasLockedOn = false;
    }

    // Dimensões do mostrador
    final double frameHeight = widget.isCompact ? 390.0 : 540.0;
    final double compassSize = widget.isCompact ? 220.0 : 300.0;

    return Container(
      height: frameHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLockedOn ? const Color(0xFFF3A522) : const Color(0xFF1E3A45),
          width: isLockedOn ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLockedOn ? const Color(0xFFF3A522) : Colors.black)
                .withValues(alpha: isLockedOn ? 0.22 : 0.4),
            blurRadius: isLockedOn ? 18 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. CABEÇALHO LIMPO (Apenas Título e Botão Expandir - Sem Timer no Topo)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF281F08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFF3A522).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.compass,
                          color: Color(0xFFF3A522),
                          size: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BÚSSOLA DOURADA',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),

                  // Botão Expandir
                  if (widget.onExpand != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        SoundService.playClick();
                        widget.onExpand!();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18252E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF1E3A45),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.expand,
                              color: Color(0xFF00A4B4),
                              size: 10,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'EXPANDIR',
                              style: GoogleFonts.cinzel(
                                color: const Color(0xFF00A4B4),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // 2. SELETOR DE SINAIS (Se houver múltiplos)
              if (targets.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(targets.length, (idx) {
                      final isSel = idx == _selectedTargetIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            SoundService.playClick();
                            setState(() => _selectedTargetIndex = idx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFF3A522) : const Color(0xFF0C1417),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFFF3A522)
                                    : Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Sinal ${idx + 1}',
                              style: GoogleFonts.cinzel(
                                color: isSel ? Colors.black : Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

              // 3. O INSTRUMENTO HERO: MOSTRADOR QUE GIRA COM O TELEFONE
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      // Fallback Web se não houver sensor físico
                      if (kIsWeb || !_hasCompassSensor) {
                        setState(() {
                          _manualHeadingOffset =
                              (_manualHeadingOffset + details.delta.dx * 0.6) % 360;
                        });
                      }
                    },
                    child: SizedBox(
                      width: compassSize,
                      height: compassSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // A. Mostrador com rosa dos ventos que gira com o sensor do telefone
                          Transform.rotate(
                            angle: -(effectiveHeading * math.pi / 180),
                            child: Container(
                              width: compassSize,
                              height: compassSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0A1115),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLockedOn
                                            ? const Color(0xFFF3A522)
                                            : Colors.black)
                                        .withValues(alpha: isLockedOn ? 0.35 : 0.6),
                                    blurRadius: isLockedOn ? 22 : 14,
                                  ),
                                ],
                                border: Border.all(
                                  color: isLockedOn
                                      ? const Color(0xFFF3A522)
                                      : const Color(0xFF8C7335).withValues(alpha: 0.7),
                                  width: isLockedOn ? 3.5 : 2.2,
                                ),
                              ),
                              child: CustomPaint(
                                size: Size(compassSize, compassSize),
                                painter: const _RotatingCompassDialPainter(),
                              ),
                            ),
                          ),

                          // B. Agulha/Vetor que aponta para a Relíquia
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              return CustomPaint(
                                size: Size(compassSize, compassSize),
                                painter: _TargetRelicNeedlePainter(
                                  relativeAngleRad: diffDegrees * math.pi / 180,
                                  isLockedOn: isLockedOn,
                                  pulseValue: _pulseController.value,
                                ),
                              );
                            },
                          ),

                          // C. Marcador de Referência Superior do Telefone (Lubber Line Fixa)
                          Positioned(
                            top: 2,
                            child: Container(
                              width: 8,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isLockedOn
                                    ? const Color(0xFFF3A522)
                                    : const Color(0xFF00D2B4),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLockedOn
                                            ? const Color(0xFFF3A522)
                                            : const Color(0xFF00D2B4))
                                        .withValues(alpha: 0.7),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. BARRA INFERIOR (Distância na Esquerda, Azimute no Centro, TIMER NO CANTO DIREITO)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Canto Esquerdo: Distância até a relíquia
                  Row(
                    children: [
                      FaIcon(
                        isLockedOn
                            ? FontAwesomeIcons.bullseye
                            : FontAwesomeIcons.locationCrosshairs,
                        color: isLockedOn
                            ? const Color(0xFFF3A522)
                            : const Color(0xFF00A4B4),
                        size: 12,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${distance.toInt()} M',
                        style: GoogleFonts.orbitron(
                          color: isLockedOn
                              ? const Color(0xFFF3A522)
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // Centro: Azimute do Telefone
                  Text(
                    '${effectiveHeading.toInt()}° ${_getCardinalLetters(effectiveHeading)}',
                    style: GoogleFonts.orbitron(
                      color: AppColors.cinzaMedio,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // CANTO DIREITO NA PARTE DE BAIXO: O TIMER DA FERRAMENTA
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1708),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF3A522).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          widget.enableToolTimer
                              ? FontAwesomeIcons.hourglassHalf
                              : FontAwesomeIcons.infinity,
                          color: const Color(0xFFF3A522),
                          size: 10,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.enableToolTimer
                              ? _formatTime(_remainingSeconds)
                              : 'ILIMITADO',
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFFF3A522),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PAINTER 1: MOSTRADOR DA BÚSSOLA (GIRA JUNTO COM O TELEFONE)
// =============================================================================
class _RotatingCompassDialPainter extends CustomPainter {
  const _RotatingCompassDialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Anéis Concêntricos Metálicos
    final ringPaint = Paint()
      ..color = const Color(0xFF8C7335).withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius * 0.94, ringPaint);
    canvas.drawCircle(center, radius * 0.72, ringPaint);
    canvas.drawCircle(center, radius * 0.38, ringPaint);

    // Eixos da Rosa dos Ventos
    final axisPaint = Paint()
      ..color = const Color(0xFF8C7335).withValues(alpha: 0.20)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, radius * 0.12), Offset(center.dx, size.height - radius * 0.12), axisPaint);
    canvas.drawLine(Offset(radius * 0.12, center.dy), Offset(size.width - radius * 0.12, center.dy), axisPaint);

    // Graduação de graus a cada 30°
    final tickPaint = Paint()
      ..color = const Color(0xFFF3A522).withValues(alpha: 0.45)
      ..strokeWidth = 1.4;

    for (int deg = 0; deg < 360; deg += 30) {
      final rad = deg * math.pi / 180;
      final outerX = center.dx + radius * 0.92 * math.cos(rad);
      final outerY = center.dy + radius * 0.92 * math.sin(rad);
      final innerX = center.dx + radius * 0.82 * math.cos(rad);
      final innerY = center.dy + radius * 0.82 * math.sin(rad);
      canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);
    }

    // Marcações Cardinais (N no topo do disco)
    _drawCardinal(canvas, center, 'N', -90, radius * 0.76, const Color(0xFFF3A522), true);
    _drawCardinal(canvas, center, 'L', 0, radius * 0.76, Colors.white70, false);
    _drawCardinal(canvas, center, 'S', 90, radius * 0.76, Colors.white70, false);
    _drawCardinal(canvas, center, 'O', 180, radius * 0.76, Colors.white70, false);
  }

  void _drawCardinal(Canvas canvas, Offset center, String text, double angleDeg,
      double dist, Color color, bool isNorth) {
    final rad = angleDeg * math.pi / 180;
    final x = center.dx + dist * math.cos(rad);
    final y = center.dy + dist * math.sin(rad);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.cinzel(
          color: color,
          fontSize: isNorth ? 12 : 9.5,
          fontWeight: isNorth ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// PAINTER 2: AGULHA RELÍQUIA / VETOR EM DIREÇÃO AO ALVO
// =============================================================================
class _TargetRelicNeedlePainter extends CustomPainter {
  final double relativeAngleRad;
  final bool isLockedOn;
  final double pulseValue;

  _TargetRelicNeedlePainter({
    required this.relativeAngleRad,
    required this.isLockedOn,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(relativeAngleRad);

    // Gema da Relíquia na ponta do indicador
    final targetY = -radius * 0.70;

    if (isLockedOn) {
      final auraPaint = Paint()
        ..color = const Color(0xFFF3A522).withValues(alpha: 0.4 * (1.0 - pulseValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(0, targetY), 12 + 8 * pulseValue, auraPaint);
    }

    final glowPaint = Paint()
      ..color = const Color(0xFFF3A522).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(0, targetY), 9, glowPaint);

    final gemPaint = Paint()..color = const Color(0xFFF3A522);
    canvas.drawCircle(Offset(0, targetY), 6, gemPaint);

    final gemCore = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(0, targetY), 2.2, gemCore);

    // Agulha Sagrada Dourada apontando para a relíquia
    final needlePath = Path()
      ..moveTo(0, targetY + 8)
      ..lineTo(radius * 0.07, 0)
      ..lineTo(0, radius * 0.25)
      ..lineTo(-radius * 0.07, 0)
      ..close();

    final needlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFA726), Color(0xFFD48B10)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-10, targetY, 20, -targetY + radius * 0.25));

    canvas.drawPath(needlePath, needlePaint);

    // Eixo Central de Latão
    final pivotOuter = Paint()..color = const Color(0xFF8C7335);
    canvas.drawCircle(Offset.zero, 8, pivotOuter);

    final pivotCore = Paint()..color = isLockedOn ? const Color(0xFFF3A522) : const Color(0xFF00D2B4);
    canvas.drawCircle(Offset.zero, 4, pivotCore);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TargetRelicNeedlePainter oldDelegate) {
    return oldDelegate.relativeAngleRad != relativeAngleRad ||
        oldDelegate.isLockedOn != isLockedOn ||
        oldDelegate.pulseValue != pulseValue;
  }
}
