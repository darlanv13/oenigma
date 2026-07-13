import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/features/enigma/screens/enigma_screen.dart';

class CardEnigma extends StatelessWidget {
  final EnigmaModel enigma;
  final EventModel event;
  final Animation<double> animation;

  const CardEnigma({
    super.key,
    required this.enigma,
    required this.event,
    required this.animation,
  });

  dynamic _getIconForCharacteristic(String key) {
    switch (key) {
      case 'nado':
        return FontAwesomeIcons.personSwimming;
      case 'corrida':
        return FontAwesomeIcons.personRunning;
      case 'camera':
        return FontAwesomeIcons.camera;
      case 'noite':
        return FontAwesomeIcons.moon;
      case 'dia':
        return FontAwesomeIcons.sun;
      case 'exploracao':
        return FontAwesomeIcons.compass;
      case 'escalada':
        return FontAwesomeIcons.mountain;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isClosed = enigma.status == 'closed';
    bool isTemporarilyBlocked = false;

    if (isClosed && enigma.closedAt != null) {
      final difference = DateTime.now().difference(enigma.closedAt!);
      if (difference.inMinutes < 15) {
        isTemporarilyBlocked = true;
      } else {
        return const SizedBox.shrink();
      }
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
    );

    return GestureDetector(
      onTap: () {
        if (isTemporarilyBlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Este enigma já foi resolvido por outro jogador e desaparecerá em breve.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final mockPhase = PhaseModel(
          id: 'find_and_win',
          order: 1,
          enigmas: [enigma],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnigmaScreen(
              event: event,
              phase: mockPhase,
              initialEnigma: enigma,
              onEnigmaSolved: () {},
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          // Adiciona uma pulsação sutil (escala de 1.0 a 1.02)
          final scale = 1.0 + (0.02 * animation.value);

          return Transform.scale(
            scale: scale,
            child: AspectRatio(
              aspectRatio: 1.0, // Força o widget a ser perfeitamente quadrado
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isTemporarilyBlocked
                      ? LinearGradient(
                          colors: [Colors.grey.shade800, Colors.grey.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            Color.lerp(
                              const Color(0xFFFFD700),
                              const Color(0xFFFDB931),
                              animation.value,
                            )!,
                            Color.lerp(
                              const Color(0xFFFDB931),
                              const Color(0xFF9E7A00),
                              animation.value,
                            )!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    // Sombra projetada
                    BoxShadow(
                      color: isTemporarilyBlocked
                          ? Colors.black.withValues(alpha: 0.5)
                          : const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.4 * animation.value),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                    // Brilho interno sutil
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: -2,
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // --- ÁREA CENTRAL: INFORMAÇÕES DO DESAFIO ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        48,
                      ), // Espaço extra embaixo para os ícones
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Text(
                            enigma.instruction,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF3E2723),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currencyFormat.format(enigma.prize),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),

                    // --- ÁREA INFERIOR: ÍCONES DE CARACTERÍSTICAS EM GLASSMORPHISM ---
                    if (enigma.characteristics.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: enigma.characteristics.map((char) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                    ),
                                    child: FaIcon(
                                      _getIconForCharacteristic(char),
                                      size: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // --- OVERLAY: BLOQUEIO TEMPORÁRIO ---
                    if (isTemporarilyBlocked)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.lock,
                                    color: Colors.white70,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'RESOLVIDO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
