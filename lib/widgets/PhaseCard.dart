import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/phase_model.dart';
import '../screens/enigma_screen.dart';
import '../utils/app_colors.dart';

class PhaseCard extends StatelessWidget {
  final EventModel event;
  final PhaseModel phase;
  final bool isLocked;
  final bool isCompleted;
  final bool isActive;
  final int currentEnigma;
  final VoidCallback onPhaseCompleted;

  const PhaseCard({
    super.key,
    required this.event,
    required this.phase,
    required this.isLocked,
    required this.isCompleted,
    required this.isActive,
    required this.currentEnigma,
    required this.onPhaseCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // Define a opacidade para fases bloqueadas
    final double opacity = isLocked ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: isLocked || isCompleted
              ? null // Impede o clique em fases bloqueadas
              : () {
                  if (phase.enigmas.isNotEmpty) {
                    int enigmaIndex = currentEnigma - 1;
                    if (enigmaIndex < 0 ||
                        enigmaIndex >= phase.enigmas.length) {
                      enigmaIndex = 0;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EnigmaScreen(
                          event: event,
                          phase: phase,
                          // --- CORREÇÃO ESTÁ AQUI ---
                          // Trocado 'enigma:' por 'initialEnigma:'
                          initialEnigma: phase.enigmas[enigmaIndex],
                          onEnigmaSolved: onPhaseCompleted,
                        ),
                      ),
                    );
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                _buildLeftIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nivel ${phase.order}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildStars(),
                    ],
                  ),
                ),
                if (!isLocked)
                  const Icon(
                    Icons.chevron_right,
                    color: secondaryTextColor,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper para construir o ícone da esquerda
  Widget _buildLeftIcon() {
    IconData iconData;
    Color backgroundColor;
    Color iconColor = Colors.white;

    if (isCompleted) {
      iconData = Icons.check;
      backgroundColor = primaryAmber;
      iconColor = darkBackground;
    } else if (isActive) {
      iconData = Icons.explore_outlined;
      backgroundColor = primaryAmber.withOpacity(0.2);
      iconColor = primaryAmber;
    } else {
      // isLocked
      iconData = Icons.lock;
      backgroundColor = Colors.black.withOpacity(0.3);
      iconColor = secondaryTextColor;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isActive ? Border.all(color: primaryAmber, width: 1.5) : null,
      ),
      child: Icon(iconData, color: iconColor, size: 26),
    );
  }

  // Helper para construir as estrelas de enigmas
  Widget _buildStars() {
    int totalEnigmas = phase.enigmas.length;
    int completedEnigmas = 0;

    if (isCompleted) {
      completedEnigmas = totalEnigmas;
    } else if (isActive) {
      // currentEnigma é 1-based, então subtraímos 1
      completedEnigmas = currentEnigma - 1;
    }
    // Para fases bloqueadas, completedEnigmas continua 0

    if (totalEnigmas == 0) {
      return const Text(
        'Nenhum enigma nesta fase',
        style: TextStyle(color: secondaryTextColor, fontSize: 12),
      );
    }

    return Row(
      children: List.generate(totalEnigmas, (index) {
        return Icon(
          index < completedEnigmas ? Icons.star : Icons.star_border,
          color: primaryAmber,
          size: 20,
        );
      }),
    );
  }
}
