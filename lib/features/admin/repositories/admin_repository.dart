import 'package:cloud_functions/cloud_functions.dart';

class AdminRepository {
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

  Future<Map<String, dynamic>> getAdminDashboardData() async {
    final result = await callFunction('getAdminDashboardData');
    return Map<String, dynamic>.from(result.data);
  }

  Future<List<dynamic>> listAllUsers() async {
    final result = await callFunction('listAllUsers');
    return result.data as List<dynamic>;
  }

  Future<void> grantAdminRole(String uid) {
    return callFunction('grantAdminRole', {'uid': uid});
  }

  Future<void> revokeAdminRole(String uid) {
    return callFunction('revokeAdminRole', {'uid': uid});
  }
}
