import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';

class WalletBalanceCard extends StatelessWidget {
  final UserWalletModel wallet;

  const WalletBalanceCard({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Fundo painel escuro
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.05),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'SALDO DISPONÍVEL',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'R\$ ${wallet.balance.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              color: const Color(0xFFFFD54F),
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              shadows: [
                Shadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
