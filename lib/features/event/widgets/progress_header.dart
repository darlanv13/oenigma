import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ProgressHeader extends StatelessWidget {
  final int totalPhases;
  final int completedPhases;

  const ProgressHeader({
    super.key,
    required this.totalPhases,
    required this.completedPhases,
  });

  @override
  Widget build(BuildContext context) {
    // Evita divisão por zero se não houver fases
    final double progress = totalPhases > 0 ? completedPhases / totalPhases : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seu Progresso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          // Barra de Progresso Customizada
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: darkBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth * progress,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryAmber, Colors.orange],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Estatísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fases Concluídas',
                style: TextStyle(color: secondaryTextColor, fontSize: 14),
              ),
              Text(
                '$completedPhases / $totalPhases',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}