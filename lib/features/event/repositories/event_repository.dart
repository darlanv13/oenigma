import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<HttpsCallableResult> callFunction(
    String functionName, [
    Map<String, dynamic>? payload,
  ]) async {
    final callable = _functions.httpsCallable(functionName);
    try {
      return await callable.call<dynamic>(payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHomeScreenData() async {
    final result = await callFunction('getHomeScreenData');
    return Map<String, dynamic>.from(result.data);
  }

  Future<List<PhaseModel>> getPhasesForEvent(String eventId) async {
    final result = await callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) {
      return [];
    }
    final eventData = Map<String, dynamic>.from(result.data);
    final List<dynamic> phasesData = eventData['phases'] ?? [];
    return phasesData.map((data) {
      final phaseMap = Map<String, dynamic>.from(data);
      return PhaseModel.fromMap(phaseMap);
    }).toList();
  }

  Future<int> getChallengeCountForEvent(String eventId) async {
    final result = await callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) return 0;
    final eventData = Map<String, dynamic>.from(result.data);
    final phases = eventData['phases'] as List?;
    return phases?.length ?? 0;
  }

  Future<EventModel> getFullEventDetails(String eventId) async {
    final result = await callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) {
      throw Exception('Evento não encontrado');
    }
    return EventModel.fromMap(Map<String, dynamic>.from(result.data));
  }

  Future<HttpsCallableResult> subscribeToEvent(String eventId) {
    return callFunction('subscribeToEvent', {'eventId': eventId});
  }

  Future<Map<String, dynamic>> getPlayerProgress(
    String playerId,
    String eventId,
  ) async {
    final playerDoc = await _firestore
        .collection('players')
        .doc(playerId)
        .get();

    if (playerDoc.exists && playerDoc.data() != null) {
      final playerData = playerDoc.data()!;
      final eventProgress = playerData['events']?[eventId];

      if (eventProgress is Map) {
        final progressMap = Map<String, dynamic>.from(eventProgress);
        return {
          'currentPhase': progressMap['currentPhase'] ?? 1,
          'currentEnigma': progressMap['currentEnigma'] ?? 1,
          'hintsPurchased': progressMap['hintsPurchased'] ?? [],
        };
      }
    }

    return {'currentPhase': 1, 'currentEnigma': 1, 'hintsPurchased': []};
  }

  // --- Funções de Escrita (Gerenciamento / Admin) ---
  Future<HttpsCallableResult> createOrUpdateEvent({
    String? eventId,
    required Map<String, dynamic> data,
  }) {
    return callFunction('createOrUpdateEvent', {
      'eventId': eventId,
      'data': data,
    });
  }

  Future<HttpsCallableResult> deleteEvent(String eventId) {
    return callFunction('deleteEvent', {'eventId': eventId});
  }

  Future<void> toggleEventStatus({
    required String eventId,
    required String newStatus,
  }) {
    return callFunction('toggleEventStatus', {
      'eventId': eventId,
      'newStatus': newStatus,
    });
  }

  Future<Map<String, dynamic>> getFindAndWinStats(String eventId) async {
    final result = await callFunction('getFindAndWinStats', {
      'eventId': eventId,
    });
    return Map<String, dynamic>.from(result.data);
  }
}
