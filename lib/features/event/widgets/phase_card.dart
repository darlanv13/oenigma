import 'dart:ui';
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
    final bool isPlayable = !isLocked && !isCompleted;
    final double scale = isActive ? 1.02 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      transform: Matrix4.diagonal3Values(scale, scale, 1.0),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: primaryAmber.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isLocked
                  ? darkBackground.withValues(alpha: 0.6)
                  : cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? primaryAmber.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: isLocked ? 0.05 : 0.1),
                width: isActive ? 1.5 : 1,
              ),
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
                                initialEnigma: phase.enigmas[enigmaIndex],
                                onEnigmaSolved: onPhaseCompleted,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Esta fase não possui enigmas cadastrados.',
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      _buildLeftIcon(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'NÍVEL ${phase.order}',
                                  style: TextStyle(
                                    color: isLocked
                                        ? secondaryTextColor
                                        : (isActive
                                              ? primaryAmber
                                              : Colors.white),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                if (isPlayable)
                                  const FaIcon(
                                    FontAwesomeIcons.chevronRight,
                                    color: primaryAmber,
                                    size: 16,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    int total = phase.enigmas.length;
    int completed = isCompleted ? total : (isActive ? currentEnigma - 1 : 0);
    double progress = total == 0 ? 0 : completed / total;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: darkBackground.withValues(alpha: 0.8),
            blurRadius: 4,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          color: isCompleted ? Colors.greenAccent : primaryAmber,
          minHeight: 6,
        ),
      ),
    );
  }

  Widget _buildLeftIcon() {
    dynamic iconData;
    Color backgroundColor;
    Color iconColor = Colors.white;

    if (isCompleted) {
      iconData = FontAwesomeIcons.check;
      backgroundColor = Colors.green.withValues(alpha: 0.15);
      iconColor = Colors.greenAccent;
    } else if (isActive) {
      iconData = FontAwesomeIcons.compass;
      backgroundColor = primaryAmber.withValues(alpha: 0.15);
      iconColor = primaryAmber;
    } else {
      iconData = FontAwesomeIcons.lock;
      backgroundColor = Colors.white.withValues(alpha: 0.05);
      iconColor = secondaryTextColor.withValues(alpha: 0.5);
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isActive
            ? Border.all(color: primaryAmber.withValues(alpha: 0.3))
            : null,
      ),
      child: Center(child: FaIcon(iconData, color: iconColor, size: 22)),
    );
  }

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
          child: FaIcon(
            isSolved ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
            color: isSolved
                ? primaryAmber
                : secondaryTextColor.withValues(alpha: 0.5),
            size: 14,
          ),
        );
      }),
    );
  }
}
