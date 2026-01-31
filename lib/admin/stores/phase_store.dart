import 'package:mobx/mobx.dart';
import 'package:oenigma/models/phase_model.dart';
import 'package:oenigma/services/firebase_service.dart';

part 'phase_store.g.dart';

class PhaseStore = _PhaseStore with _$PhaseStore;

abstract class _PhaseStore with Store {
  final FirebaseService _service = FirebaseService();

  @observable
  ObservableList<PhaseModel> phases = ObservableList<PhaseModel>();

  @observable
  bool isLoading = false;

  @action
  Future<void> loadPhases(String eventId) async {
    isLoading = true;
    try {
      final list = await _service.getPhasesForEvent(eventId);
      // Ordena localmente para garantir
      list.sort((a, b) => a.order.compareTo(b.order));
      phases = ObservableList.of(list);
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> addPhase(String eventId) async {
    isLoading = true;
    await _service.createOrUpdatePhase(
      eventId: eventId,
      data: {},
    ); // Backend cria ordem auto
    await loadPhases(eventId); // Recarrega para pegar a nova
  }

  @action
  Future<void> deletePhase(String eventId, String phaseId) async {
    phases.removeWhere((p) => p.id == phaseId); // Otimista UI
    await _service.deletePhase(eventId: eventId, phaseId: phaseId);
    await loadPhases(eventId); // Sincroniza ordem correta
  }

  @action
  Future<void> reorderPhases(String eventId, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final PhaseModel item = phases.removeAt(oldIndex);
    phases.insert(newIndex, item);

    // Atualizar ordem no backend (Isso requer que seu service aceite update em lote ou loop)
    // Para simplificar, vamos iterar e atualizar. Idealmente, faça uma Cloud Function para isso.
    for (int i = 0; i < phases.length; i++) {
      // Atualiza apenas se mudou
      // No mundo real, chame uma função 'updatePhaseOrder(eventId, phases)'
      // Aqui simularemos updates individuais:
      _service.createOrUpdatePhase(
        eventId: eventId,
        phaseId: phases[i].id,
        data: {'order': i + 1},
      );
    }
  }
}
