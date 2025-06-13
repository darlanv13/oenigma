import 'package:cloud_firestore/cloud_firestore.dart';

class EnigmaModel {
  final String id;
  final String question;
  final String hint;
  final String code;
  final GeoPoint location;

  EnigmaModel({
    required this.id, required this.question, required this.hint,
    required this.code, required this.location,
  });

  factory EnigmaModel.fromMap(Map<String, dynamic> map) {
    double latitude = 0.0;
    double longitude = 0.0;

    if (map['location'] is Map) {
      final locationData = map['location'] as Map<String, dynamic>;
      latitude = (locationData['_latitude'] as num?)?.toDouble() ?? 0.0;
      longitude = (locationData['_longitude'] as num?)?.toDouble() ?? 0.0;
    } else if (map['location'] is GeoPoint) {
      latitude = map['location'].latitude;
      longitude = map['location'].longitude;
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
