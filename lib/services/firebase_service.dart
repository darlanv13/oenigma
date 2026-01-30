import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import '../models/phase_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<HttpsCallableResult> callFunction(
    String functionName, [
    Map<String, dynamic>? payload,
  ]) async {
    final callable = _functions.httpsCallable(functionName);
    try {
      return await callable.call<dynamic>(payload);
    } on FirebaseFunctionsException catch (e, stack) {
      // LOG DE ERRO DE FUNÇÃO
      print(
        "FirebaseFunctionsException em $functionName: ${e.code} - ${e.message}",
      );
      // Não logamos 'canceled' ou erros de validação simples como fatais, mas erros 'internal' sim
      if (e.code == 'internal' || e.code == 'unknown') {
        await _crashlytics.recordError(
          e,
          stack,
          reason: 'Function: $functionName',
        );
      }
      rethrow;
    } catch (e, stack) {
      // LOG DE ERRO GENÉRICO
      print("Exceção genérica em $functionName: $e");
      await _crashlytics.recordError(
        e,
        stack,
        reason: 'Function Generic: $functionName',
      );
      rethrow;
    }
  }

  // NOVA FUNÇÃO OTIMIZADA E CENTRALIZADA
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

  Future<Map<String, dynamic>?> getPlayerDetails(String userId) async {
    final doc = await _firestore.collection('players').doc(userId).get();
    return doc.data();
  }

  Future<UserWalletModel> getUserWalletData() async {
    final result = await callFunction('getUserWalletData');
    if (result.data == null) {
      throw Exception("Não foi possível carregar os dados da carteira.");
    }
    final walletData = Map<String, dynamic>.from(result.data);
    return UserWalletModel.fromMap(walletData);
  }

  Future<HttpsCallableResult> callEnigmaFunction(
    String action,
    Map<String, dynamic> payload,
  ) {
    final fullPayload = {'action': action, ...payload};
    return callFunction('handleEnigmaAction', fullPayload);
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

  Future<HttpsCallableResult> subscribeToEvent(String eventId) {
    return callFunction('subscribeToEvent', {'eventId': eventId});
  }

  Future<Map<String, dynamic>> getAdminDashboardData() async {
    final result = await callFunction('getAdminDashboardData');
    return Map<String, dynamic>.from(result.data);
  }

  Future<EventModel> getFullEventDetails(String eventId) async {
    final result = await callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) {
      throw Exception('Evento não encontrado');
    }
    return EventModel.fromMap(Map<String, dynamic>.from(result.data));
  }

  Future<HttpsCallableResult> createOrUpdateEvent({
    String? eventId,
    required Map<String, dynamic> data,
  }) {
    return callFunction('createOrUpdateEvent', {
      'eventId': eventId,
      'data': data,
    });
  }

  Future<HttpsCallableResult> createOrUpdatePhase({
    required String eventId,
    String? phaseId,
    required Map<String, dynamic> data,
  }) {
    return callFunction('createOrUpdatePhase', {
      'eventId': eventId,
      'phaseId': phaseId,
      'data': data,
    });
  }

  Future<HttpsCallableResult> createOrUpdateEnigma({
    required String eventId,
    String? phaseId,
    String? enigmaId,
    required Map<String, dynamic> data,
  }) {
    return callFunction('createOrUpdateEnigma', {
      'eventId': eventId,
      'phaseId': phaseId,
      'enigmaId': enigmaId,
      'data': data,
    });
  }

  Future<HttpsCallableResult> deleteEvent(String eventId) {
    return callFunction('deleteEvent', {'eventId': eventId});
  }

  Future<List<dynamic>> listAllUsers() async {
    final result = await callFunction('listAllUsers');
    return result.data as List<dynamic>;
  }

  Future<void> grantAdminRole(String uid) {
    return callFunction('grantAdminRole', {'uid': uid});
  }

  Future<void> revokeAdminRole(String uid) {
    return callFunction('revokeAdminRole', {'uid': uid});
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

  Future<void> deletePhase({required String eventId, required String phaseId}) {
    return callFunction('deletePhase', {
      'eventId': eventId,
      'phaseId': phaseId,
    });
  }

  Future<void> deleteEnigma({
    required String eventId,
    String? phaseId,
    required String enigmaId,
  }) {
    return callFunction('deleteEnigma', {
      'eventId': eventId,
      'phaseId': phaseId,
      'enigmaId': enigmaId,
    });
  }

  Future<List<EnigmaModel>> getEnigmasForParent(
    String eventId,
    String? phaseId,
  ) async {
    final EventModel event = await getFullEventDetails(eventId);
    if (phaseId != null) {
      final phase = event.phases.firstWhere((p) => p.id == phaseId);
      return phase.enigmas;
    } else {
      return event.enigmas;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingWithdrawals() async {
    final snapshot = await _firestore
        .collection('withdrawals')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> approveWithdrawal(String withdrawalId) {
    return callFunction('approveWithdrawal', {'withdrawalId': withdrawalId});
  }

  Future<void> rejectWithdrawal(String withdrawalId, {String? reason}) {
    return callFunction('rejectWithdrawal', {
      'withdrawalId': withdrawalId,
      'reason': reason,
    });
  }
}
