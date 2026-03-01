import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class HomeProfileCard extends StatelessWidget {
  final Map<String, dynamic> playerData;
  final UserWalletModel wallet;
  final List<EventModel> events;
  final List<dynamic> allPlayers;

  const HomeProfileCard({
    super.key,
    required this.playerData,
    required this.wallet,
    required this.events,
    required this.allPlayers,
  });

  @override
  Widget build(BuildContext context) {
    final String firstName = wallet.name.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryAmber, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAmber.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: darkBackground,
                  backgroundImage:
                      (wallet.photoURL != null && wallet.photoURL!.isNotEmpty)
                      ? NetworkImage(wallet.photoURL!)
                      : null,
                  child: (wallet.photoURL == null || wallet.photoURL!.isEmpty)
                      ? const Icon(
                          Icons.person_outline,
                          color: secondaryTextColor,
                          size: 30,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $firstName!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, size: 14, color: primaryAmber),
                        const SizedBox(width: 4),
                        Text(
                          'Ranking: #${wallet.lastEventRank ?? '-'}',
                          style: const TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Saldo',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${wallet.balance.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      color: primaryAmber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
