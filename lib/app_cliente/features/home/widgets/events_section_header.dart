import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventsSectionHeader extends StatelessWidget {
  const EventsSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFC0A060),
              Color(0xFFF5E6B8),
              Color(0xFFB8944B),
            ],
            stops: [0.0, 0.6, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            "ESCOLHA SUA CAÇADA",
            style: GoogleFonts.orbitron(
              fontSize: 17.6, // 1.1rem
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Eventos disponíveis no momento",
          style: TextStyle(
            fontSize: 11.2, // 0.7rem
            color: Color(0xFF8A7A5A),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            fontFamily: 'Inter',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
