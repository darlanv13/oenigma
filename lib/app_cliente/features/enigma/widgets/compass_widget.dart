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

/// Bússola Dourada do Explorador: Relíquia em latão e obsidiana de alta performance.
/// Otimizada para carregamento instantâneo no Web, Android e iOS.
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
  late final AnimationController _animController;

  double _currentHeading = 0.0;
  double _manualHeadingOffset = 0.0;
  bool _hasCompassSensor = true;
  Position? _currentPosition;
  bool _hasPermissions = true;
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

    // Controlador para o pulso suave da bússola
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _initSensorsFast();
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

  /// Inicialização ultra-rápida não bloqueante de geolocalização e sensores
  Future<void> _initSensorsFast() async {
    // 1. Tenta recuperar a última posição conhecida em milissegundos
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() => _currentPosition = lastKnown);
      }
    } catch (_) {}

    // 2. Verifica permissão de forma assíncrona
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final hasPerm = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (mounted) setState(() => _hasPermissions = hasPerm);

      if (hasPerm) {
        // Stream de posição contínuo
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

        // Stream de orientação da bússola
        _compassSubscription?.cancel();
        if (FlutterCompass.events != null) {
          _compassSubscription = FlutterCompass.events!.listen(
            (event) {
              if (mounted && event.heading != null) {
                setState(() {
                  _hasCompassSensor = true;
                  _currentHeading = event.heading!;
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
      }
    } catch (_) {
      if (mounted) setState(() => _hasPermissions = false);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _animController.dispose();
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
    if (normalized >= 337.5 || normalized < 22.5) return 'N (000°)';
    if (normalized >= 22.5 && normalized < 67.5) return 'NE (045°)';
    if (normalized >= 67.5 && normalized < 112.5) return 'L (090°)';
    if (normalized >= 112.5 && normalized < 157.5) return 'SE (135°)';
    if (normalized >= 157.5 && normalized < 202.5) return 'S (180°)';
    if (normalized >= 202.5 && normalized < 247.5) return 'SO (225°)';
    if (normalized >= 247.5 && normalized < 292.5) return 'O (270°)';
    return 'NO (315°)';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTargets = _effectiveTargets;
    if (_selectedTargetIndex >= effectiveTargets.length) {
      _selectedTargetIndex = 0;
    }
    final currentTarget = effectiveTargets[_selectedTargetIndex];

    // Cálculos de distância e azimute
    double distance = 150.0;
    double bearing = 0.0;

    if (_currentPosition != null) {
      distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        currentTarget.latitude,
        currentTarget.longitude,
      );
      bearing = Geolocator.bearingBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        currentTarget.latitude,
        currentTarget.longitude,
      );
    }

    final effectiveHeading = (_currentHeading + _manualHeadingOffset) % 360;
    final double targetAngle = (bearing - effectiveHeading) * (math.pi / 180);

    // Detecção de Lock-on (alinhamento em ±15°)
    double diffDegrees = (bearing - effectiveHeading) % 360;
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

    // Altura padrão unificada entre todas as ferramentas
    final double frameHeight = widget.isCompact ? 390.0 : 540.0;
    final double compassDialSize = widget.isCompact ? 210.0 : 280.0;

    return Container(
      height: frameHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLockedOn
              ? const Color(0xFFF3A522)
              : const Color(0xFF1E3A45),
          width: isLockedOn ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLockedOn ? const Color(0xFFF3A522) : Colors.black)
                .withValues(alpha: isLockedOn ? 0.25 : 0.4),
            blurRadius: isLockedOn ? 18 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Brilho dourado de fundo sutil
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLockedOn
                      ? const Color(0xFFF3A522).withValues(alpha: 0.12)
                      : const Color(0xFF007D8A).withValues(alpha: 0.08),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. HUD SUPERIOR UNIFICADO (Título + Timer + Botão Expandir)
                  _buildHeaderHud(isLockedOn),

                  // 2. SELETOR DE ALVOS (Sinais 1 a 5)
                  if (effectiveTargets.length > 1)
                    _buildTargetSelector(effectiveTargets, distance)
                  else
                    const SizedBox(height: 4),

                  // 3. MOSTRADOR CENTRAL DA BÚSSOLA (Interativo com suporte Web)
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          // Permite girar o mostrador manualmente no Web se não houver bússola
                          if (kIsWeb || !_hasCompassSensor) {
                            setState(() {
                              _manualHeadingOffset =
                                  (_manualHeadingOffset + details.delta.dx * 0.5) % 360;
                            });
                          }
                        },
                        child: Container(
                          width: compassDialSize,
                          height: compassDialSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0C1318),
                            boxShadow: [
                              BoxShadow(
                                color: (isLockedOn
                                        ? const Color(0xFFF3A522)
                                        : Colors.black)
                                    .withValues(alpha: isLockedOn ? 0.4 : 0.6),
                                blurRadius: isLockedOn ? 20 : 12,
                              ),
                            ],
                            border: Border.all(
                              color: isLockedOn
                                  ? const Color(0xFFF3A522)
                                  : const Color(0xFF8C7335).withValues(alpha: 0.7),
                              width: isLockedOn ? 3.5 : 2.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Mostrador estático de fundo (cacheado para 60fps no Web)
                              RepaintBoundary(
                                child: CustomPaint(
                                  size: Size(compassDialSize, compassDialSize),
                                  painter: const _AntiqueCompassDialPainter(),
                                ),
                              ),
                              // Agulha e indicador dinâmicos
                              AnimatedBuilder(
                                animation: _animController,
                                builder: (context, _) {
                                  return CustomPaint(
                                    size: Size(compassDialSize, compassDialSize),
                                    painter: _CompassNeedlePainter(
                                      targetAngle: targetAngle,
                                      distance: distance,
                                      isLockedOn: isLockedOn,
                                      pulseValue: _animController.value,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. TELEMETRIA INFERIOR UNIFICADA (Distância, Azimute, Lock-on)
                  _buildFooterTelemetry(distance, diffDegrees, isLockedOn),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER HUD
  // ===========================================================================
  Widget _buildHeaderHud(bool isLockedOn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Título do Instrumento
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
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),

        // Centro: Timer da Ferramenta
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1708),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF3A522).withValues(alpha: 0.4),
              width: 1,
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
                size: 9.5,
              ),
              const SizedBox(width: 5),
              Text(
                widget.enableToolTimer
                    ? _formatTime(_remainingSeconds)
                    : 'ILIMITADO',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFF3A522),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Botão Expandir no canto direito
        if (widget.onExpand != null)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              SoundService.playClick();
              widget.onExpand!();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const SizedBox(width: 4),
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
          )
        else
          const SizedBox(width: 20),
      ],
    );
  }

  // ===========================================================================
  // 2. SELETOR DE ALVOS (SINAIS 1 A 5)
  // ===========================================================================
  Widget _buildTargetSelector(List<DecoyTarget> targets, double currentDist) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.radio,
                      size: 8.5,
                      color: isSel ? Colors.black : const Color(0xFFF3A522),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sinal ${idx + 1}',
                      style: GoogleFonts.cinzel(
                        color: isSel ? Colors.black : Colors.white70,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // 4. FOOTER TELEMETRIA
  // ===========================================================================
  Widget _buildFooterTelemetry(double distance, double diffDegrees, bool isLockedOn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1417),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLockedOn
              ? const Color(0xFFF3A522)
              : const Color(0xFF1E3A45),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Distância em Orbitron
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.locationCrosshairs,
                color: isLockedOn ? const Color(0xFFF3A522) : const Color(0xFF00A4B4),
                size: 11,
              ),
              const SizedBox(width: 6),
              Text(
                '${distance.toInt()} M',
                style: GoogleFonts.orbitron(
                  color: isLockedOn ? const Color(0xFFF3A522) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // Status de Alinhamento
          Row(
            children: [
              FaIcon(
                isLockedOn
                    ? FontAwesomeIcons.bullseye
                    : (diffDegrees > 0
                        ? FontAwesomeIcons.arrowRight
                        : FontAwesomeIcons.arrowLeft),
                color: isLockedOn ? const Color(0xFFF3A522) : AppColors.cinzaMedio,
                size: 10,
              ),
              const SizedBox(width: 5),
              Text(
                isLockedOn
                    ? 'ALINHADO'
                    : (diffDegrees > 0
                        ? 'GIRE DIREITA (${diffDegrees.toInt()}°)'
                        : 'GIRE ESQUERDA (${(-diffDegrees).toInt()}°)'),
                style: GoogleFonts.cinzel(
                  color: isLockedOn ? const Color(0xFFF3A522) : Colors.white70,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Azimute Cardeal
          Text(
            _getCardinalDirection(_currentHeading + _manualHeadingOffset),
            style: GoogleFonts.orbitron(
              color: AppColors.cinzaMedio,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PAINTER 1: MOSTRADOR ESTÁTICO DE LATÃO DA EXPEDIÇÃO (CACHEADO)
// =============================================================================
class _AntiqueCompassDialPainter extends CustomPainter {
  const _AntiqueCompassDialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Fundo Gradiente Obsidiana
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF131D24), Color(0xFF080C0E)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // Anéis Concêntricos em Latão Envelhecido
    final ringPaint = Paint()
      ..color = const Color(0xFF8C7335).withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius * 0.94, ringPaint);
    canvas.drawCircle(center, radius * 0.72, ringPaint);
    canvas.drawCircle(center, radius * 0.40, ringPaint);

    // Eixos Cardinais Sutis
    final axisPaint = Paint()
      ..color = const Color(0xFF8C7335).withValues(alpha: 0.25)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, radius * 0.1), Offset(center.dx, size.height - radius * 0.1), axisPaint);
    canvas.drawLine(Offset(radius * 0.1, center.dy), Offset(size.width - radius * 0.1, center.dy), axisPaint);

    // Traços de Graus a cada 30°
    final tickPaint = Paint()
      ..color = const Color(0xFFF3A522).withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    for (int deg = 0; deg < 360; deg += 30) {
      final rad = deg * math.pi / 180;
      final outerX = center.dx + radius * 0.92 * math.cos(rad);
      final outerY = center.dy + radius * 0.92 * math.sin(rad);
      final innerX = center.dx + radius * 0.84 * math.cos(rad);
      final innerY = center.dy + radius * 0.84 * math.sin(rad);
      canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);
    }

    // Marcações Cardinais (N, L, S, O)
    _drawCardinal(canvas, center, 'N', 0, radius * 0.77, const Color(0xFFF3A522), true);
    _drawCardinal(canvas, center, 'L', 90, radius * 0.77, Colors.white70, false);
    _drawCardinal(canvas, center, 'S', 180, radius * 0.77, Colors.white70, false);
    _drawCardinal(canvas, center, 'O', 270, radius * 0.77, Colors.white70, false);
  }

  void _drawCardinal(Canvas canvas, Offset center, String text, double angleDeg,
      double dist, Color color, bool isNorth) {
    final rad = (angleDeg - 90) * math.pi / 180;
    final x = center.dx + dist * math.cos(rad);
    final y = center.dy + dist * math.sin(rad);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.cinzel(
          color: color,
          fontSize: isNorth ? 11 : 9,
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
// PAINTER 2: AGULHA DOURADA E ALVO DINÂMICO
// =============================================================================
class _CompassNeedlePainter extends CustomPainter {
  final double targetAngle;
  final double distance;
  final bool isLockedOn;
  final double pulseValue;

  _CompassNeedlePainter({
    required this.targetAngle,
    required this.distance,
    required this.isLockedOn,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Posição da Relíquia Sagrada
    const double maxRange = 350.0;
    final double displayRadius = distance > maxRange
        ? radius * 0.72
        : math.max(radius * 0.25, (distance / maxRange) * (radius * 0.70));

    final targetX = center.dx + displayRadius * math.cos(targetAngle - math.pi / 2);
    final targetY = center.dy + displayRadius * math.sin(targetAngle - math.pi / 2);
    final targetOffset = Offset(targetX, targetY);

    // Linha de Trava Mística
    if (isLockedOn) {
      final beamPaint = Paint()
        ..color = const Color(0xFFF3A522).withValues(alpha: 0.35 + 0.15 * math.sin(pulseValue * math.pi * 2))
        ..strokeWidth = 2.0;
      canvas.drawLine(center, targetOffset, beamPaint);

      final lockRingPaint = Paint()
        ..color = const Color(0xFFF3A522).withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(targetOffset, 14 + 3 * pulseValue, lockRingPaint);
    }

    // Gema da Relíquia
    final glowPaint = Paint()
      ..color = const Color(0xFFF3A522).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(targetOffset, 10, glowPaint);

    final gemPaint = Paint()..color = const Color(0xFFF3A522);
    canvas.drawCircle(targetOffset, 6, gemPaint);

    final gemCore = Paint()..color = Colors.white;
    canvas.drawCircle(targetOffset, 2.5, gemCore);

    // 2. Agulha Ornada de Navegação
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(targetAngle);

    // Ponta Norte (Dourada)
    final northPath = Path()
      ..moveTo(0, -radius * 0.65)
      ..lineTo(radius * 0.08, 0)
      ..lineTo(0, -radius * 0.10)
      ..close();

    final northPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-10, -radius * 0.65, 20, radius * 0.65));
    canvas.drawPath(northPath, northPaint);

    final northPathLeft = Path()
      ..moveTo(0, -radius * 0.65)
      ..lineTo(-radius * 0.08, 0)
      ..lineTo(0, -radius * 0.10)
      ..close();
    final northLeftPaint = Paint()..color = const Color(0xFFD48B10);
    canvas.drawPath(northPathLeft, northLeftPaint);

    // Ponta Sul (Aço Escuro)
    final southPath = Path()
      ..moveTo(0, radius * 0.45)
      ..lineTo(radius * 0.07, 0)
      ..lineTo(-radius * 0.07, 0)
      ..close();
    final southPaint = Paint()..color = const Color(0xFF324755);
    canvas.drawPath(southPath, southPaint);

    // Gema Central da Bússola
    final pivotOuter = Paint()..color = const Color(0xFF8C7335);
    canvas.drawCircle(Offset.zero, 8, pivotOuter);

    final pivotCore = Paint()..color = const Color(0xFFF3A522);
    canvas.drawCircle(Offset.zero, 4.5, pivotCore);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter oldDelegate) {
    return oldDelegate.targetAngle != targetAngle ||
        oldDelegate.distance != distance ||
        oldDelegate.isLockedOn != isLockedOn ||
        oldDelegate.pulseValue != pulseValue;
  }
}
