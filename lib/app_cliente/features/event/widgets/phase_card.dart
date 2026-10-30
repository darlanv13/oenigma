import 'package:flutter/material.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/app_cliente/features/enigma/screens/enigma_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.verdeVale
              : (isCompleted
                  ? AppColors.verdeVale.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08)),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.verdeVale.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: AppColors.verdeVale.withValues(alpha: 0.1),
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
                : (isLocked
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.lock,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Fase Bloqueada! Resolva todos os enigmas da etapa anterior para avançar.',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.darkCardColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                        );
                      }
                    : () {
                        if (phase.enigmas.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EnigmaScreen(
                                event: event,
                                phase: phase,
                                initialEnigma: phase.enigmas.first,
                                onEnigmaSolved: onPhaseCompleted,
                              ),
                            ),
                          );
                        }
                      }),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  _buildLeftIcon(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NÍVEL ${phase.order}',
                              style: GoogleFonts.poppins(
                                color: isLocked
                                    ? AppColors.cinzaMedio
                                    : (isActive
                                          ? AppColors.verdeVale
                                          : Colors.white),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (isPlayable)
                              const FaIcon(
                                FontAwesomeIcons.chevronRight,
                                color: AppColors.verdeVale,
                                size: 14,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildStars(),
                        const SizedBox(height: 10),
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
    );
  }

  Widget _buildProgressBar() {
    int total = phase.enigmas.length;
    int completed = isCompleted ? total : (isActive ? currentEnigma - 1 : 0);
    double progress = total == 0 ? 0 : completed / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        color: isCompleted ? AppColors.verdeVale : AppColors.amareloVale,
        minHeight: 6,
      ),
    );
  }

  Widget _buildLeftIcon() {
    dynamic iconData;
    Color backgroundColor;
    Color iconColor;

    if (isCompleted) {
      iconData = FontAwesomeIcons.check;
      backgroundColor = AppColors.verdeVale.withValues(alpha: 0.15);
      iconColor = AppColors.verdeVale;
    } else if (isActive) {
      iconData = FontAwesomeIcons.compass;
      backgroundColor = AppColors.verdeVale.withValues(alpha: 0.2);
      iconColor = AppColors.verdeVale;
    } else {
      iconData = FontAwesomeIcons.lock;
      backgroundColor = Colors.white.withValues(alpha: 0.05);
      iconColor = AppColors.cinzaMedio;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? AppColors.verdeVale.withValues(alpha: 0.5)
              : (isCompleted
                  ? AppColors.verdeVale.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Center(child: FaIcon(iconData, color: iconColor, size: 18)),
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
      return Text(
        'Nenhum enigma nesta fase',
        style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12),
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
                ? AppColors.amareloVale
                : Colors.white.withValues(alpha: 0.15),
            size: 13,
          ),
        );
      }),
    );
  }
}
