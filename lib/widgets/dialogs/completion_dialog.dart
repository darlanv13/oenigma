import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../utils/app_colors.dart';

void showCompletionDialog(
  BuildContext context, {
  required VoidCallback onOkPressed,
  required bool isPhaseComplete,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Completion Dialog',
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/check.json',
                  height: 130,
                  repeat: false,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Fase Concluída!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryAmber,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Você desvendou o enigma. Prepare-se para o próximo desafio!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: onOkPressed,
                    child: const Text(
                      'CONTINUAR',
                      style: TextStyle(
                        fontSize: 18,
                        color: darkBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
