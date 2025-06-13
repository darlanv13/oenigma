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
    
    // Verificação defensiva para a lista de enigmas
    if (map['enigmas'] is List) {
      final enigmasData = map['enigmas'] as List;
      // Itera de forma segura, garantindo que cada item é um mapa válido
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
