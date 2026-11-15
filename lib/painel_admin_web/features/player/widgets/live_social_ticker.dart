import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class LiveSocialTicker extends StatefulWidget {
  final String challengeTitle;
  final String prize;
  final int initialExplorers;

  const LiveSocialTicker({
    super.key,
    required this.challengeTitle,
    required this.prize,
    this.initialExplorers = 142,
  });

  @override
  State<LiveSocialTicker> createState() => _LiveSocialTickerState();
}

class _LiveSocialTickerState extends State<LiveSocialTicker>
    with SingleTickerProviderStateMixin {
  late Timer _tickerTimer;
  int _currentIndex = 0;
  late final List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        'icon': FontAwesomeIcons.fire,
        'color': Colors.orangeAccent,
        'badge': 'EM ALTA',
        'badgeColor': Colors.orangeAccent,
        'text': 'Mais de ${widget.initialExplorers} caçadores decifrando agora',
      },
      {
        'icon': FontAwesomeIcons.bolt,
        'color': AppColors.amareloVale,
        'badge': 'AO VIVO',
        'badgeColor': AppColors.amareloVale,
        'text': '@marcos_09 tentou a Cifra de César há 28 segundos',
      },
      {
        'icon': FontAwesomeIcons.vault,
        'color': Colors.greenAccent,
        'badge': 'COFRE PIX',
        'badgeColor': Colors.greenAccent,
        'text': 'Prêmio de ${widget.prize} aguarda o 1º colocado!',
      },
      {
        'icon': FontAwesomeIcons.unlock,
        'color': Colors.lightBlueAccent,
        'badge': 'ARSENAL',
        'badgeColor': Colors.lightBlueAccent,
        'text': 'Super Dicas desbloqueadas recentemente por 14 detetives',
      },
      {
        'icon': FontAwesomeIcons.trophy,
        'color': AppColors.amareloVale,
        'badge': 'OPORTUNIDADE',
        'badgeColor': AppColors.amareloVale,
        'text': 'O cofre ainda está trancado. Seja você o campeão!',
      },
    ];

    _tickerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _messages[_currentIndex];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D161C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (current['color'] as Color).withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (current['color'] as Color).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Row(
          key: ValueKey<int>(_currentIndex),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (current['badgeColor'] as Color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: (current['badgeColor'] as Color).withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    current['icon'] as dynamic,
                    size: 9,
                    color: current['badgeColor'] as Color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    current['badge'] as String,
                    style: GoogleFonts.orbitron(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: current['badgeColor'] as Color,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                current['text'] as String,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
