import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:oenigma/app_cliente/features/enigma/services/decoy_location_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Mapa de Perímetro da Expedição Antiga (Estilo Indiana Jones / Cores Vale).
/// Apresenta o raio de 300 metros, até 5 alvos (1 real + 4 decoys) e contagem ativa de 15min.
class MapRadiusWidget extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;
  final bool isCompact;
  final VoidCallback? onExpand;
  final List<DecoyTarget>? targets;
  final int remainingSeconds;

  const MapRadiusWidget({
    super.key,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.isCompact = false,
    this.onExpand,
    this.targets,
    this.remainingSeconds = 900,
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
      "stylers": [{"color": "#007D8A"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _obfuscateCenter();
    _checkPermissions();
    _createCustomMarker();
  }

  @override
  void didUpdateWidget(covariant MapRadiusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinationLatitude != widget.destinationLatitude ||
        oldWidget.destinationLongitude != widget.destinationLongitude) {
      _obfuscateCenter();
      _recenterTarget();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _obfuscateCenter() {
    _obfuscatedCenter = LatLng(
      widget.destinationLatitude,
      widget.destinationLongitude,
    );
  }

  Future<void> _checkPermissions() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        setState(() {
          _hasLocationPermission = true;
        });
        _getCurrentLocation();
        _startLocationUpdates();
      }
    } catch (_) {}
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    } catch (_) {}
  }

  void _startLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    });
  }

  Future<void> _createCustomMarker() async {
    try {
      _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueYellow,
      );
    } catch (_) {}
  }

  void _recenterTarget() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _obfuscatedCenter,
            zoom: 16.2,
          ),
        ),
      );
    }
  }

  void _recenterUser() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 16.5,
          ),
        ),
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (widget.targets != null && widget.targets!.isNotEmpty) {
      for (final t in widget.targets!) {
        markers.add(
          Marker(
            markerId: MarkerId('target_${t.index}'),
            position: LatLng(t.latitude, t.longitude),
            icon: _customMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: 'Anomalia Sagrada #${t.index}',
              snippet: 'Eco detectado no raio de 300m da expedição.',
            ),
          ),
        );
      }
    } else {
      markers.add(
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
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final double mapHeight = widget.isCompact ? 220.0 : 420.0;
    final distanceMeters = _currentPosition != null
        ? Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            widget.destinationLatitude,
            widget.destinationLongitude,
          )
        : null;

    final isLowTime = widget.remainingSeconds < 120;

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
              markers: _buildMarkers(),
              circles: {
                // Perímetro Interno da Relíquia (300m)
                Circle(
                  circleId: const CircleId('search_area_fill'),
                  center: _obfuscatedCenter,
                  radius: 300.0,
                  fillColor: AppColors.verdeVale.withValues(alpha: 0.14),
                  strokeColor: AppColors.verdeVale.withValues(alpha: 0.85),
                  strokeWidth: 2,
                ),
                // Borda Dourada Externa (315m)
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

            // Top HUD do Mapa: Perímetro, Timer Ativo de 15 Minutos & Distância
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Perímetro 300M
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
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
                          size: 10,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'PERÍMETRO: 300M',
                          style: GoogleFonts.cinzel(
                            color: AppColors.verdeVale,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Timer Ativo de 15 Minutos (Pausa quando fecha)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (isLowTime ? Colors.redAccent : AppColors.amareloVale)
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.stopwatch,
                          color: isLowTime ? Colors.redAccent : AppColors.amareloVale,
                          size: 10,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatTime(widget.remainingSeconds),
                          style: GoogleFonts.spaceMono(
                            color: isLowTime ? Colors.redAccent : AppColors.amareloVale,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Distância estimada até o epicentro
                  if (distanceMeters != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
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
                          const SizedBox(width: 5),
                          Text(
                            '~${distanceMeters.toStringAsFixed(0)}M',
                            style: GoogleFonts.cinzel(
                              color: AppColors.amareloVale,
                              fontSize: 9.5,
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
