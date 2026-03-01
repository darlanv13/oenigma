import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class WalletSectionHeader extends StatelessWidget {
  final String title;

  const WalletSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: primaryAmber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
