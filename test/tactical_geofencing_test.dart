import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

/// Cálculo de Distância Haversine em metros
double calculateHaversineDistance({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const double earthRadiusMeters = 6371000.0;
  final double dLat = _degToRad(lat2 - lat1);
  final double dLon = _degToRad(lon2 - lon1);

  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMeters * c;
}

double _degToRad(double deg) => deg * (math.pi / 180.0);

/// Checa se uma velocidade calculada entre dois pontos representa anomalia de teletransporte
bool isImpossibleTravel({
  required double distanceMeters,
  required double elapsedSeconds,
  double maxSpeedKmH = 100.0,
}) {
  if (elapsedSeconds <= 0) return distanceMeters > 50; // salto instantâneo
  final double speedKmH = (distanceMeters / elapsedSeconds) * 3.6;
  return speedKmH > maxSpeedKmH;
}

/// Verifica se o usuário está dentro do raio tático com tolerância de drift urbano
bool isWithinTacticalGeofence({
  required double userLat,
  required double userLon,
  required double targetLat,
  required double targetLon,
  required double tacticalRadiusMeters,
  double urbanDriftToleranceMeters = 50.0,
}) {
  final double distance = calculateHaversineDistance(
    lat1: userLat,
    lon1: userLon,
    lat2: targetLat,
    lon2: targetLon,
  );
  final double maxAllowed = math.max(tacticalRadiusMeters, 150.0) + urbanDriftToleranceMeters;
  return distance <= maxAllowed;
}

void main() {
  group('Tactical Geofencing & Anti-Cheat Suite', () {
    // Coordenadas de teste: Praça dos Três Poderes (Brasília)
    const double targetLat = -15.8000;
    const double targetLon = -47.8600;

    test('Deve calcular distância próxima a zero para mesmo ponto', () {
      final distance = calculateHaversineDistance(
        lat1: targetLat,
        lon1: targetLon,
        lat2: targetLat,
        lon2: targetLon,
      );
      expect(distance, closeTo(0.0, 0.01));
    });

    test('Deve aprovar usuário dentro do raio tático permitido', () {
      // Ponto a aproximadamente 35 metros do alvo
      const double userLat = -15.8003;
      const double userLon = -47.8600;

      final isAllowed = isWithinTacticalGeofence(
        userLat: userLat,
        userLon: userLon,
        targetLat: targetLat,
        targetLon: targetLon,
        tacticalRadiusMeters: 50.0,
      );

      expect(isAllowed, isTrue);
    });

    test('Deve rejeitar usuário fora do raio permitido (tentativa remota)', () {
      // Ponto a mais de 1 km de distância
      const double remoteLat = -15.8150;
      const double remoteLon = -47.8700;

      final isAllowed = isWithinTacticalGeofence(
        userLat: remoteLat,
        userLon: remoteLon,
        targetLat: targetLat,
        targetLon: targetLon,
        tacticalRadiusMeters: 50.0,
      );

      expect(isAllowed, isFalse);
    });

    test('Deve detectar anomalia de Impossible Travel (Teletransporte > 100 km/h)', () {
      // 5 km percorridos em apenas 30 segundos = 600 km/h
      final bool anomalous = isImpossibleTravel(
        distanceMeters: 5000,
        elapsedSeconds: 30,
        maxSpeedKmH: 100.0,
      );
      expect(anomalous, isTrue);
    });

    test('Deve considerar caminhada urbana realista como segura', () {
      // 300 metros percorridos em 3 minutos (180 segundos) = 6 km/h
      final bool anomalous = isImpossibleTravel(
        distanceMeters: 300,
        elapsedSeconds: 180,
        maxSpeedKmH: 100.0,
      );
      expect(anomalous, isFalse);
    });
  });
}
