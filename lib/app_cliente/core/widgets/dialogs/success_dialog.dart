import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_cliente/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void showSuccessDialog(
  BuildContext context, {
  required VoidCallback onOkPressed,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        backgroundColor: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC0A060), width: 3),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.check,
                  color: Color(0xFFC0A060),
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Fase Concluída',
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFC0A060),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Você concluiu esta fase com sucesso!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0A060),
                    foregroundColor: const Color(0xFF121212),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onOkPressed,
                  child: Text(
                    'OK',
                    style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
