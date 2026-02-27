import 'package:flutter/material.dart';
import '../../models/user_wallet_model.dart';
import '../../utils/app_colors.dart';
import '../stores/wallet_store.dart';
import '../widgets/wallet/balance_card.dart';
import '../widgets/wallet/credit_options.dart';
import '../widgets/wallet/payment_bottom_sheet.dart';
import '../widgets/wallet/prizes_card.dart';
import '../widgets/wallet/profile_header.dart';
import '../widgets/wallet/stats_card.dart';

class WalletScreen extends StatefulWidget {
  final UserWalletModel wallet;

  const WalletScreen({super.key, required this.wallet});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletStore _store = WalletStore();

  @override
  void initState() {
    super.initState();
    _store.setBalance(widget.wallet.balance);
    _store.initBalanceStream(widget.wallet.uid);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  void _buyCredits(BuildContext context, double amount) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentBottomSheet(amount: amount, wallet: widget.wallet),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Solicitar Saque',
          style: TextStyle(color: primaryAmber),
        ),
        content: const Text(
          'Informe seus dados de pagamento (ex: Chave PIX) para que sua solicitação seja enviada para aprovação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ENTENDIDO',
              style: TextStyle(color: primaryAmber),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Carteira'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileHeader(wallet: widget.wallet),
          const SizedBox(height: 24),
          BalanceCard(
            store: _store,
            onWithdraw: () => _showWithdrawDialog(context),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('ADICIONAR SALDO'),
          const SizedBox(height: 12),
          CreditOptions(
            onBuyCredits: (amount) => _buyCredits(context, amount),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('ÚLTIMO PRÉMIO'),
          const SizedBox(height: 12),
          PrizesCard(lastWonEventName: widget.wallet.lastWonEventName),
          const SizedBox(height: 24),
          _buildSectionTitle('ESTATÍSTICAS'),
          const SizedBox(height: 12),
          StatsCard(
            rank: widget.wallet.lastEventRank,
            eventName: widget.wallet.lastEventName,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: secondaryTextColor,
        letterSpacing: 1.2,
      ),
    );
  }
}
