import 'dart:math' as math;
import 'package:flutter/material.dart';

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
}
