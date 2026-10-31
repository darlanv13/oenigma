import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/controllers/enigma_controller.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Barra superior de expedição antiga (Estilo Indiana Jones / Tomb Raider / Cores Vale).
class EnigmaHeader extends StatelessWidget {
  final EnigmaController controller;

  const EnigmaHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isClassic = controller.isClassic;
    final enigma = controller.currentEnigma;
    final isBlocked = controller.isBlocked;
    final distance = controller.distance;

    final String titleText = enigma.type == 'qrcode'
        ? "RELÍQUIA SAGRADA"
        : controller.phase.id == 'find_and_win'
            ? (enigma.title.isNotEmpty ? enigma.title : "BAÚ DO TESOURO")
            : "CÂMARA ${controller.phase.order} • ENIGMA ${controller.phase.enigmas.indexOf(enigma) + 1}";

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkBackground.withValues(alpha: 0.90),
            border: Border(
              bottom: BorderSide(
                color: AppColors.amareloVale.withValues(alpha: 0.35),
                width: 1.4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Botão Voltar (Amuleto do Explorador)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.darkCardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.amareloVale.withValues(alpha: 0.6),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amareloVale.withValues(alpha: 0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.chevronLeft,
                          color: AppColors.amareloVale,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Título Central com Medalhão de Modalidade
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge de Expedição / Caça ao Tesouro
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isClassic ? AppColors.verdeVale : AppColors.amareloVale)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (isClassic ? AppColors.verdeVale : AppColors.amareloVale)
                                .withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              isClassic ? FontAwesomeIcons.compass : FontAwesomeIcons.gem,
                              size: 10,
                              color: isClassic ? AppColors.verdeVale : AppColors.amareloVale,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isClassic ? 'EXPEDIÇÃO CLÁSSICA' : 'CAÇA AO TESOURO',
                              style: GoogleFonts.cinzel(
                                color: isClassic ? AppColors.verdeVale : AppColors.amareloVale,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          titleText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Talismã de Proximidade / Status da Jornada
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isBlocked
                        ? AppColors.danger.withValues(alpha: 0.18)
                        : (distance != null
                            ? AppColors.amareloVale.withValues(alpha: 0.18)
                            : AppColors.verdeVale.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isBlocked
                          ? AppColors.danger
                          : (distance != null ? AppColors.amareloVale : AppColors.verdeVale),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isBlocked
                                ? AppColors.danger
                                : (distance != null ? AppColors.amareloVale : AppColors.verdeVale))
                            .withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        isBlocked
                            ? FontAwesomeIcons.hourglassHalf
                            : (distance != null
                                ? FontAwesomeIcons.locationArrow
                                : FontAwesomeIcons.fire),
                        size: 11,
                        color: isBlocked
                            ? AppColors.danger
                            : (distance != null ? AppColors.amareloVale : AppColors.verdeVale),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isBlocked
                            ? 'AGUARDE'
                            : (distance != null ? '${distance.toInt()}m' : 'EM JORNADA'),
                        style: GoogleFonts.cinzel(
                          color: isBlocked
                              ? AppColors.danger
                              : (distance != null ? AppColors.amareloVale : AppColors.verdeVale),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).scaleXY(
                  begin: 1.0,
                  end: 1.03,
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
