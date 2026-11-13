import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/hunter_share_card.dart';

void showCompletionDialog(
  BuildContext context, {
  required VoidCallback onOkPressed,
  required bool isPhaseComplete,
  String? eventTitle,
  double prizeWon = 0.0,
}) {
  if (isPhaseComplete) {
    SoundService.playVictory();
  } else {
    SoundService.playSuccess();
  }

  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Completion Dialog',
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (dialogCtx, anim1, anim2) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
        child: _CelebrationDialogContent(
          onOkPressed: onOkPressed,
          isPhaseComplete: isPhaseComplete,
          eventTitle: eventTitle,
          prizeWon: prizeWon,
        ),
      );
    },
  );
}

class _CelebrationDialogContent extends StatefulWidget {
  final VoidCallback onOkPressed;
  final bool isPhaseComplete;
  final String? eventTitle;
  final double prizeWon;

  const _CelebrationDialogContent({
    required this.onOkPressed,
    required this.isPhaseComplete,
    this.eventTitle,
    this.prizeWon = 0.0,
  });

  @override
  State<_CelebrationDialogContent> createState() => _CelebrationDialogContentState();
}

class _CelebrationDialogContentState extends State<_CelebrationDialogContent> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _openShareCard() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    final playerName = user?.get<String>('name') ?? user?.get<String>('username') ?? 'Explorador';
    final referralCode = user != null ? 'ENIGMA-${user.objectId!.substring(0, 6).toUpperCase()}' : null;

    if (mounted) {
      await HunterShareCard.show(
        context,
        playerName: playerName,
        eventTitle: widget.eventTitle ?? (widget.isPhaseComplete ? 'Fase Concluída' : 'Enigma Desvendado'),
        prizeWon: widget.prizeWon,
        referralCode: referralCode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: widget.isPhaseComplete
                  ? AppColors.amareloVale.withValues(alpha: 0.6)
                  : AppColors.verdeVale.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          backgroundColor: AppColors.darkCardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/check.json',
                  height: 110,
                  repeat: false,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isPhaseComplete ? 'Fase Concluída!' : 'Enigma Desvendado!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: widget.isPhaseComplete ? AppColors.amareloVale : AppColors.verdeVale,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isPhaseComplete
                      ? 'Você decifrou todas as pistas desta fase com maestria! O próximo estágio foi liberado.'
                      : 'Você encontrou a pista secreta e avançou no desafio!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                if (widget.prizeWon > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.verdeVale.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.coins, color: AppColors.amareloVale, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'Recompensa: R\$ ${widget.prizeWon.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: GoogleFonts.poppins(
                            color: AppColors.verdeVale,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Botão de Compartilhar Vitória
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openShareCard,
                    icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 14, color: AppColors.amareloVale),
                    label: Text(
                      'COMPARTILHAR CONQUISTA',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amareloVale,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.amareloVale.withValues(alpha: 0.8), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Botão Continuar
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AppColors.gradienteVerdeVale,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.verdeVale.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: widget.onOkPressed,
                    child: Text(
                      'CONTINUAR EXPEDIÇÃO',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Emissor de Confetti comemorativo no topo do diálogo
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            AppColors.amareloVale,
            AppColors.verdeVale,
            Colors.amber,
            Colors.white,
            Colors.orange,
          ],
        ),
      ],
    );
  }
}
