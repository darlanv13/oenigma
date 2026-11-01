import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/controllers/enigma_controller.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Barra superior de expedição: moderna, limpa e sem poluição visual.
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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1115).withValues(alpha: 0.90),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Botão Voltar Redondo e Discreto
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D24),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.chevronLeft,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Título Central com Pill de Modalidade
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: (isClassic ? AppColors.verdeVale : AppColors.amareloVale)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isClassic ? AppColors.verdeVale : AppColors.amareloVale)
                                .withValues(alpha: 0.40),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              isClassic ? FontAwesomeIcons.compass : FontAwesomeIcons.gem,
                              size: 9,
                              color: isClassic ? AppColors.verdeVale : AppColors.amareloVale,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isClassic ? 'EXPEDIÇÃO CLÁSSICA' : 'CAÇA AO TESOURO',
                              style: GoogleFonts.cinzel(
                                color: isClassic ? AppColors.verdeVale : AppColors.amareloVale,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Pill de Proximidade / Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isBlocked
                          ? AppColors.danger.withValues(alpha: 0.6)
                          : (distance != null
                              ? AppColors.amareloVale.withValues(alpha: 0.5)
                              : AppColors.verdeVale.withValues(alpha: 0.4)),
                      width: 1.0,
                    ),
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
                        size: 10,
                        color: isBlocked
                            ? AppColors.danger
                            : (distance != null ? AppColors.amareloVale : AppColors.verdeVale),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isBlocked
                            ? 'PAUSA'
                            : (distance != null ? '${distance.toInt()}m' : 'EM JORNADA'),
                        style: GoogleFonts.cinzel(
                          color: isBlocked
                              ? AppColors.danger
                              : (distance != null ? AppColors.amareloVale : AppColors.verdeVale),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
