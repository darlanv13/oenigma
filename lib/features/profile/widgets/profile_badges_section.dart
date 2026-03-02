import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ProfileBadgesSection extends StatelessWidget {
  final Map<String, dynamic> playerData;

  const ProfileBadgesSection({super.key, required this.playerData});

  List<Map<String, dynamic>> _calculateBadges() {
    List<Map<String, dynamic>> badges = [];
    final events = playerData['events'] ?? {};
    final winnerEvents = playerData['winnerEvents'] ?? [];

    // 1. Desbravador (Has participated in at least 1 event)
    if (events.isNotEmpty) {
      badges.add({
        'title': 'Desbravador',
        'icon': Icons.explore,
        'color': Colors.blueAccent,
        'description': 'Entrou em um evento pela primeira vez.'
      });
    } else {
      badges.add({
        'title': 'Desbravador',
        'icon': Icons.explore_off,
        'color': Colors.grey,
        'description': 'Ainda não participou de nenhum evento.',
        'locked': true
      });
    }

    // 2. Primeiro Sangue (Won an event)
    if (winnerEvents.isNotEmpty) {
      badges.add({
        'title': 'Primeiro Sangue',
        'icon': Icons.military_tech,
        'color': primaryAmber,
        'description': 'Venceu um evento em 1º lugar.'
      });
    } else {
      badges.add({
        'title': 'Primeiro Sangue',
        'icon': Icons.military_tech,
        'color': Colors.grey,
        'description': 'Ainda não venceu nenhum evento.',
        'locked': true
      });
    }

    // 3. Veterano (Participated in 5+ events)
    if (events.length >= 5) {
      badges.add({
        'title': 'Veterano',
        'icon': Icons.local_fire_department,
        'color': Colors.deepOrangeAccent,
        'description': 'Participou de 5 ou mais eventos.'
      });
    } else {
      badges.add({
        'title': 'Veterano',
        'icon': Icons.local_fire_department,
        'color': Colors.grey,
        'description': 'Participe de 5 eventos para desbloquear.',
        'locked': true
      });
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final badges = _calculateBadges();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONQUISTAS & MEDALHAS',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: badges.map((badge) {
              final bool isLocked = badge['locked'] == true;
              return Tooltip(
                message: badge['description'],
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: badge['color'].withValues(alpha: 0.2),
                      child: Icon(
                        badge['icon'],
                        size: 30,
                        color: badge['color'],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge['title'],
                      style: TextStyle(
                        color: isLocked ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
