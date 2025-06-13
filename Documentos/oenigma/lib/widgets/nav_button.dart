import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? primaryAmber : cardColor,
            borderRadius: BorderRadius.circular(15),
            border: isActive ? null : Border.all(color: Colors.grey[800]!),
          ),
          child: Icon(
            icon,
            color: isActive ? darkBackground : textColor,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? primaryAmber : secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
