import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/foundation.dart';

class EnigmaModel {
  final String id;
  final String type;
  final String instruction;
  final String title;
  final String code;
  final String? imageUrl;
  final String? audioUrl;
  final ParseGeoPoint? location;
  final String? hintType;
  final String? hintData;
  final double hintPrice;
  final double prize;
  final int order;
  final List<String> characteristics;
  final String? status;
  final DateTime? closedAt;
  final double compassPrice;
  final int compassDuration;
  final String icon;
  final String difficulty;

  EnigmaModel({
    required this.id,
    required this.type,
    required this.instruction,
    this.title = '',
    required this.code,
    this.imageUrl,
    this.audioUrl,
    this.location,
    this.hintType,
    this.hintData,
    this.hintPrice = 0.0,
    this.prize = 0.0,
    this.order = 1,
    this.characteristics = const [],
    this.status,
    this.closedAt,
    this.compassPrice = 0.0,
    this.compassDuration = 0,
    this.icon = 'skull',
    this.difficulty = 'MÉDIA',
  });

  EnigmaModel copyWith({
    String? id,
    String? type,
    String? instruction,
    String? title,
    String? code,
    String? imageUrl,
    String? audioUrl,
    ParseGeoPoint? location,
    ValueGetter<String?>? hintType,
    String? hintData,
    double? prize,
    int? order,
    List<String>? characteristics,
    String? status,
    DateTime? closedAt,
    double? compassPrice,
    int? compassDuration,
    String? icon,
    String? difficulty,
  }) {
    return EnigmaModel(
      id: id ?? this.id,
      type: type ?? this.type,
      instruction: instruction ?? this.instruction,
      title: title ?? this.title,
      code: code ?? this.code,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      location: location ?? this.location,
      hintType: hintType != null ? hintType() : this.hintType,
      hintData: hintData ?? this.hintData,
      prize: prize ?? this.prize,
      order: order ?? this.order,
      characteristics: characteristics ?? this.characteristics,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
      compassPrice: compassPrice ?? this.compassPrice,
      compassDuration: compassDuration ?? this.compassDuration,
      icon: icon ?? this.icon,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  factory EnigmaModel.fromMap(Map<String, dynamic> map) {
    ParseGeoPoint? parsedLocation;
    if (map['location'] is ParseGeoPoint) {
      parsedLocation = map['location'];
    } else if (map['location'] is Map) {
      final locationMap = Map<String, dynamic>.from(map['location']);
      final lat = (locationMap['_latitude'] as num?)?.toDouble() ?? 0.0;
      final lon = (locationMap['_longitude'] as num?)?.toDouble() ?? 0.0;
      parsedLocation = ParseGeoPoint(latitude: lat, longitude: lon);
    } else if (map['compassCoords'] != null && map['compassCoords'].toString().isNotEmpty) {
      final coords = map['compassCoords'].toString().split(',');
      if (coords.length == 2) {
        parsedLocation = ParseGeoPoint(latitude: double.tryParse(coords[0].trim()) ?? 0.0, longitude: double.tryParse(coords[1].trim()) ?? 0.0);
      }
    }
    return EnigmaModel(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      instruction: map['instruction'] ?? '',
      title: map['title'] ?? '',
      code: map['code'] ?? '',
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      location: parsedLocation,
      hintType: map['hintType'],
      hintData: map['hintData'],
      prize: (map['prize'] as num?)?.toDouble() ?? 0.0,
      order: map['order'] ?? 1,
      characteristics:
          (map['characteristics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: map['status'],
      closedAt: map['closedAt'] != null
          ? (map['closedAt'] is DateTime
                ? map['closedAt']
                : DateTime.tryParse(map['closedAt'].toString()))
          : null,
      compassPrice: (map['compassPrice'] as num?)?.toDouble() ?? 0.0,
      compassDuration: (map['compassDuration'] as num?)?.toInt() ?? 0,
      icon: map['icon'] ?? 'skull',
      difficulty: map['difficulty'] ?? 'MÉDIA',
    );
  }

  // Adicione este método dentro da classe EnigmaModel
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'instruction': instruction,
      'title': title,
      'code': code,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'location': location, // O Back4App/Parse aceita ParseGeoPoint direto
      'hintType': hintType,
      'hintData': hintData,
      'hintPrice': hintPrice, // Importante para sua monetização
      'prize': prize,
      'order': order,
      'characteristics': characteristics,
      'status': status,
      'closedAt': closedAt?.toIso8601String(),
      'compassPrice': compassPrice,
      'compassDuration': compassDuration,
      'icon': icon,
      'difficulty': difficulty,
    };
  }
}
