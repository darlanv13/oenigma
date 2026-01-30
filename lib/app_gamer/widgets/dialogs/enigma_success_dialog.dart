import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../utils/app_colors.dart';

// Diálogo para quando um enigma é resolvido, mas a fase ainda não acabou.
void showEnigmaSuccessDialog(
  BuildContext context, {
  required VoidCallback onContinue,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/check.json', // Animação de "check"
                height: 130,
                repeat: false,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enigma Resolvido!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onContinue,
                  child: const Text(
                    'Próximo Desafio',
                    style: TextStyle(fontSize: 18, color: textColor),
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
