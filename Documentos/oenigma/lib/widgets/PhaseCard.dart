import 'package:flutter/material.dart';
import 'dart:ui';
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
    return GestureDetector(
      //...
      onTap: () {
        // Sem async
        if (isActive && phase.enigmas.isNotEmpty) {
          int enigmaIndex = currentEnigma - 1;
          if (enigmaIndex < 0 || enigmaIndex >= phase.enigmas.length) {
            enigmaIndex = 0;
          }

          Navigator.push(
            // Sem await
            context,
            MaterialPageRoute(
              builder: (context) => EnigmaScreen(
                event: event,
                phase: phase,
                enigma: phase.enigmas[enigmaIndex],
                onEnigmaSolved: onPhaseCompleted,
              ),
            ),
          );

          // A chamada para onPhaseCompleted() foi removida daqui.
        }
      },
      //...
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isCompleted
              ? LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [cardColor, Color(0xFF2a2a2a)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: isActive ? Border.all(color: primaryAmber, width: 2) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primaryAmber.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.verified_user
                          : (isActive ? Icons.explore : Icons.lock_outline),
                      size: 50,
                      color: isCompleted
                          ? Colors.white
                          : textColor.withOpacity(0.7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Fase ${phase.order}",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.white : textColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lock,
                        size: 50,
                        color: secondaryTextColor,
                      ),
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
