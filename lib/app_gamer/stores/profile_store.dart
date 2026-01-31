import 'package:mobx/mobx.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/services/firebase_service.dart';

part 'profile_store.g.dart';

class ProfileStore = _ProfileStore with _$ProfileStore;

abstract class _ProfileStore with Store {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  @observable
  bool isLoading = false;

  @observable
  Map<String, dynamic>? playerData;

  @observable
  UserWalletModel? walletData;

  @action
  void setInitialData({Map<String, dynamic>? player, UserWalletModel? wallet}) {
    if (player != null) playerData = player;
    if (wallet != null) walletData = wallet;
  }

  @action
  Future<void> fetchMissingData() async {
    if (playerData != null && walletData != null) return;
    
    isLoading = true;
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final results = await Future.wait([
        if (playerData == null) _firebaseService.getPlayerDetails(userId),
        if (walletData == null) _firebaseService.getUserWalletData(),
      ]);

      int index = 0;
      if (playerData == null) {
        playerData = results[index] as Map<String, dynamic>?;
        index++;
      }
      if (walletData == null) {
        if (index < results.length) {
          final result = results[index];
          if (result is UserWalletModel) {
            walletData = result;
          }
        }
      }
    } catch (e) {
      print("Erro ao atualizar perfil: $e");
    } finally {
      isLoading = false;
    }
  }
}
