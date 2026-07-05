import 'package:cloud_functions/cloud_functions.dart';
import 'package:oenigma/core/models/event_model.dart';

import 'package:oenigma/core/models/enigma_model.dart';

class EnigmaRepository {
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

  Future<HttpsCallableResult> callEnigmaFunction(
    String action,
    Map<String, dynamic> payload,
  ) {
    final fullPayload = {'action': action, ...payload};
    return callFunction('handleEnigmaAction', fullPayload);
  }

  // Admin Methods
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
    final result = await callFunction('getEventData', {'eventId': eventId});
    if (result.data == null) throw Exception('Event not found');
    final event = EventModel.fromMap(Map<String, dynamic>.from(result.data));

    if (phaseId != null) {
      final phase = event.phases.firstWhere((p) => p.id == phaseId);
      return phase.enigmas;
    } else {
      return event.enigmas;
    }
  }
}
