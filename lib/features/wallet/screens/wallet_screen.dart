import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/wallet/providers/wallet_provider.dart';
import 'package:oenigma/features/wallet/widgets/wallet_balance_card.dart';
import 'package:oenigma/features/wallet/widgets/wallet_credit_options_sheet.dart';
import 'package:oenigma/features/wallet/widgets/wallet_history_list.dart';
import 'package:oenigma/features/wallet/widgets/wallet_profile_header.dart';
import 'package:oenigma/features/wallet/widgets/wallet_prizes_section.dart';
import 'package:oenigma/features/wallet/widgets/wallet_section_header.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _refreshWalletData() async {
    return await ref.refresh(walletProvider.future);
  }

  void _showAddFundsDialog(UserWalletModel wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CreditOptionsSheet(wallet: wallet);
      },
    ).then((_) {
      _refreshWalletData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text(
          'Carteira',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: walletAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryAmber),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar carteira',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshWalletData,
                style: ElevatedButton.styleFrom(backgroundColor: primaryAmber),
                child: const Text('Tentar Novamente', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
        data: (walletData) {
          _fadeController.forward();
          return RefreshIndicator(
            onRefresh: _refreshWalletData,
            color: primaryAmber,
            backgroundColor: cardColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      WalletProfileHeader(wallet: walletData),
                      const SizedBox(height: 32),
                      WalletBalanceCard(wallet: walletData),
                      const SizedBox(height: 24),
                      _buildActionButtons(walletData),
                      const SizedBox(height: 40),
                      const WalletSectionHeader(title: 'MEUS PRÊMIOS'),
                      WalletPrizesSection(wallet: walletData),
                      const SizedBox(height: 32),
                      const WalletSectionHeader(title: 'HISTÓRICO RECENTE'),
                      WalletHistoryList(wallet: walletData),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(UserWalletModel wallet) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddFundsDialog(wallet),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Adicionar\nSaldo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAmber,
              foregroundColor: darkBackground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
