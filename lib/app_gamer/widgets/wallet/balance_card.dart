import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../../stores/wallet_store.dart';

class BalanceCard extends StatelessWidget {
  final WalletStore store;
  final VoidCallback onWithdraw;

  const BalanceCard({
    super.key,
    required this.store,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
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
                  'R\$ ${store.balance.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: primaryAmber,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: onWithdraw,
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
}
