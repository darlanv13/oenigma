import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class RankingRepository {
  Future<ParseResponse> callFunction(
    String functionName, [
    Map<String, dynamic>? payload,
  ]) async {
    final ParseCloudFunction function = ParseCloudFunction(functionName);
    try {
      final response = await function.execute(parameters: payload);
      if (!response.success) {
        throw response.error ?? ParseError();
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRankingData(String eventId) async {
      throw UnimplementedError("getRankingData is not yet implemented in Cloud Functions");
  }
}
