import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class EventsSectionHeader extends StatelessWidget {
  const EventsSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: primaryAmber,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          "EVENTOS DISPONÍVEIS",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: secondaryTextColor,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
