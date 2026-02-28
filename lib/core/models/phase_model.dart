import 'enigma_model.dart';

class PhaseModel {
  final String id;
  final int order;
  final List<EnigmaModel> enigmas;

  const PhaseModel({
    required this.id,
    required this.order,
    this.enigmas = const [],
  });

  factory PhaseModel.fromMap(Map<String, dynamic> map) {
    List<EnigmaModel> enigmasList = [];

    // 1. Verifica se o campo 'enigmas' existe e é uma lista.
    if (map['enigmas'] is List) {
      final enigmasData = map['enigmas'] as List;

      // 2. Mapeia a lista de enigmas de forma SEGURA.
      enigmasList = enigmasData
          .map((enigmaData) {
            // 3. Garante que cada item da lista é um mapa.
            if (enigmaData is Map) {
              // 4. CONVERSÃO SEGURA: Usa Map.from() para criar um novo mapa com os tipos corretos.
              //    Isso elimina o erro de "type cast".
              return EnigmaModel.fromMap(Map<String, dynamic>.from(enigmaData));
            }
            return null; // Descarta itens que não são mapas.
          })
          .whereType<EnigmaModel>()
          .toList(); // Filtra qualquer item nulo/inválido.
    }

    return PhaseModel(
      id: map['id']?.toString() ?? '',
      order: map['order'] as int? ?? 0,
      enigmas: enigmasList,
    );
  }

  // Adicione este método dentro da classe PhaseModel
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order': order,
      // Converte cada objeto EnigmaModel da lista em um Map
      'enigmas': enigmas.map((x) => x.toMap()).toList(),
    };
  }
}
