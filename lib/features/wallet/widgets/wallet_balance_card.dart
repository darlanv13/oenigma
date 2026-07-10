import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class WalletBalanceCard extends StatelessWidget {
  final UserWalletModel wallet;

  const WalletBalanceCard({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, const Color(0xFF2C2C2C), cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: primaryAmber.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryAmber.withValues(alpha: 0.05),
            blurRadius: 25,
            spreadRadius: 2,
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
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'R\$ ${wallet.balance.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              color: primaryAmber,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              shadows: [
                Shadow(
                  color: primaryAmber.withValues(alpha: 0.4),
                  blurRadius: 15,
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
