import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventsSectionHeader extends StatelessWidget {
  const EventsSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "ESCOLHA SUA CAÇADA",
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(
              0xFFD6B570,
            ), // Destaque na cor do tema em dourado apagado
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          "Eventos disponíveis no momento",
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF9E8B61),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
