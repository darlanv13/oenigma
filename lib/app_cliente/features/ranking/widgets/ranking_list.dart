import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
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
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final player = players[index];
        final isCurrentUser = player.objectId == currentUserId;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? AppColors.verdeVale.withValues(alpha: 0.15)
                : AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrentUser
                  ? AppColors.verdeVale
                  : Colors.white.withValues(alpha: 0.08),
              width: isCurrentUser ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrentUser
                    ? AppColors.verdeVale.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  "${player.position}º",
                  style: GoogleFonts.poppins(
                    color: isCurrentUser ? AppColors.verdeVale : AppColors.cinzaMedio,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentUser ? AppColors.verdeVale : Colors.white.withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  backgroundImage: player.photoURL != null
                      ? NetworkImage(player.photoURL!)
                      : null,
                  child: player.photoURL == null
                      ? const FaIcon(
                          FontAwesomeIcons.solidUser,
                          size: 16,
                          color: AppColors.verdeVale,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
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
                      color: AppColors.verdeVale,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Fases',
                    style: GoogleFonts.inter(
                      color: AppColors.cinzaMedio,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
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
