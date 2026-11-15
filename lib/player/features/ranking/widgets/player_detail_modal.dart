import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class PlayerDetailModal extends StatelessWidget {
  final RankingPlayerModel player;
  final RankingPlayerModel? leaderPlayer;
  final String eventName;

  const PlayerDetailModal({
    super.key,
    required this.player,
    this.leaderPlayer,
    required this.eventName,
  });

  static Future<void> show(
    BuildContext context, {
    required RankingPlayerModel player,
    RankingPlayerModel? leaderPlayer,
    required String eventName,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlayerDetailModal(
        player: player,
        leaderPlayer: leaderPlayer,
        eventName: eventName,
      ),
    );
  }

  Color _getRankColor() {
    switch (player.position) {
      case 1:
        return AppColors.amareloVale;
      case 2:
        return const Color(0xFFC0D3DA);
      case 3:
        return const Color(0xFFE09F67);
      default:
        if (player.position <= 10) return AppColors.verdeVale;
        return const Color(0xFF5A7982);
    }
  }

  String _getRankTitle() {
    switch (player.position) {
      case 1:
        return 'LÍDER • CAMPEÃO DO ENIGMA';
      case 2:
        return '2º LUGAR • VICE-CAMPEÃO';
      case 3:
        return '3º LUGAR • PÓDIO';
      default:
        if (player.position <= 10) return 'TOP 10 • EXPLORADOR DE ELITE';
        return '${player.position}º LUGAR • EXPLORADOR';
    }
  }

  FaIconData _getRankIcon() {
    switch (player.position) {
      case 1:
        return FontAwesomeIcons.crown;
      case 2:
        return FontAwesomeIcons.medal;
      case 3:
        return FontAwesomeIcons.award;
      default:
        if (player.position <= 10) return FontAwesomeIcons.solidStar;
        return FontAwesomeIcons.compass;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor();
    final differenceToLeader = leaderPlayer != null && leaderPlayer!.objectId != player.objectId
        ? leaderPlayer!.phasesCompleted - player.phasesCompleted
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: rankColor.withValues(alpha: 0.2),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rankColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(_getRankIcon(), size: 12, color: rankColor),
                const SizedBox(width: 8),
                Text(
                  _getRankTitle(),
                  style: GoogleFonts.cinzel(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: rankColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Avatar with Rank Aura
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFF0B1115),
              backgroundImage: player.photoURL != null ? NetworkImage(player.photoURL!) : null,
              child: player.photoURL == null
                  ? FaIcon(
                      FontAwesomeIcons.solidUser,
                      size: 34,
                      color: rankColor,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),

          // Player Name
          Text(
            player.name,
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Event Name
          Text(
            eventName,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.cinzaMedio,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Progress Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1115),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROGRESSO NA EXPEDIÇÃO',
                      style: GoogleFonts.cinzel(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cinzaMedio,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      '${player.progressPercent}%',
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: player.progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${player.phasesCompleted} de ${player.totalPhases} fases completadas',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2x2 Grid of Stats
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  icon: FontAwesomeIcons.trophy,
                  label: 'Posição Oficial',
                  value: '#${player.position}',
                  valueColor: rankColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  icon: FontAwesomeIcons.puzzlePiece,
                  label: 'Fases Superadas',
                  value: '${player.phasesCompleted}',
                  valueColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  icon: FontAwesomeIcons.clockRotateLeft,
                  label: 'Último Avanço',
                  value: player.formattedCompletionTime,
                  valueColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  icon: FontAwesomeIcons.bullseye,
                  label: 'Status Geral',
                  value: player.position == 1
                      ? 'Liderança'
                      : (differenceToLeader > 0
                          ? '-$differenceToLeader p/ líder'
                          : 'Top Rank'),
                  valueColor: player.position == 1 ? AppColors.amareloVale : AppColors.verdeVale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkCardColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
                elevation: 0,
              ),
              child: Text(
                'FECHAR',
                style: GoogleFonts.cinzel(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required FaIconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1115),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 14, color: AppColors.amareloVale),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.cinzel(
              fontSize: 9.5,
              color: AppColors.cinzaMedio,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
