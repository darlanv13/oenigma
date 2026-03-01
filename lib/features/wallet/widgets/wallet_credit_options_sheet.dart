import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class CreditOptionsSheet extends StatelessWidget {
  final UserWalletModel wallet;

  const CreditOptionsSheet({super.key, required this.wallet});

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
                      return PaymentBottomSheet(
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

class PaymentBottomSheet extends StatefulWidget {
  final double amount;
  final UserWalletModel wallet;

  const PaymentBottomSheet({super.key, required this.amount, required this.wallet});

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
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
    return const Column(
      children: [
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    if (context.mounted) {
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
