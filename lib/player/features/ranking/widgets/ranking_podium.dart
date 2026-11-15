import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class RankingPodium extends StatelessWidget {
  final List<RankingPlayerModel> top3;
  final ValueChanged<RankingPlayerModel>? onPlayerTap;
  final VoidCallback? onCelebrateFirstPlace;

  const RankingPodium({
    super.key,
    required this.top3,
    this.onPlayerTap,
    this.onCelebrateFirstPlace,
  });

  @override
  Widget build(BuildContext context) {
    final podiumConfig = {
      1: {
        'accentColor': AppColors.amareloVale,
        'borderColor': const Color(0xFFFFC107),
        'pedestalGradient': const [Color(0xFF2C2210), Color(0xFF1A1409)],
        'height': 155.0,
      },
      2: {
        'accentColor': const Color(0xFFB0BEC5),
        'borderColor': const Color(0xFFCFD8DC),
        'pedestalGradient': const [Color(0xFF1B2628), Color(0xFF11191A)],
        'height': 120.0,
      },
      3: {
        'accentColor': const Color(0xFFE09F67),
        'borderColor': const Color(0xFFFFB74D),
        'pedestalGradient': const [Color(0xFF281C16), Color(0xFF18100C)],
        'height': 95.0,
      },
    };

    final List<Widget> podiumPlaces = [];

    // Ordem visual clássica: 2º (esquerda), 1º (centro), 3º (direita)
    if (top3.length > 1) {
      podiumPlaces.add(
        _PodiumPlace(
          player: top3[1],
          height: podiumConfig[2]!['height'] as double,
          accentColor: podiumConfig[2]!['accentColor'] as Color,
          borderColor: podiumConfig[2]!['borderColor'] as Color,
          gradient: podiumConfig[2]!['pedestalGradient'] as List<Color>,
          place: 2,
          animationDelayMs: 150,
          onTap: () {
            SoundService.playClick();
            onPlayerTap?.call(top3[1]);
          },
        ),
      );
    }
    if (top3.isNotEmpty) {
      podiumPlaces.add(
        _PodiumPlace(
          player: top3[0],
          height: podiumConfig[1]!['height'] as double,
          accentColor: podiumConfig[1]!['accentColor'] as Color,
          borderColor: podiumConfig[1]!['borderColor'] as Color,
          gradient: podiumConfig[1]!['pedestalGradient'] as List<Color>,
          isFirstPlace: true,
          place: 1,
          animationDelayMs: 0,
          onTap: () {
            SoundService.playVictory();
            onCelebrateFirstPlace?.call();
            onPlayerTap?.call(top3[0]);
          },
        ),
      );
    }
    if (top3.length > 2) {
      podiumPlaces.add(
        _PodiumPlace(
          player: top3[2],
          height: podiumConfig[3]!['height'] as double,
          accentColor: podiumConfig[3]!['accentColor'] as Color,
          borderColor: podiumConfig[3]!['borderColor'] as Color,
          gradient: podiumConfig[3]!['pedestalGradient'] as List<Color>,
          place: 3,
          animationDelayMs: 300,
          onTap: () {
            SoundService.playClick();
            onPlayerTap?.call(top3[2]);
          },
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
  final Color accentColor;
  final Color borderColor;
  final List<Color> gradient;
  final bool isFirstPlace;
  final int place;
  final int animationDelayMs;
  final VoidCallback onTap;

  const _PodiumPlace({
    required this.player,
    required this.height,
    required this.accentColor,
    required this.borderColor,
    required this.gradient,
    this.isFirstPlace = false,
    required this.place,
    required this.animationDelayMs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + animationDelayMs),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              alignment: Alignment.bottomCenter,
              child: child,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar & Crown/Trophy
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Glow background aura
                  Container(
                    width: isFirstPlace ? 88 : 68,
                    height: isFirstPlace ? 88 : 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: isFirstPlace ? 0.35 : 0.2),
                          blurRadius: isFirstPlace ? 24 : 14,
                          spreadRadius: isFirstPlace ? 4 : 2,
                        ),
                      ],
                    ),
                  ),

                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: isFirstPlace ? 3.5 : 2.5,
                      ),
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
                              color: accentColor,
                            )
                          : null,
                    ),
                  ),

                  // Lottie Trophy or Crown for 1st Place
                  if (isFirstPlace)
                    Positioned(
                      top: -48,
                      child: Lottie.asset(
                        'assets/animations/trofel.json',
                        width: 68,
                        height: 68,
                        fit: BoxFit.contain,
                      ),
                    ),

                  // Place Badge Pill
                  Positioned(
                    bottom: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor,
                            borderColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isFirstPlace) ...[
                            const FaIcon(
                              FontAwesomeIcons.crown,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            "$placeº",
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Player Name
              Text(
                player.name.split(' ').first,
                style: GoogleFonts.cinzel(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 3D Styled Pedestal
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: borderColor.withValues(alpha: isFirstPlace ? 0.6 : 0.4),
                    width: isFirstPlace ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isFirstPlace ? 0.2 : 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Watermarked Rank Number
                    Positioned(
                      bottom: 4,
                      child: Text(
                        '$place',
                        style: GoogleFonts.orbitron(
                          fontSize: isFirstPlace ? 64 : 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),

                    // Pedestal Content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${player.phasesCompleted}',
                          style: GoogleFonts.orbitron(
                            fontSize: isFirstPlace ? 22 : 18,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        Text(
                          'FASES',
                          style: GoogleFonts.cinzel(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.cinzaMedio,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${player.progressPercent}%',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
