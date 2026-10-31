import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_dialogs.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Card principal do desafio: Códice Ancestral / Pergaminho da Expedição
/// Estilo Indiana Jones / Tomb Raider com texturas de relíquia e cores Vale.
class EnigmaCard extends StatelessWidget {
  final EnigmaModel enigma;

  const EnigmaCard({super.key, required this.enigma});

  @override
  Widget build(BuildContext context) {
    final hasImage = enigma.imageUrl != null && enigma.imageUrl!.isNotEmpty;
    final hasAudio = enigma.audioUrl != null && enigma.audioUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.amareloVale.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.amareloVale.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cantoneiras ornamentadas de relíquia dourada
          Positioned.fill(
            child: CustomPaint(
              painter: RelicCornerPainter(
                color: AppColors.amareloVale.withValues(alpha: 0.40),
                cornerLength: 22,
                strokeWidth: 2.2,
                showStuds: true,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header do Códice
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.amareloVale.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.amareloVale.withValues(alpha: 0.6),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amareloVale.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.scroll,
                          color: AppColors.amareloVale,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CÓDICE ANCESTRAL',
                            style: GoogleFonts.cinzel(
                              color: AppColors.amareloVale,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Decifre as escrituras para localizar o tesouro sagrado',
                            style: GoogleFonts.poppins(
                              color: AppColors.cinzaMedio,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.verdeVale.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.ankh,
                            size: 11,
                            color: AppColors.verdeVale,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'RELÍQUIA',
                            style: GoogleFonts.cinzel(
                              color: AppColors.verdeVale,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Divisor Ornamental Antigo
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.amareloVale.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: FaIcon(
                        FontAwesomeIcons.gem,
                        size: 10,
                        color: AppColors.amareloVale.withValues(alpha: 0.7),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.amareloVale.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Manuscrito do Enigma (Estilo Tábua de Pedra / Pergaminho)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.amareloVale.withValues(alpha: 0.20),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        margin: const EdgeInsets.only(top: 4, right: 14),
                        decoration: BoxDecoration(
                          color: AppColors.amareloVale,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amareloVale.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        height: 52,
                      ),
                      Expanded(
                        child: MarkdownBody(
                          data: enigma.instruction,
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 14.5,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                            strong: GoogleFonts.cinzel(
                              color: AppColors.amareloVale,
                              fontWeight: FontWeight.w800,
                            ),
                            em: GoogleFonts.poppins(
                              color: AppColors.verdeValeLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Artefatos em Anexo (Fotos / Áudios)
                if (hasImage || hasAudio) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      if (hasImage)
                        _buildEvidenciaButton(
                          context,
                          icon: FontAwesomeIcons.image,
                          title: 'REGISTRO VISUAL',
                          subtitle: 'Ver foto do enigma',
                          color: AppColors.verdeVale,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            EnigmaDialogs.showMediaPreview(
                              context,
                              type: 'image',
                              url: enigma.imageUrl!,
                            );
                          },
                        ),
                      if (hasAudio)
                        _buildEvidenciaButton(
                          context,
                          icon: FontAwesomeIcons.headphones,
                          title: 'ECO ANCESTRAL',
                          subtitle: 'Ouvir pista sonora',
                          color: AppColors.amareloVale,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            EnigmaDialogs.showMediaPreview(
                              context,
                              type: 'audio',
                              url: enigma.audioUrl!,
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildEvidenciaButton(
    BuildContext context, {
    required dynamic icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
                ),
                child: Center(
                  child: FaIcon(icon, size: 14, color: color),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
