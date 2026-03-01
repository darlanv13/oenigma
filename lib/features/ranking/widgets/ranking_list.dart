import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';

class RankingList extends ConsumerWidget {
  final List<RankingPlayerModel> players;

  const RankingList({super.key, required this.players});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final player = players[index];
        final isCurrentUser = player.uid == currentUserId;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isCurrentUser
                ? Border.all(color: primaryAmber, width: 1.5)
                : Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: isCurrentUser
                ? [
                    BoxShadow(
                      color: primaryAmber.withValues(alpha: 0.15),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  player.position.toString(),
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentUser ? primaryAmber : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: player.photoURL != null
                      ? NetworkImage(player.photoURL!)
                      : null,
                  child: player.photoURL == null
                      ? const Icon(
                          Icons.person,
                          size: 20,
                          color: secondaryTextColor,
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
                      player.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${player.phasesCompleted}',
                    style: const TextStyle(
                      color: primaryAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Fases',
                    style: TextStyle(color: secondaryTextColor, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
