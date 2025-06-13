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

  // Construtor atualizado para lidar com a lista de enigmas aninhada
  factory PhaseModel.fromMap(Map<String, dynamic> map) {
    List<EnigmaModel> enigmasList = [];
    
    // Verifica se a chave 'enigmas' existe e se é uma lista
    if (map['enigmas'] is List) {
      final enigmasData = map['enigmas'] as List;
      // Converte cada item da lista para um EnigmaModel de forma segura
      enigmasList = enigmasData
          .where((e) => e is Map<String, dynamic>)
          .map((e) => EnigmaModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    
    return PhaseModel(
      id: map['id']?.toString() ?? '',
      order: map['order'] as int? ?? 0,
      enigmas: enigmasList,
    );
  }
}
