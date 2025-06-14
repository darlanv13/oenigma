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
  final int currentEnigma;
  final VoidCallback onPhaseCompleted;

  const PhaseCard({
    super.key,
    required this.event,
    required this.phase,
    required this.isLocked,
    required this.isCompleted,
    required this.currentEnigma,
    required this.onPhaseCompleted,
  });

  @override
  Widget build(BuildContext context) {
    String status;
    Color statusColor;

    if (isCompleted) {
      status = 'Já foi!';
      statusColor = Colors.blue.shade800;
    } else if (isLocked) {
      status = 'Calma aí!';
      statusColor = Colors.red.shade900;
    } else {
      status = 'É agora!';
      statusColor = Colors.green.shade800;
    }

    return GestureDetector(
      onTap: () {
        if (!isLocked && !isCompleted) {
          if (phase.enigmas.isNotEmpty) {
            int enigmaIndex = currentEnigma - 1;
            if (enigmaIndex >= 0 && enigmaIndex < phase.enigmas.length) {
              Navigator.push(
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
            } else {
              print("Erro: o índice do enigma ($enigmaIndex) é inválido.");
            }
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? cardColor.withOpacity(0.6) : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle_outline : Icons.explore,
                    size: 60,
                    color: textColor.withOpacity(0.5),
                  ),
                  Text(
                    "Fase ${phase.order}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Chip(
                    label: Text(status),
                    backgroundColor: statusColor,
                    labelStyle: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      alignment: Alignment.center,
                      child: const Icon(Icons.lock, size: 50, color: textColor),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}