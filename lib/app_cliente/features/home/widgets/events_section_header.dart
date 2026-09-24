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
          style: GoogleFonts.poppins(
            fontSize: 20, // 1.25rem
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          "Eventos disponíveis no momento",
          style: TextStyle(
            fontSize: 12, // 0.75rem
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            fontFamily: 'Inter',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
