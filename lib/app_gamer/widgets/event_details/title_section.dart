import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/utils/app_colors.dart';

class TitleSection extends StatelessWidget {
  final EventModel event;

  const TitleSection({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Lottie.asset(
                'assets/animations/trofel.json',
                height: 60,
                width: 60,
                repeat: true,
              ),
              const SizedBox(width: 4),
              const Text(
                'Prêmio:',
                style: TextStyle(color: secondaryTextColor, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                event.prize,
                style: const TextStyle(
                  color: primaryAmber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
