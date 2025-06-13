import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/enigma_model.dart';
import '../models/event_model.dart';
import '../models/phase_model.dart';
import '../models/ranking_player_model.dart';

/// A classe `FirebaseService` centraliza toda a comunicação com os
/// serviços do Firebase (Firestore e Cloud Functions) para a aplicação.
class FirebaseService {
  /// Instância do Firestore para acesso ao banco de dados NoSQL.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Instância do Cloud Functions, configurada para a região da América do Sul.
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  /// Função auxiliar para chamar uma Cloud Function de forma padronizada e segura.
  ///
  /// [functionName] é o nome da função a ser chamada.
  /// [payload] são os dados a serem enviados para a função.
  Future<HttpsCallableResult> _callFunction(String functionName,
      [Map<String, dynamic>? payload]) async {
    final callable = _functions.httpsCallable(functionName);
    try {
      return await callable.call<dynamic>(payload);
    } on FirebaseFunctionsException catch (e) {
      // Log do erro para facilitar a depuração no console.
      print(
          "FirebaseFunctionsException em ${functionName}: ${e.code} - ${e.message}");
      // Relança a exceção para que a interface do usuário possa lidar com ela.
      rethrow;
    } catch (e) {
      print("Exceção genérica em ${functionName}: $e");
      rethrow;
    }
  }

  /// Busca a lista de todos os eventos disponíveis.
  Future<List<EventModel>> getEvents() async {
    final result = await _callFunction('getEventData');
    final List<dynamic> eventsData = result.data ?? [];
    return eventsData
        .map((data) => EventModel.fromMap(Map<String, dynamic>.from(data)))
        .toList();
  }

  /// Busca as fases de um evento específico.
  ///
  /// Esta versão foi corrigida para processar os dados diretamente,
  /// evitando erros de conversão.
  Future<List<PhaseModel>> getPhasesForEvent(String eventId) async {
    final result = await _callFunction('getEventData', {'eventId': eventId});
    final eventData = result.data as Map<String, dynamic>?;

    if (eventData == null) {
      return [];
    }

    final List<dynamic> phasesData = eventData['phases'] ?? [];
    return phasesData
        .map((data) => PhaseModel.fromMap(data as Map<String, dynamic>))
        .toList();
  }

  /// Retorna a contagem de fases (desafios) para um determinado evento.
  Future<int> getChallengeCountForEvent(String eventId) async {
    final result = await _callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) return 0;

    final eventData = Map<String, dynamic>.from(result.data);
    final phases = eventData['phases'] as List?;
    return phases?.length ?? 0;
  }

  /// Busca o ranking completo dos jogadores para um evento específico.
  Future<List<RankingPlayerModel>> getRankingForEvent(String eventId) async {
    final result = await _callFunction('getEventRanking', {'eventId': eventId});
    final List<dynamic> rankingData = result.data ?? [];
    return rankingData
        .map((data) => RankingPlayerModel.fromMap(Map<String, dynamic>.from(data)))
        .toList();
  }

  /// Centraliza as chamadas para a Cloud Function que gerencia as ações do enigma.
  ///
  /// [action] especifica a ação a ser executada (ex: 'validateCode', 'purchaseHint').
  /// [payload] contém os dados necessários para a ação.
  Future<HttpsCallableResult> callEnigmaFunction(
      String action, Map<String, dynamic> payload) {
    final fullPayload = {'action': action, ...payload};
    return _callFunction('handleEnigmaAction', fullPayload);
  }

  /// Busca os detalhes do perfil de um jogador a partir do seu ID de usuário.
  Future<Map<String, dynamic>?> getPlayerDetails(String userId) async {
    final doc = await _firestore.collection('players').doc(userId).get();
    return doc.data();
  }

  /// Busca o progresso de um jogador em um evento específico.
  ///
  /// Retorna um mapa com o progresso atual. Se nenhum progresso for encontrado,
  /// retorna um estado padrão inicial.
  Future<Map<String, dynamic>> getPlayerProgress(
      String playerId, String eventId) async {
    final playerDoc = await _firestore.collection('players').doc(playerId).get();

    if (playerDoc.exists && playerDoc.data() != null) {
      final playerData = playerDoc.data()!;
      final eventProgress = playerData['events']?[eventId];
      
      if (eventProgress is Map<String, dynamic>) {
        // Retorna o progresso existente, garantindo valores padrão se
        // alguma chave estiver faltando.
        return {
          'currentPhase': eventProgress['currentPhase'] ?? 1,
          'hintsPurchased': eventProgress['hintsPurchased'] ?? [],
        };
      }
    }
    
    // Retorna o estado inicial padrão se o jogador ou o evento não tiverem registro.
    return {'currentPhase': 1, 'hintsPurchased': []};
  }

  // O método advancePlayerProgress foi removido, pois a sua lógica agora está no back-end.
}