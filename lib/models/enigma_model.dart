import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EnigmaModel {
  final String id;
  final String type;
  final String instruction;
  final String code;
  final String? imageUrl;
  final GeoPoint? location;
  final String? hintType;
  final String? hintData;
  final double hintPrice;
  final double prize;
  final int order;

  EnigmaModel({
    required this.id,
    required this.type,
    required this.instruction,
    required this.code,
    this.imageUrl,
    this.location,
    this.hintType,
    this.hintData,
    this.hintPrice = 0.0,
    this.prize = 0.0,
    this.order = 1,
  });

  EnigmaModel copyWith({
    String? id,
    String? type,
    String? instruction,
    String? code,
    String? imageUrl,
    GeoPoint? location,
    ValueGetter<String?>? hintType,
    String? hintData,
    double? prize,
    int? order,
  }) {
    return EnigmaModel(
      id: id ?? this.id,
      type: type ?? this.type,
      instruction: instruction ?? this.instruction,
      code: code ?? this.code,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      hintType: hintType != null ? hintType() : this.hintType,
      hintData: hintData ?? this.hintData,
      prize: prize ?? this.prize,
      order: order ?? this.order,
    );
  }

  factory EnigmaModel.fromMap(Map<String, dynamic> map) {
    GeoPoint? parsedLocation;
    if (map['location'] is GeoPoint) {
      parsedLocation = map['location'];
    } else if (map['location'] is Map) {
      final locationMap = Map<String, dynamic>.from(map['location']);
      final lat = (locationMap['_latitude'] as num?)?.toDouble() ?? 0.0;
      final lon = (locationMap['_longitude'] as num?)?.toDouble() ?? 0.0;
      parsedLocation = GeoPoint(lat, lon);
    }
    return EnigmaModel(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      instruction: map['instruction'] ?? '',
      code: map['code'] ?? '',
      imageUrl: map['imageUrl'],
      location: parsedLocation,
      hintType: map['hintType'],
      hintData: map['hintData'],
      prize: (map['prize'] as num?)?.toDouble() ?? 0.0,
      order: map['order'] ?? 1,
    );
  }

  // Adicione este método dentro da classe EnigmaModel
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'instruction': instruction,
      'code': code,
      'imageUrl': imageUrl,
      'location': location, // O Firestore aceita GeoPoint direto
      'hintType': hintType,
      'hintData': hintData,
      'hintPrice': hintPrice, // Importante para sua monetização
      'prize': prize,
      'order': order,
    };
  }
}
