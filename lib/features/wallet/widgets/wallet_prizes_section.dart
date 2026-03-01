import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class WalletPrizesSection extends StatelessWidget {
  final UserWalletModel wallet;

  const WalletPrizesSection({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Prêmio Resgatado',
                  style: TextStyle(color: primaryAmber, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
