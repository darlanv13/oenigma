import 'package:cloud_firestore/cloud_firestore.dart';

class EnigmaModel {
  final String id;
  final String type;
  final String instruction;
  final String code;
  final String? imageUrl;
  final GeoPoint? location;
  final String? hintType;
  final String? hintData;
  // --- NOVOS CAMPOS PARA "FIND & WIN" ---
  final int order; // Ordem do enigma na sequência (1, 2, 3...)
  final double prize; // Prêmio específico deste enigma
  final String status; // 'open' ou 'closed'
  final String? winnerId; // UID de quem resolveu

  EnigmaModel({
    required this.id,
    required this.type,
    required this.instruction,
    required this.code,
    this.imageUrl,
    this.location,
    this.hintType,
    this.hintData,
    this.order = 1, // <-- NOVO
    this.prize = 0.0, // <-- NOVO
    this.status = 'open', // <-- NOVO
    this.winnerId, // <-- NOVO
  });

  // --- MÉTODO copyWith ADICIONADO ---
  // Ele cria uma nova instância de EnigmaModel, copiando os valores
  // antigos e substituindo apenas os que são fornecidos.
  EnigmaModel copyWith({
    String? id,
    String? type,
    String? instruction,
    String? code,
    String? imageUrl,
    GeoPoint? location,
    String? hintType,
    String? hintData,
    required double prize,
  }) {
    return EnigmaModel(
      id: id ?? this.id,
      type: type ?? this.type,
      instruction: instruction ?? this.instruction,
      code: code ?? this.code,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      hintType: hintType ?? this.hintType,
      hintData: hintData ?? this.hintData,
    );
  }

  factory EnigmaModel.fromMap(Map<String, dynamic> map) {
    GeoPoint? parsedLocation;
    if (map['location'] is Map) {
      final locationMap = Map<String, dynamic>.from(map['location']);
      final lat = (locationMap['_latitude'] as num?)?.toDouble() ?? 0.0;
      final lon = (locationMap['_longitude'] as num?)?.toDouble() ?? 0.0;
      parsedLocation = GeoPoint(lat, lon);
    }

    return EnigmaModel(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      instruction: map['instruction'] ?? 'Instrução não encontrada',
      code: map['code'] ?? '',
      imageUrl: map['imageUrl'],
      location: parsedLocation,
      hintType: map['hintType'],
      hintData: map['hintData'],
      order: map['order'] ?? 1,
      prize: (map['prize'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'open',
    );
  }
}
