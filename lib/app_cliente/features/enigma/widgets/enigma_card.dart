import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_dialogs.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Card do desafio: Códice Ancestral limpo, moderno e sem poluição visual.
class EnigmaCard extends StatelessWidget {
  final EnigmaModel enigma;

  const EnigmaCard({super.key, required this.enigma});

  @override
  Widget build(BuildContext context) {
    final hasImage = enigma.imageUrl != null && enigma.imageUrl!.isNotEmpty;
    final hasAudio = enigma.audioUrl != null && enigma.audioUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header do Códice (Protegido contra overflow)
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.amareloVale.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.amareloVale.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.scroll,
                      color: AppColors.amareloVale,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CÓDICE ANCESTRAL',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cinzel(
                          color: AppColors.amareloVale,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Decifre o manuscrito para localizar o tesouro',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: AppColors.cinzaMedio,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.verdeVale.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.verdeVale.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.gem,
                        size: 9,
                        color: AppColors.verdeVale,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'RELÍQUIA',
                        style: GoogleFonts.cinzel(
                          color: AppColors.verdeVale,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Linha divisória sutil
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),

            const SizedBox(height: 14),

            // Manuscrito do Enigma (Sem caixas aninhadas, texto fluido e respirável)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
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

            // Pílulas de Mídia Anexa (se houver imagem ou áudio)
            if (hasImage || hasAudio) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (hasImage) ...[
                    Expanded(
                      child: _buildMediaPill(
                        context,
                        icon: FontAwesomeIcons.image,
                        label: 'Ver Imagem',
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
                    ),
                    if (hasAudio) const SizedBox(width: 10),
                  ],
                  if (hasAudio)
                    Expanded(
                      child: _buildMediaPill(
                        context,
                        icon: FontAwesomeIcons.headphones,
                        label: 'Ouvir Áudio',
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
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildMediaPill(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.40),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 12, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
