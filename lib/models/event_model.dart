// lib/models/event_model.dart

import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/models/phase_model.dart';

class EventModel {
  final String id;
  final String name;
  final String prize; // No modo Find & Win, este será o prêmio total (soma)
  final double price;
  final String icon;
  final String startDate;
  final String location;
  final String fullDescription;
  final String status;
  final String? winnerName;
  final String? winnerPhotoURL;
  final int playerCount;
  final List<PhaseModel> phases;
  final String eventType; // 'classic' ou 'find_and_win'
  final List<EnigmaModel> enigmas; // Para o modo Find & Win

  EventModel({
    required this.id,
    required this.name,
    required this.prize,
    required this.price,
    required this.icon,
    required this.startDate,
    required this.location,
    required this.fullDescription,
    required this.status,
    this.winnerName,
    this.winnerPhotoURL,
    this.phases = const [],
    this.playerCount = 0,
    this.eventType = 'classic',
    this.enigmas = const [],
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    // Conversão segura da Lista de Fases
    List<PhaseModel> phasesList = [];
    if (map['phases'] != null) {
      phasesList = (map['phases'] as List)
          .map(
            (phaseData) =>
                PhaseModel.fromMap(Map<String, dynamic>.from(phaseData)),
          )
          .toList();
    }

    // Conversão segura da Lista de Enigmas (Modo Find & Win)
    List<EnigmaModel> enigmasList = [];
    if (map['enigmas'] != null) {
      enigmasList = (map['enigmas'] as List)
          .map(
            (enigmaData) =>
                EnigmaModel.fromMap(Map<String, dynamic>.from(enigmaData)),
          )
          .toList();
    }

    return EventModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Evento Desconhecido',
      prize: map['prize'] ?? 'R\$ 0',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      icon: map['icon'] ?? '',
      startDate: map['startDate'] ?? 'Data não definida',
      location: map['location'] ?? 'Local não definido',
      fullDescription: map['fullDescription'] ?? 'Nenhuma descrição.',
      status: map['status'] ?? 'dev',
      winnerName: map['winnerName'],
      winnerPhotoURL: map['winnerPhotoURL'],
      phases: phasesList,
      playerCount: map['playerCount'] ?? 0,
      eventType: map['eventType'] ?? 'classic',
      enigmas: enigmasList,
    );
  }

  // --- CORREÇÃO IMPORTANTE AQUI ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'prize': prize,
      'price': price,
      'icon': icon,
      'startDate': startDate,
      'location': location,
      'fullDescription': fullDescription,
      'status': status,
      'winnerName': winnerName,
      'winnerPhotoURL': winnerPhotoURL,
      'playerCount': playerCount,
      'eventType': eventType,
      // Converte os objetos para Map antes de enviar ao Firebase
      'phases': phases.map((x) => x.toMap()).toList(),
      'enigmas': enigmas.map((x) => x.toMap()).toList(),
    };
  }

  // --- NOVOS GETTERS AUXILIARES ---
  // Use estes getters na UI para deixar o código mais limpo:
  // Ex: if (event.isFindAndWin) { ... }

  bool get isFindAndWin => eventType == 'find_and_win';
  bool get isClassic => eventType == 'classic';

  bool get isOpen => status == 'open';
  bool get isDev => status == 'dev';
  bool get isClosed => status == 'closed';
}
