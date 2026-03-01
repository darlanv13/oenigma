import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class CompassWidget extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;

  const CompassWidget({
    super.key,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget> {
  Position? _currentPosition;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
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

    setState(() {
      _hasPermissions = true;
    });

    Geolocator.getPositionStream().listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  double _calculateBearing(Position currentPosition) {
    final lat1 = currentPosition.latitude * math.pi / 180;
    final lon1 = currentPosition.longitude * math.pi / 180;
    final lat2 = widget.destinationLatitude * math.pi / 180;
    final lon2 = widget.destinationLongitude * math.pi / 180;

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Permissão de localização necessária para a bússola.',
            style: TextStyle(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(color: primaryAmber),
        ),
      );
    }

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erro ao ler a bússola: \${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryAmber),
          );
        }

        double? direction = snapshot.data?.heading;

        if (direction == null) {
          return const Center(
            child: Text("Bússola não disponível no dispositivo."),
          );
        }

        final destinationBearing = _calculateBearing(_currentPosition!);
        // A direção que a seta deve apontar é a diferença entre o azimute do destino e o norte do dispositivo
        final arrowDirection = (destinationBearing - direction) * (math.pi / 180);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'N',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              Transform.rotate(
                angle: arrowDirection,
                child: const Icon(
                  Icons.navigation,
                  color: Colors.greenAccent,
                  size: 80,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Alvo',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
