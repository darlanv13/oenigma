import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/utils/app_colors.dart';

class EnigmaCard extends StatelessWidget {
  final EnigmaModel enigma;

  const EnigmaCard({super.key, required this.enigma});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Text(
                'DESAFIO ATUAL',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEnigmaContent(),
        ],
      ),
    );
  }

  Widget _buildEnigmaContent() {
    switch (enigma.type) {
      case 'photo_location':
      case 'text':
        return Column(
          children: [
            if (enigma.imageUrl != null && enigma.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(enigma.imageUrl!),
              )
            else if (enigma.type != 'text')
              Lottie.asset('assets/animations/no_enigma.json', height: 150),
            if (enigma.imageUrl != null) const SizedBox(height: 20),
            Text(
              enigma.instruction,
              style: const TextStyle(
                fontSize: 16,
                color: textColor,
                height: 1.6,
              ),
            ),
          ],
        );
      case 'qr_code_gps':
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}
