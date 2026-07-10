import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, Color(0xFF2C2C2C), cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryAmber.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryAmber.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
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
                      ? const FaIcon(
                          FontAwesomeIcons.user,
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
                        const FaIcon(
                          FontAwesomeIcons.trophy,
                          size: 14,
                          color: primaryAmber,
                        ),
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
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${wallet.balance.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      color: primaryAmber,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: primaryAmber.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
