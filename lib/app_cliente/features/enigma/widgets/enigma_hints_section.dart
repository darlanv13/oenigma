import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/controllers/enigma_controller.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_dialogs.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_hint_dialog.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Seção com segredos ancestrais (pistas) e instrumentos de exploração (bússola, mapa, radar).
/// Estilo Caça ao Tesouro / Indiana Jones com cores Vale.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho da Seção de Pistas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.amareloVale.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.amareloVale.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.fire,
                      color: AppColors.amareloVale,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'SEGREDOS & PISTAS ANCESTRAIS',
                  style: GoogleFonts.cinzel(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            if (controller.hintsList.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amareloVale.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.amareloVale.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${controller.hintsList.length} ${controller.hintsList.length == 1 ? "SEGREDO" : "SEGREDOS"}',
                  style: GoogleFonts.cinzel(
                    color: AppColors.amareloVale,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),

        // Estado de Carregamento
        if (controller.isLoadingHints)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.2)),
            ),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.amareloVale,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),

        // Listagem de Pistas
        if (!controller.isLoadingHints && controller.hintsList.isNotEmpty)
          ...controller.hintsList.asMap().entries.map((entry) {
            final int index = entry.key;
            final hint = entry.value;
            final isPurchased = controller.hintsPurchased.contains(hint.objectId);
            final price = hint.get<num>('price')?.toDouble() ?? 0.0;

            if (isPurchased || price <= 0.0) {
              // Pista Desbloqueada (Gema Sagrada Verde-Vale)
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.verdeVale.withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.verdeVale.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.verdeVale, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.verdeVale.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.key,
                          color: AppColors.verdeVale,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'SEGREDO REVELADO',
                                style: GoogleFonts.cinzel(
                                  color: AppColors.verdeVale,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.verdeVale,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hint.get<String>('title') ?? 'Pista decifrada disponível',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        EnigmaHintDialog.show(context, hint);
                      },
                      icon: const FaIcon(FontAwesomeIcons.eye, size: 12),
                      label: Text(
                        'LER',
                        style: GoogleFonts.cinzel(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verdeVale,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms).slideX(begin: -0.04, end: 0);
            }

            // Pista Bloqueada (Pergaminho Lacrado em Ouro Asteca)
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.amareloVale.withValues(alpha: 0.40),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.amareloVale.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.amareloVale.withValues(alpha: 0.6),
                        width: 1.3,
                      ),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.lock,
                        color: AppColors.amareloVale,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERGAMINHO LACRADO',
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Desbloqueie para ler o segredo ancestral',
                          style: GoogleFonts.poppins(
                            color: AppColors.cinzaMedio,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: AppColors.gradienteAmareloVale,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amareloVale.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
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
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.coins, size: 11, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(
                            'R\$ ${price.toStringAsFixed(2)}',
                            style: GoogleFonts.cinzel(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms).slideX(begin: -0.04, end: 0);
          }),

        if (hasTools) ...[
          const SizedBox(height: 10),
          _buildToolsPurchaseButtons(context, enigma),
        ],
      ],
    );
  }

  Widget _buildToolsPurchaseButtons(BuildContext context, dynamic enigma) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.amareloVale,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'INSTRUMENTOS DE EXPEDIÇÃO',
              style: GoogleFonts.cinzel(
                color: AppColors.cinzaMedio,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (enigma.hasMap)
              Expanded(
                child: _buildToolQuickChip(
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
              const SizedBox(width: 8),
            if (enigma.hasCompass)
              Expanded(
                child: _buildToolQuickChip(
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
              const SizedBox(width: 8),
            if (enigma.hasRadar)
              Expanded(
                child: _buildToolQuickChip(
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
    );
  }

  Widget _buildToolQuickChip({
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
          if (toolKey == 'radar' &&
              controller.targetLatitude != null &&
              controller.targetLongitude != null) {
            EnigmaDialogs.openCompassExpanded(
              context,
              latitude: controller.targetLatitude!,
              longitude: controller.targetLongitude!,
              durationSeconds: controller.compassRemainingSeconds ?? controller.compassDuration,
              onTick: controller.updateCompassRemainingSeconds,
              onTimeUp: () => controller.onCompassTimeUp(context),
            );
          }
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isPurchased
              ? (isSelected
                  ? color.withValues(alpha: 0.25)
                  : color.withValues(alpha: 0.14))
              : AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPurchased
                ? (isSelected ? color : color.withValues(alpha: 0.55))
                : color.withValues(alpha: 0.30),
            width: isSelected ? 1.6 : 1.1,
          ),
          boxShadow: isPurchased && isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.30),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: color, size: 13),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPurchased
                      ? AppColors.verdeVale.withValues(alpha: 0.30)
                      : Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPurchased ? 'ATIVO' : 'R\$${price.toInt()}',
                  style: GoogleFonts.cinzel(
                    color: isPurchased ? AppColors.verdeVale : AppColors.amareloVale,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
