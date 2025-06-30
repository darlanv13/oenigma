// lib/models/event_model.dart

import 'package:oenigma/models/phase_model.dart';

class EventModel {
  final String id;
  final String name;
  final String prize;
  final double price;
  final String icon;
  final String startDate;
  final String location;
  final String fullDescription;
  final String status;
  final String? winnerName;
  final String? winnerPhotoURL; // <-- 1. ADICIONE ESTA LINHA
  final List<PhaseModel> phases;
  final int playerCount;

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
    this.winnerPhotoURL, // <-- 2. ADICIONE AO CONSTRUTOR
    this.phases = const [],
    this.playerCount = 0,
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
    );
  }
}
