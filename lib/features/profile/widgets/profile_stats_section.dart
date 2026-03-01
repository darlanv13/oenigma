import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ProfileStatsSection extends StatelessWidget {
  final UserWalletModel wallet;

  const ProfileStatsSection({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Saldo',
            value: 'R\$ ${wallet.balance.toStringAsFixed(2)}',
            icon: Icons.wallet,
            color: primaryAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Ranking',
            value: '#${wallet.lastEventRank ?? '-'}',
            icon: Icons.bar_chart,
            color: Colors.lightBlueAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Vitórias',
            value: wallet.lastWonEventName != null ? "1" : "0",
            icon: Icons.emoji_events,
            color: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
