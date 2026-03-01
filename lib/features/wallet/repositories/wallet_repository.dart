import 'package:cloud_functions/cloud_functions.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';

class WalletRepository {
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

  Future<UserWalletModel> getUserWalletData() async {
    final result = await callFunction('getUserWalletData');
    if (result.data == null) {
      throw Exception("Não foi possível carregar os dados da carteira.");
    }
    final walletData = Map<String, dynamic>.from(result.data);
    return UserWalletModel.fromMap(walletData);
  }
}
