import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

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

  Future<void> grantAdminRole(String objectId) {
    return callFunction('grantAdminRole', {'objectId': objectId});
  }

  Future<void> revokeAdminRole(String objectId) {
    return callFunction('revokeAdminRole', {'objectId': objectId});
  }
}
