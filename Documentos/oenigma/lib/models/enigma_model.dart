import 'package:cloud_firestore/cloud_firestore.dart';

class EnigmaModel {
  final String id;
  final String type; // 'photo_location', 'qr_code_gps', 'text'
  final String instruction;
  final String code;
  final String? imageUrl;
  final GeoPoint? location;
  final String? hintType; // 'photo' ou 'gps'
  final String? hintData; // URL da foto ou coordenadas "lat,lng"

  EnigmaModel({
    required this.id,
    required this.type,
    required this.instruction,
    required this.code,
    this.imageUrl,
    this.location,
    this.hintType,
    this.hintData,
  });

  // --- FÁBRICA CORRIGIDA ---
  factory EnigmaModel.fromMap(Map<String, dynamic> map) {
    GeoPoint? parsedLocation;

    // Lógica para processar a localização
    if (map['location'] != null) {
      // Caso 1: O dado já é um GeoPoint (leitura direta do Firestore)
      if (map['location'] is GeoPoint) {
        parsedLocation = map['location'] as GeoPoint;
      }
      // Caso 2: O dado é um Mapa (vindo de uma Cloud Function)
      else if (map['location'] is Map) {
        final locationMap = Map<String, dynamic>.from(map['location']);
        final lat = (locationMap['_latitude'] as num?)?.toDouble() ?? 0.0;
        final lon = (locationMap['_longitude'] as num?)?.toDouble() ?? 0.0;
        parsedLocation = GeoPoint(lat, lon);
      }
    }

    return EnigmaModel(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      instruction:
          map['instruction'] ?? map['question'] ?? 'Instrução não encontrada',
      code: map['code'] ?? '',
      imageUrl: map['imageUrl'],
      location: parsedLocation, // Usa a localização processada
      hintType: map['hintType'],
      hintData: map['hintData'],
    );
  }
}
