import 'package:mobx/mobx.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:location/location.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;

part 'enigma_store.g.dart';

class EnigmaStore = _EnigmaStore with _$EnigmaStore;

abstract class _EnigmaStore with Store {
  final FirebaseService _firebaseService = FirebaseService();
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _statusPollTimer;

  @observable
  bool isLoading = false;

  @observable
  bool canBuyHint = false;

  @observable
  bool isHintVisible = false;

  @observable
  bool isBlocked = false;

  @observable
  Map<String, dynamic>? hintData;

  @observable
  double? distance;

  @observable
  bool isNear = false;

  @observable
  String? cooldownUntil;

  @observable
  String? errorMessage;

  @observable
  bool shakeTrigger = false;

  @observable
  Map<String, dynamic>? nextStep; // For successful validation

  @observable
  bool insufficientFunds = false;

  @observable
  EnigmaModel? currentEnigma;

  @action
  void setCurrentEnigma(EnigmaModel enigma) {
    currentEnigma = enigma;
  }

  @action
  Future<void> resetEnigmaState(String eventId, int phaseOrder) async {
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();

    isHintVisible = false;
    canBuyHint = false;
    hintData = null;
    distance = null;
    isNear = false;
    isBlocked = false;
    isLoading = true;
    errorMessage = null;
    nextStep = null;

    await fetchInitialStatus(eventId, phaseOrder);

    if (currentEnigma?.type == 'qr_code_gps') {
      await initializeGpsListener();
    }
    isLoading = false;
  }

  @action
  Future<void> fetchInitialStatus(String eventId, int phaseOrder) async {
    if (currentEnigma == null) return;
    try {
      final result = await _firebaseService.callEnigmaFunction('getStatus', {
        'eventId': eventId,
        'phaseOrder': phaseOrder,
        'enigmaId': currentEnigma!.id,
      });
      final statusData = Map<String, dynamic>.from(result.data);
      isHintVisible = statusData['isHintVisible'] ?? false;
      canBuyHint = statusData['canBuyHint'] ?? false;
      isBlocked = statusData['isBlocked'] ?? false;

      if (isBlocked && statusData['cooldownUntil'] != null) {
        cooldownUntil = statusData['cooldownUntil'];
      }
    } catch (e) {
      print("Erro ao buscar status: $e");
    }
  }

  @action
  Future<void> handleAction(String action, String eventId, int phaseOrder, {String? code}) async {
    if (currentEnigma == null) return;
    isLoading = true;
    errorMessage = null;
    shakeTrigger = false;
    insufficientFunds = false;
    nextStep = null;

    try {
      final result = await _firebaseService.callEnigmaFunction(action, {
        'eventId': eventId,
        'phaseOrder': phaseOrder,
        'enigmaId': currentEnigma!.id,
        if (code != null) 'code': code,
      });

      final data = Map<String, dynamic>.from(result.data);
      final success = data['success'] ?? false;

      if (success) {
        if (action == 'purchaseHint') {
          isHintVisible = true;
          hintData = Map<String, dynamic>.from(data['hint']);
        } else if (action == 'validateCode') {
           nextStep = data['nextStep'] != null
              ? Map<String, dynamic>.from(data['nextStep'])
              : null;
        }
      } else {
        final message = data['message'] ?? 'Ação falhou.';
        if (action == 'validateCode') {
          shakeTrigger = true; // Trigger shake
        }

        if (data['cooldownUntil'] != null) {
          cooldownUntil = data['cooldownUntil'];
          isBlocked = true;
        } else {
          errorMessage = message;
        }
      }
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' &&
          e.message != null &&
          e.message!.contains('Saldo insuficiente')) {
        insufficientFunds = true;
      } else {
        errorMessage = e.message ?? 'Erro desconhecido.';
      }
    } catch (e) {
      errorMessage = 'Erro inesperado: $e';
    } finally {
      isLoading = false;
    }
  }

  @action
  void resetShake() {
    shakeTrigger = false;
  }

  @action
  Future<void> initializeGpsListener() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
    _locationSubscription = _location.onLocationChanged.listen((currentLocation) {
      if (currentEnigma?.location == null) return;
      final distanceInMeters = _calculateDistance(
        currentLocation.latitude!,
        currentLocation.longitude!,
        currentEnigma!.location!.latitude,
        currentEnigma!.location!.longitude,
      );

      distance = distanceInMeters;
      isNear = distanceInMeters <= 100;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  void dispose() {
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();
  }
}
