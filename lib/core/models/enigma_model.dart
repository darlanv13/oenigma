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

  final bool hasCompass;
  final bool hasMap;
  final bool hasRadar;
  final double mapPrice;
  final double radarPrice;
  final String compassCoords;
  final String mapCoords;
  final String radarCoords;

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
    this.compassPrice = 15.0,
    this.compassDuration = 0,
    this.icon = 'skull',
    this.difficulty = 'MÉDIA',
    this.hasCompass = false,
    this.hasMap = false,
    this.hasRadar = false,
    this.mapPrice = 4.99,
    this.radarPrice = 2.99,
    this.compassCoords = '',
    this.mapCoords = '',
    this.radarCoords = '',
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
    bool? hasCompass,
    bool? hasMap,
    bool? hasRadar,
    double? mapPrice,
    double? radarPrice,
    String? compassCoords,
    String? mapCoords,
    String? radarCoords,
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
      hasCompass: hasCompass ?? this.hasCompass,
      hasMap: hasMap ?? this.hasMap,
      hasRadar: hasRadar ?? this.hasRadar,
      mapPrice: mapPrice ?? this.mapPrice,
      radarPrice: radarPrice ?? this.radarPrice,
      compassCoords: compassCoords ?? this.compassCoords,
      mapCoords: mapCoords ?? this.mapCoords,
      radarCoords: radarCoords ?? this.radarCoords,
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
    } else if (map['compassCoords'] != null &&
        map['compassCoords'].toString().isNotEmpty) {
      try {
        final parts = map['compassCoords'].toString().split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lon = double.tryParse(parts[1].trim());
          if (lat != null && lon != null) {
            parsedLocation = ParseGeoPoint(latitude: lat, longitude: lon);
          }
        }
      } catch (e) {
        // Ignora erro de parsing e deixa nulo
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
      compassPrice: (map['compassPrice'] as num?)?.toDouble() ?? 15.0,
      compassDuration: (map['compassDuration'] as num?)?.toInt() ?? 0,
      icon: map['icon'] ?? 'skull',
      difficulty: map['difficulty'] ?? 'MÉDIA',

      hasCompass: map['hasCompass'] ?? false,
      hasMap: map['hasMap'] ?? false,
      hasRadar: map['hasRadar'] ?? false,
      mapPrice: (map['mapPrice'] as num?)?.toDouble() ?? 4.99,
      radarPrice: (map['radarPrice'] as num?)?.toDouble() ?? 2.99,
      compassCoords: map['compassCoords'] ?? '',
      mapCoords: map['mapCoords'] ?? '',
      radarCoords: map['radarCoords'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'instruction': instruction,
      'title': title,
      'code': code,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'location': location,
      'hintType': hintType,
      'hintData': hintData,
      'hintPrice': hintPrice,
      'prize': prize,
      'order': order,
      'characteristics': characteristics,
      'status': status,
      'closedAt': closedAt?.toIso8601String(),
      'compassPrice': compassPrice,
      'compassDuration': compassDuration,
      'icon': icon,
      'difficulty': difficulty,

      'hasCompass': hasCompass,
      'hasMap': hasMap,
      'hasRadar': hasRadar,
      'mapPrice': mapPrice,
      'radarPrice': radarPrice,
      'compassCoords': compassCoords,
      'mapCoords': mapCoords,
      'radarCoords': radarCoords,
    };
  }
}
