import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class AdminRepository {
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

  Future<Map<String, dynamic>> getAdminDashboardData() async {
    final result = await callFunction('getAdminDashboardData');
    return Map<String, dynamic>.from(result.result);
  }

  Future<List<dynamic>> listAllUsers() async {
    final result = await callFunction('listAllUsers');
    return result.result as List<dynamic>;
  }

  Future<void> grantAdminRole(String uid) {
    return callFunction('grantAdminRole', {'uid': uid});
  }

  Future<void> revokeAdminRole(String uid) {
    return callFunction('revokeAdminRole', {'uid': uid});
  }
}
