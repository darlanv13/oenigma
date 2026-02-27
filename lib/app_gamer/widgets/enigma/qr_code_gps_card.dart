import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../../stores/enigma_store.dart';

class QrCodeGpsCard extends StatelessWidget {
  final EnigmaStore store;
  final EnigmaModel enigma;
  final VoidCallback onScan;

  const QrCodeGpsCard({
    super.key,
    required this.store,
    required this.enigma,
    required this.onScan,
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
                'MISSÃO DE CAMPO',
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (enigma.imageUrl != null && enigma.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(enigma.imageUrl!),
                )
              else
                Lottie.asset('assets/animations/no_enigma.json', height: 150),
              const SizedBox(height: 16),
              Text(
                enigma.instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: textColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Observer(
                builder: (_) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: darkBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: store.distance == null
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: secondaryTextColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Localizando alvo...",
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "Distância: ${store.distance!.toStringAsFixed(0)} metros",
                          style: const TextStyle(
                            fontSize: 14,
                            color: primaryAmber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Observer(
                builder: (_) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: store.isNear && !store.isBlocked ? onScan : null,
                    icon: Icon(
                      store.isBlocked
                          ? Icons.timer_off_outlined
                          : Icons.qr_code_scanner,
                    ),
                    label: Text(
                      store.isBlocked
                          ? 'Aguarde o Cooldown'
                          : (store.isNear
                              ? 'ESCANEAR CÓDIGO'
                              : 'APROXIME-SE DO LOCAL'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: store.isNear && !store.isBlocked
                          ? Colors.green
                          : cardColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      elevation: 0,
                      side: BorderSide(
                        color: store.isNear && !store.isBlocked
                            ? Colors.transparent
                            : Colors.white10,
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
