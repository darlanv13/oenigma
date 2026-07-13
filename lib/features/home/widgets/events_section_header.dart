import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EventsSectionHeader extends StatelessWidget {
  const EventsSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
            ),
          ),
          child: const FaIcon(
            FontAwesomeIcons.mapLocationDot,
            color: Color(0xFFFFD54F),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "ESCOLHA SUA CAÇADA",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD54F), // Destaque na cor do tema
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Eventos disponíveis no momento",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
