import 'package:cloud_functions/cloud_functions.dart';

class RankingRepository {
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

  Future<Map<String, dynamic>> getRankingData(String eventId) async {
      throw UnimplementedError("getRankingData is not yet implemented in Cloud Functions");
  }
}
