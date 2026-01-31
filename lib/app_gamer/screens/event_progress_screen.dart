// lib/app_gamer/screens/event_progress_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobx/mobx.dart';
import '../../models/event_model.dart';
import '../../models/phase_model.dart';
import '../../utils/app_colors.dart';
import '../screens/enigma_screen.dart';
import '../stores/event_progress_store.dart';

class EventProgressScreen extends StatefulWidget {
  final EventModel event;
  const EventProgressScreen({super.key, required this.event});

  @override
  State<EventProgressScreen> createState() => _EventProgressScreenState();
}

class _EventProgressScreenState extends State<EventProgressScreen> {
  final EventProgressStore _store = EventProgressStore();
  final Completer<GoogleMapController> _controller = Completer();
  ReactionDisposer? _navigationDisposer;

  @override
  void initState() {
    super.initState();
    _store.initData(widget.event.id);
    
    // Set up reaction for navigation
    _navigationDisposer = reaction<PhaseModel?>(
      (_) => _store.selectedPhaseToNavigate,
      (phase) {
        if (phase != null) {
          _navigateToPhase(phase);
          _store.clearSelectedPhase();
        }
      },
    );
  }

  @override
  void dispose() {
    _navigationDisposer?.call();
    super.dispose();
  }

  void _navigateToPhase(PhaseModel phase) {
    // Encontrar o enigma atual dentro desta fase
    final currentEnigmaIndex = (_store.currentEnigma - 1) % phase.enigmas.length;
    
    if (phase.enigmas.isEmpty) return;
    
    final safeIndex = (currentEnigmaIndex >= 0 && currentEnigmaIndex < phase.enigmas.length) 
        ? currentEnigmaIndex 
        : 0;

    final enigma = phase.enigmas[safeIndex];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnigmaScreen(
          event: widget.event,
          phase: phase,
          initialEnigma: enigma,
          onEnigmaSolved: () {
            // Recarrega o progresso ao voltar
            _store.initData(widget.event.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Observer(
        builder: (_) {
          if (_store.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _store.userLocation != null
                      ? LatLng(
                          _store.userLocation!.latitude!,
                          _store.userLocation!.longitude!,
                        )
                      : (_store.markers.isNotEmpty
                            ? _store.markers.first.position
                            : const LatLng(-14.2350, -51.9253)),
                  zoom: 14,
                ),
                onMapCreated: (controller) {
                   if (!_controller.isCompleted) {
                     _controller.complete(controller);
                   }
                },
                markers: _store.markers,
                polylines: _store.polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                style: _darkMapStyle,
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
                            "Fase ${_store.currentPhase} / ${_store.phases.length}",
                            style: const TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        width: 40,
                      ),
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
                    if (_controller.isCompleted && _store.userLocation != null) {
                       final controller = await _controller.future;
                       controller.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(
                            _store.userLocation!.latitude!,
                            _store.userLocation!.longitude!,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

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
