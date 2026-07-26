import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // <-- IMPORT DO GEOLOCATOR ADICIONADO
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
  bool _hasLocationPermission = false; // <-- VARIÁVEL DE CONTROLE ADICIONADA

  // Dark/Night map style JSON
  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#746855"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#263c3f"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6b9a76"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#38414e"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#212a37"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#9ca5b3"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#746855"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#1f2835"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#f3d19c"}]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [{"color": "#2f3948"}]
    },
    {
      "featureType": "transit.station",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#17263c"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#515c6d"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#17263c"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _obfuscatedCenter = _generateObfuscatedLocation(
      widget.destinationLatitude,
      widget.destinationLongitude,
      150.0, // Mova o centro em até 150 metros do ponto real
    );
    _checkLocationPermission(); // <-- INICIA A CHECAGEM DE PERMISSÃO
  }

  // NOVA FUNÇÃO: Checa se a EnigmaScreen já liberou o GPS
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) {
        setState(() {
          _hasLocationPermission = true;
        });
      }
    }
  }

  // Gera um ponto aleatório perto do destino para ser o centro do círculo
  // Isso impede que o usuário apenas vá para o centro exato do círculo desenhado
  LatLng _generateObfuscatedLocation(
    double lat,
    double lng,
    double maxRadiusMeters,
  ) {
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
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _obfuscatedCenter,
            zoom: 15.5,
          ),
          // MODIFICADO AQUI: Só ativa a bolinha azul se já tiver permissão
          myLocationEnabled: _hasLocationPermission,
          myLocationButtonEnabled: _hasLocationPermission,
          onMapCreated: (GoogleMapController controller) {
            controller.setMapStyle(_mapStyle);
          },
          circles: {
            Circle(
              circleId: const CircleId('search_area'),
              center: _obfuscatedCenter,
              radius: 300.0, // Raio de busca de 300 metros
              fillColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
              strokeColor: const Color(0xFF00FFFF),
              strokeWidth: 3,
            ),
          },
        ),
      ),
    );
  }
}
