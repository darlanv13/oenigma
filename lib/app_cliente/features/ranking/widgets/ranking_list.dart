import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class RankingList extends ConsumerWidget {
  final List<RankingPlayerModel> players;

  const RankingList({super.key, required this.players});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref
        .read(authRepositoryProvider)
        .currentUser
        ?.objectId;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final player = players[index];
        final isCurrentUser = player.objectId == currentUserId;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: isCurrentUser
                ? Border.all(color: const Color(0xFF8B5CF6), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  player.position.toString(),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
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
                    color: isCurrentUser ? const Color(0xFF8B5CF6) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: player.photoURL != null
                      ? NetworkImage(player.photoURL!)
                      : null,
                  child: player.photoURL == null
                      ? const FaIcon(
                          FontAwesomeIcons.solidUser,
                          size: 20,
                          color: Color(0xFF94A3B8),
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
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF1E293B),
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
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8B5CF6),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Fases',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10),
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
