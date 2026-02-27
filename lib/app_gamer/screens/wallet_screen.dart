import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../models/user_wallet_model.dart';
import '../../utils/app_colors.dart';
import '../stores/wallet_store.dart';
import '../widgets/wallet/payment_bottom_sheet.dart';

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
          _buildProfileHeader(widget.wallet),
          const SizedBox(height: 24),
          _buildBalanceCard(context),
          const SizedBox(height: 24),
          _buildSectionTitle('ADICIONAR SALDO'),
          const SizedBox(height: 12),
          _buildCreditOptions(context),
          const SizedBox(height: 24),
          _buildSectionTitle('ÚLTIMO PRÉMIO'),
          const SizedBox(height: 12),
          _buildPrizesCard(widget.wallet.lastWonEventName),
          const SizedBox(height: 24),
          _buildSectionTitle('ESTATÍSTICAS'),
          const SizedBox(height: 12),
          _buildStatsCard(widget.wallet.lastEventRank, widget.wallet.lastEventName),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserWalletModel wallet) {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: cardColor,
          backgroundImage: wallet.photoURL != null
              ? NetworkImage(wallet.photoURL!)
              : null,
          child: wallet.photoURL == null
              ? const Icon(Icons.person, size: 35, color: secondaryTextColor)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                wallet.email,
                style: const TextStyle(fontSize: 14, color: secondaryTextColor),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Observer(
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardColor, cardColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Disponível',
                  style: TextStyle(color: secondaryTextColor, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'R\$ ${_store.balance.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: primaryAmber,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => _showWithdrawDialog(context),
              icon: const Icon(Icons.arrow_upward_rounded),
              style: IconButton.styleFrom(
                backgroundColor: primaryAmber.withOpacity(0.1),
                foregroundColor: primaryAmber,
                padding: const EdgeInsets.all(12),
              ),
              tooltip: 'Sacar',
            ),
          ],
        ),
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

  Widget _buildCreditOptions(BuildContext context) {
    final options = [5, 10, 15, 20, 50, 100];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final amount = options[index];
        return Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _buyCredits(context, amount.toDouble()),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                'R\$ $amount',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrizesCard(String? lastWonEventName) {
    if (lastWonEventName == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Text(
            'Você ainda não venceu nenhum evento.',
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryAmber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryAmber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: primaryAmber,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Última Vitória",
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  lastWonEventName,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int? rank, String? eventName) {
    if (rank == null || eventName == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "RANKING ATUAL",
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  eventName,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryAmber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
