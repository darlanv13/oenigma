import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EventsSectionHeader extends StatelessWidget {
  const EventsSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const FaIcon(
            FontAwesomeIcons.mapLocationDot,
            color: primaryAmber,
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
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Eventos disponíveis no momento",
              style: TextStyle(fontSize: 12, color: secondaryTextColor),
            ),
          ],
        ),
      ],
    );
  }
}
