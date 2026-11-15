import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class UserRankHighlightCard extends StatelessWidget {
  final RankingPlayerModel? userPlayer;
  final bool isGuest;
  final int? podiumThresholdPhases;
  final VoidCallback? onScrollToUser;
  final VoidCallback? onViewDetails;

  const UserRankHighlightCard({
    super.key,
    required this.userPlayer,
    required this.isGuest,
    this.podiumThresholdPhases,
    this.onScrollToUser,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131D24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amareloVale.withValues(alpha: 0.15),
              ),
              child: const FaIcon(
                FontAwesomeIcons.rightToBracket,
                size: 16,
                color: AppColors.amareloVale,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo Visitante',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Faça login para pontuar no ranking e concorrer aos prêmios.',
                    style: GoogleFonts.inter(
                      color: AppColors.cinzaMedio,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (userPlayer == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131D24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.verdeVale.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
              ),
              child: const FaIcon(
                FontAwesomeIcons.compass,
                size: 20,
                color: AppColors.verdeVale,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Você ainda não pontuou',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Resolva enigmas do evento para registrar seu nome no ranking!',
                    style: GoogleFonts.inter(
                      color: AppColors.cinzaMedio,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final player = userPlayer!;
    final phasesToPodium = podiumThresholdPhases != null && podiumThresholdPhases! > player.phasesCompleted
        ? podiumThresholdPhases! - player.phasesCompleted + 1
        : 0;

    String motivationalMessage;
    if (player.position == 1) {
      motivationalMessage = '👑 Você lidera este evento! Mantenha a velocidade.';
    } else if (player.position <= 3) {
      motivationalMessage = '🏆 Você está no Pódio! Rumo ao 1º lugar.';
    } else if (phasesToPodium > 0) {
      motivationalMessage = '🔥 Apenas $phasesToPodium fase(s) para alcançar o Pódio!';
    } else {
      motivationalMessage = '⭐ Desempenho sólido! Continue avançando nas fases.';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00383E),
            Color(0xFF142023),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.verdeVale.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.verdeVale, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.verdeVale.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.darkCardColor,
                      backgroundImage: player.photoURL != null ? NetworkImage(player.photoURL!) : null,
                      child: player.photoURL == null
                          ? const FaIcon(
                              FontAwesomeIcons.solidUser,
                              size: 16,
                              color: AppColors.verdeVale,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VOCÊ',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.name,
                            style: GoogleFonts.cinzel(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: player.position <= 3
                                ? AppColors.amareloVale.withValues(alpha: 0.2)
                                : AppColors.verdeVale.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: player.position <= 3
                                  ? AppColors.amareloVale
                                  : AppColors.verdeVale,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '#${player.position}º LUGAR',
                            style: GoogleFonts.orbitron(
                              color: player.position <= 3
                                  ? AppColors.amareloVale
                                  : AppColors.verdeVale,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      motivationalMessage,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: player.progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.verdeVale),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${player.phasesCompleted} de ${player.totalPhases} fases resolvidas',
                style: GoogleFonts.inter(
                  color: AppColors.cinzaMedio,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  if (onScrollToUser != null)
                    InkWell(
                      onTap: () {
                        SoundService.playClick();
                        onScrollToUser!();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.crosshairs,
                              size: 11,
                              color: AppColors.verdeVale,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Localizar',
                              style: GoogleFonts.inter(
                                color: AppColors.verdeVale,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (onViewDetails != null) ...[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        SoundService.playClick();
                        onViewDetails!();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.circleInfo,
                              size: 11,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Detalhes',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
