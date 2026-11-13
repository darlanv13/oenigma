import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amareloVale.withValues(alpha: 0.15),
              ),
              child: const FaIcon(
                FontAwesomeIcons.gem,
                size: 10,
                color: AppColors.amareloVale,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "ESCOLHA SUA EXPEDIÇÃO",
              style: GoogleFonts.cinzel(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.verdeVale.withValues(alpha: 0.15),
              ),
              child: const FaIcon(
                FontAwesomeIcons.compass,
                size: 10,
                color: AppColors.verdeVale,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          "Selecione uma missão ativa para iniciar a caçada",
          style: GoogleFonts.inter(
            fontSize: 12,
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
