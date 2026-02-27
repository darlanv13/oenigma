import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../../stores/wallet_store.dart';

class PaymentBottomSheet extends StatefulWidget {
  final double amount;
  final UserWalletModel wallet;

  const PaymentBottomSheet({super.key, required this.amount, required this.wallet});

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  final WalletStore _store = WalletStore();

  @override
  void initState() {
    super.initState();
    _store.initiatePayment(widget.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Container(
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

            if (_store.paymentLoading)
              _buildLoadingState()
            else if (_store.paymentError != null)
              _buildErrorState()
            else
              _buildPaymentState(),

            const SizedBox(height: 20),
          ],
        ),
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
          _store.paymentError ?? "Erro desconhecido",
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
          .doc(_store.txid)
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
            if (_store.qrCodeBase64 != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.memory(
                  base64Decode(_store.qrCodeBase64!.split(',').last),
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
                  if (_store.copiaCola != null) {
                    await Clipboard.setData(ClipboardData(text: _store.copiaCola!));
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
