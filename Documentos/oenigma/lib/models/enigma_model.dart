import 'package:cloud_firestore/cloud_firestore.dart';

class EnigmaModel {
  final String id;
  final String question;
  final String hint;
  final String code;
  final GeoPoint location;

  EnigmaModel({
    required this.id,
    required this.question,
    required this.hint,
    required this.code,
    required this.location,
  });

  factory EnigmaModel.fromMap(Map<String, dynamic> map) {
    double latitude = 0.0;
    double longitude = 0.0;

    // CORREÇÃO FINAL APLICADA AQUI
    if (map['location'] != null) {
      // Primeiro, checa se o dado já é um GeoPoint nativo do Firestore.
      if (map['location'] is GeoPoint) {
        final locationData = map['location'] as GeoPoint;
        latitude = locationData.latitude;
        longitude = locationData.longitude;
      }
      // Se não for, checa se é um mapa genérico (vindo da Cloud Function).
      else if (map['location'] is Map) {
        // Converte o mapa de localização de forma SEGURA.
        final locationMap = Map<String, dynamic>.from(map['location']);
        
        latitude = (locationMap['_latitude'] as num?)?.toDouble() ?? 0.0;
        longitude = (locationMap['_longitude'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return EnigmaModel(
      id: map['id']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      hint: map['hint']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      location: GeoPoint(latitude, longitude),
    );
  }
}