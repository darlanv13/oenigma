import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/services/decoy_location_service.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Ferramenta Mística de Radar: Sonar de varredura 360° com detecção de proximidade,
/// eco luminoso de até 5 alvos (1 real + 4 decoys em raio 300m) e contagem ativa de 15min.
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
  bool _isManualPinging = false;
  DateTime? _lastHapticTime;
  int _selectedTargetIndex = 0;

  // Cache de distâncias e bearings por alvo
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

    // 1. Feixe de Varredura Contínuo (360° em 3 segundos)
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // 2. Pulso Sonar Expansivo (1.8s)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Listener para feedback háptico quando o feixe passa por qualquer sinal
    _sweepController.addListener(_checkSweepIntersection);

    _initSensors();
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

      if (diff < 14.0 || diff > 346.0) {
        final now = DateTime.now();
        if (_lastHapticTime == null ||
            now.difference(_lastHapticTime!).inMilliseconds > 750) {
          _lastHapticTime = now;
          HapticFeedback.selectionClick();
        }
        break;
      }
    }
  }

  Future<void> _initSensors() async {
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.always ||
          hasPermission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          setState(() {
            _currentPosition = pos;
            _updateCalculations();
          });
        }

        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        ).listen((pos) {
          if (mounted) {
            setState(() {
              _currentPosition = pos;
              _updateCalculations();
            });
          }
        });
      }
    } catch (_) {}

    // Bússola para radar orientado à direção do explorador
    try {
      _compassSubscription = FlutterCompass.events?.listen((event) {
        if (mounted && event.heading != null) {
          setState(() {
            _deviceHeading = event.heading!;
          });
        }
      });
    } catch (_) {}
  }

  void _updateCalculations() {
    if (_currentPosition == null) return;

    final targets = _effectiveTargets;
    for (int i = 0; i < targets.length; i++) {
      final target = targets[i];
      final dist = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        target.latitude,
        target.longitude,
      );

      final bearing = Geolocator.bearingBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        target.latitude,
        target.longitude,
      );

      _targetDistances[i] = dist;
      _targetBearings[i] = (bearing + 360.0) % 360.0;
    }
  }

  void _triggerManualPing() {
    SoundService.playScan();
    HapticFeedback.mediumImpact();
    setState(() {
      _isManualPinging = true;
    });

    _pulseController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isManualPinging = false;
        });
        _pulseController.repeat();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _sweepController.removeListener(_checkSweepIntersection);
    _sweepController.dispose();
    _pulseController.dispose();
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.isCompact;
    final double radarSize = isCompact ? 220.0 : 300.0;
    final targets = _effectiveTargets;

    final selectedDist = _targetDistances[_selectedTargetIndex] ?? widget.initialDistance;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F171B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Barra de Telemetria Superior (Status, Timer Ativo de 15min e Sinal)
          _buildRadarHeader(selectedDist),

          const SizedBox(height: 10),

          // Seletor de Sinais Detectados (5 Alvos no Raio de 300m)
          if (targets.length > 1) _buildTargetSelector(),

          const SizedBox(height: 10),

          // 2. Visor Circular do Radar
          Center(
            child: SizedBox(
              width: radarSize,
              height: radarSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Grade e Anéis Concêntricos
                  CustomPaint(
                    size: Size(radarSize, radarSize),
                    painter: _RadarGridPainter(
                      rangeMeters: _selectedRange,
                      gridColor: AppColors.verdeVale.withValues(alpha: 0.22),
                      accentColor: AppColors.verdeVale,
                    ),
                  ),

                  // Pulso Sonar Expansivo
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final val = _pulseController.value;
                      return Container(
                        width: radarSize * val,
                        height: radarSize * val,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.verdeVale.withValues(
                              alpha: (1.0 - val) * 0.45,
                            ),
                            width: 1.5,
                          ),
                        ),
                      );
                    },
                  ),

                  // Feixe de Varredura 360° Rotativo
                  AnimatedBuilder(
                    animation: _sweepController,
                    builder: (context, child) {
                      final angle = _sweepController.value * 2 * math.pi;
                      return Transform.rotate(
                        angle: angle,
                        child: Container(
                          width: radarSize,
                          height: radarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              startAngle: 0.0,
                              endAngle: math.pi / 2,
                              colors: [
                                AppColors.verdeVale.withValues(alpha: 0.40),
                                AppColors.verdeVale.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Blips / Ecos de todos os alvos detectados (1 Real + 4 Decoys)
                  for (int i = 0; i < targets.length; i++)
                    _buildTargetBlip(radarSize, i),

                  // Centro do Explorador (Você está aqui)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.verdeVale,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.verdeVale.withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.navigation,
                        color: Colors.black,
                        size: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Controles Inferiores: Seletor de Escala & Botão de Pulso Sonar
          _buildRadarControls(),
        ],
      ),
    );
  }

  // --- SELETOR DOS 5 SINAIS DETECTADOS ---
  Widget _buildTargetSelector() {
    final targets = _effectiveTargets;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(targets.length, (idx) {
          final isSelected = _selectedTargetIndex == idx;
          final dist = _targetDistances[idx];
          final distLabel = dist != null ? '${dist.toInt()}m' : '---';

          return GestureDetector(
            onTap: () {
              SoundService.playClick();
              setState(() {
                _selectedTargetIndex = idx;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.amareloVale.withValues(alpha: 0.20)
                    : const Color(0xFF131D24),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.amareloVale
                      : Colors.white.withValues(alpha: 0.12),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.signal,
                    size: 9,
                    color: isSelected ? AppColors.amareloVale : AppColors.cinzaMedio,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sinal ${idx + 1} ($distLabel)',
                    style: GoogleFonts.cinzel(
                      fontSize: 9.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.amareloVale : AppColors.cinzaMedio,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- CABEÇALHO DO RADAR COM TIMER ATIVO (15 MIN) E NÍVEL DE SINAL ---
  Widget _buildRadarHeader(double? dist) {
    int signalBars = 1;
    String statusText = 'BUSCANDO ECO MÍSTICO...';
    Color signalColor = AppColors.cinzaMedio;

    if (dist != null) {
      if (dist <= 25) {
        signalBars = 5;
        statusText = 'ALVO LOCALIZADO! (<25m)';
        signalColor = AppColors.verdeVale;
      } else if (dist <= 60) {
        signalBars = 4;
        statusText = 'SINAL INTENSO (${dist.toInt()}m)';
        signalColor = AppColors.verdeVale;
      } else if (dist <= 150) {
        signalBars = 3;
        statusText = 'SINAL EM PROXIMIDADE (${dist.toInt()}m)';
        signalColor = AppColors.amareloVale;
      } else if (dist <= 300) {
        signalBars = 2;
        statusText = 'ECO FRACO (${dist.toInt()}m)';
        signalColor = AppColors.amareloValeAlt;
      } else {
        signalBars = 1;
        statusText = 'FORA DE ALCANCE (${dist.toInt()}m)';
        signalColor = AppColors.cinzaMedio;
      }
    }

    final isLowTime = widget.remainingSeconds < 120;

    return Row(
      children: [
        FaIcon(FontAwesomeIcons.satelliteDish, color: signalColor, size: 13),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'RADAR DE RELÍQUIAS',
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge do Timer Ativo de 15 Minutos (Pausa quando fecha)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isLowTime ? Colors.redAccent : AppColors.amareloVale)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (isLowTime ? Colors.redAccent : AppColors.amareloVale)
                            .withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.stopwatch,
                          size: 8,
                          color: isLowTime ? Colors.redAccent : AppColors.amareloVale,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatTime(widget.remainingSeconds),
                          style: GoogleFonts.spaceMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isLowTime ? Colors.redAccent : AppColors.amareloVale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: GoogleFonts.poppins(
                  color: signalColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Barras de Força de Sinal
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (index) {
            final active = index < signalBars;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.5,
              height: 6.0 + (index * 3.0),
              decoration: BoxDecoration(
                color: active ? signalColor : Colors.white12,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        ),
        if (widget.isCompact && widget.onExpand != null) ...[
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const FaIcon(
              FontAwesomeIcons.upRightAndDownLeftFromCenter,
              color: AppColors.cinzaMedio,
              size: 11,
            ),
            tooltip: 'Expandir Radar',
            onPressed: widget.onExpand,
          ),
        ],
      ],
    );
  }

  // --- BLIP DO ALVO NO RADAR ---
  Widget _buildTargetBlip(double radarSize, int targetIndex) {
    final dist = _targetDistances[targetIndex];
    final bearing = _targetBearings[targetIndex];
    if (dist == null || bearing == null) return const SizedBox.shrink();

    final isSelected = _selectedTargetIndex == targetIndex;

    // Ângulo relativo entre a orientação do telefone e o azimute da relíquia
    final relativeAngleRad =
        ((bearing - _deviceHeading - 90.0) * math.pi) / 180.0;

    // Distância proporcional dentro do raio de visualização
    final radius = radarSize / 2.0;
    final clampedDist = dist.clamp(0.0, _selectedRange);
    final ratio = (clampedDist / _selectedRange) * 0.85;
    final blipRadius = radius * ratio;

    final dx = radius + blipRadius * math.cos(relativeAngleRad);
    final dy = radius + blipRadius * math.sin(relativeAngleRad);

    final isInsideScope = dist <= _selectedRange;

    return Positioned(
      left: dx - (isSelected ? 9 : 7),
      top: dy - (isSelected ? 9 : 7),
      child: AnimatedBuilder(
        animation: _sweepController,
        builder: (context, child) {
          final relativeDeg = (bearing - _deviceHeading + 360.0) % 360.0;
          final sweepDeg = _sweepController.value * 360.0;
          final diff = (sweepDeg - relativeDeg).abs();
          final isHighlighted = diff < 22.0 || diff > 338.0;

          final Color blipColor = isHighlighted
              ? AppColors.amareloVale
              : (isSelected
                  ? AppColors.amareloVale
                  : (isInsideScope ? AppColors.verdeVale : Colors.redAccent.withValues(alpha: 0.6)));

          return Container(
            width: isSelected ? 18 : 14,
            height: isSelected ? 18 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blipColor,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 1.2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: blipColor.withValues(alpha: isHighlighted ? 0.95 : 0.6),
                  blurRadius: isHighlighted ? 12 : 6,
                  spreadRadius: isHighlighted ? 3 : 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${targetIndex + 1}',
                style: GoogleFonts.cinzel(
                  color: Colors.black,
                  fontSize: isSelected ? 9 : 7.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- CONTROLES DE ZOOM E PULSO SONAR ---
  Widget _buildRadarControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Seletor de Escala (100m, 250m, 500m)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [100.0, 250.0, 500.0].map((range) {
            final isSelected = _selectedRange == range;
            return GestureDetector(
              onTap: () {
                SoundService.playClick();
                setState(() {
                  _selectedRange = range;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.verdeVale.withValues(alpha: 0.20)
                      : const Color(0xFF131D24),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.verdeVale
                        : Colors.white.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  '${range.toInt()}m',
                  style: GoogleFonts.poppins(
                    color: isSelected ? AppColors.verdeVale : AppColors.cinzaMedio,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Botão de Disparo Manual de Sonar (Ping)
        InkWell(
          onTap: _isManualPinging ? null : _triggerManualPing,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.verdeVale.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  FontAwesomeIcons.waveSquare,
                  color: AppColors.verdeVale,
                  size: 10,
                ),
                const SizedBox(width: 6),
                Text(
                  'PULSAR SONAR',
                  style: GoogleFonts.cinzel(
                    color: AppColors.verdeVale,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Pintor customizado para os anéis de alcance e retículo tático do Radar
class _RadarGridPainter extends CustomPainter {
  final double rangeMeters;
  final Color gridColor;
  final Color accentColor;

  _RadarGridPainter({
    required this.rangeMeters,
    required this.gridColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Borda Externa Metálica
    canvas.drawCircle(center, maxRadius, borderPaint);

    // 4 Círculos de Alcance Concêntricos
    for (int i = 1; i <= 4; i++) {
      final r = maxRadius * (i / 4.0);
      canvas.drawCircle(center, r, gridPaint);
    }

    // Linhas em Cruz (Eixos N-S e L-O)
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      gridPaint,
    );

    // Eixos Diagonais Pontilhados (45° e 135°)
    final diagPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final cos45 = math.cos(math.pi / 4) * maxRadius;
    final sin45 = math.sin(math.pi / 4) * maxRadius;

    canvas.drawLine(
      Offset(center.dx - cos45, center.dy - sin45),
      Offset(center.dx + cos45, center.dy + sin45),
      diagPaint,
    );
    canvas.drawLine(
      Offset(center.dx - cos45, center.dy + sin45),
      Offset(center.dx + cos45, center.dy - sin45),
      diagPaint,
    );

    // Rótulos Cardeais (N, S, L, O)
    _drawCardinalText(canvas, 'N', Offset(center.dx, 6));
    _drawCardinalText(canvas, 'S', Offset(center.dx, size.height - 14));
    _drawCardinalText(canvas, 'L', Offset(size.width - 10, center.dy - 5));
    _drawCardinalText(canvas, 'O', Offset(4, center.dy - 5));
  }

  void _drawCardinalText(Canvas canvas, String text, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.cinzel(
          color: accentColor.withValues(alpha: 0.7),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarGridPainter oldDelegate) {
    return oldDelegate.rangeMeters != rangeMeters ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.accentColor != accentColor;
  }
}
