import 'package:mobx/mobx.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/services/firebase_service.dart';

// O build_runner vai gerar este arquivo .g.dart
part 'enigma_store.g.dart';

class EnigmaStore = _EnigmaStore with _$EnigmaStore;

abstract class _EnigmaStore with Store {
  final FirebaseService _firebaseService = FirebaseService();

  // --- ESTADO (Observables) ---

  @observable
  String instruction = '';

  @observable
  String code = '';

  @observable
  String imageUrl = '';

  @observable
  String type = 'text';

  @observable
  LatLng? location;

  @observable
  String? hintType;

  @observable
  String hintData = '';

  @observable
  double hintPrice = 0.0;

  @observable
  double prize = 0.0;

  @observable
  int order = 1;

  @observable
  bool isUploading = false;

  @observable
  bool isSaving = false;

  @observable
  String? errorMessage;

  // --- DADOS DERIVADOS (Computed) ---

  @computed
  bool get isValid => instruction.isNotEmpty && code.isNotEmpty;

  @computed
  bool get hasLocation => location != null;

  // --- AÇÕES (Actions) ---

  @action
  void setInstruction(String value) => instruction = value;

  @action
  void setCode(String value) => code = value;

  @action
  void setImageUrl(String value) => imageUrl = value;

  @action
  void setType(String value) => type = value;

  @action
  void setLocation(LatLng? value) => location = value;

  @action
  void setHintType(String? value) => hintType = value;

  @action
  void setHintData(String value) => hintData = value;

  @action
  void setHintPrice(String value) {
    hintPrice = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }

  @action
  void setPrize(String value) {
    prize = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }

  @action
  void setOrder(String value) {
    order = int.tryParse(value) ?? 1;
  }

  @action
  void setIsUploading(bool value) => isUploading = value;

  // Carrega dados para edição
  @action
  void loadFromModel(EnigmaModel enigma) {
    instruction = enigma.instruction;
    code = enigma.code;
    imageUrl = enigma.imageUrl ?? '';
    type = enigma.type;

    if (enigma.location != null) {
      location = LatLng(enigma.location!.latitude, enigma.location!.longitude);
    } else {
      location = null;
    }

    hintType = enigma.hintType;
    hintData = enigma.hintData ?? '';
    hintPrice = enigma.hintPrice;
    prize = enigma.prize;
    order = enigma.order;
  }

  // Salva no Firebase
  @action
  Future<bool> saveEnigma(
    String eventId,
    String? phaseId,
    String? enigmaId,
  ) async {
    if (!isValid) {
      errorMessage = "Por favor, preencha a instrução e o código da resposta.";
      return false;
    }

    if (type == 'qr_code_gps' && location == null) {
      errorMessage =
          "Para enigmas com GPS, é necessário definir uma localização no mapa.";
      return false;
    }

    isSaving = true;
    errorMessage = null;

    try {
      Map<String, dynamic>? locationData;
      if (location != null &&
          (type == 'qr_code_gps' || type == 'photo_location')) {
        locationData = {
          '_latitude': location!.latitude,
          '_longitude': location!.longitude,
        };
      }

      final data = {
        'instruction': instruction,
        'code': code,
        'type': type,
        'order': order,
        'prize': prize,
        'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
        'hintType': hintType,
        'hintData': hintData.isNotEmpty ? hintData : null,
        'hintPrice': hintPrice,
        'location': locationData,
      };

      await _firebaseService.createOrUpdateEnigma(
        eventId: eventId,
        phaseId: phaseId,
        enigmaId: enigmaId,
        data: data,
      );

      return true;
    } catch (e) {
      errorMessage = "Erro ao salvar: $e";
      return false;
    } finally {
      isSaving = false;
    }
  }

  @action
  void clear() {
    instruction = '';
    code = '';
    imageUrl = '';
    type = 'text';
    location = null;
    hintType = null;
    hintData = '';
    hintPrice = 0.0;
    prize = 0.0;
    order = 1;
    errorMessage = null;
    isSaving = false;
  }
}
