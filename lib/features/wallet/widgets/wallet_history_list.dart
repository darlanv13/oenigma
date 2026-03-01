import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class WalletHistoryList extends StatelessWidget {
  final UserWalletModel wallet;

  const WalletHistoryList({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
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
          _HistoryItem(
            icon: Icons.bar_chart,
            title: 'Classificação em Evento',
            subtitle: 'Você ficou em #${wallet.lastEventRank}',
            color: Colors.lightBlueAccent,
          ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _HistoryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
