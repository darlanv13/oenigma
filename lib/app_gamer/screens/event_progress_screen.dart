// lib/app_gamer/screens/event_progress_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../models/event_model.dart';
import '../../models/phase_model.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_colors.dart';
import '../screens/enigma_screen.dart'; // Import necessário para navegação

class EventProgressScreen extends StatefulWidget {
  final EventModel event;
  const EventProgressScreen({super.key, required this.event});

  @override
  State<EventProgressScreen> createState() => _EventProgressScreenState();
}

class _EventProgressScreenState extends State<EventProgressScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  final Completer<GoogleMapController> _controller = Completer();

  // Variáveis de Estado
  List<PhaseModel> _phases = [];
  int _currentPhase = 1;
  int _currentEnigma = 1;
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LocationData? _userLocation;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadEventData();
    await _getUserLocation();
    _buildMapElements();
    setState(() => _isLoading = false);
  }

  Future<void> _getUserLocation() async {
    final location = Location();
    try {
      _userLocation = await location.getLocation();
    } catch (e) {
      print("Erro ao obter localização: $e");
    }
  }

  Future<void> _loadEventData() async {
    final phases = await _firebaseService.getPhasesForEvent(widget.event.id);
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      final progress = await _firebaseService.getPlayerProgress(
        userId,
        widget.event.id,
      );
      if (mounted) {
        setState(() {
          _phases = phases;
          _currentPhase = progress['currentPhase'];
          _currentEnigma = progress['currentEnigma'];
        });
      }
    }
  }

  void _buildMapElements() {
    Set<Marker> newMarkers = {};
    List<LatLng> polylineCoordinates = [];

    for (var phase in _phases) {
      // Usa a localização do primeiro enigma da fase como ponto de referência
      // Se a fase não tiver localização GPS, usamos uma posição padrão ou do evento
      // (Assumindo que fases têm enigmas com location ou a fase teria um campo location)
      // Adaptando para pegar do primeiro enigma que tiver location:
      final enigmaWithLoc = phase.enigmas.firstWhere(
        (e) => e.location != null,
        orElse: () => phase.enigmas.first,
      );

      // Fallback se nenhum enigma tiver localização (ex: enigmas de texto apenas)
      // Idealmente, seu CMS deve exigir localização para fases no mapa.
      if (enigmaWithLoc.location == null) continue;

      final position = LatLng(
        enigmaWithLoc.location!.latitude,
        enigmaWithLoc.location!.longitude,
      );
      polylineCoordinates.add(position);

      final isCompleted = phase.order < _currentPhase;
      final isLocked = phase.order > _currentPhase;
      final isActive = !isLocked && !isCompleted;

      // Definindo a cor do marcador (Hue)
      double iconHue = BitmapDescriptor.hueRed; // Bloqueado
      if (isCompleted) iconHue = BitmapDescriptor.hueGreen;
      if (isActive) iconHue = BitmapDescriptor.hueOrange;

      newMarkers.add(
        Marker(
          markerId: MarkerId('phase_${phase.id}'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(iconHue),
          infoWindow: InfoWindow(
            title: "Fase ${phase.order}",
            snippet: isActive
                ? "Toque para jogar!"
                : (isLocked ? "Bloqueado" : "Concluído"),
          ),
          onTap: isActive ? () => _navigateToPhase(phase) : null,
          alpha: isLocked ? 0.5 : 1.0,
        ),
      );
    }

    // Criar linhas conectando as fases
    if (polylineCoordinates.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: primaryAmber.withOpacity(0.7),
          points: polylineCoordinates,
          width: 4,
          jointType: JointType.round,
          patterns: [
            PatternItem.dash(10),
            PatternItem.gap(10),
          ], // Linha pontilhada estilo "Mapa do Tesouro"
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _navigateToPhase(PhaseModel phase) {
    // Encontrar o enigma atual dentro desta fase
    final currentEnigmaIndex = (_currentEnigma - 1) % phase.enigmas.length;
    final enigma = phase.enigmas[currentEnigmaIndex];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnigmaScreen(
          event: widget.event,
          phase: phase,
          initialEnigma: enigma,
          onEnigmaSolved: () {
            setState(() => _isLoading = true);
            _initData(); // Recarrega o progresso ao voltar
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: primaryAmber),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLocation != null
                        ? LatLng(
                            _userLocation!.latitude!,
                            _userLocation!.longitude!,
                          )
                        : (_markers.isNotEmpty
                              ? _markers.first.position
                              : const LatLng(-14.2350, -51.9253)),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) =>
                      _controller.complete(controller),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  style: _darkMapStyle, // Estilo Dark Mode aplicado abaixo
                ),

          // Header Flutuante
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: darkBackground.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryAmber.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Column(
                    children: [
                      Text(
                        widget.event.name,
                        style: const TextStyle(
                          color: primaryAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Fase $_currentPhase / ${_phases.length}",
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 40,
                  ), // Espaço para balancear o ícone de voltar
                ],
              ),
            ),
          ),

          // Botão de Centralizar
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: primaryAmber,
              child: const Icon(Icons.my_location, color: darkBackground),
              onPressed: () async {
                final controller = await _controller.future;
                if (_userLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(
                        _userLocation!.latitude!,
                        _userLocation!.longitude!,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Estilo JSON para Google Maps Dark Mode (Opcional, mas recomendado para o tema)
  final String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#212121"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#212121"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#2c2c2c"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8a8a8a"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#000000"}]
    }
  ]
  ''';
}
