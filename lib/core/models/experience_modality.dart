// lib/core/models/experience_modality.dart
// Conformidade com o PRD v1.0 (README.md - Seções 4 e 8.2)

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

enum ExperienceModality {
  hunt,
  quiz,
  challenge,
  mission,
}

extension ExperienceModalityExtension on ExperienceModality {
  String get code {
    switch (this) {
      case ExperienceModality.hunt:
        return 'HUNT';
      case ExperienceModality.quiz:
        return 'QUIZ';
      case ExperienceModality.challenge:
        return 'CHALLENGE';
      case ExperienceModality.mission:
        return 'MISSION';
    }
  }

  String get title {
    switch (this) {
      case ExperienceModality.hunt:
        return 'O Enigma HUNT';
      case ExperienceModality.quiz:
        return 'O Enigma QUIZ';
      case ExperienceModality.challenge:
        return 'O Enigma CHALLENGE';
      case ExperienceModality.mission:
        return 'O Enigma MISSION';
    }
  }

  String get shortName {
    switch (this) {
      case ExperienceModality.hunt:
        return 'HUNT';
      case ExperienceModality.quiz:
        return 'QUIZ';
      case ExperienceModality.challenge:
        return 'CHALLENGE';
      case ExperienceModality.mission:
        return 'MISSION';
    }
  }

  String get description {
    switch (this) {
      case ExperienceModality.hunt:
        return 'Caça ao tesouro com pistas, radar/bússola/mapa e validação por QR Code.';
      case ExperienceModality.quiz:
        return 'Desafios de perguntas e respostas com pontuação e ranking.';
      case ExperienceModality.challenge:
        return 'Desafios criativos de foto, vídeo ou texto com aprovação.';
      case ExperienceModality.mission:
        return 'Missões sequenciais em etapas encadeadas com barra de progresso.';
    }
  }

  int get creditCost {
    switch (this) {
      case ExperienceModality.hunt:
        return 2; // HUNT consome 2 créditos
      case ExperienceModality.quiz:
      case ExperienceModality.challenge:
      case ExperienceModality.mission:
        return 1; // Outros consomem 1 crédito
    }
  }

  dynamic get icon {
    switch (this) {
      case ExperienceModality.hunt:
        return FontAwesomeIcons.compass;
      case ExperienceModality.quiz:
        return FontAwesomeIcons.circleQuestion;
      case ExperienceModality.challenge:
        return FontAwesomeIcons.camera;
      case ExperienceModality.mission:
        return FontAwesomeIcons.listCheck;
    }
  }

  Color get color {
    switch (this) {
      case ExperienceModality.hunt:
        return AppColors.amareloVale;
      case ExperienceModality.quiz:
        return Colors.blueAccent;
      case ExperienceModality.challenge:
        return Colors.purpleAccent;
      case ExperienceModality.mission:
        return Colors.greenAccent;
    }
  }

  static ExperienceModality fromString(String? val) {
    if (val == null) return ExperienceModality.mission;
    final lower = val.toLowerCase();
    if (lower.contains('hunt')) return ExperienceModality.hunt;
    if (lower.contains('quiz')) return ExperienceModality.quiz;
    if (lower.contains('challenge')) return ExperienceModality.challenge;
    return ExperienceModality.mission;
  }
}
