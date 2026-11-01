import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/controllers/enigma_controller.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_dialogs.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_hint_dialog.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Seção de pistas e instrumentos: limpa, compacta e sem caixas excessivas.
class EnigmaHintsSection extends StatelessWidget {
  final EnigmaController controller;
  final VoidCallback onShake;
  final VoidCallback onEnigmaSolved;

  const EnigmaHintsSection({
    super.key,
    required this.controller,
    required this.onShake,
    required this.onEnigmaSolved,
  });

  @override
  Widget build(BuildContext context) {
    final enigma = controller.currentEnigma;
    final hasTools = enigma.hasMap || enigma.hasCompass || enigma.hasRadar;
    final hasHints = controller.hintsList.isNotEmpty;

    if (!hasHints && !hasTools && !controller.isLoadingHints) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho da Seção (Discreto)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.fire,
                  color: AppColors.amareloVale,
                  size: 11,
                ),
                const SizedBox(width: 8),
                Text(
                  'SEGREDOS & PISTAS',
                  style: GoogleFonts.cinzel(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            if (hasHints)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D24),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  '${controller.hintsList.length} ${controller.hintsList.length == 1 ? "PISTA" : "PISTAS"}',
                  style: GoogleFonts.cinzel(
                    color: AppColors.amareloVale,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // Estado de Carregamento
        if (controller.isLoadingHints)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF131D24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.amareloVale,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),

        // Listagem de Pistas (Design Plano e Direto)
        if (!controller.isLoadingHints && hasHints)
          ...controller.hintsList.asMap().entries.map((entry) {
            final int index = entry.key;
            final hint = entry.value;
            final isPurchased = controller.hintsPurchased.contains(hint.objectId);
            final price = hint.get<num>('price')?.toDouble() ?? 0.0;

            if (isPurchased || price <= 0.0) {
              // Pista Desbloqueada
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.verdeVale.withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.key,
                      color: AppColors.verdeVale,
                      size: 13,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SEGREDO REVELADO',
                            style: GoogleFonts.cinzel(
                              color: AppColors.verdeVale,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            hint.get<String>('title') ?? 'Pista disponível para leitura',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        EnigmaHintDialog.show(context, hint);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verdeVale,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        minimumSize: const Size(0, 32),
                      ),
                      child: Text(
                        'LER',
                        style: GoogleFonts.cinzel(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: (index * 60).ms);
            }

            // Pista Bloqueada
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF131D24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.lock,
                    color: AppColors.amareloVale,
                    size: 13,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERGAMINHO LACRADO',
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Desbloqueie para revelar a pista',
                          style: GoogleFonts.poppins(
                            color: AppColors.cinzaMedio,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () async {
                            final bool? confirmed =
                                await EnigmaDialogs.showPurchaseConfirmation(
                              context,
                              cost: price,
                              type: 'Pista Sagrada',
                            );
                            if (confirmed == true && context.mounted) {
                              controller.handleAction(
                                'purchaseHint',
                                context: context,
                                hintId: hint.objectId,
                                onEnigmaSolved: onEnigmaSolved,
                                onShake: onShake,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloVale,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      minimumSize: const Size(0, 32),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.coins, size: 10, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          'R\$ ${price.toStringAsFixed(2)}',
                          style: GoogleFonts.cinzel(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: (index * 60).ms);
          }),

        // Instrumentos Rápidos (Mapa, Bússola, Radar)
        if (hasTools) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (enigma.hasMap)
                Expanded(
                  child: _buildToolChip(
                    context: context,
                    title: 'MAPA',
                    icon: FontAwesomeIcons.mapLocationDot,
                    color: AppColors.verdeVale,
                    isPurchased: controller.hasMap,
                    price: enigma.mapPrice,
                    tabIndex: 2,
                    toolKey: 'map',
                  ),
                ),
              if (enigma.hasMap && (enigma.hasCompass || enigma.hasRadar))
                const SizedBox(width: 6),
              if (enigma.hasCompass)
                Expanded(
                  child: _buildToolChip(
                    context: context,
                    title: 'BÚSSOLA',
                    icon: FontAwesomeIcons.compass,
                    color: AppColors.amareloVale,
                    isPurchased: controller.hasCompass,
                    price: controller.compassPrice,
                    tabIndex: 1,
                    toolKey: 'compass',
                  ),
                ),
              if ((enigma.hasMap || enigma.hasCompass) && enigma.hasRadar)
                const SizedBox(width: 6),
              if (enigma.hasRadar)
                Expanded(
                  child: _buildToolChip(
                    context: context,
                    title: 'RADAR',
                    icon: FontAwesomeIcons.satelliteDish,
                    color: AppColors.verdeValeAlt,
                    isPurchased: controller.hasRadar,
                    price: enigma.radarPrice,
                    tabIndex: 1,
                    toolKey: 'radar',
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildToolChip({
    required BuildContext context,
    required String title,
    required dynamic icon,
    required Color color,
    required bool isPurchased,
    required double price,
    required int tabIndex,
    required String toolKey,
  }) {
    final bool isSelected = controller.selectedTacticalTab == tabIndex;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        if (isPurchased) {
          controller.setSelectedTacticalTab(tabIndex);
        } else {
          final bool? confirmed = await EnigmaDialogs.showPurchaseConfirmation(
            context,
            cost: price,
            type: title,
          );
          if (confirmed == true && context.mounted) {
            await controller.handleToolPurchase(toolKey, context);
            if (context.mounted) controller.setSelectedTacticalTab(tabIndex);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isPurchased
              ? (isSelected
                  ? color.withValues(alpha: 0.20)
                  : color.withValues(alpha: 0.10))
              : const Color(0xFF131D24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPurchased
                ? (isSelected ? color : color.withValues(alpha: 0.4))
                : Colors.white.withValues(alpha: 0.10),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 11),
            const SizedBox(width: 5),
            Text(
              title,
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9.5,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isPurchased ? 'ATIVO' : 'R\$${price.toInt()}',
              style: GoogleFonts.cinzel(
                color: isPurchased ? AppColors.verdeVale : AppColors.amareloVale,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
