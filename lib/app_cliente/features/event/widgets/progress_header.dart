import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    final double progress = totalPhases > 0
        ? completedPhases / totalPhases
        : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1E293B).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Color(0xFF1E293B).withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFF0F4F8).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.route,
                      color: Color(0xFF8B5CF6),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'STATUS DA CAÇADA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: secondaryTextColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFF0F4F8).withValues(alpha: 0.8),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Color(0xFF1E293B).withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth * progress,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFFFD54F)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF8B5CF6).withValues(alpha: 0.6),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fases Concluídas',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$completedPhases / $totalPhases',
                    style: TextStyle(
                      color: const Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
