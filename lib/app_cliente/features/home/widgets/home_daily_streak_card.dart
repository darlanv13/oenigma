import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class HomeDailyStreakCard extends StatefulWidget {
  final int streakDays;
  final VoidCallback? onClaimReward;

  const HomeDailyStreakCard({
    super.key,
    this.streakDays = 5,
    this.onClaimReward,
  });

  @override
  State<HomeDailyStreakCard> createState() => _HomeDailyStreakCardState();
}

class _HomeDailyStreakCardState extends State<HomeDailyStreakCard> {
  bool _claimed = false;

  void _claim() {
    if (_claimed) return;
    HapticFeedback.heavyImpact();
    SoundService.playSuccess();
    setState(() => _claimed = true);
    widget.onClaimReward?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const FaIcon(FontAwesomeIcons.coins, color: AppColors.amareloVale, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Recompensa diária coletada! +50 Moedas Táticas adicionadas à sua carteira.',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F2B1D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fogo Animado / Contador
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1F1D17),
              border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const FaIcon(
              FontAwesomeIcons.fire,
              color: Colors.orangeAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Informações de Dias Consecutivos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SEQUÊNCIA DIÁRIA',
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4), width: 0.8),
                      ),
                      child: Text(
                        '${widget.streakDays} DIAS',
                        style: GoogleFonts.orbitron(
                          color: Colors.orangeAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _claimed
                    ? 'Recompensa de hoje resgatada! Volte amanhã para manter o fogo aceso.'
                    : 'Acesse todo dia para acumular moedas e usar ferramentas grátis!',
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Botão de Resgate
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _claimed ? const Color(0xFF1E3A45) : AppColors.amareloVale,
              foregroundColor: _claimed ? AppColors.cinzaMedio : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: _claim,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  _claimed ? FontAwesomeIcons.check : FontAwesomeIcons.gift,
                  size: 11,
                ),
                const SizedBox(width: 6),
                Text(
                  _claimed ? 'COLETADO' : '+50 TÁTICO',
                  style: GoogleFonts.orbitron(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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
