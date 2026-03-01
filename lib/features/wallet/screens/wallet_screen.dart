import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/wallet/providers/wallet_provider.dart';

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
        return _CreditOptionsSheet(wallet: wallet);
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
                      _buildProfileHeader(walletData),
                      const SizedBox(height: 32),
                      _buildBalanceCard(walletData),
                      const SizedBox(height: 24),
                      _buildActionButtons(walletData),
                      const SizedBox(height: 40),
                      _buildSectionHeader('MEUS PRÊMIOS'),
                      _buildPrizesSection(walletData),
                      const SizedBox(height: 32),
                      _buildSectionHeader('HISTÓRICO RECENTE'),
                      _buildHistoryList(walletData),
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

  Widget _buildProfileHeader(UserWalletModel wallet) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryAmber, width: 2),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: darkBackground,
            backgroundImage: (wallet.photoURL != null && wallet.photoURL!.isNotEmpty)
                ? NetworkImage(wallet.photoURL!)
                : null,
            child: (wallet.photoURL == null || wallet.photoURL!.isEmpty)
                ? const Icon(Icons.person, color: secondaryTextColor, size: 30)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.name,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                wallet.email,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(UserWalletModel wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Saldo Disponível',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'R\$ ${wallet.balance.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              color: primaryAmber,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: primaryAmber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizesSection(UserWalletModel wallet) {
    if (wallet.lastWonEventName == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: secondaryTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum prêmio ainda.',
              style: TextStyle(color: secondaryTextColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Participe de eventos para ganhar!',
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryAmber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: primaryAmber, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Última Vitória',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  wallet.lastWonEventName!,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Prêmio Resgatado',
                  style: const TextStyle(color: primaryAmber, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(UserWalletModel wallet) {
    if (wallet.lastEventRank == null && wallet.lastWonEventName == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'Nenhuma atividade recente.',
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (wallet.lastEventRank != null)
          _buildHistoryItem(
            icon: Icons.bar_chart,
            title: 'Classificação em Evento',
            subtitle: 'Você ficou em #${wallet.lastEventRank}',
            color: Colors.lightBlueAccent,
          ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditOptionsSheet extends StatelessWidget {
  final UserWalletModel wallet;

  const _CreditOptionsSheet({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final amounts = [5.0, 10.0, 15.0, 20.0, 50.0, 100.0];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Adicionar Saldo",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Escolha o valor que deseja adicionar à sua carteira.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: amounts.length,
            itemBuilder: (context, index) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber.withValues(alpha: 0.1),
                  foregroundColor: primaryAmber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: primaryAmber),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // Fecha a tela de opções
                  // Abre o modal de pagamento Pix
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return _PaymentBottomSheet(
                        amount: amounts[index],
                        wallet: wallet,
                      );
                    },
                  );
                },
                child: Text(
                  "R\$ ${amounts[index].toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PaymentBottomSheet extends StatefulWidget {
  final double amount;
  final UserWalletModel wallet;

  const _PaymentBottomSheet({required this.amount, required this.wallet});

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  bool _isLoading = true;
  String? _error;
  String? _qrCodeBase64;
  String? _copiaCola;
  String? _txid;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      ).httpsCallable('createPixCharge').call({'amount': widget.amount});

      final data = result.data as Map<dynamic, dynamic>;

      if (mounted) {
        setState(() {
          _qrCodeBase64 = data['qrCodeImage'];
          _copiaCola = data['copiaCola'];
          _txid = data['txid'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else
            _buildPaymentState(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: const [
        CircularProgressIndicator(color: primaryAmber),
        SizedBox(height: 16),
        Text(
          "Gerando Cobrança Pix...",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
        const SizedBox(height: 16),
        const Text(
          "Erro ao gerar Pix",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? "Erro desconhecido",
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentState() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .doc(_txid)
          .snapshots(),
      builder: (context, snapshot) {
        String status = 'pending';
        if (snapshot.hasData && snapshot.data!.exists) {
          final transData = snapshot.data!.data() as Map<String, dynamic>;
          status = transData['status'] ?? 'pending';
        }

        if (status == 'approved') {
          return _buildSuccessState();
        }

        return Column(
          children: [
            const Text(
              "Pagamento Pix",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "R\$ ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')}",
              style: const TextStyle(
                color: primaryAmber,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (_qrCodeBase64 != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.memory(
                  base64Decode(_qrCodeBase64!.split(',').last),
                  height: 200,
                  width: 200,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryAmber,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Aguardando confirmação...",
                  style: TextStyle(color: primaryAmber, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.copy, color: Colors.black),
                label: const Text(
                  "COPIAR CÓDIGO PIX",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (_copiaCola != null) {
                    await Clipboard.setData(ClipboardData(text: _copiaCola!));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Código Pix copiado!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
        const SizedBox(height: 16),
        const Text(
          "Pagamento Confirmado!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "O valor de R\$ ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')} já está na sua carteira.",
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CONCLUIR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
