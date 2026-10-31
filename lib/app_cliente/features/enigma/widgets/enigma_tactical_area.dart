import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/controllers/enigma_controller.dart';
import 'package:oenigma/app_cliente/features/enigma/screens/scanner_screen.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/compass_widget.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_dialogs.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/map_radius_widget.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Câmara da Relíquia & Validação: Estilo Indiana Jones / Tomb Raider com cores Vale.
/// Possui Instinto do Explorador (Proximidade Quente/Frio), Selo da Relíquia, Bússola e Mapa.
class EnigmaTacticalArea extends StatelessWidget {
  final EnigmaController controller;
  final VoidCallback onShake;
  final VoidCallback onEnigmaSolved;

  const EnigmaTacticalArea({
    super.key,
    required this.controller,
    required this.onShake,
    required this.onEnigmaSolved,
  });

  @override
  Widget build(BuildContext context) {
    final isGpsEnigma = controller.isGpsEnigma;
    final isActionReady = controller.isActionReady;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.verdeVale.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cantoneiras ornamentadas de relíquia esmeralda
          Positioned.fill(
            child: CustomPaint(
              painter: RelicCornerPainter(
                color: AppColors.verdeVale.withValues(alpha: 0.35),
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
                // Top Header da Câmara da Relíquia
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.verdeVale.withValues(alpha: 0.6),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.verdeVale.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.landmark,
                          color: AppColors.verdeVale,
                          size: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CÂMARA DA RELÍQUIA',
                            style: GoogleFonts.cinzel(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Instinto do explorador, bússola dourada & revelação',
                            style: GoogleFonts.poppins(
                              color: AppColors.cinzaMedio,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 1. Instinto do Explorador (Proximidade Quente & Frio com Gemas Sagradas)
                _buildExplorerInstinctBar(isGpsEnigma),

                const SizedBox(height: 16),

                // 2. Seletor de Instrumentos da Expedição
                _buildExpeditionTabSelector(isActionReady),

                const SizedBox(height: 18),

                // 3. Conteúdo do Instrumento Ativo
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentExpeditionContent(context, isActionReady, isGpsEnigma),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  // --- INSTINTO DO EXPLORADOR (HOT & COLD COM GEMAS SAGRADAS E TOCHAS) ---
  Widget _buildExplorerInstinctBar(bool isGpsEnigma) {
    final distance = controller.distance;

    if (!isGpsEnigma && distance == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.verdeVale.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.5)),
              ),
              child: const FaIcon(
                FontAwesomeIcons.gem,
                color: AppColors.verdeVale,
                size: 16,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REVELAÇÃO DE RELÍQUIA FÍSICA',
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Aponte a lente para o selo físico gravado ou inscreva o código.',
                    style: GoogleFonts.poppins(
                      color: AppColors.cinzaMedio,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    int gemLevel = 1;
    String instinctTitle = 'TRILHA DA EXPEDIÇÃO';
    String instinctSubtitle = 'Sintonizando instinto e bússola com a relíquia...';
    Color instinctColor = AppColors.cinzaMedio;
    dynamic instinctIcon = FontAwesomeIcons.compass;

    if (distance != null) {
      if (distance <= 25) {
        gemLevel = 5;
        instinctTitle = 'RELÍQUIA AO SEU ALCANCE!';
        instinctSubtitle = 'O tesouro está a poucos passos! Procure a marca sagrada.';
        instinctColor = AppColors.verdeVale;
        instinctIcon = FontAwesomeIcons.bullseye;
      } else if (distance <= 75) {
        gemLevel = 4;
        instinctTitle = 'FERVENDO! MUITO PRÓXIMO';
        instinctSubtitle = 'Faltam ${distance.toInt()}m. Você está na câmara exata do tesouro!';
        instinctColor = AppColors.amareloVale;
        instinctIcon = FontAwesomeIcons.fire;
      } else if (distance <= 150) {
        gemLevel = 3;
        instinctTitle = 'AQUECENDO • PASSO CERTO';
        instinctSubtitle = 'Distância estimada: ${distance.toInt()} metros até o local.';
        instinctColor = AppColors.amareloValeAlt;
        instinctIcon = FontAwesomeIcons.personWalking;
      } else if (distance <= 300) {
        gemLevel = 2;
        instinctTitle = 'TRILHA FRIA • MANTENHA A DIREÇÃO';
        instinctSubtitle = 'A relíquia repousa a ${distance.toInt()} metros à frente.';
        instinctColor = AppColors.cinzaMedio;
        instinctIcon = FontAwesomeIcons.route;
      } else {
        gemLevel = 1;
        instinctTitle = 'DISTANTE NAS RUÍNAS';
        instinctSubtitle = 'Distância: ${distance.toInt()}m. Siga pela rota indicada.';
        instinctColor = AppColors.cinzaMedio.withValues(alpha: 0.7);
        instinctIcon = FontAwesomeIcons.snowflake;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: instinctColor.withValues(alpha: 0.5), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: instinctColor.withValues(alpha: 0.15),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: instinctColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: instinctColor.withValues(alpha: 0.6), width: 1.2),
                      ),
                      child: Center(
                        child: FaIcon(instinctIcon, color: instinctColor, size: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        instinctTitle,
                        style: GoogleFonts.cinzel(
                          color: instinctColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Gemas Sagradas de Proximidade (5 gemas em losango)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final active = index < gemLevel;
                  return Transform.rotate(
                    angle: 0.785398, // 45 graus = Losango sagrado
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      width: 9.0,
                      height: 9.0,
                      decoration: BoxDecoration(
                        color: active ? instinctColor : Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: instinctColor.withValues(alpha: 0.7),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  instinctSubtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ),
              if (distance != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: instinctColor.withValues(alpha: 0.6), width: 1.2),
                  ),
                  child: Text(
                    '${distance.toStringAsFixed(0)}M',
                    style: GoogleFonts.cinzel(
                      color: instinctColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- SELETOR DE INSTRUMENTOS DA EXPEDIÇÃO ---
  Widget _buildExpeditionTabSelector(bool isActionReady) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _buildExpeditionTabButton(
            index: 0,
            title: 'SELO DA RELÍQUIA',
            icon: FontAwesomeIcons.qrcode,
            badgeColor: isActionReady ? AppColors.verdeVale : AppColors.cinzaMedio,
          ),
          const SizedBox(width: 4),
          _buildExpeditionTabButton(
            index: 1,
            title: 'BÚSSOLA DOURADA',
            icon: FontAwesomeIcons.compass,
            badgeColor: controller.hasCompass ? AppColors.verdeVale : AppColors.amareloVale,
            isLocked: !controller.hasCompass && !controller.hasRadar,
          ),
          const SizedBox(width: 4),
          _buildExpeditionTabButton(
            index: 2,
            title: 'MAPA ANTIGO',
            icon: FontAwesomeIcons.mapLocationDot,
            badgeColor: controller.hasMap ? AppColors.verdeVale : AppColors.amareloVale,
            isLocked: !controller.hasMap,
          ),
        ],
      ),
    );
  }

  Widget _buildExpeditionTabButton({
    required int index,
    required String title,
    required dynamic icon,
    required Color badgeColor,
    bool isLocked = false,
  }) {
    final bool isSelected = controller.selectedTacticalTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          controller.setSelectedTacticalTab(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.verdeVale.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.verdeVale : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.cinzaMedio,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.cinzel(
                    color: isSelected ? Colors.white : AppColors.cinzaMedio,
                    fontSize: 9.5,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 5),
                if (isLocked)
                  const FaIcon(
                    FontAwesomeIcons.lock,
                    color: AppColors.amareloVale,
                    size: 8.5,
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentExpeditionContent(
    BuildContext context,
    bool isActionReady,
    bool isGpsEnigma,
  ) {
    switch (controller.selectedTacticalTab) {
      case 1:
        return _buildCompassTab(context);
      case 2:
        return _buildMapTab(context);
      case 0:
      default:
        return _buildRelicScannerTab(context, isActionReady, isGpsEnigma);
    }
  }

  // --- ABA 0: LENTE DA RELÍQUIA / SCANNER DO TEMPLO ---
  Widget _buildRelicScannerTab(
    BuildContext context,
    bool isActionReady,
    bool isGpsEnigma,
  ) {
    return Column(
      key: const ValueKey('relic_scanner_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lente do Explorador com Cantoneiras Antigas
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActionReady
                  ? AppColors.verdeVale.withValues(alpha: 0.5)
                  : Colors.white12,
              width: 1.4,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActionReady ? AppColors.verdeVale : AppColors.amareloVale.withValues(alpha: 0.4),
                    width: 1.6,
                  ),
                  boxShadow: isActionReady
                      ? [
                          BoxShadow(
                            color: AppColors.verdeVale.withValues(alpha: 0.3),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(116, 116),
                      painter: RelicCornerPainter(
                        color: isActionReady ? AppColors.verdeVale : AppColors.amareloVale.withValues(alpha: 0.6),
                        cornerLength: 20,
                        strokeWidth: 2.2,
                        showStuds: true,
                      ),
                    ),
                    FaIcon(
                      isActionReady
                          ? FontAwesomeIcons.gem
                          : FontAwesomeIcons.locationCrosshairs,
                      color: isActionReady ? AppColors.verdeVale : AppColors.amareloVale,
                      size: 40,
                    ).animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    ).scaleXY(
                      begin: 0.94,
                      end: 1.06,
                      duration: 1600.ms,
                      curve: Curves.easeInOut,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (isGpsEnigma && !controller.isNear) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.amareloVale.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.triangleExclamation,
                        color: AppColors.amareloVale,
                        size: 13,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          controller.distance != null
                              ? 'Aproxime-se a menos de 100m da relíquia (Faltam ${controller.distance!.toInt()}m)'
                              : 'Buscando conexão de coordenadas com o templo...',
                          style: GoogleFonts.cinzel(
                            color: AppColors.amareloVale,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    controller.setSelectedTacticalTab(1);
                  },
                  icon: const FaIcon(FontAwesomeIcons.compass, size: 13),
                  label: Text(
                    'ABRIR BÚSSOLA PARA TE GUIAR',
                    style: GoogleFonts.cinzel(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.amareloVale,
                  ),
                ),
              ] else ...[
                Text(
                  'LENTE DA RELÍQUIA PRONTA',
                  style: GoogleFonts.cinzel(
                    color: AppColors.verdeVale,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aponte a câmera para a relíquia física gravada para desvendar.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.cinzaMedio,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Botão Principal com Shimmer Dourado: REVELAR RELÍQUIA AGORA
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isActionReady
                ? AppColors.gradienteVerdeVale
                : const LinearGradient(
                    colors: [Color(0xFF384346), Color(0xFF1E282A)],
                  ),
            boxShadow: isActionReady
                ? [
                    BoxShadow(
                      color: AppColors.verdeVale.withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton.icon(
            onPressed: isActionReady
                ? () {
                    HapticFeedback.heavyImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ScannerScreen(
                          onScan: (scannedCode) => controller.handleAction(
                            'validateCode',
                            context: context,
                            code: scannedCode,
                            onEnigmaSolved: onEnigmaSolved,
                            onShake: onShake,
                          ),
                        ),
                      ),
                    );
                  }
                : null,
            icon: FaIcon(
              controller.isBlocked ? FontAwesomeIcons.hourglassHalf : FontAwesomeIcons.camera,
              color: isActionReady ? Colors.white : Colors.grey,
              size: 16,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                controller.isBlocked
                    ? 'COOLDOWN DO EXPLORADOR'
                    : (isActionReady ? 'REVELAR RELÍQUIA AGORA' : 'APROXIME-SE DO PONTO'),
                style: GoogleFonts.cinzel(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isActionReady ? Colors.white : Colors.grey,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              minimumSize: const Size(double.infinity, 54),
            ),
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(),
        ).shimmer(
          duration: 2600.ms,
          color: AppColors.amareloVale.withValues(alpha: 0.35),
        ),

        const SizedBox(height: 8),

        // Ação Secundária: Inscrição Manual de Código
        Center(
          child: TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              EnigmaDialogs.openManualCodeSheet(
                context,
                onCodeSubmitted: (code) => controller.handleAction(
                  'validateCode',
                  context: context,
                  code: code,
                  onEnigmaSolved: onEnigmaSolved,
                  onShake: onShake,
                ),
              );
            },
            icon: const FaIcon(
              FontAwesomeIcons.keyboard,
              color: AppColors.amareloVale,
              size: 13,
            ),
            label: Text(
              'INSCREVER CÓDIGO DA RELÍQUIA MANUALMENTE',
              style: GoogleFonts.cinzel(
                color: AppColors.amareloVale,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- ABA 1: BÚSSOLA DOURADA 360° ---
  Widget _buildCompassTab(BuildContext context) {
    final bool isUnlocked = controller.hasCompass || controller.hasRadar;
    final targetLat = controller.targetLatitude;
    final targetLng = controller.targetLongitude;

    if (targetLat == null || targetLng == null) {
      return Container(
        key: const ValueKey('compass_tab_no_coords'),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.compass, color: AppColors.cinzaMedio, size: 36),
            const SizedBox(height: 10),
            Text(
              'Coordenadas Não Requeridas',
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Este enigma não necessita de bússola direcional. Utilize a aba Selo da Relíquia para validar.',
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!isUnlocked) {
      return _buildLockedToolCard(
        context: context,
        key: const ValueKey('compass_tab_locked'),
        title: 'BÚSSOLA DOURADA DO EXPLORADOR',
        icon: FontAwesomeIcons.compass,
        accentColor: AppColors.amareloVale,
        description:
          'Ativa a bússola dourada em tempo real com agulha direcional mística que te guia até a câmara exata do tesouro.',
        price: controller.compassPrice,
        toolKey: 'compass',
      );
    }

    return Container(
      key: const ValueKey('compass_tab_unlocked'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.amareloVale.withValues(alpha: 0.45),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          CompassWidget(
            targetLatitude: targetLat,
            targetLongitude: targetLng,
            destinationLongitude: targetLng,
            destinationLatitude: targetLat,
            durationSeconds: controller.compassRemainingSeconds ?? controller.compassDuration,
            isCompact: true,
            onTick: controller.updateCompassRemainingSeconds,
            onTimeUp: () => controller.onCompassTimeUp(context),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => EnigmaDialogs.openCompassExpanded(
              context,
              latitude: targetLat,
              longitude: targetLng,
              durationSeconds: controller.compassRemainingSeconds ?? controller.compassDuration,
              onTick: controller.updateCompassRemainingSeconds,
              onTimeUp: () => controller.onCompassTimeUp(context),
            ),
            icon: const FaIcon(FontAwesomeIcons.upRightAndDownLeftFromCenter, size: 12),
            label: Text(
              'EXPANDIR BÚSSOLA EM TELA CHEIA',
              style: GoogleFonts.cinzel(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.amareloVale,
              side: const BorderSide(color: AppColors.amareloVale, width: 1.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // --- ABA 2: MAPA DA EXPEDIÇÃO ---
  Widget _buildMapTab(BuildContext context) {
    final bool isUnlocked = controller.hasMap;
    final targetLat = controller.targetLatitude;
    final targetLng = controller.targetLongitude;

    if (targetLat == null || targetLng == null) {
      return Container(
        key: const ValueKey('map_tab_no_coords'),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.mapLocationDot, color: AppColors.cinzaMedio, size: 36),
            const SizedBox(height: 10),
            Text(
              'Mapa Não Requerido',
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Este enigma não necessita de mapa topográfico. Utilize a aba Selo da Relíquia para validar.',
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!isUnlocked) {
      return _buildLockedToolCard(
        context: context,
        key: const ValueKey('map_tab_locked'),
        title: 'MAPA ANTIGO DA EXPEDIÇÃO',
        icon: FontAwesomeIcons.mapLocationDot,
        accentColor: AppColors.verdeVale,
        description:
          'Revela o pergaminho geográfico com o raio estimado das ruínas onde a relíquia sagrada se encontra.',
        price: controller.currentEnigma.mapPrice,
        toolKey: 'map',
      );
    }

    return Container(
      key: const ValueKey('map_tab_unlocked'),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.45),
          width: 1.4,
        ),
      ),
      child: MapRadiusWidget(
        destinationLatitude: targetLat,
        destinationLongitude: targetLng,
        isCompact: true,
        onExpand: () => EnigmaDialogs.openMapExpanded(
          context,
          latitude: targetLat,
          longitude: targetLng,
        ),
      ),
    );
  }

  // --- CARD DE INSTRUMENTO BLOQUEADO ---
  Widget _buildLockedToolCard({
    required BuildContext context,
    Key? key,
    required String title,
    required dynamic icon,
    required Color accentColor,
    required String description,
    required double price,
    required String toolKey,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.16),
              border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Center(
              child: FaIcon(icon, color: accentColor, size: 24),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.poppins(
              color: AppColors.cinzaMedio,
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.85)],
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: controller.isLoading
                  ? null
                  : () async {
                      final bool? confirmed =
                          await EnigmaDialogs.showPurchaseConfirmation(
                        context,
                        cost: price,
                        type: title,
                      );
                      if (confirmed == true && context.mounted) {
                        controller.handleToolPurchase(toolKey, context);
                      }
                    },
              icon: const FaIcon(FontAwesomeIcons.lockOpen, size: 13, color: Colors.black),
              label: Text(
                'DESBLOQUEAR (R\$ ${price.toInt()})',
                style: GoogleFonts.cinzel(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
