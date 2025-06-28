import 'package:oenigma/models/phase_model.dart'; // Importe o PhaseModel

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
  // CAMPO ADICIONADO PARA CORRIGIR O ERRO
  final List<PhaseModel> phases;

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
    this.phases = const [], // Define um valor padrão
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    // Lógica para converter os dados das fases, se existirem
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
      phases: phasesList, // Atribui a lista de fases convertida
    );
  }
}
