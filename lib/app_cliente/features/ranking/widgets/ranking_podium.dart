import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class RankingPodium extends StatelessWidget {
  final List<RankingPlayerModel> top3;

  const RankingPodium({super.key, required this.top3});

  @override
  Widget build(BuildContext context) {
    // Definindo cores e estilos para os lugares (cores pastéis ou suaves)
    final podiumConfig = {
      1: {'color': const Color(0xFFFDE047), 'height': 160.0}, // Amarelo suave
      2: {'color': const Color(0xFFE2E8F0), 'height': 120.0}, // Cinza azulado claro
      3: {'color': const Color(0xFFFED7AA), 'height': 90.0}, // Laranja pastel
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
                  border: Border.all(color: color, width: isFirstPlace ? 4 : 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isFirstPlace ? 0.6 : 0.3),
                      blurRadius: isFirstPlace ? 25 : 15,
                      spreadRadius: isFirstPlace ? 4 : 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: isFirstPlace ? 40 : 30,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: player.photoURL != null
                      ? NetworkImage(player.photoURL!)
                      : null,
                  child: player.photoURL == null
                      ? FaIcon(
                          FontAwesomeIcons.solidUser,
                          size: isFirstPlace ? 30 : 20,
                          color: const Color(0xFF94A3B8),
                        )
                      : null,
                ),
              ),
              if (isFirstPlace)
                Positioned(
                  top: -55,
                  child: Lottie.asset(
                    'assets/animations/trofel.json',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),
              Positioned(
                bottom: -12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    "$placeº",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            player.name.split(' ').first,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
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
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32), // Mais arredondado para combinar com Home
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                  blurRadius: 15,
                  offset: const Offset(0, -5), // Sombra Neumórfica superior
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${player.phasesCompleted}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color, // Número usa a cor do troféu
                  ),
                ),
                Text(
                  'Fases',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
