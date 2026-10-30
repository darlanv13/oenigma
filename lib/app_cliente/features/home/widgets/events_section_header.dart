import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class EventsSectionHeader extends StatelessWidget {
  const EventsSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amareloVale,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "ESCOLHA SUA CAÇADA",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.verdeVale,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Eventos disponíveis no momento",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.cinzaMedio,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
