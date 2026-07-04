import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';

class EnigmaRepository {
  Future<ParseResponse> callFunction(
    String functionName, [
    Map<String, dynamic>? payload,
  ]) async {
    final ParseCloudFunction function = ParseCloudFunction(functionName);
    try {
      return await function.execute(parameters: payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<ParseResponse> callEnigmaFunction(
    String action,
    Map<String, dynamic> payload,
  ) {
    final fullPayload = {'action': action, ...payload};
    return callFunction('handleEnigmaAction', fullPayload);
  }

  // Admin Methods
  Future<ParseResponse> createOrUpdatePhase({
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

  Future<ParseResponse> createOrUpdateEnigma({
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

  Future<void> deletePhase({required String eventId, required String phaseId}) async {
    await callFunction('deletePhase', {
      'eventId': eventId,
      'phaseId': phaseId,
    });
  }

  Future<void> deleteEnigma({
    required String eventId,
    String? phaseId,
    required String enigmaId,
  }) async {
    await callFunction('deleteEnigma', {
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
    if (!result.success || result.result == null) throw Exception(result.error?.message ?? 'Event not found');
    final event = EventModel.fromMap(Map<String, dynamic>.from(result.result));

    if (phaseId != null) {
      final phase = event.phases.firstWhere((p) => p.id == phaseId);
      return phase.enigmas;
    } else {
      return event.enigmas;
    }
  }
}
