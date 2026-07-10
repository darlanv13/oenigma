import 'dart:ui';
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryAmber.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUS DA CAÇADA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: primaryAmber,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: primaryAmber.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Barra de Progresso Customizada
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: darkBackground.withValues(alpha: 0.8),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: darkBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth * progress,
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryAmber, Color(0xFFFFD54F)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: primaryAmber.withValues(alpha: 0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Estatísticas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fases Concluídas',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$completedPhases / $totalPhases',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}