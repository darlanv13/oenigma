import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:math' as math;

class MapRadiusWidget extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;

  const MapRadiusWidget({
    super.key,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  @override
  State<MapRadiusWidget> createState() => _MapRadiusWidgetState();
}

class _MapRadiusWidgetState extends State<MapRadiusWidget> {
  late LatLng _obfuscatedCenter;

  @override
  void initState() {
    super.initState();
    _obfuscatedCenter = _generateObfuscatedLocation(
      widget.destinationLatitude,
      widget.destinationLongitude,
      150.0, // Mova o centro em até 150 metros do ponto real
    );
  }

  // Gera um ponto aleatório perto do destino para ser o centro do círculo
  // Isso impede que o usuário apenas vá para o centro exato do círculo desenhado
  LatLng _generateObfuscatedLocation(double lat, double lng, double maxRadiusMeters) {
    final random = math.Random();

    // Converte o raio de metros para graus aproximados (1 grau ~ 111km)
    final radiusInDegrees = maxRadiusMeters / 111000.0;

    final u = random.nextDouble();
    final v = random.nextDouble();

    final w = radiusInDegrees * math.sqrt(u);
    final t = 2 * math.pi * v;
    final x = w * math.cos(t);
    final y = w * math.sin(t);

    // Ajusta o longitude devido ao achatamento da terra
    final adjustedLon = x / math.cos(lat * math.pi / 180.0);

    return LatLng(lat + y, lng + adjustedLon);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _obfuscatedCenter,
            zoom: 15.5,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          circles: {
            Circle(
              circleId: const CircleId('search_area'),
              center: _obfuscatedCenter,
              radius: 300.0, // Raio de busca de 300 metros
              fillColor: Colors.blueAccent.withValues(alpha: 0.2),
              strokeColor: Colors.blueAccent,
              strokeWidth: 2,
            ),
          },
        ),
      ),
    );
  }
}
