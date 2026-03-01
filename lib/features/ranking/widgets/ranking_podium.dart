import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class RankingPodium extends StatelessWidget {
  final List<RankingPlayerModel> top3;

  const RankingPodium({super.key, required this.top3});

  @override
  Widget build(BuildContext context) {
    // Definindo cores e estilos para os lugares
    final podiumConfig = {
      1: {'color': const Color(0xFFFFC107), 'height': 160.0}, // Ouro
      2: {'color': const Color(0xFFE0E0E0), 'height': 120.0}, // Prata
      3: {'color': const Color(0xFFA1887F), 'height': 90.0}, // Bronze
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
                  border: Border.all(color: color, width: 3),
                  boxShadow: isFirstPlace
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: CircleAvatar(
                  radius: isFirstPlace ? 40 : 30,
                  backgroundColor: darkBackground,
                  backgroundImage: player.photoURL != null
                      ? NetworkImage(player.photoURL!)
                      : null,
                  child: player.photoURL == null
                      ? Icon(
                          Icons.person,
                          size: isFirstPlace ? 30 : 20,
                          color: secondaryTextColor,
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
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$placeº",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            player.name.split(' ').first,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.3)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
                left: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
                right: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${player.phasesCompleted}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Fases',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
