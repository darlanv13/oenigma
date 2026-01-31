import 'package:mobx/mobx.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/services/firebase_service.dart';

part 'enigma_deck_store.g.dart';

class EnigmaDeckStore = _EnigmaDeckStore with _$EnigmaDeckStore;

abstract class _EnigmaDeckStore with Store {
  final FirebaseService _service = FirebaseService();

  @observable
  ObservableList<EnigmaModel> enigmas = ObservableList<EnigmaModel>();

  @observable
  bool isLoading = false;

  @action
  Future<void> loadEnigmas(String eventId, String? phaseId) async {
    isLoading = true;
    try {
      final list = await _service.getEnigmasForParent(eventId, phaseId);
      // Ordena pela ordem definida (1, 2, 3...)
      list.sort((a, b) => a.order.compareTo(b.order));
      enigmas = ObservableList.of(list);
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> deleteEnigma(
    String eventId,
    String? phaseId,
    String enigmaId,
  ) async {
    // Remoção otimista da UI para sensação de velocidade
    final originalList = List<EnigmaModel>.from(enigmas);
    enigmas.removeWhere((e) => e.id == enigmaId);

    try {
      await _service.deleteEnigma(
        eventId: eventId,
        phaseId: phaseId,
        enigmaId: enigmaId,
      );
    } catch (e) {
      // Reverte se der erro
      enigmas = ObservableList.of(originalList);
      rethrow;
    }
  }
}
