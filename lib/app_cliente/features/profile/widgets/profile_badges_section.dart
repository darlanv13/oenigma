import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileBadgesSection extends StatelessWidget {
  final Map<String, dynamic> playerData;
  const ProfileBadgesSection({super.key, required this.playerData});

  List<Map<String, dynamic>> _calculateBadges() {
    List<Map<String, dynamic>> badges = [];
    final events = playerData['events'] ?? {};
    final winnerEvents = playerData['winnerEvents'] ?? [];

    if (events.isNotEmpty) {
      badges.add({
        'title': 'Desbravador',
        'icon': FontAwesomeIcons.compass,
        'color': Colors.blueAccent,
        'description': 'Entrou em um evento pela primeira vez.',
      });
    } else {
      badges.add({
        'title': 'Desbravador',
        'icon': FontAwesomeIcons.compass,
        'color': Colors.grey.shade800,
        'description': 'Ainda não participou de nenhum evento.',
        'locked': true,
      });
    }

    if (winnerEvents.isNotEmpty) {
      badges.add({
        'title': '1º Sangue',
        'icon': FontAwesomeIcons.medal,
        'color': const Color(0xFFFFD54F),
        'description': 'Venceu um evento em 1º lugar.',
      });
    } else {
      badges.add({
        'title': '1º Sangue',
        'icon': FontAwesomeIcons.medal,
        'color': Colors.grey.shade800,
        'description': 'Ainda não venceu nenhum evento.',
        'locked': true,
      });
    }

    if (events.length >= 5) {
      badges.add({
        'title': 'Veterano',
        'icon': FontAwesomeIcons.fire,
        'color': Colors.deepOrangeAccent,
        'description': 'Participou de 5 ou mais eventos.',
      });
    } else {
      badges.add({
        'title': 'Veterano',
        'icon': FontAwesomeIcons.fire,
        'color': Colors.grey.shade800,
        'description': 'Participe de 5 eventos para desbloquear.',
        'locked': true,
      });
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final badges = _calculateBadges();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              FaIcon(
                FontAwesomeIcons.award,
                color: Color(0xFFFFD54F),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'CONQUISTAS & MEDALHAS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: badges.map((badge) {
              final bool isLocked = badge['locked'] == true;
              return Tooltip(
                message: badge['description'],
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLocked
                            ? Colors.transparent
                            : badge['color'].withValues(alpha: 0.1),
                        border: Border.all(
                          color: isLocked
                              ? Colors.white.withValues(alpha: 0.05)
                              : badge['color'].withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: FaIcon(
                        badge['icon'],
                        size: 28,
                        color: isLocked ? Colors.grey.shade700 : badge['color'],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge['title'],
                      style: TextStyle(
                        color: isLocked ? Colors.grey.shade600 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
