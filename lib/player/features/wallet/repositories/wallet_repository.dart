import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';

class WalletRepository {
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

  Future<UserWalletModel> getUserWalletData() async {
    final result = await callFunction('getUserWalletData');
    if (result.result == null) {
      throw Exception("Não foi possível carregar os dados da carteira.");
    }
    final walletData = Map<String, dynamic>.from(result.result);
    return UserWalletModel.fromMap(walletData);
  }
}
