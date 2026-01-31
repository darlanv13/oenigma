import 'package:mobx/mobx.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'dart:async';

part 'find_and_win_store.g.dart';

class FindAndWinStore = _FindAndWinStore with _$FindAndWinStore;

abstract class _FindAndWinStore with Store {
  final FirebaseService _firebaseService = FirebaseService();

  @observable
  bool isLoading = false;

  @observable
  bool isBlocked = false;

  @observable
  Map<String, dynamic>? eventData;

  @observable
  Map<String, dynamic>? currentEnigmaData;

  @observable
  String? currentEnigmaId;

  @observable
  String? eventStatus;

  @observable
  String? errorMessage;

  @observable
  String? cooldownUntil;

  @observable
  bool success = false;

  StreamSubscription? _eventSubscription;
  StreamSubscription? _enigmaSubscription;

  @action
  void init(String eventId) {
    _eventSubscription?.cancel();
    _eventSubscription = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            eventData = data;
            final newEnigmaId = data?['currentEnigmaId'];
            eventStatus = data?['status'];

            if (newEnigmaId != currentEnigmaId) {
              currentEnigmaId = newEnigmaId;
              _listenToEnigma(eventId, currentEnigmaId);
            }
          }
        });
  }

  void _listenToEnigma(String eventId, String? enigmaId) {
    _enigmaSubscription?.cancel();
    if (enigmaId == null || enigmaId.isEmpty) {
      currentEnigmaData = null;
      return;
    }
    _enigmaSubscription = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('enigmas')
        .doc(enigmaId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            currentEnigmaData = {
              'id': snapshot.id,
              ...data,
            };
          } else {
            currentEnigmaData = null;
          }
        });
  }

  @action
  Future<void> validateCode(String eventId, String enigmaId, String code) async {
    if (code.isEmpty) return;
    isLoading = true;
    errorMessage = null;
    success = false;
    try {
      final result = await _firebaseService.callFunction('handleEnigmaAction', {
        'eventId': eventId,
        'enigmaId': enigmaId,
        'code': code,
      });

      final data = Map<String, dynamic>.from(result.data);
      if (!(data['success'] as bool)) {
        final message = data['message'] ?? "Código incorreto.";
        if (data['cooldownUntil'] != null) {
          cooldownUntil = data['cooldownUntil'];
          isBlocked = true;
        } else {
          errorMessage = message;
        }
      } else {
        success = true;
      }
    } catch (e) {
      errorMessage = "Ocorreu um erro: ${e.toString()}";
    } finally {
      isLoading = false;
    }
  }

  @action
  void setBlocked(bool value) => isBlocked = value;

  @action
  void resetSuccess() => success = false;

  @action
  void resetError() => errorMessage = null;

  void dispose() {
    _eventSubscription?.cancel();
    _enigmaSubscription?.cancel();
  }
}
