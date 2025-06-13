import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enigma_model.dart';
import '../models/event_model.dart';
import '../models/phase_model.dart';
import '../models/ranking_player_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  // --- Funções Auxiliares para Conversão Segura de Tipos ---
  
  // Converte recursivamente um mapa genérico para Map<String, dynamic>
  Map<String, dynamic> _deepCastMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      final String stringKey = key.toString();
      if (value is Map) {
        return MapEntry(stringKey, _deepCastMap(value));
      }
      if (value is List) {
        return MapEntry(stringKey, _deepCastList(value));
      }
      return MapEntry(stringKey, value);
    });
  }

  // Converte recursivamente uma lista genérica
  List<dynamic> _deepCastList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _deepCastMap(item);
      }
      if (item is List) {
        return _deepCastList(item);
      }
      return item;
    }).toList();
  }


  Future<HttpsCallableResult> _callFunction(String functionName, [Map<String, dynamic>? payload]) async {
    final callable = _functions.httpsCallable(functionName);
    return await callable.call<dynamic>(payload);
  }

  // --- Métodos de API Atualizados ---

  Future<List<EventModel>> getEvents() async {
    final result = await _callFunction('getEventData');
    if (result.data == null) return [];
    final List<dynamic> eventsData = _deepCastList(result.data);
    return eventsData.map((data) => EventModel.fromMap(data)).toList();
  }

  Future<List<PhaseModel>> getPhasesForEvent(String eventId) async {
    final result = await _callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) return [];
    
    final Map<String, dynamic> eventData = _deepCastMap(result.data);
    final List<dynamic> phasesData = eventData['phases'] ?? [];
    return phasesData.map((data) => PhaseModel.fromMap(data)).toList();
  }
  
  Future<int> getChallengeCountForEvent(String eventId) async {
    final result = await _callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) return 0;
    final eventData = _deepCastMap(result.data);
    return (eventData['phases'] as List?)?.length ?? 0;
  }
  
  Future<List<RankingPlayerModel>> getRankingForEvent(String eventId) async {
    final result = await _callFunction('getEventRanking', {'eventId': eventId});
     if (result.data == null) return [];
    final List<dynamic> rankingData = _deepCastList(result.data);
    return rankingData.map((data) => RankingPlayerModel.fromMap(data)).toList();
  }

  Future<HttpsCallableResult> callEnigmaFunction(String action, Map<String, dynamic> payload) {
      final fullPayload = {'action': action, ...payload};
      return _callFunction('handleEnigmaAction', fullPayload);
  }

  Future<Map<String, dynamic>?> getPlayerDetails(String userId) async {
    final doc = await _firestore.collection('players').doc(userId).get();
    return doc.data();
  }

  Future<Map<String, dynamic>> getPlayerProgress(String playerId, String eventId) async {
    final playerDoc = await _firestore.collection('players').doc(playerId).get();
    return playerDoc.data()?['events']?[eventId] ?? {'currentPhase': 1, 'hintsPurchased': []};
  }
}