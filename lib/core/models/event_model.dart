// lib/models/event_model.dart

import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/phase_model.dart';

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
  final String prizeType; // 'dinheiro' ou 'objeto'
  final String? prizeImageUrl; // URL da imagem PNG do prêmio
  final String difficulty; // ex: 'Média'

  String get description => fullDescription;

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
    this.prizeType = 'dinheiro',
    this.prizeImageUrl,
    this.difficulty = 'Média',
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

    final rawPrize = map['prize']?.toString() ??
        (map['prizePool'] != null ? map['prizePool'].toString() : '');

    final prizeType = (map['prizeType']?.toString().toLowerCase() == 'objeto' ||
            (map['prizeImageUrl'] != null &&
                map['prizeImageUrl'].toString().trim().isNotEmpty))
        ? 'objeto'
        : 'dinheiro';

    final String? prizeImageUrl =
        map['prizeImageUrl']?.toString() ?? map['imageUrl']?.toString();
    final String difficulty = map['difficulty']?.toString() ?? 'Média';

    final String rawDescription = (map['description']?.toString().trim().isNotEmpty ?? false)
        ? map['description'].toString().trim()
        : (map['fullDescription']?.toString().trim().isNotEmpty ?? false)
            ? map['fullDescription'].toString().trim()
            : (map['descricao']?.toString().trim().isNotEmpty ?? false)
                ? map['descricao'].toString().trim()
                : (map['details']?.toString().trim().isNotEmpty ?? false)
                    ? map['details'].toString().trim()
                    : '';
    final String parsedDescription =
        (rawDescription.isNotEmpty && rawDescription != 'Nenhuma descrição.')
            ? rawDescription
            : '';

    String formattedPrize;
    if (prizeType == 'objeto') {
      formattedPrize = rawPrize.isNotEmpty
          ? rawPrize
          : (map['prizeName']?.toString() ?? 'Prêmio Especial');
    } else {
      if (rawPrize.isEmpty || rawPrize == '0' || rawPrize == 'R\$ 0') {
        formattedPrize = 'R\$ 0,00';
      } else if (!rawPrize.startsWith('R\$')) {
        formattedPrize = 'R\$ $rawPrize';
      } else {
        formattedPrize = rawPrize;
      }
    }

    return EventModel(
      id: map['id'] ?? map['objectId'] ?? '',
      name: map['name'] ?? map['title'] ?? 'Evento Desconhecido',
      prize: formattedPrize,
      price: map['price'] != null
          ? double.tryParse(map['price'].toString()) ?? 0.0
          : 0.0,
      icon: map['icon'] ?? '',
      startDate: map['startDate'] ?? 'Data não definida',
      location: map['location'] ?? 'Local não definido',
      fullDescription: parsedDescription,
      status: map['status'] ?? 'open',
      winnerName: map['winnerName'],
      winnerPhotoURL: map['winnerPhotoURL'],
      phases: phasesList,
      playerCount: map['playerCount'] ?? 0,
      eventType: map['eventType'] ?? 'classic',
      enigmas: enigmasList,
      prizeType: prizeType,
      prizeImageUrl: prizeImageUrl,
      difficulty: difficulty,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'prize': prize,
      'price': price,
      'icon': icon,
      'startDate': startDate,
      'location': location,
      'description': fullDescription,
      'fullDescription': fullDescription,
      'status': status,
      'winnerName': winnerName,
      'winnerPhotoURL': winnerPhotoURL,
      'playerCount': playerCount,
      'eventType': eventType,
      'prizeType': prizeType,
      'prizeImageUrl': prizeImageUrl,
      'difficulty': difficulty,
      'phases': phases.map((x) => x.toMap()).toList(),
      'enigmas': enigmas.map((x) => x.toMap()).toList(),
    };
  }
}
