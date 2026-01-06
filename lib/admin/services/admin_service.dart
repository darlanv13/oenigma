import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/models/withdrawal_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  // ===========================================================================
  // LEITURAS (Espelho em Tempo Real - Mantemos Streams)
  // ===========================================================================

  Stream<List<EventModel>> getEvents() {
    return _firestore
        .collection('events')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<UserWalletModel>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserWalletModel.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<WithdrawalModel>> getPendingWithdrawals() {
    return _firestore
        .collection('withdrawals')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => WithdrawalModel.fromMap(d.data())).toList(),
        );
  }

  // ===========================================================================
  // ESCRITAS (Via Cloud Functions - management.js)
  // ===========================================================================

  /// Salva apenas os dados do Evento (Sem subcoleções de fases/enigmas)
  Future<String> saveEvent(EventModel event) async {
    // Prepara o payload removendo listas aninhadas para não duplicar dados
    final eventMap = event.toMap();
    eventMap.remove('phases'); // Gerenciado via subcoleções/funções dedicadas
    eventMap.remove('enigmas');

    final HttpsCallable callable = _functions.httpsCallable(
      'createOrUpdateEvent',
    );

    final result = await callable.call({
      'eventId': event.id.isEmpty ? null : event.id, // Null cria novo
      'data': eventMap,
    });

    // Retorna o ID do evento (novo ou existente)
    return result.data['id'] as String;
  }

  /// Deleta Evento (e todas as subcoleções via recursive delete no backend)
  Future<void> deleteEvent(String eventId) async {
    final HttpsCallable callable = _functions.httpsCallable('deleteEvent');
    await callable.call({'eventId': eventId});
  }

  /// Salva/Atualiza um Enigma Específico
  Future<void> saveEnigma({
    required String eventId,
    String? phaseId, // Null se for Find & Win (direto no evento)
    required EnigmaModel enigma,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable(
      'createOrUpdateEnigma',
    );

    // Prepara dados do enigma
    final enigmaData = enigma.toMap();
    // Remove o ID do corpo dos dados, pois é passado separadamente se for update
    enigmaData.remove('id');

    // Tratamento especial para GeoPoint (precisa ser enviado como mapa simples para a Function converter)
    if (enigma.location != null) {
      enigmaData['location'] = {
        'latitude': enigma.location!.latitude,
        'longitude': enigma.location!.longitude,
      };
    }

    await callable.call({
      'eventId': eventId,
      'phaseId': phaseId,
      'enigmaId': enigma.id.isEmpty ? null : enigma.id,
      'data': enigmaData,
    });
  }

  /// Deleta um Enigma
  Future<void> deleteEnigma({
    required String eventId,
    String? phaseId,
    required String enigmaId,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('deleteEnigma');
    await callable.call({
      'eventId': eventId,
      'phaseId': phaseId,
      'enigmaId': enigmaId,
    });
  }

  /// Deleta uma Fase Inteira
  Future<void> deletePhase({
    required String eventId,
    required String phaseId,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable('deletePhase');
    await callable.call({'eventId': eventId, 'phaseId': phaseId});
  }

  // ===========================================================================
  // FINANCEIRO (Suposição: você tem/terá uma function approveWithdrawal)
  // ===========================================================================

  Future<void> updateWithdrawalStatus(String id, String newStatus) async {
    // ATENÇÃO: Verifique se o nome da função no seu backend é 'approveWithdrawal'
    // Se não tiver essa função em 'wallet.js', você precisará criá-la.
    final HttpsCallable callable = _functions.httpsCallable(
      'approveWithdrawal',
    );
    await callable.call({
      'withdrawalId': id,
      'status': newStatus, // 'approved' ou 'rejected'
    });
  }

  /// Salva/Cria uma Fase (Apenas container, sem enigmas)
  Future<void> savePhase({
    required String eventId,
    String? phaseId,
    required int order,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable(
      'createOrUpdatePhase',
    );

    await callable.call({
      'eventId': eventId,
      'phaseId': phaseId,
      'data': {
        'order': order,
        // Você pode adicionar um campo 'title' ou 'description' futuramente
      },
    });
  }

  // Chama a função 'listAllUsers' do management.js
  Future<List<Map<String, dynamic>>> listAllUsers() async {
    final HttpsCallable callable = _functions.httpsCallable('listAllUsers');
    final result = await callable.call();

    // Converte a resposta para uma lista de Mapas
    return (result.data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Alternar permissão de admin
  Future<void> toggleAdminRole(String uid, bool makeAdmin) async {
    final String functionName = makeAdmin
        ? 'grantAdminRole'
        : 'revokeAdminRole';
    final HttpsCallable callable = _functions.httpsCallable(functionName);

    await callable.call({'uid': uid});
  }

  // Atualiza permissões detalhadas
  Future<void> updateUserPermissions({
    required String uid,
    required bool isAdmin,
    required Map<String, bool> permissions,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable(
      'updateUserPermissions',
    );

    await callable.call({
      'uid': uid,
      'isAdmin': isAdmin,
      'permissions': permissions,
    });
  }
}
