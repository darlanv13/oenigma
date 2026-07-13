import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/features/wallet/providers/wallet_provider.dart';
import 'package:oenigma/features/wallet/widgets/wallet_balance_card.dart';
import 'package:oenigma/features/wallet/widgets/wallet_credit_options_sheet.dart';
import 'package:oenigma/features/wallet/widgets/wallet_history_list.dart';
import 'package:oenigma/features/wallet/widgets/wallet_profile_header.dart';
import 'package:oenigma/features/wallet/widgets/wallet_prizes_section.dart';
import 'package:oenigma/features/wallet/widgets/wallet_section_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'CARTEIRA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFD54F),
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: walletAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.circleExclamation,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar carteira',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshWalletData,
                icon: const FaIcon(
                  FontAwesomeIcons.rotateRight,
                  color: Colors.black,
                ),
                label: const Text(
                  'TENTAR NOVAMENTE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (walletData) {
          _fadeController.forward();
          return RefreshIndicator(
            onRefresh: _refreshWalletData,
            color: const Color(0xFFFFD54F),

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showAddFundsDialog(wallet),
        icon: const FaIcon(FontAwesomeIcons.circlePlus, color: Colors.black),
        label: const Text(
          'ADICIONAR SALDO',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}
