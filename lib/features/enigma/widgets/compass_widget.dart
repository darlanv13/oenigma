import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

class CompassWidget extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;

  const CompassWidget({
    super.key,
    required this.targetLatitude,
    required this.targetLongitude,
    required double destinationLongitude,
    required double destinationLatitude,
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

  @override
  void initState() {
    super.initState();
    // Controlador da animação da "linha do radar" que fica girando
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initSensors();
  }

  Future<void> _initSensors() async {
    // Requisitar permissão de localização
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      setState(() => _hasPermissions = true);

      // Ouvir a localização atual do usuário
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      ).listen((Position position) {
        if (mounted) setState(() => _currentPosition = position);
      });

      // Ouvir a bússola do celular (para onde ele está apontando)
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions) {
      return const Center(
        child: Text(
          'Permissão de localização necessária para o Radar.',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF88C928)),
      );
    }

    // Calcula a distância e a direção (Bearing) até o alvo
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

    // Ajusta o ângulo do alvo com base na direção que o celular está apontando
    final double targetAngle = (bearing - _currentHeading) * (math.pi / 180);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A Carcaça Metálica do Radar
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(
              0xFFDCDCDC,
            ), // Cinza clássico da carcaça do Dragon Radar
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 4,
                offset: Offset(-2, -2),
              ), // Bezel highlight
            ],
            border: Border.all(color: const Color(0xFF8B8B8B), width: 8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            // O Visor do Radar
            child: ClipOval(
              child: AnimatedBuilder(
                animation: _scannerController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: DragonRadarPainter(
                      scannerAngle: _scannerController.value * 2 * math.pi,
                      targetAngle: targetAngle,
                      distance: distance,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Visor Digital de Distância
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF88C928), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0xFF88C928), blurRadius: 8),
            ],
          ),
          child: Text(
            '${distance.toStringAsFixed(0)} M',
            style: const TextStyle(
              color: Color(0xFF88C928),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier', // Fonte estilo digital
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// CUSTOM PAINTER - A Magia Gráfica do Radar do Dragão
// ---------------------------------------------------------
class DragonRadarPainter extends CustomPainter {
  final double scannerAngle;
  final double targetAngle;
  final double distance;

  DragonRadarPainter({
    required this.scannerAngle,
    required this.targetAngle,
    required this.distance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Fundo Verde do Radar
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF88C928), Color(0xFF426815)],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Grade Cibernética (Grid Lines)
    final gridPaint = Paint()
      ..color = const Color(0xFFB5E655).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const int lines = 6;
    final double step = size.width / lines;
    for (int i = 1; i < lines; i++) {
      // Linhas verticais
      canvas.drawLine(
        Offset(step * i, 0),
        Offset(step * i, size.height),
        gridPaint,
      );
      // Linhas horizontais
      canvas.drawLine(
        Offset(0, step * i),
        Offset(size.width, step * i),
        gridPaint,
      );
    }

    // Círculo central da grade
    canvas.drawCircle(center, radius * 0.3, gridPaint);
    canvas.drawCircle(center, radius * 0.7, gridPaint);

    // 3. A "Esfera do Dragão" (O Alvo Brilhante)
    // Limita o alcance visual máximo no radar para 500 metros
    const double maxRadarRange = 500.0;
    final double displayRadius = distance > maxRadarRange
        ? radius * 0.9
        : (distance / maxRadarRange) * radius;

    // Calcula as coordenadas X e Y usando trigonometria
    // Subtraímos pi/2 para que o ângulo 0 aponte para "Cima" (Frente do celular)
    final double targetX =
        center.dx + displayRadius * math.cos(targetAngle - math.pi / 2);
    final double targetY =
        center.dy + displayRadius * math.sin(targetAngle - math.pi / 2);
    final targetOffset = Offset(targetX, targetY);

    // O Efeito Neon da Esfera
    final glowPaint = Paint()
      ..color = Colors.orangeAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(targetOffset, 12, glowPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFFFD700); // Amarelo Dourado
    canvas.drawCircle(targetOffset, 8, dotPaint);

    // Pequeno centro vermelho (simulando a estrela)
    final starPaint = Paint()..color = Colors.red;
    canvas.drawCircle(targetOffset, 3, starPaint);

    // 4. Scanner de Varredura (Sweep Animation)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFB5E655).withValues(alpha: 0.1),
          const Color(0xFFE8FFB7).withValues(alpha: 0.6),
        ],
        stops: const [0.0, 0.8, 1.0],
        transform: GradientRotation(scannerAngle - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // Usar um path para garantir que a varredura não saia do círculo
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      true,
      sweepPaint,
    );

    // Linha forte do scanner
    final scannerLinePaint = Paint()
      ..color = const Color(0xFFE8FFB7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final lineEndX = center.dx + radius * math.cos(scannerAngle - math.pi / 2);
    final lineEndY = center.dy + radius * math.sin(scannerAngle - math.pi / 2);
    canvas.drawLine(center, Offset(lineEndX, lineEndY), scannerLinePaint);

    // 5. O Jogador (Triângulo Vermelho no Centro)
    final playerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - 12); // Ponta
    path.lineTo(center.dx - 8, center.dy + 8); // Esquerda
    path.lineTo(center.dx, center.dy + 4); // Fenda inferior
    path.lineTo(center.dx + 8, center.dy + 8); // Direita
    path.close();

    // Sombra do jogador
    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, playerPaint);
  }

  @override
  bool shouldRepaint(covariant DragonRadarPainter oldDelegate) {
    return oldDelegate.scannerAngle != scannerAngle ||
        oldDelegate.targetAngle != targetAngle ||
        oldDelegate.distance != distance;
  }
}
