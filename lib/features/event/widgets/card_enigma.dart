import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/enigma/screens/enigma_screen.dart';

class CardEnigma extends StatelessWidget {
  final EnigmaModel enigma;
  final EventModel event;
  final Animation<double> animation;

  const CardEnigma({
    super.key,
    required this.enigma,
    required this.event,
    required this.animation,
  });

  dynamic _getIconForCharacteristic(String key) {
    switch (key) {
      case 'nado': return FontAwesomeIcons.personSwimming;
      case 'corrida': return FontAwesomeIcons.personRunning;
      case 'camera': return FontAwesomeIcons.camera;
      case 'noite': return FontAwesomeIcons.moon;
      case 'dia': return FontAwesomeIcons.sun;
      case 'exploracao': return FontAwesomeIcons.compass;
      case 'escalada': return FontAwesomeIcons.mountain;
      default: return FontAwesomeIcons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isClosed = enigma.status == 'closed';
    bool isTemporarilyBlocked = false;

    if (isClosed && enigma.closedAt != null) {
      final difference = DateTime.now().difference(enigma.closedAt!);
      if (difference.inMinutes < 15) {
        isTemporarilyBlocked = true;
      } else {
        return const SizedBox.shrink(); // Hide completely if more than 15 mins
      }
    }

    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return GestureDetector(
      onTap: () {
        if (isTemporarilyBlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este enigma já foi resolvido por outro jogador e desaparecerá em breve.'), backgroundColor: Colors.red),
          );
          return;
        }

        // Mock a Phase for Find & Win compat
        final mockPhase = PhaseModel(
          id: 'find_and_win',
          order: 1,
          enigmas: [enigma],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnigmaScreen(
              event: event,
              phase: mockPhase,
              initialEnigma: enigma,
              onEnigmaSolved: () {
                // Return handling or rebuild handled by stream
              },
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isTemporarilyBlocked
                  ? [Colors.grey.shade800, Colors.grey.shade600]
                  : [
                      Color.lerp(primaryAmber, Colors.orangeAccent, animation.value)!,
                      Color.lerp(Colors.orangeAccent, primaryAmber, animation.value)!,
                    ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: isTemporarilyBlocked ? Colors.transparent : primaryAmber.withValues(alpha: 0.5 * animation.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        enigma.title.isNotEmpty ? enigma.title : enigma.instruction,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        currencyFormat.format(enigma.prize),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: enigma.characteristics.map((char) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: FaIcon(_getIconForCharacteristic(char), size: 14, color: Colors.black54),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                if (isTemporarilyBlocked)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.lock, color: Colors.white, size: 30),
                          SizedBox(height: 8),
                          Text('RESOLVIDO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
