import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final bool isDark;

  const AppBackground({
    super.key,
    required this.child,
    this.opacity = 0.08,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBackground,
      child: Stack(
        children: [
          // Top-right Verde-Vale ambient glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.verdeVale.withValues(alpha: 0.12),
              ),
            ),
          ),
          // Bottom-left Amarelo-Vale ambient glow
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amareloVale.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Background asset with subtle opacity
          Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: const Image(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
                errorBuilder: _fallbackEmpty,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  static Widget _fallbackEmpty(BuildContext context, Object error, StackTrace? stackTrace) {
    return const SizedBox.shrink();
  }
}
