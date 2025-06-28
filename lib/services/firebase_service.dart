import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import '../models/event_model.dart';
import '../models/phase_model.dart';
import '../models/ranking_player_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<HttpsCallableResult> _callFunction(
    String functionName, [
    Map<String, dynamic>? payload,
  ]) async {
    final callable = _functions.httpsCallable(functionName);
    try {
      return await callable.call<dynamic>(payload);
    } on FirebaseFunctionsException catch (e) {
      print(
        "FirebaseFunctionsException em ${functionName}: ${e.code} - ${e.message}",
      );
      rethrow;
    } catch (e) {
      print("Exceção genérica em ${functionName}: $e");
      rethrow;
    }
  }

  // NOVA FUNÇÃO OTIMIZADA E CENTRALIZADA
  Future<Map<String, dynamic>> getHomeScreenData() async {
    final result = await _callFunction('getHomeScreenData');
    return Map<String, dynamic>.from(result.data);
  }

  // --- FUNÇÕES MANTIDAS PARA OUTRAS TELAS ---

  Future<List<PhaseModel>> getPhasesForEvent(String eventId) async {
    // Esta função ainda é usada na tela de progresso do evento
    final result = await _callFunction('getEventData', {'eventId': eventId});
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
    final result = await _callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) return 0;
    final eventData = Map<String, dynamic>.from(result.data);
    final phases = eventData['phases'] as List?;
    return phases?.length ?? 0;
  }

  Future<Map<String, dynamic>?> getPlayerDetails(String userId) async {
    // Usado na tela de Perfil
    final doc = await _firestore.collection('players').doc(userId).get();
    return doc.data();
  }

  Future<UserWalletModel> getUserWalletData() async {
    // Usado na tela de Carteira
    final result = await _callFunction('getUserWalletData');
    if (result.data == null) {
      throw Exception("Não foi possível carregar os dados da carteira.");
    }
    final walletData = Map<String, dynamic>.from(result.data);
    return UserWalletModel.fromMap(walletData);
  }

  // --- FUNÇÕES DE GAMEPLAY (permanecem inalteradas) ---
  Future<HttpsCallableResult> callEnigmaFunction(
    String action,
    Map<String, dynamic> payload,
  ) {
    final fullPayload = {'action': action, ...payload};
    return _callFunction('handleEnigmaAction', fullPayload);
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
}
