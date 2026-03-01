import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ProfileSectionHeader extends StatelessWidget {
  final String title;

  const ProfileSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
