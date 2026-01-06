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
  final String eventType; // <-- NOVO CAMPO: 'classic' ou 'find_and_win'
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
    this.eventType = 'classic', // <-- NOVO CAMPO
    this.enigmas = const [], // Valor padrão
  });
  factory EventModel.fromMap(Map<String, dynamic> map) {
    var phasesList = <PhaseModel>[];
    if (map['phases'] is List) {
      phasesList = (map['phases'] as List)
          .map(
            (phaseData) =>
                PhaseModel.fromMap(Map<String, dynamic>.from(phaseData)),
          )
          .toList();
    }

    var enigmasList = <EnigmaModel>[];
    if (map['enigmas'] is List) {
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
      status: map['status'] ?? 'open',
      winnerName: map['winnerName'],
      winnerPhotoURL: map['winnerPhotoURL'], // <-- 3. LEIA O DADO DO MAPA
      phases: phasesList,
      playerCount: map['playerCount'] ?? 0,
      eventType: map['eventType'] ?? 'classic', // <-- Lendo o novo campo
      enigmas: enigmasList,
    );
  }

  // Adicione este método dentro da classe EventModel
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
      // Precisamos converter as listas de objetos para listas de Maps
      'phases': phases.map((x) => x.toMap()).toList(),
      'enigmas': enigmas.map((x) => x.toMap()).toList(),
    };
  }
}
