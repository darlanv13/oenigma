import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class RankingPodium extends StatelessWidget {
  final List<RankingPlayerModel> top3;

  const RankingPodium({super.key, required this.top3});

  @override
  Widget build(BuildContext context) {
    final podiumConfig = {
      1: {'color': AppColors.amareloVale, 'height': 150.0},
      2: {'color': AppColors.verdeVale, 'height': 115.0},
      3: {'color': const Color(0xFFE09F67), 'height': 90.0},
    };

    final List<Widget> podiumPlaces = [];

    // Ordem visual: 2º, 1º, 3º
    if (top3.length > 1) {
      podiumPlaces.add(
        _PodiumPlace(
          player: top3[1],
          height: podiumConfig[2]!['height'] as double,
          color: podiumConfig[2]!['color'] as Color,
          place: 2,
        ),
      );
    }
    if (top3.isNotEmpty) {
      podiumPlaces.add(
        _PodiumPlace(
          player: top3[0],
          height: podiumConfig[1]!['height'] as double,
          color: podiumConfig[1]!['color'] as Color,
          isFirstPlace: true,
          place: 1,
        ),
      );
    }
    if (top3.length > 2) {
      podiumPlaces.add(
        _PodiumPlace(
          player: top3[2],
          height: podiumConfig[3]!['height'] as double,
          color: podiumConfig[3]!['color'] as Color,
          place: 3,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: podiumPlaces,
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final RankingPlayerModel player;
  final double height;
  final Color color;
  final bool isFirstPlace;
  final int place;

  const _PodiumPlace({
    required this.player,
    required this.height,
    required this.color,
    this.isFirstPlace = false,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: isFirstPlace ? 3.5 : 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isFirstPlace ? 0.4 : 0.25),
                      blurRadius: isFirstPlace ? 18 : 10,
                      spreadRadius: isFirstPlace ? 2 : 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: isFirstPlace ? 38 : 28,
                  backgroundColor: AppColors.darkCardColor,
                  backgroundImage: player.photoURL != null
                      ? NetworkImage(player.photoURL!)
                      : null,
                  child: player.photoURL == null
                      ? FaIcon(
                          FontAwesomeIcons.solidUser,
                          size: isFirstPlace ? 26 : 18,
                          color: color,
                        )
                      : null,
                ),
              ),
              if (isFirstPlace)
                Positioned(
                  top: -50,
                  child: Lottie.asset(
                    'assets/animations/trofel.json',
                    width: 65,
                    height: 65,
                    fit: BoxFit.contain,
                  ),
                ),
              Positioned(
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    "$placeº",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            player.name.split(' ').first,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: height,
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${player.phasesCompleted}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  'Fases',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.cinzaMedio,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
