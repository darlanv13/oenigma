class EventModel {
  final String id;
  final String name;
  final String prize;
  final double price;
  final String icon; // URL da animação Lottie
  final String startDate;
  final String location;
  final String fullDescription;

  // CAMPOS ADICIONADOS PARA O STATUS DO EVENTO
  final String status;
  final String? winnerName;

  EventModel({
    required this.id,
    required this.name,
    required this.prize,
    required this.price,
    required this.icon,
    required this.startDate,
    required this.location,
    required this.fullDescription,
    required this.status, // Novo campo
    this.winnerName, // Novo campo
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Evento Desconhecido',
      prize: map['prize'] ?? 'R\$ 0',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      icon: map['icon'] ?? '',
      startDate: map['startDate'] ?? 'Data não definida',
      location: map['location'] ?? 'Local não definido',
      fullDescription: map['fullDescription'] ?? 'Nenhuma descrição.',
      // Lendo os novos campos do banco de dados
      status: map['status'] ?? 'open',
      winnerName: map['winnerName'],
    );
  }
}
