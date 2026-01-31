import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_wallet_model.dart';
import '../../utils/app_colors.dart';

class WalletScreen extends StatelessWidget {
  final UserWalletModel wallet;

  const WalletScreen({super.key, required this.wallet});

  void _buyCredits(BuildContext context, double amount) async {
    // Exibe o BottomSheet imediatamente com estado de carregamento
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentBottomSheet(amount: amount, wallet: wallet),
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
          _buildProfileHeader(wallet),
          const SizedBox(height: 24),
          _buildBalanceCard(context, wallet.balance),
          const SizedBox(height: 24),
          _buildSectionTitle('ADICIONAR SALDO'),
          const SizedBox(height: 12),
          _buildCreditOptions(context),
          const SizedBox(height: 24),
          _buildSectionTitle('ÚLTIMO PRÉMIO'),
          const SizedBox(height: 12),
          _buildPrizesCard(wallet.lastWonEventName),
          const SizedBox(height: 24),
          _buildSectionTitle('ESTATÍSTICAS'),
          const SizedBox(height: 12),
          _buildStatsCard(wallet.lastEventRank, wallet.lastEventName),
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

  Widget _buildBalanceCard(BuildContext context, double initialBalance) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('players')
          .doc(wallet.uid)
          .snapshots(),
      builder: (context, snapshot) {
        double currentBalance = initialBalance;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['balance'] != null) {
            currentBalance = (data['balance'] as num).toDouble();
          }
        }

        return Container(
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
                    'R\$ ${currentBalance.toStringAsFixed(2).replaceAll('.', ',')}',
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
        );
      },
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

// ============================================================================
// WIDGET DO BOTTOM SHEET DE PAGAMENTO
// ============================================================================
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
          // Handle Bar
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
        Text(
          "Erro ao gerar Pix",
          style: const TextStyle(
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
