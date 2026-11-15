// lib/core/models/gamification_model.dart
// Conformidade com o PRD v1.0 (README.md - Seções 7.4, 7.5 e 13)

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class EnigmaLevel {
  final int level;
  final String title;
  final int minXP;
  final int? nextXP;
  final Color color;
  final dynamic icon;

  const EnigmaLevel({
    required this.level,
    required this.title,
    required this.minXP,
    this.nextXP,
    required this.color,
    required this.icon,
  });

  static EnigmaLevel fromXP(int xp) {
    if (xp >= 3501) {
      return const EnigmaLevel(
        level: 5,
        title: 'Lenda O Enigma',
        minXP: 3501,
        nextXP: null,
        color: AppColors.amareloVale,
        icon: FontAwesomeIcons.crown,
      );
    }
    if (xp >= 1501) {
      return const EnigmaLevel(
        level: 4,
        title: 'Especialista',
        minXP: 1501,
        nextXP: 3501,
        color: Colors.purpleAccent,
        icon: FontAwesomeIcons.certificate,
      );
    }
    if (xp >= 501) {
      return const EnigmaLevel(
        level: 3,
        title: 'Desbravador',
        minXP: 501,
        nextXP: 1501,
        color: Colors.lightBlueAccent,
        icon: FontAwesomeIcons.compass,
      );
    }
    if (xp >= 101) {
      return const EnigmaLevel(
        level: 2,
        title: 'Explorador',
        minXP: 101,
        nextXP: 501,
        color: Colors.greenAccent,
        icon: FontAwesomeIcons.binoculars,
      );
    }
    return const EnigmaLevel(
      level: 1,
      title: 'Iniciante',
      minXP: 0,
      nextXP: 101,
      color: Colors.grey,
      icon: FontAwesomeIcons.userCheck,
    );
  }

  double progressInLevel(int currentXP) {
    if (nextXP == null) return 1.0;
    final span = nextXP! - minXP;
    final current = currentXP - minXP;
    return (current / span).clamp(0.0, 1.0);
  }
}

class EnigmaBadge {
  final String id;
  final String name;
  final String description;
  final dynamic icon;
  final Color color;

  const EnigmaBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<EnigmaBadge> officialBadges = [
    EnigmaBadge(
      id: 'first_enigma',
      name: 'Primeiro Enigma',
      description: 'Concluiu sua primeira experiência com sucesso.',
      icon: FontAwesomeIcons.flagCheckered,
      color: Colors.greenAccent,
    ),
    EnigmaBadge(
      id: 'explorer',
      name: 'Explorador',
      description: 'Superou 5 enigmas em diferentes modalidades.',
      icon: FontAwesomeIcons.compass,
      color: Colors.lightBlueAccent,
    ),
    EnigmaBadge(
      id: 'riddle_master',
      name: 'Mestre dos Enigmas',
      description: 'Decifrou charadas avançadas e códigos cifrados.',
      icon: FontAwesomeIcons.brain,
      color: Colors.purpleAccent,
    ),
    EnigmaBadge(
      id: 'frequent_hunter',
      name: 'Participante Frequente',
      description: 'Manteve 7 dias consecutivos de caçada ativa.',
      icon: FontAwesomeIcons.fire,
      color: Colors.orangeAccent,
    ),
    EnigmaBadge(
      id: 'trailblazer',
      name: 'Desbravador',
      description: 'Alcançou o Nível 3 com mais de 500 XP acumulados.',
      icon: FontAwesomeIcons.trophy,
      color: AppColors.amareloVale,
    ),
    EnigmaBadge(
      id: 'challenge_champion',
      name: 'Campeão de Desafios',
      description: 'Submeteu e teve aprovado um desafio criativo comunitário.',
      icon: FontAwesomeIcons.award,
      color: Colors.amberAccent,
    ),
  ];
}
