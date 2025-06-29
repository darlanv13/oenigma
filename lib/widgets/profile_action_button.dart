import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const ProfileActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: primaryAmber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(icon, color: primaryAmber, size: 24),
          ),
        ),
      ),
    );
  }
}
