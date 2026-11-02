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
import 'package:oenigma/app_cliente/features/enigma/widgets/radar_widget.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Câmara da Relíquia: limpa, direta, sem poluição visual e sem caixas aninhadas.
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Barra de Proximidade (Instinto do Explorador) - Compacta e Elegante
            _buildProximityStrip(isGpsEnigma),

            const SizedBox(height: 14),

            // 2. Seletor de Instrumentos em Segmented Control Moderno
            _buildExpeditionTabSelector(isActionReady),

            const SizedBox(height: 16),

            // 3. Conteúdo da Aba Ativa
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildCurrentTabContent(context, isActionReady, isGpsEnigma),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  // --- 1. STRIP DE PROXIMIDADE (COMPACTA, MODERNA, SEM CAIXAS ANINHADAS) ---
  Widget _buildProximityStrip(bool isGpsEnigma) {
    final distance = controller.distance;

    if (!isGpsEnigma && distance == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F171B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.gem,
              color: AppColors.verdeVale,
              size: 13,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aponte a lente para o QR Code da relíquia física.',
                style: GoogleFonts.poppins(
                  color: AppColors.cinzaMedio,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    int gemLevel = 1;
    String label = 'TRILHA DA EXPEDIÇÃO';
    Color accentColor = AppColors.cinzaMedio;
    dynamic icon = FontAwesomeIcons.compass;

    if (distance != null) {
      if (distance <= 25) {
        gemLevel = 5;
        label = 'RELÍQUIA AO SEU ALCANCE!';
        accentColor = AppColors.verdeVale;
        icon = FontAwesomeIcons.bullseye;
      } else if (distance <= 75) {
        gemLevel = 4;
        label = 'FERVENDO! MUITO PRÓXIMO';
        accentColor = AppColors.amareloVale;
        icon = FontAwesomeIcons.fire;
      } else if (distance <= 150) {
        gemLevel = 3;
        label = 'AQUECENDO • PASSO CERTO';
        accentColor = AppColors.amareloValeAlt;
        icon = FontAwesomeIcons.personWalking;
      } else if (distance <= 300) {
        gemLevel = 2;
        label = 'TRILHA FRIA • SIGA EM FRENTE';
        accentColor = AppColors.cinzaMedio;
        icon = FontAwesomeIcons.route;
      } else {
        gemLevel = 1;
        label = 'DISTANTE NAS RUÍNAS';
        accentColor = AppColors.cinzaMedio.withValues(alpha: 0.7);
        icon = FontAwesomeIcons.snowflake;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F171B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: accentColor, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cinzel(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // 5 Gemas Sagradas em Losango Compacto
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final active = index < gemLevel;
              return Transform.rotate(
                angle: 0.785398, // 45 graus
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 7.0,
                  height: 7.0,
                  decoration: BoxDecoration(
                    color: active ? accentColor : Colors.white12,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }),
          ),

          if (distance != null) ...[
            const SizedBox(width: 10),
            Text(
              '${distance.toInt()}m',
              style: GoogleFonts.cinzel(
                color: accentColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 2. SELETOR DE INSTRUMENTOS (PILLS MODERNAS, SEM CAIXA PESADA) ---
  Widget _buildExpeditionTabSelector(bool isActionReady) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F171B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _buildTabPill(
            index: 0,
            title: 'LENTE QR',
            icon: FontAwesomeIcons.qrcode,
            badgeColor: isActionReady ? AppColors.verdeVale : AppColors.cinzaMedio,
          ),
          const SizedBox(width: 3),
          _buildTabPill(
            index: 1,
            title: 'BÚSSOLA',
            icon: FontAwesomeIcons.compass,
            badgeColor: controller.hasCompass ? AppColors.verdeVale : AppColors.amareloVale,
            isLocked: !controller.hasCompass,
          ),
          const SizedBox(width: 3),
          _buildTabPill(
            index: 2,
            title: 'RADAR',
            icon: FontAwesomeIcons.satelliteDish,
            badgeColor: controller.hasRadar ? AppColors.verdeVale : AppColors.amareloVale,
            isLocked: !controller.hasRadar,
          ),
          const SizedBox(width: 3),
          _buildTabPill(
            index: 3,
            title: 'MAPA',
            icon: FontAwesomeIcons.mapLocationDot,
            badgeColor: controller.hasMap ? AppColors.verdeVale : AppColors.amareloVale,
            isLocked: !controller.hasMap,
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.verdeVale.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected ? AppColors.verdeVale.withValues(alpha: 0.6) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                color: isSelected ? Colors.white : AppColors.cinzaMedio,
                size: 10,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cinzel(
                    color: isSelected ? Colors.white : AppColors.cinzaMedio,
                    fontSize: 9.0,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 3),
                const FaIcon(
                  FontAwesomeIcons.lock,
                  color: AppColors.amareloVale,
                  size: 7.5,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(
    BuildContext context,
    bool isActionReady,
    bool isGpsEnigma,
  ) {
    switch (controller.selectedTacticalTab) {
      case 1:
        return _buildCompassTab(context);
      case 2:
        return _buildRadarTab(context);
      case 3:
        return _buildMapTab(context);
      case 0:
      default:
        return _buildRelicScannerTab(context, isActionReady, isGpsEnigma);
    }
  }

  // --- ABA 0: LENTE DA RELÍQUIA (FLUIDA, SEM CAIXA DENTRO DE CAIXA) ---
  Widget _buildRelicScannerTab(
    BuildContext context,
    bool isActionReady,
    bool isGpsEnigma,
  ) {
    return Column(
      key: const ValueKey('relic_scanner_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Abertura Central da Lente (Limpa e com Moldura Fina)
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF0F171B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActionReady
                    ? AppColors.verdeVale.withValues(alpha: 0.55)
                    : AppColors.amareloVale.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(96, 96),
                  painter: RelicCornerPainter(
                    color: isActionReady ? AppColors.verdeVale : AppColors.amareloVale,
                    cornerLength: 16,
                    strokeWidth: 1.8,
                    showStuds: false,
                  ),
                ),
                FaIcon(
                  isActionReady ? FontAwesomeIcons.qrcode : FontAwesomeIcons.gem,
                  color: isActionReady ? AppColors.verdeVale : AppColors.amareloVale,
                  size: 34,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Texto Informativo / Aviso de Proximidade
        if (isGpsEnigma && !controller.isNear) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amareloVale.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    color: AppColors.amareloVale,
                    size: 11,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      controller.distance != null
                          ? 'Aproxime-se a menos de 100m (Faltam ${controller.distance!.toInt()}m)'
                          : 'Buscando coordenadas GPS do templo...',
                      style: GoogleFonts.cinzel(
                        color: AppColors.amareloVale,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                controller.setSelectedTacticalTab(1);
              },
              icon: const FaIcon(FontAwesomeIcons.compass, size: 11, color: AppColors.amareloVale),
              label: Text(
                'ABRIR BÚSSOLA',
                style: GoogleFonts.cinzel(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amareloVale,
                ),
              ),
            ),
          ),
        ] else ...[
          Center(
            child: Text(
              'Aponte a câmera para a relíquia física gravada no local.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Botão Principal: REVELAR RELÍQUIA AGORA
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isActionReady
                ? AppColors.gradienteVerdeVale
                : const LinearGradient(
                    colors: [Color(0xFF243034), Color(0xFF192225)],
                  ),
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
              color: isActionReady ? Colors.white : Colors.white38,
              size: 14,
            ),
            label: Text(
              controller.isBlocked
                  ? 'COOLDOWN DO EXPLORADOR'
                  : (isActionReady ? 'REVELAR RELÍQUIA AGORA' : 'APROXIME-SE DO PONTO'),
              style: GoogleFonts.cinzel(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: isActionReady ? Colors.white : Colors.white38,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ).animate(
          onPlay: (c) => c.repeat(),
        ).shimmer(
          duration: 2600.ms,
          color: AppColors.amareloVale.withValues(alpha: 0.25),
        ),

        const SizedBox(height: 6),

        // Atalho de Inscrição Manual
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
              size: 11,
            ),
            label: Text(
              'INSCREVER CÓDIGO MANUAL',
              style: GoogleFonts.cinzel(
                color: AppColors.amareloVale,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- ABA 1: BÚSSOLA DOURADA 360° ---
  Widget _buildCompassTab(BuildContext context) {
    final bool isUnlocked = controller.hasCompass;
    final targetLat = controller.targetLatitude;
    final targetLng = controller.targetLongitude;

    if (targetLat == null || targetLng == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.compass, color: AppColors.cinzaMedio, size: 28),
            const SizedBox(height: 8),
            Text(
              'Coordenadas Não Requeridas',
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Utilize a aba Lente QR para validar este enigma.',
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11),
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
            'Ativa a agulha direcional mística que te guia em tempo real até a câmara exata.',
        price: controller.compassPrice,
        toolKey: 'compass',
      );
    }

    return Column(
      children: [
        CompassWidget(
          targetLatitude: targetLat,
          targetLongitude: targetLng,
          destinationLongitude: targetLng,
          destinationLatitude: targetLat,
          durationSeconds: controller.compassRemainingSeconds,
          targets: controller.targets,
          isCompact: true,
          onTick: controller.updateCompassRemainingSeconds,
          onTimeUp: () => controller.onCompassTimeUp(context),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => EnigmaDialogs.openCompassExpanded(
            context,
            latitude: targetLat,
            longitude: targetLng,
            durationSeconds: controller.compassRemainingSeconds,
            targets: controller.targets,
            onTick: controller.updateCompassRemainingSeconds,
            onTimeUp: () => controller.onCompassTimeUp(context),
          ),
          icon: const FaIcon(FontAwesomeIcons.upRightAndDownLeftFromCenter, size: 10),
          label: Text(
            'EXPANDIR BÚSSOLA',
            style: GoogleFonts.cinzel(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.amareloVale,
            side: BorderSide(color: AppColors.amareloVale.withValues(alpha: 0.5), width: 1.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        ),
      ],
    );
  }

  // --- ABA 2: RADAR MÍSTICO (SONAR 360°) ---
  Widget _buildRadarTab(BuildContext context) {
    final bool isUnlocked = controller.hasRadar;
    final targetLat = controller.targetLatitude;
    final targetLng = controller.targetLongitude;

    if (targetLat == null || targetLng == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.satelliteDish, color: AppColors.cinzaMedio, size: 28),
            const SizedBox(height: 8),
            Text(
              'Coordenadas Não Requeridas',
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Utilize a aba Lente QR para validar este enigma.',
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!isUnlocked) {
      return _buildLockedToolCard(
        context: context,
        key: const ValueKey('radar_tab_locked'),
        title: 'RADAR MÍSTICO DE RELÍQUIAS',
        icon: FontAwesomeIcons.satelliteDish,
        accentColor: AppColors.verdeVale,
        description:
            'Ativa a varredura contínua de ondas e pulso de sonar para detectar a aproximação e o eco da relíquia.',
        price: controller.currentEnigma.radarPrice,
        toolKey: 'radar',
      );
    }

    return Column(
      children: [
        RadarWidget(
          targetLatitude: targetLat,
          targetLongitude: targetLng,
          initialDistance: controller.distance,
          targets: controller.targets,
          remainingSeconds: controller.radarRemainingSeconds,
          onTick: controller.updateRadarRemainingSeconds,
          onTimeUp: () => controller.onRadarTimeUp(context),
          isCompact: true,
          onExpand: () => EnigmaDialogs.openRadarExpanded(
            context,
            latitude: targetLat,
            longitude: targetLng,
            initialDistance: controller.distance,
            targets: controller.targets,
            remainingSeconds: controller.radarRemainingSeconds,
            onTick: controller.updateRadarRemainingSeconds,
            onTimeUp: () => controller.onRadarTimeUp(context),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => EnigmaDialogs.openRadarExpanded(
            context,
            latitude: targetLat,
            longitude: targetLng,
            initialDistance: controller.distance,
            targets: controller.targets,
            remainingSeconds: controller.radarRemainingSeconds,
            onTick: controller.updateRadarRemainingSeconds,
            onTimeUp: () => controller.onRadarTimeUp(context),
          ),
          icon: const FaIcon(FontAwesomeIcons.upRightAndDownLeftFromCenter, size: 10),
          label: Text(
            'EXPANDIR RADAR',
            style: GoogleFonts.cinzel(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.verdeVale,
            side: BorderSide(color: AppColors.verdeVale.withValues(alpha: 0.5), width: 1.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        ),
      ],
    );
  }

  // --- ABA 3: MAPA DA EXPEDIÇÃO ---
  Widget _buildMapTab(BuildContext context) {
    final bool isUnlocked = controller.hasMap;
    final targetLat = controller.targetLatitude;
    final targetLng = controller.targetLongitude;

    if (targetLat == null || targetLng == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.mapLocationDot, color: AppColors.cinzaMedio, size: 28),
            const SizedBox(height: 8),
            Text(
              'Mapa Não Requerido',
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Utilize a aba Lente QR para validar este enigma.',
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11),
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
            'Revela o perímetro geográfico com o raio estimado das ruínas onde a relíquia repousa.',
        price: controller.currentEnigma.mapPrice,
        toolKey: 'map',
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: MapRadiusWidget(
        destinationLatitude: targetLat,
        destinationLongitude: targetLng,
        targets: controller.targets,
        remainingSeconds: controller.mapRemainingSeconds,
        isCompact: true,
        onExpand: () => EnigmaDialogs.openMapExpanded(
          context,
          latitude: targetLat,
          longitude: targetLng,
          targets: controller.targets,
          remainingSeconds: controller.mapRemainingSeconds,
        ),
      ),
    );
  }

  // --- CARD DE INSTRUMENTO BLOQUEADO (LIMPO E COMPACTO) ---
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F171B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: accentColor, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.poppins(
              color: AppColors.cinzaMedio,
              fontSize: 11,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
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
            icon: const FaIcon(FontAwesomeIcons.lockOpen, size: 11, color: Colors.black),
            label: Text(
              'DESBLOQUEAR (R\$ ${price.toInt()})',
              style: GoogleFonts.cinzel(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
