import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/wallet/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});
