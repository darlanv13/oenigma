import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class EventRankingStatsCard extends StatelessWidget {
  final EventModel event;
  final int totalCompetitors;
  final int totalPhases;

  const EventRankingStatsCard({
    super.key,
    required this.event,
    required this.totalCompetitors,
    required this.totalPhases,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Prize
          _buildItem(
            icon: FontAwesomeIcons.trophy,
            iconColor: AppColors.amareloVale,
            label: 'Premiação',
            value: event.prize,
            valueColor: AppColors.amareloVale,
          ),
          _buildDivider(),
          // Competitors
          _buildItem(
            icon: FontAwesomeIcons.users,
            iconColor: AppColors.verdeVale,
            label: 'Competidores',
            value: '$totalCompetitors',
            valueColor: Colors.white,
          ),
          _buildDivider(),
          // Phases
          _buildItem(
            icon: FontAwesomeIcons.puzzlePiece,
            iconColor: const Color(0xFF00B4D8),
            label: 'Desafios',
            value: '$totalPhases fases',
            valueColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildItem({
    required FaIconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 12, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.orbitron(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.cinzel(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.cinzaMedio,
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
