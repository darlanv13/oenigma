import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/controllers/enigma_controller.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_card.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_header.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_hints_section.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_tactical_area.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

// Exportações para manter compatibilidade com importadores legados
export 'package:oenigma/app_cliente/features/enigma/screens/scanner_screen.dart';
export 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';
export 'package:oenigma/app_cliente/features/enigma/widgets/scanner_corners_painter.dart';

/// Tela principal do Enigma: limpa, moderna, sem poluição visual e inspirada na página de detalhes.
class EnigmaScreen extends StatefulWidget {
  final EventModel event;
  final PhaseModel phase;
  final EnigmaModel initialEnigma;
  final VoidCallback onEnigmaSolved;

  const EnigmaScreen({
    super.key,
    required this.event,
    required this.phase,
    required this.initialEnigma,
    required this.onEnigmaSolved,
  });

  @override
  State<EnigmaScreen> createState() => _EnigmaScreenState();
}

class _EnigmaScreenState extends State<EnigmaScreen>
    with SingleTickerProviderStateMixin {
  late final EnigmaController _controller;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _controller = EnigmaController(
      event: widget.event,
      phase: widget.phase,
      initialEnigma: widget.initialEnigma,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.resetEnigmaState(context);
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0B1115),
          body: Stack(
            children: [
              // Luzes ambientais suaves e discretas de fundo
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.verdeVale.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.amareloVale.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // ScrollView com Header e Conteúdo da Expedição
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final double offset = _shakeController.value > 0
                      ? math.sin(_shakeController.value * math.pi * 4) * 8
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 1. Barra Superior Discreta
                    SliverToBoxAdapter(
                      child: EnigmaHeader(controller: _controller),
                    ),

                    // 2. Conteúdo Principal (Códice, Validação & Pistas)
                    SliverToBoxAdapter(
                      child: _controller.isLoading && _controller.hintsList.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.only(top: 100),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.amareloVale),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_controller.distance != null && _controller.distance! <= 250) ...[
                                    _buildGeigerProximityBanner(_controller.distance!),
                                    const SizedBox(height: 14),
                                  ],
                                  EnigmaCard(enigma: _controller.currentEnigma),
                                  const SizedBox(height: 14),
                                  EnigmaTacticalArea(
                                    controller: _controller,
                                    onShake: _triggerShake,
                                    onEnigmaSolved: widget.onEnigmaSolved,
                                  ),
                                  const SizedBox(height: 14),
                                  EnigmaHintsSection(
                                    controller: _controller,
                                    onShake: _triggerShake,
                                    onEnigmaSolved: widget.onEnigmaSolved,
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeigerProximityBanner(double distance) {
    Color bannerColor;
    String statusTitle;
    String statusSub;
    FaIconData iconData;

    if (distance <= 15) {
      bannerColor = const Color(0xFFFF334B);
      statusTitle = 'PROXIMIDADE CRÍTICA';
      statusSub = 'O enigma está ao seu redor! Procure visualmente o QR Code ou pista física.';
      iconData = FontAwesomeIcons.bullseye;
    } else if (distance <= 50) {
      bannerColor = Colors.orangeAccent;
      statusTitle = 'ZONA QUENTE';
      statusSub = 'Você está a menos de 50 metros do alvo. Vibração tátil intensa ativada!';
      iconData = FontAwesomeIcons.fire;
    } else if (distance <= 120) {
      bannerColor = AppColors.amareloVale;
      statusTitle = 'ZONA MORNA';
      statusSub = 'Sinal de proximidade captado. Continue avançando na direção indicada.';
      iconData = FontAwesomeIcons.satelliteDish;
    } else {
      bannerColor = AppColors.verdeVale;
      statusTitle = 'RADAR ATIVO';
      statusSub = 'Alvo no horizonte sensorial. Aproxime-se para calibrar o sensor.';
      iconData = FontAwesomeIcons.signal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bannerColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bannerColor.withValues(alpha: 0.15),
              border: Border.all(color: bannerColor, width: 1),
            ),
            child: FaIcon(iconData, color: bannerColor, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusTitle,
                      style: GoogleFonts.cinzel(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: bannerColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bannerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${distance.toInt()} METROS',
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: bannerColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusSub,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white70,
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
}
