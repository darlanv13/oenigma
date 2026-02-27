import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../../stores/enigma_store.dart';

class ActionArea extends StatelessWidget {
  final EnigmaStore store;
  final TextEditingController codeController;
  final Animation<double> shakeAnimation;
  final VoidCallback onSubmit;

  const ActionArea({
    super.key,
    required this.store,
    required this.codeController,
    required this.shakeAnimation,
    required this.onSubmit,
  });

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
                'SUA RESPOSTA',
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
          Column(
            children: [
              AnimatedBuilder(
                animation: shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(sin(shakeAnimation.value * pi) * 10, 0),
                    child: child,
                  );
                },
                child: Observer(
                  builder: (_) => TextField(
                    controller: codeController,
                    enabled: !store.isBlocked,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: store.isBlocked ? secondaryTextColor : textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'CÓDIGO',
                      hintStyle: TextStyle(
                        color: secondaryTextColor.withOpacity(0.3),
                        letterSpacing: 2,
                        fontFamily: 'Poppins',
                        fontSize: 24,
                      ),
                      filled: true,
                      fillColor: darkBackground,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: primaryAmber, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Observer(
                builder: (_) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: store.isLoading || store.isBlocked
                        ? null
                        : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      foregroundColor: darkBackground,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: primaryAmber.withOpacity(0.4),
                    ),
                    child: store.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: darkBackground,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            store.isBlocked ? 'Aguarde...' : 'ENVIAR RESPOSTA',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
