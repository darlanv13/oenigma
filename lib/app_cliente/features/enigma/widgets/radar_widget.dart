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

/// Radar Sonar 360°: Varredura contínua de eco com detecção de proximidade.
/// Foco visual no instrumento, sem poluição de texto e com timer no canto inferior direito.
class RadarWidget extends StatefulWidget {
  final double? targetLatitude;
  final double? targetLongitude;
  final double? initialDistance;
  final bool isCompact;
  final VoidCallback? onExpand;
  final List<DecoyTarget>? targets;
  final int remainingSeconds;
  final VoidCallback? onTimeUp;
  final Function(int)? onTick;
  final bool enableToolTimer;

  const RadarWidget({
    super.key,
    this.targetLatitude,
    this.targetLongitude,
    this.initialDistance,
    this.isCompact = true,
    this.onExpand,
    this.targets,
    this.remainingSeconds = 900,
    this.onTimeUp,
    this.onTick,
    this.enableToolTimer = true,
  });

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget>
    with TickerProviderStateMixin {
  late final AnimationController _sweepController;
  late final AnimationController _pulseController;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  Position? _currentPosition;
  double _deviceHeading = 0.0;
  double _selectedRange = 250.0; // Metros (100m, 250m, 500m)
  int _selectedTargetIndex = 0;
  DateTime? _lastHapticTime;

  late int _remainingSeconds;
  Timer? _countdownTimer;

  final Map<int, double> _targetDistances = {};
  final Map<int, double> _targetBearings = {};

  List<DecoyTarget> get _effectiveTargets {
    if (widget.targets != null && widget.targets!.isNotEmpty) {
      return widget.targets!;
    }
    if (widget.targetLatitude != null && widget.targetLongitude != null) {
      return [
        DecoyTarget(
          index: 1,
          label: 'Sinal 1',
          latitude: widget.targetLatitude!,
          longitude: widget.targetLongitude!,
          isReal: true,
        ),
      ];
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.remainingSeconds;

    // 1. Feixe de Varredura Sonar (360° em 3 segundos)
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // 2. Pulso de Eco Expansivo (1.8s)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _sweepController.addListener(_checkSweepIntersection);

    _initSensorsFast();
    _startTimer();
  }

  void _startTimer() {
    if (!widget.enableToolTimer || _remainingSeconds <= 0) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        widget.onTick?.call(_remainingSeconds);
        if (_remainingSeconds <= 0) {
          timer.cancel();
          widget.onTimeUp?.call();
        }
      });
    });
  }

  /// Inicialização instantânea não bloqueante
  Future<void> _initSensorsFast() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() {
          _currentPosition = lastKnown;
          _recalculateTargetPositions(lastKnown);
        });
      }
    } catch (_) {}

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
            distanceFilter: kIsWeb ? 0 : 2,
          ),
        ).listen(
          (pos) {
            if (mounted) {
              setState(() {
                _currentPosition = pos;
                _recalculateTargetPositions(pos);
              });
            }
          },
          onError: (_) {},
        );

        _compassSubscription?.cancel();
        if (FlutterCompass.events != null) {
          _compassSubscription = FlutterCompass.events!.listen(
            (event) {
              if (mounted && event.heading != null) {
                setState(() => _deviceHeading = event.heading!);
              }
            },
            onError: (_) {},
          );
        }
      }
    } catch (_) {}
  }

  void _recalculateTargetPositions(Position pos) {
    final targets = _effectiveTargets;
    for (int i = 0; i < targets.length; i++) {
      final t = targets[i];
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        t.latitude,
        t.longitude,
      );
      final b = Geolocator.bearingBetween(
        pos.latitude,
        pos.longitude,
        t.latitude,
        t.longitude,
      );
      _targetDistances[i] = d;
      _targetBearings[i] = b;
    }
  }

  void _checkSweepIntersection() {
    final targets = _effectiveTargets;
    if (targets.isEmpty || _currentPosition == null) return;

    final sweepAngleDeg = _sweepController.value * 360.0;

    for (int i = 0; i < targets.length; i++) {
      final bearing = _targetBearings[i];
      if (bearing == null) continue;

      final relativeTargetAngle = (bearing - _deviceHeading + 360.0) % 360.0;
      final diff = (sweepAngleDeg - relativeTargetAngle).abs();

      if (diff < 12.0 || diff > 348.0) {
        final now = DateTime.now();
        if (_lastHapticTime == null ||
            now.difference(_lastHapticTime!).inMilliseconds > 450) {
          _lastHapticTime = now;
          if (i == _selectedTargetIndex) {
            HapticFeedback.lightImpact();
            SoundService.playClick();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _sweepController.dispose();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final targets = _effectiveTargets;
    if (_selectedTargetIndex >= targets.length) {
      _selectedTargetIndex = 0;
    }

    final currentTargetDistance = _targetDistances[_selectedTargetIndex] ??
        widget.initialDistance ??
        140.0;

    final double frameHeight = widget.isCompact ? 390.0 : 540.0;
    final double radarSize = widget.isCompact ? 220.0 : 300.0;

    return Container(
      height: frameHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
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
                          color: const Color(0xFF0C242C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF007D8A).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.satelliteDish,
                          color: Color(0xFF00A4B4),
                          size: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RADAR SONAR 360°',
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

              // 2. SELETOR DE ALVOS (Se houver múltiplos)
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
                              color: isSel ? const Color(0xFF00A4B4) : const Color(0xFF0C1417),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF00A4B4)
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

              // 3. DISPLAY DO SONAR (HERO PRINCIPAL)
              Expanded(
                child: Center(
                  child: Container(
                    width: radarSize,
                    height: radarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0A1215),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A4B4).withValues(alpha: 0.25),
                          blurRadius: 18,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF007D8A).withValues(alpha: 0.6),
                        width: 2.2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Grade estática do radar (60fps)
                        RepaintBoundary(
                          child: CustomPaint(
                            size: Size(radarSize, radarSize),
                            painter: const _RadarStaticGridPainter(),
                          ),
                        ),

                        // Feixe dinâmico e ecos dos alvos
                        AnimatedBuilder(
                          animation: _sweepController,
                          builder: (context, _) {
                            return CustomPaint(
                              size: Size(radarSize, radarSize),
                              painter: _RadarDynamicSweepPainter(
                                sweepValue: _sweepController.value,
                                pulseValue: _pulseController.value,
                                selectedRange: _selectedRange,
                                targets: targets,
                                targetDistances: _targetDistances,
                                targetBearings: _targetBearings,
                                deviceHeading: _deviceHeading,
                                selectedIndex: _selectedTargetIndex,
                              ),
                            );
                          },
                        ),

                        // Centro do Operador
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00A4B4),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF00A4B4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. BARRA INFERIOR (Distância na Esquerda, Alcance no Centro, TIMER NO CANTO DIREITO)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Canto Esquerdo: Distância até o alvo
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.bullseye,
                        color: Color(0xFF00A4B4),
                        size: 12,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${currentTargetDistance.toInt()} M',
                        style: GoogleFonts.orbitron(
                          color: const Color(0xFF00A4B4),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // Centro: Seletor de Alcance Rápido (100m, 250m, 500m)
                  Row(
                    children: [100.0, 250.0, 500.0].map((range) {
                      final isSel = _selectedRange == range;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedRange = range);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF007D8A).withValues(alpha: 0.55)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSel ? const Color(0xFF00A4B4) : Colors.white12,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${range.toInt()}m',
                              style: GoogleFonts.orbitron(
                                fontSize: 9.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : AppColors.cinzaMedio,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
// PAINTER 1: GRADE ESTÁTICA DO RADAR
// =============================================================================
class _RadarStaticGridPainter extends CustomPainter {
  const _RadarStaticGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Fundo Ciano/Preto
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF0D1E22), Color(0xFF050B0D)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // 4 Anéis Concêntricos
    final ringPaint = Paint()
      ..color = const Color(0xFF007D8A).withValues(alpha: 0.28)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius * 0.25, ringPaint);
    canvas.drawCircle(center, radius * 0.50, ringPaint);
    canvas.drawCircle(center, radius * 0.75, ringPaint);
    canvas.drawCircle(center, radius * 0.95, ringPaint);

    // Eixos em Cruz Graduados
    final axisPaint = Paint()
      ..color = const Color(0xFF007D8A).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, 4), Offset(center.dx, size.height - 4), axisPaint);
    canvas.drawLine(Offset(4, center.dy), Offset(size.width - 4, center.dy), axisPaint);

    // Pontos Cardinais em Cinzel
    _drawLabel(canvas, 'N', Offset(center.dx, 10), const Color(0xFF00A4B4));
    _drawLabel(canvas, 'L', Offset(size.width - 12, center.dy), Colors.white54);
    _drawLabel(canvas, 'S', Offset(center.dx, size.height - 12), Colors.white54);
    _drawLabel(canvas, 'O', Offset(12, center.dy), Colors.white54);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.cinzel(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// PAINTER 2: FEIXE DINÂMICO E ECOS DOS ALVOS
// =============================================================================
class _RadarDynamicSweepPainter extends CustomPainter {
  final double sweepValue;
  final double pulseValue;
  final double selectedRange;
  final List<DecoyTarget> targets;
  final Map<int, double> targetDistances;
  final Map<int, double> targetBearings;
  final double deviceHeading;
  final int selectedIndex;

  _RadarDynamicSweepPainter({
    required this.sweepValue,
    required this.pulseValue,
    required this.selectedRange,
    required this.targets,
    required this.targetDistances,
    required this.targetBearings,
    required this.deviceHeading,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngleRad = sweepValue * 2 * math.pi;

    // 1. Feixe de Varredura com Rastro Gradiente
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00A4B4).withValues(alpha: 0.05),
          const Color(0xFF00A4B4).withValues(alpha: 0.40),
        ],
        stops: const [0.0, 0.75, 1.0],
        transform: GradientRotation(sweepAngleRad - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.95),
      0,
      2 * math.pi,
      true,
      sweepPaint,
    );

    // Linha frontal do feixe
    final sweepFrontX = center.dx + radius * 0.95 * math.cos(sweepAngleRad - math.pi / 2);
    final sweepFrontY = center.dy + radius * 0.95 * math.sin(sweepAngleRad - math.pi / 2);
    final linePaint = Paint()
      ..color = const Color(0xFF00D2B4)
      ..strokeWidth = 1.5;
    canvas.drawLine(center, Offset(sweepFrontX, sweepFrontY), linePaint);

    // 2. Renderização dos Ecos dos Alvos (Blips)
    for (int i = 0; i < targets.length; i++) {
      final dist = targetDistances[i] ?? 120.0;
      final bearing = targetBearings[i] ?? 0.0;

      final relativeAngle = (bearing - deviceHeading) * math.pi / 180.0;
      final normDist = math.min(1.0, dist / selectedRange);
      final blipRadius = normDist * (radius * 0.88);

      final blipX = center.dx + blipRadius * math.cos(relativeAngle - math.pi / 2);
      final blipY = center.dy + blipRadius * math.sin(relativeAngle - math.pi / 2);
      final blipOffset = Offset(blipX, blipY);

      final isSelected = i == selectedIndex;
      final blipColor = isSelected ? const Color(0xFFF3A522) : const Color(0xFF00A4B4);

      // Pulso luminoso do alvo
      if (isSelected) {
        final ripplePaint = Paint()
          ..color = blipColor.withValues(alpha: 0.4 * (1.0 - pulseValue))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(blipOffset, 6 + 10 * pulseValue, ripplePaint);
      }

      // Ponto do alvo
      final dotPaint = Paint()..color = blipColor;
      canvas.drawCircle(blipOffset, isSelected ? 5.5 : 4.0, dotPaint);

      final corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(blipOffset, 2.0, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarDynamicSweepPainter oldDelegate) {
    return oldDelegate.sweepValue != sweepValue ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.selectedRange != selectedRange ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.deviceHeading != deviceHeading;
  }
}
