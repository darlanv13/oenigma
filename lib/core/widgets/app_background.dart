import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const AppBackground({
    super.key,
    required this.child,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        image: DecorationImage(
          image: const AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 1.0 - opacity),
            BlendMode.dstOut,
          ),
        ),
      ),
      child: child,
    );
  }
}
