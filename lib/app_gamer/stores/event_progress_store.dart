import 'package:mobx/mobx.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:oenigma/models/phase_model.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';

part 'event_progress_store.g.dart';

class EventProgressStore = _EventProgressStore with _$EventProgressStore;

abstract class _EventProgressStore with Store {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  @observable
  bool isLoading = true;

  @observable
  List<PhaseModel> phases = [];

  @observable
  int currentPhase = 1;

  @observable
  int currentEnigma = 1;

  @observable
  Set<Marker> markers = {};

  @observable
  Set<Polyline> polylines = {};

  @observable
  LocationData? userLocation;

  @observable
  PhaseModel? selectedPhaseToNavigate;

  @action
  Future<void> initData(String eventId) async {
    isLoading = true;
    await Future.wait([
      _loadEventData(eventId),
      _getUserLocation(),
    ]);
    _buildMapElements();
    isLoading = false;
  }

  Future<void> _getUserLocation() async {
    final location = Location();
    try {
      userLocation = await location.getLocation();
    } catch (e) {
      print("Erro ao obter localização: $e");
    }
  }

  Future<void> _loadEventData(String eventId) async {
    final phasesData = await _firebaseService.getPhasesForEvent(eventId);
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      final progress = await _firebaseService.getPlayerProgress(userId, eventId);
      phases = phasesData;
      currentPhase = progress['currentPhase'];
      currentEnigma = progress['currentEnigma'];
    }
  }

  @action
  void _buildMapElements() {
    Set<Marker> newMarkers = {};
    List<LatLng> polylineCoordinates = [];

    for (var phase in phases) {
      // Usa a localização do primeiro enigma da fase como ponto de referência
      // Se a fase não tiver localização GPS, usamos uma posição padrão ou do evento
      // (Assumindo que fases têm enigmas com location ou a fase teria um campo location)
      // Adaptando para pegar do primeiro enigma que tiver location:
      final enigmaWithLoc = phase.enigmas.firstWhere(
        (e) => e.location != null,
        orElse: () => phase.enigmas.first,
      );

      // Fallback se nenhum enigma tiver localização (ex: enigmas de texto apenas)
      if (enigmaWithLoc.location == null) continue;

      final position = LatLng(
        enigmaWithLoc.location!.latitude,
        enigmaWithLoc.location!.longitude,
      );
      polylineCoordinates.add(position);

      final isCompleted = phase.order < currentPhase;
      final isLocked = phase.order > currentPhase;
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
          onTap: isActive ? () => selectPhase(phase) : null,
          alpha: isLocked ? 0.5 : 1.0,
        ),
      );
    }

    // Criar linhas conectando as fases
    if (polylineCoordinates.isNotEmpty) {
      polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: primaryAmber.withOpacity(0.7),
          points: polylineCoordinates,
          width: 4,
          jointType: JointType.round,
          patterns: [
            PatternItem.dash(10),
            PatternItem.gap(10),
          ], 
        ),
      };
    }

    markers = newMarkers;
  }

  @action
  void selectPhase(PhaseModel phase) {
    selectedPhaseToNavigate = phase;
  }
  
  @action
  void clearSelectedPhase() {
    selectedPhaseToNavigate = null;
  }
}
