import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/features/wallet/providers/wallet_repository_provider.dart';

final walletProvider = FutureProvider<UserWalletModel>((ref) async {
  final walletRepository = ref.watch(walletRepositoryProvider);
  return await walletRepository.getUserWalletData();
});
