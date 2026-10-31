import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class RankingList extends ConsumerWidget {
  final List<RankingPlayerModel> players;
  final ValueChanged<RankingPlayerModel>? onPlayerTap;
  final GlobalKey? userItemKey;

  const RankingList({
    super.key,
    required this.players,
    this.onPlayerTap,
    this.userItemKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.objectId;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final player = players[index];
        final isCurrentUser = player.objectId == currentUserId;
        final isTop10 = player.position <= 10;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            key: isCurrentUser ? userItemKey : null,
            onTap: () {
              SoundService.playClick();
              onPlayerTap?.call(player);
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF00383E),
                          Color(0xFF142023),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isCurrentUser ? null : AppColors.darkCardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCurrentUser
                      ? AppColors.verdeVale
                      : (isTop10
                          ? AppColors.verdeVale.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08)),
                  width: isCurrentUser ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCurrentUser
                        ? AppColors.verdeVale.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: isCurrentUser ? 12 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Position badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrentUser
                          ? AppColors.verdeVale.withValues(alpha: 0.2)
                          : (isTop10
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.transparent),
                    ),
                    child: Center(
                      child: Text(
                        "${player.position}º",
                        style: GoogleFonts.poppins(
                          color: isCurrentUser
                              ? AppColors.verdeVale
                              : (isTop10 ? Colors.white : AppColors.cinzaMedio),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrentUser
                                ? AppColors.verdeVale
                                : (isTop10
                                    ? AppColors.verdeVale.withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.15)),
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
                      if (isCurrentUser)
                        Positioned(
                          bottom: -2,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.verdeVale,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'VOCÊ',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Name & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                player.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isTop10 && !isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.verdeVale.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.verdeVale.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'TOP 10',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.verdeVale,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Mini progress bar + completion timestamp
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: player.progress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCurrentUser
                                        ? AppColors.verdeVale
                                        : (isTop10
                                            ? AppColors.verdeVale.withValues(alpha: 0.7)
                                            : Colors.white.withValues(alpha: 0.3)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              player.formattedCompletionTime,
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
                  ),
                  const SizedBox(width: 12),

                  // Phases Count
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${player.phasesCompleted}',
                        style: GoogleFonts.poppins(
                          color: isCurrentUser
                              ? AppColors.verdeVale
                              : (isTop10 ? Colors.white : AppColors.cinzaMedio),
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
                  const SizedBox(width: 4),
                  const FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 10,
                    color: Colors.white24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
