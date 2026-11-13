import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:oenigma/app_cliente/features/enigma/services/decoy_location_service.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Mapa de Perímetro da Expedição Antiga (Estilo Indiana Jones / Cores Vale).
/// Apresenta o raio de 300 metros, até 5 alvos (1 real + 4 decoys) e contagem ativa.
/// Otimizado para carregamento instantâneo no Web, Android e iOS.
class MapRadiusWidget extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;
  final bool isCompact;
  final VoidCallback? onExpand;
  final List<DecoyTarget>? targets;
  final int remainingSeconds;
  final bool enableToolTimer;
  final Function(int)? onTick;
  final VoidCallback? onTimeUp;

  const MapRadiusWidget({
    super.key,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.isCompact = true,
    this.onExpand,
    this.targets,
    this.remainingSeconds = 900,
    this.enableToolTimer = true,
    this.onTick,
    this.onTimeUp,
  });

  @override
  State<MapRadiusWidget> createState() => _MapRadiusWidgetState();
}

class _MapRadiusWidgetState extends State<MapRadiusWidget>
    with SingleTickerProviderStateMixin {
  late LatLng _obfuscatedCenter;
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _isMapReady = false;

  late int _remainingSeconds;
  Timer? _countdownTimer;
  int _selectedTargetIndex = 0;

  // Estilo escuro com tons de pedra de templo e esmeralda Vale
  static const String _darkMapStyle = '''
  [
    { "elementType": "geometry", "stylers": [{"color": "#11181d"}] },
    { "elementType": "labels.text.fill", "stylers": [{"color": "#7c919d"}] },
    { "elementType": "labels.text.stroke", "stylers": [{"color": "#11181d"}] },
    { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#F3A522"}] },
    { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#007D8A"}] },
    { "featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#0d1b1e"}] },
    { "featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1c2a31"}] },
    { "featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#11181d"}] },
    { "featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8c9ca9"}] },
    { "featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#005861"}] },
    { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#F3A522"}] },
    { "featureType": "water", "elementType": "geometry", "stylers": [{"color": "#081014"}] },
    { "featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#007D8A"}] }
  ]
  ''';

  List<DecoyTarget> get _effectiveTargets {
    if (widget.targets != null && widget.targets!.isNotEmpty) {
      return widget.targets!;
    }
    return [
      DecoyTarget(
        index: 1,
        label: 'Sinal 1',
        latitude: widget.destinationLatitude,
        longitude: widget.destinationLongitude,
        isReal: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.remainingSeconds;
    _obfuscatedCenter = LatLng(
      widget.destinationLatitude,
      widget.destinationLongitude,
    );

    _initLocationFast();
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

  /// Inicialização instantânea não bloqueante da localização
  Future<void> _initLocationFast() async {
    // 1. Pega última posição em cache para não esperar pelo GPS
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() => _currentPosition = lastKnown);
      }
    } catch (_) {}

    // 2. Escuta stream de posição
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        _positionSubscription?.cancel();
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
            distanceFilter: kIsWeb ? 0 : 3,
          ),
        ).listen(
          (pos) {
            if (mounted) setState(() => _currentPosition = pos);
          },
          onError: (_) {},
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _countdownTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _recenterTarget(LatLng target) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.5),
        ),
      );
    }
  }

  void _recenterUser() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
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
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  String _formatTime(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final targets = _effectiveTargets;

    for (int i = 0; i < targets.length; i++) {
      final t = targets[i];
      final isSel = i == _selectedTargetIndex;
      markers.add(
        Marker(
          markerId: MarkerId('target_${t.index}'),
          position: LatLng(t.latitude, t.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSel ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueCyan,
          ),
          infoWindow: InfoWindow(
            title: 'Sinal #${t.index}',
            snippet: 'Eco no perímetro de 300m.',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildCircles() {
    final circles = <Circle>{};
    circles.add(
      Circle(
        circleId: const CircleId('relic_perimeter'),
        center: _obfuscatedCenter,
        radius: 300.0,
        fillColor: const Color(0xFF007D8A).withValues(alpha: 0.14),
        strokeColor: const Color(0xFF00A4B4).withValues(alpha: 0.7),
        strokeWidth: 2,
      ),
    );
    return circles;
  }

  @override
  Widget build(BuildContext context) {
    final targets = _effectiveTargets;
    if (_selectedTargetIndex >= targets.length) {
      _selectedTargetIndex = 0;
    }
    final activeTarget = targets[_selectedTargetIndex];

    double distance = 150.0;
    if (_currentPosition != null) {
      distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        activeTarget.latitude,
        activeTarget.longitude,
      );
    }

    // Altura padrão idêntica para todas as ferramentas
    final double frameHeight = widget.isCompact ? 390.0 : 540.0;

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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. HUD SUPERIOR UNIFICADO
                  _buildHeaderHud(),

                  // 2. SELETOR DE ALVOS (Sinais 1 a 5)
                  if (targets.length > 1)
                    _buildTargetSelector(targets)
                  else
                    const SizedBox(height: 4),

                  // 3. MAPA EXPEDIÇÃO (com carregamento instantâneo)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Grade de placeholder instantânea para evitar tela preta no Web
                          Positioned.fill(
                            child: Container(
                              color: const Color(0xFF0A1215),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Color(0xFF00A4B4),
                                      strokeWidth: 2,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'SINCRONIZANDO MAPA DO CÓDICE...',
                                      style: GoogleFonts.cinzel(
                                        color: AppColors.cinzaMedio,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Google Map com estilo escuro
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _obfuscatedCenter,
                              zoom: 16.0,
                            ),
                            mapType: _currentMapType,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            compassEnabled: true,
                            markers: _buildMarkers(),
                            circles: _buildCircles(),
                            style: _darkMapStyle,
                            onMapCreated: (controller) {
                              _mapController = controller;
                              if (mounted) setState(() => _isMapReady = true);
                            },
                          ),

                          // Controles Flutuantes do Mapa (Centralizar Alvo, Usuário, Satélite)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Column(
                              children: [
                                _buildMapFloatingButton(
                                  icon: FontAwesomeIcons.layerGroup,
                                  onTap: _toggleMapType,
                                  tooltip: 'Camada de Satélite',
                                ),
                                const SizedBox(height: 6),
                                _buildMapFloatingButton(
                                  icon: FontAwesomeIcons.crosshairs,
                                  onTap: () => _recenterTarget(
                                    LatLng(activeTarget.latitude, activeTarget.longitude),
                                  ),
                                  tooltip: 'Centralizar Alvo',
                                ),
                                const SizedBox(height: 6),
                                _buildMapFloatingButton(
                                  icon: FontAwesomeIcons.locationArrow,
                                  onTap: _recenterUser,
                                  tooltip: 'Minha Posição',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 4. TELEMETRIA INFERIOR UNIFICADA
                  _buildFooterTelemetry(distance),
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
  Widget _buildHeaderHud() {
    return Row(
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
                FontAwesomeIcons.mapLocationDot,
                color: Color(0xFF00A4B4),
                size: 11,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'MAPA DA EXPEDIÇÃO',
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),

        // Timer
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

        // Botão Expandir
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
  // 2. SELETOR DE ALVOS
  // ===========================================================================
  Widget _buildTargetSelector(List<DecoyTarget> targets) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(targets.length, (idx) {
          final isSel = idx == _selectedTargetIndex;
          final t = targets[idx];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                SoundService.playClick();
                setState(() => _selectedTargetIndex = idx);
                _recenterTarget(LatLng(t.latitude, t.longitude));
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.locationPin,
                      size: 8.5,
                      color: isSel ? Colors.black : const Color(0xFF00A4B4),
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

  Widget _buildMapFloatingButton({
    required dynamic icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF131D24).withValues(alpha: 0.90),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF1E3A45),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: 11,
            color: const Color(0xFF00A4B4),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. TELEMETRIA INFERIOR
  // ===========================================================================
  Widget _buildFooterTelemetry(double distance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1417),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.circleDot,
                color: Color(0xFF00A4B4),
                size: 11,
              ),
              const SizedBox(width: 6),
              Text(
                '${distance.toInt()} M',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00A4B4),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.circleNodes,
                color: AppColors.amareloVale,
                size: 10,
              ),
              const SizedBox(width: 5),
              Text(
                'RAIO 300M',
                style: GoogleFonts.cinzel(
                  color: AppColors.amareloVale,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),

          Text(
            _isMapReady ? 'SATÉLITE ON' : 'CARREGANDO',
            style: GoogleFonts.cinzel(
              color: _isMapReady ? AppColors.verdeVale : AppColors.cinzaMedio,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
