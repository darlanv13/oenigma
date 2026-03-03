import 'package:flutter/material.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/features/enigma/screens/enigma_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


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
    // Fases bloqueadas ficam acinzentadas, Fases ativas brilham
    final bool isPlayable = !isLocked && !isCompleted;
    final double scale = isActive ? 1.02 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      transform: Matrix4.diagonal3Values(scale, scale, 1.0),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: primaryAmber.withValues(alpha: 0.5), width: 2) : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: primaryAmber.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: primaryAmber.withValues(alpha: 0.2),
          onTap: isPlayable
              ? () {
                  if (phase.enigmas.isNotEmpty) {
                    int enigmaIndex = currentEnigma - 1;
                    if (enigmaIndex < 0 || enigmaIndex >= phase.enigmas.length) {
                      enigmaIndex = 0;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EnigmaScreen(
                          event: event,
                          phase: phase,
                          initialEnigma: phase.enigmas[enigmaIndex],
                          onEnigmaSolved: onPhaseCompleted,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Esta fase não possui enigmas cadastrados.')),
                    );
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                _buildLeftIcon(),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nivel \${phase.order}',
                            style: TextStyle(
                              color: isLocked ? secondaryTextColor : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          if (isPlayable)
                            const Icon(FontAwesomeIcons.chevronRight, color: primaryAmber, size: 16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStars(),
                      const SizedBox(height: 12),
                      _buildProgressBar(),
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

  // Barra de progresso linear fina
  Widget _buildProgressBar() {
    int total = phase.enigmas.length;
    int completed = isCompleted ? total : (isActive ? currentEnigma - 1 : 0);
    double progress = total == 0 ? 0 : completed / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        color: isCompleted ? Colors.greenAccent : primaryAmber,
        minHeight: 6,
      ),
    );
  }

  // Helper para construir o ícone da esquerda
  Widget _buildLeftIcon() {
    IconData iconData;
    Color backgroundColor;
    Color iconColor = Colors.white;

    if (isCompleted) {
      iconData = FontAwesomeIcons.check;
      backgroundColor = Colors.green.withValues(alpha: 0.2);
      iconColor = Colors.greenAccent;
    } else if (isActive) {
      iconData = FontAwesomeIcons.compass;
      backgroundColor = primaryAmber.withValues(alpha: 0.2);
      iconColor = primaryAmber;
    } else {
      iconData = FontAwesomeIcons.lock;
      backgroundColor = Colors.black.withValues(alpha: 0.3);
      iconColor = secondaryTextColor;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: isActive ? [
          BoxShadow(color: primaryAmber.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)
        ] : [],
      ),
      child: Center(
        child: Icon(iconData, color: iconColor, size: 28),
      ),
    );
  }

  // Helper para construir as estrelas de enigmas
  Widget _buildStars() {
    int totalEnigmas = phase.enigmas.length;
    int completedEnigmas = 0;

    if (isCompleted) {
      completedEnigmas = totalEnigmas;
    } else if (isActive) {
      completedEnigmas = currentEnigma - 1;
    }

    if (totalEnigmas == 0) {
      return const Text(
        'Nenhum enigma nesta fase',
        style: TextStyle(color: secondaryTextColor, fontSize: 12),
      );
    }

    return Row(
      children: List.generate(totalEnigmas, (index) {
        bool isSolved = index < completedEnigmas;
        return Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: Icon(
            isSolved ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
            color: isSolved ? primaryAmber : secondaryTextColor.withValues(alpha: 0.5),
            size: 16,
          ),
        );
      }),
    );
  }
}
