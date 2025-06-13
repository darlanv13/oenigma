import 'package:flutter/material.dart';

IconData getIconDataFromString(String iconName) {
  switch (iconName) {
    case 'garoa':
      return Icons.cloudy_snowing;
    default:
      return Icons.help_outline;
  }
}

class EventModel {
  final String id;
  final String name;
  final String prize;
  final double price;
  final IconData icon;
  final String startDate;
  final String location;
  final String fullLocation;

  EventModel({
    required this.id,
    required this.name,
    required this.prize,
    required this.price,
    required this.icon,
    required this.startDate,
    required this.location,
    required this.fullLocation,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Evento Desconhecido',
      prize: map['prize'] ?? 'R\$ 0',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      icon: getIconDataFromString(map['icon'] ?? 'help_outline'),
      startDate: map['startDate'] ?? 'Data não definida',
      location: map['location'] ?? 'Local não definido',
      fullLocation: map['fullLocation'] ?? 'Localização completa não definida',
    );
  }
}
