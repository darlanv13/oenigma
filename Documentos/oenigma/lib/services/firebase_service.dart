import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enigma_model.dart';
import '../models/event_model.dart';
import '../models/phase_model.dart';
import '../models/ranking_player_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  Future<HttpsCallableResult> _callFunction(String functionName, [Map<String, dynamic>? payload]) async {
    final callable = _functions.httpsCallable(functionName);
    return await callable.call<dynamic>(payload);
  }

  Future<List<EventModel>> getEvents() async {
    final result = await _callFunction('getEventData');
    final List<dynamic> eventsData = result.data ?? [];
    return eventsData.map((data) => EventModel.fromMap(Map<String, dynamic>.from(data))).toList();
  }

  Future<List<PhaseModel>> getPhasesForEvent(String eventId) async {
    final result = await _callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) return [];
    
    final encodedData = jsonEncode(result.data);
    final eventData = jsonDecode(encodedData) as Map<String, dynamic>;

    final List<dynamic> phasesData = eventData['phases'] ?? [];
    return phasesData.map((data) => PhaseModel.fromMap(data as Map<String, dynamic>)).toList();
  }
  
  Future<int> getChallengeCountForEvent(String eventId) async {
    final result = await _callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) return 0;
    final eventData = Map<String, dynamic>.from(result.data);
    return (eventData['phases'] as List?)?.length ?? 0;
  }
  
  Future<List<RankingPlayerModel>> getRankingForEvent(String eventId) async {
    final result = await _callFunction('getEventRanking', {'eventId': eventId});
    final List<dynamic> rankingData = result.data ?? [];
    return rankingData.map((data) => RankingPlayerModel.fromMap(Map<String, dynamic>.from(data))).toList();
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

  // O método advancePlayerProgress foi removido, pois a sua lógica agora está no back-end.
}