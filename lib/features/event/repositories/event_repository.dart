import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';

class EventRepository {
  Future<ParseResponse> callFunction(
    String functionName, [
    Map<String, dynamic>? payload,
  ]) async {
    final ParseCloudFunction function = ParseCloudFunction(functionName);
    try {
      final response = await function.execute(parameters: payload);
      if (!response.success) {
        throw response.error ?? ParseError();
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHomeScreenData() async {
    final result = await callFunction('getHomeScreenData');
    return Map<String, dynamic>.from(result.result);
  }

  Future<List<PhaseModel>> getPhasesForEvent(String eventId) async {
    final result = await callFunction('getEventData', {'eventId': eventId});
    if (result.result == null) {
      return [];
    }
    final eventData = Map<String, dynamic>.from(result.result);
    final List<dynamic> phasesData = eventData['phases'] ?? [];
    return phasesData.map((data) {
      final phaseMap = Map<String, dynamic>.from(data);
      return PhaseModel.fromMap(phaseMap);
    }).toList();
  }

  Future<int> getChallengeCountForEvent(String eventId) async {
    final result = await callFunction('getEventData', {'eventId': eventId});
    if (result.result == null) return 0;
    final eventData = Map<String, dynamic>.from(result.result);
    final phases = eventData['phases'] as List?;
    return phases?.length ?? 0;
  }

  Future<EventModel> getFullEventDetails(String eventId) async {
    final result = await callFunction('getEventData', {'eventId': eventId});
    if (result.result == null) {
      throw Exception('Evento não encontrado');
    }
    return EventModel.fromMap(Map<String, dynamic>.from(result.result));
  }

  Future<ParseResponse> subscribeToEvent(String eventId) {
    return callFunction('subscribeToEvent', {'eventId': eventId});
  }

  Future<Map<String, dynamic>> getPlayerProgress(
    String playerId,
    String eventId,
  ) async {
    final query = QueryBuilder<ParseUser>(ParseUser.forQuery())..whereEqualTo('objectId', playerId);
    final response = await query.query();

    if (response.success && response.results != null && response.results!.isNotEmpty) {
      final ParseUser player = response.results!.first as ParseUser;
      final events = player.get<Map<String, dynamic>>('events') ?? {};
      final eventProgress = events[eventId];

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
  Future<ParseResponse> createOrUpdateEvent({
    String? eventId,
    required Map<String, dynamic> data,
  }) {
    return callFunction('createOrUpdateEvent', {
      'eventId': eventId,
      'data': data,
    });
  }

  Future<ParseResponse> deleteEvent(String eventId) {
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
    return Map<String, dynamic>.from(result.result);
  }
}
