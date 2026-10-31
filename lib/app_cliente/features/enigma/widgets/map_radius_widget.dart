import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';

/// Mapa de Perímetro da Expedição Antiga (Estilo Indiana Jones / Cores Vale).
class MapRadiusWidget extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;
  final bool isCompact;
  final VoidCallback? onExpand;

  const MapRadiusWidget({
    super.key,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.isCompact = false,
    this.onExpand,
  });

  @override
  State<MapRadiusWidget> createState() => _MapRadiusWidgetState();
}

class _MapRadiusWidgetState extends State<MapRadiusWidget>
    with SingleTickerProviderStateMixin {
  late LatLng _obfuscatedCenter;
  bool _hasLocationPermission = false;
  BitmapDescriptor? _customMarkerIcon;
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  late AnimationController _pulseController;

  // Estilo escuro com tons de pedra de templo e esmeralda Vale
  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#1b242a"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8fa3ad"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1b242a"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#F3A522"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#007D8A"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#142526"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#4e7b7f"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#28373e"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#151d21"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#9ca5b3"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#005861"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#003b41"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#F3A522"}]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [{"color": "#202e35"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#0d181d"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#264350"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _obfuscatedCenter = _generateObfuscatedLocation(
      widget.destinationLatitude,
      widget.destinationLongitude,
      130.0,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _checkLocationPermission();
    _loadCustomMarker();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomMarker() async {
    try {
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(44, 44)),
        'assets/images/compass_icon.png',
      );
      if (mounted) setState(() => _customMarkerIcon = icon);
    } catch (_) {}
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) {
        setState(() => _hasLocationPermission = true);
        _startLocationUpdates();
      }
    }
  }

  void _startLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
  }

  LatLng _generateObfuscatedLocation(
    double lat,
    double lng,
    double maxRadiusMeters,
  ) {
    final random = math.Random();
    final radiusInDegrees = maxRadiusMeters / 111000.0;
    final u = random.nextDouble();
    final v = random.nextDouble();
    final w = radiusInDegrees * math.sqrt(u);
    final t = 2 * math.pi * v;
    final x = w * math.cos(t);
    final y = w * math.sin(t);
    final adjustedLon = x / math.cos(lat * math.pi / 180.0);
    return LatLng(lat + y, lng + adjustedLon);
  }

  void _recenterTarget() {
    HapticFeedback.selectionClick();
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _obfuscatedCenter, zoom: 16.0),
      ),
    );
  }

  void _recenterUser() {
    HapticFeedback.selectionClick();
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 16.5,
          ),
        ),
      );
    }
  }

  void _toggleMapType() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double mapHeight = widget.isCompact ? 260.0 : 380.0;
    final double? distanceMeters = _currentPosition != null
        ? Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            widget.destinationLatitude,
            widget.destinationLongitude,
          )
        : null;

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Mapa do Google com Estilo Noturno
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _obfuscatedCenter,
                zoom: 15.5,
              ),
              mapType: _currentMapType,
              style: _currentMapType == MapType.normal ? _mapStyle : null,
              myLocationEnabled: _hasLocationPermission,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: {
                Marker(
                  markerId: const MarkerId('destination'),
                  position: _obfuscatedCenter,
                  icon: _customMarkerIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                  infoWindow: const InfoWindow(
                    title: 'Perímetro da Relíquia',
                    snippet: 'O tesouro repousa neste raio estimado.',
                  ),
                ),
              },
              circles: {
                // Perímetro Interno da Relíquia
                Circle(
                  circleId: const CircleId('search_area_fill'),
                  center: _obfuscatedCenter,
                  radius: 300.0,
                  fillColor: AppColors.verdeVale.withValues(alpha: 0.14),
                  strokeColor: AppColors.verdeVale.withValues(alpha: 0.85),
                  strokeWidth: 2,
                ),
                // Borda Dourada Externa
                Circle(
                  circleId: const CircleId('search_area_outer'),
                  center: _obfuscatedCenter,
                  radius: 315.0,
                  fillColor: Colors.transparent,
                  strokeColor: AppColors.amareloVale.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              },
            ),

            // Top HUD do Mapa: Perímetro & Distância da Expedição
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.80),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.verdeVale.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.compass,
                          color: AppColors.verdeVale,
                          size: 11,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PERÍMETRO: 300M',
                          style: GoogleFonts.cinzel(
                            color: AppColors.verdeVale,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (distanceMeters != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.amareloVale.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.route,
                            color: AppColors.amareloVale,
                            size: 10,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '~${distanceMeters.toStringAsFixed(0)}M',
                            style: GoogleFonts.cinzel(
                              color: AppColors.amareloVale,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Botões de Ação do Mapa da Expedição (Direita)
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Alternar Visão Normal / Satélite
                  _buildMapActionButton(
                    icon: _currentMapType == MapType.normal
                        ? FontAwesomeIcons.earthAmericas
                        : FontAwesomeIcons.map,
                    tooltip: 'Visão Satélite / Pergaminho',
                    color: AppColors.verdeVale,
                    onTap: _toggleMapType,
                  ),
                  const SizedBox(height: 8),

                  // Centralizar na Relíquia
                  _buildMapActionButton(
                    icon: FontAwesomeIcons.gem,
                    tooltip: 'Centralizar na Relíquia',
                    color: AppColors.amareloVale,
                    onTap: _recenterTarget,
                  ),
                  const SizedBox(height: 8),

                  // Centralizar na Posição do Explorador
                  if (_hasLocationPermission) ...[
                    _buildMapActionButton(
                      icon: FontAwesomeIcons.locationCrosshairs,
                      tooltip: 'Minha Posição',
                      color: AppColors.verdeVale,
                      onTap: _recenterUser,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Expandir Mapa
                  if (widget.onExpand != null)
                    _buildMapActionButton(
                      icon: FontAwesomeIcons.upRightAndDownLeftFromCenter,
                      tooltip: 'Expandir Mapa',
                      color: Colors.white,
                      onTap: widget.onExpand!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapActionButton({
    required dynamic icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.darkCardColor.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(icon, color: color, size: 14),
        ),
      ),
    );
  }
}
