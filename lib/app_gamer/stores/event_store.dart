import 'package:mobx/mobx.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:cloud_functions/cloud_functions.dart';

part 'event_store.g.dart';

class EventStore = _EventStore with _$EventStore;

abstract class _EventStore with Store {
  final FirebaseService _firebaseService = FirebaseService();

  @observable
  bool isLoading = false;

  @observable
  bool isSubscribed = false;

  @observable
  Map<String, int>? stats;

  @observable
  String? errorMessage;
  
  @observable
  bool insufficientFunds = false;

  @action
  void checkSubscription(Map<String, dynamic> playerData, String eventId) {
    isSubscribed = playerData['events']?[eventId] != null;
  }

  @action
  Future<void> loadStats(String eventId, String eventType) async {
    try {
      if (eventType == 'find_and_win') {
        final res = await _firebaseService.getFindAndWinStats(eventId);
        stats = {
          'total': res['totalEnigmas'] ?? 0,
          'solved': res['solvedEnigmas'] ?? 0,
        };
      } else {
        final count = await _firebaseService.getChallengeCountForEvent(eventId);
        stats = {
          'total': count,
          'solved': 0,
        };
      }
    } catch (e) {
      print(e);
    }
  }

  @action
  Future<bool> subscribeToEvent(String eventId) async {
    isLoading = true;
    errorMessage = null;
    insufficientFunds = false;
    try {
      await _firebaseService.subscribeToEvent(eventId);
      isSubscribed = true;
      return true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        insufficientFunds = true;
      } else {
        errorMessage = e.message ?? "Ocorreu um erro.";
      }
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }
}
