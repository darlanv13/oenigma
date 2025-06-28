import 'package:flutter/material.dart';
import '../models/user_wallet_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<UserWalletModel> _walletFuture;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  void _loadWalletData() {
    setState(() {
      _walletFuture = _firebaseService.getUserWalletData();
    });
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Adicionar Créditos',
          style: TextStyle(color: primaryAmber),
        ),
        content: const Text(
          'A integração com um sistema de pagamentos (como Mercado Pago, Stripe, etc.) seria implementada aqui para processar a compra.',
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

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Solicitar Saque',
          style: TextStyle(color: primaryAmber),
        ),
        content: const Text(
          'Aqui, o utilizador informaria os seus dados de pagamento (ex: Chave PIX) e a sua solicitação seria enviada para aprovação do administrador.',
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
      body: FutureBuilder<UserWalletModel>(
        future: _walletFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar dados da carteira: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum dado encontrado.'));
          }

          final wallet = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _loadWalletData(),
            color: primaryAmber,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileHeader(wallet),
                const SizedBox(height: 24),
                _buildBalanceCard(wallet.balance),
                const SizedBox(height: 24),
                _buildSectionTitle('ADICIONAR SALDO'),
                const SizedBox(height: 12),
                _buildCreditOptions(),
                const SizedBox(height: 24),
                _buildSectionTitle('ÚLTIMO PRÉMIO'),
                const SizedBox(height: 12),
                _buildPrizesCard(wallet.lastWonEventName),
                const SizedBox(height: 24),
                _buildSectionTitle('ESTATÍSTICAS'),
                const SizedBox(height: 12),
                _buildStatsCard(wallet.lastEventRank, wallet.lastEventName),
              ],
            ),
          );
        },
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

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo Atual',
                style: TextStyle(color: secondaryTextColor, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _showWithdrawDialog,
            icon: const Icon(Icons.arrow_circle_up_rounded),
            label: const Text('Sacar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAmber.withOpacity(0.2),
              foregroundColor: primaryAmber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: secondaryTextColor,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCreditOptions() {
    final options = [5, 10, 15, 20];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final amount = options[index];
        return Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: _showPurchaseDialog,
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: Text(
                'R\$ $amount',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrizesCard(String? lastWonEventName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: (lastWonEventName == null)
          ? const Center(
              child: Text(
                'Você ainda não venceu nenhum evento.',
                style: TextStyle(color: secondaryTextColor),
              ),
            )
          : Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: primaryAmber,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Parabéns pela sua última vitória!",
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastWonEventName,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard(int? rank, String? eventName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: (rank == null || eventName == null)
          ? const Center(
              child: Text(
                "Nenhum ranking de evento ativo para exibir.",
                style: TextStyle(color: secondaryTextColor),
              ),
            )
          : Column(
              children: [
                const Text(
                  "SUA POSIÇÃO NO ÚLTIMO EVENTO ATIVO",
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  eventName,
                  style: const TextStyle(
                    color: primaryAmber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '#$rank',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}
