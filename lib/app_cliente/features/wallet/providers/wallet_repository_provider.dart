import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/app_cliente/features/wallet/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});
