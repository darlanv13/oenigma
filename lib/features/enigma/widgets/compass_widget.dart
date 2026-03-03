import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class CompassWidget extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;
  final double maxRadarDistance; // Distância máxima que o radar deteta (em metros)

  const CompassWidget({
    super.key,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.maxRadarDistance = 500.0, // Padrão: 500 metros
  });

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget> with SingleTickerProviderStateMixin {
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _positionSubscription;

  double? _currentHeading;
  Position? _currentPosition;
  double _distanceToTarget = 0.0;

  // Controlador para o efeito de "piscar" do ponto amarelo
  late AnimationController _pulseController;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _startSensors();

    // Animação para fazer o ponto amarelo piscar como no anime
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  Future<void> _startSensors() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    if (mounted) {
      setState(() {
        _hasPermissions = true;
      });
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
        if (mounted) {
          setState(() {
            _currentHeading = event.heading;
          });
        }
      });

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Atualiza a cada metro
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _distanceToTarget = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              widget.destinationLatitude,
              widget.destinationLongitude,
            );
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _positionSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Permissão de localização necessária para o radar.',
            style: TextStyle(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_currentHeading == null || _currentPosition == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.greenAccent),
            SizedBox(height: 16),
            Text('A sintonizar frequências...', style: TextStyle(color: Colors.greenAccent)),
          ],
        ),
      );
    }

    // 1. Cálculo do Ângulo
    final double bearing = Geolocator.bearingBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.destinationLatitude,
      widget.destinationLongitude,
    );
    double direction = bearing - _currentHeading!;
    final double directionInRadians = direction * (math.pi / 180);

    // 2. Cálculo da Distância (Para o ponto amarelo aproximar-se do centro)
    // O raio do radar visual é de cerca de 130 pixels (num contentor de 300x300)
    const double maxVisualRadius = 130.0;

    // Se estiver mais longe que a distância máxima, prende o ponto na borda
    double distanceScale = (_distanceToTarget / widget.maxRadarDistance).clamp(0.0, 1.0);
    double visualDistanceFromCenter = distanceScale * maxVisualRadius;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A Carcaça do Radar (Metálica)
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300, // Borda metálica
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 15, spreadRadius: 5, offset: Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            // O Ecrã Verde do Radar
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F380F), // Verde clássico do GameBoy/Radar
                border: Border.all(color: Colors.black, width: 4),
              ),
              child: ClipOval(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // A Grelha Quadriculada (Desenhada com CustomPaint)
                    CustomPaint(
                      size: const Size(300, 300),
                      painter: RadarGridPainter(),
                    ),

                    // O PONTO DO TESOURO (BOLA DE CRISTAL)
                    Transform.rotate(
                      angle: directionInRadians,
                      child: Transform.translate(
                        // Move o ponto para cima (negativo no eixo Y) consoante a distância
                        offset: Offset(0, -visualDistanceFromCenter),
                        child: FadeTransition(
                          opacity: _pulseController,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.yellowAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellowAccent.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // O JOGADOR (Triângulo Vermelho no Centro)
                    const Icon(
                      Icons.navigation, // Um ícone que parece um triângulo
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Painel de Distância Digital
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              const Text('ALVO DETETADO', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(
                '${_distanceToTarget.toStringAsFixed(1)} m',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier', // Fonte com aspeto digital
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==============================================================
// PINTOR DA GRELHA (Desenha as linhas verdes ao estilo Dragon Ball)
// ==============================================================
class RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF306230).withValues(alpha: 0.6) // Verde claro para as linhas
      ..strokeWidth = 1.5;

    final centerPaint = Paint()
      ..color = const Color(0xFF8BAC0F).withValues(alpha: 0.8) // Linha central mais forte
      ..strokeWidth = 2.0;

    const double step = 25.0; // Espaçamento entre as linhas da grelha

    // Desenha as linhas verticais e horizontais
    for (double i = 0; i <= size.width; i += step) {
      // Desenha as linhas horizontais
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
      // Desenha as linhas verticais
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Desenha a cruz central mais forte
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), centerPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
