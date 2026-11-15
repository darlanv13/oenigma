import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Alvo de relíquia ou eco fantasma gerado no raio de 300 metros.
class DecoyTarget {
  final int index;
  final String label;
  final double latitude;
  final double longitude;
  final bool isReal;

  const DecoyTarget({
    required this.index,
    required this.label,
    required this.latitude,
    required this.longitude,
    this.isReal = false,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);
}

/// Serviço de geração determinística de 4 locais fake em raio de 300 metros do local verdadeiro.
class DecoyLocationService {
  /// Gera deterministamente 5 alvos (1 verdadeiro + 4 fake) no raio de 300 metros.
  /// A lista é embaralhada de forma determinística pelo [enigmaId] para que o local
  /// real não seja adivinhável pelo índice.
  static List<DecoyTarget> generateTargets({
    required String enigmaId,
    required double trueLatitude,
    required double trueLongitude,
  }) {
    // Semente determinística para que os pontos não mudem a cada frame ou reabertura
    final int seed = enigmaId.isNotEmpty ? enigmaId.hashCode : 42;
    final rng = math.Random(seed);

    final List<DecoyTarget> targets = [];

    // 1. Alvo Real
    targets.add(
      DecoyTarget(
        index: 0,
        label: 'Sinal 1',
        latitude: trueLatitude,
        longitude: trueLongitude,
        isReal: true,
      ),
    );

    // 2. Quatro Alvos Falsos distribuídos nos 4 quadrantes cardeais (entre 60m e 290m)
    final List<double> baseAngles = [45.0, 135.0, 225.0, 315.0];

    for (int i = 0; i < 4; i++) {
      // Jitter angular de +/- 30 graus no quadrante
      final double angleJitter = (rng.nextDouble() * 60.0) - 30.0;
      final double bearing = (baseAngles[i] + angleJitter + 360.0) % 360.0;

      // Distância estrita entre 65 metros e 285 metros (dentro do raio de 300m)
      final double distanceMeters = 65.0 + (rng.nextDouble() * 220.0);

      final offsetLatLng = _computeOffset(
        trueLatitude,
        trueLongitude,
        distanceMeters,
        bearing,
      );

      targets.add(
        DecoyTarget(
          index: i + 1,
          label: 'Sinal ${i + 2}',
          latitude: offsetLatLng.latitude,
          longitude: offsetLatLng.longitude,
          isReal: false,
        ),
      );
    }

    // 3. Embaralha de forma pseudoaleatória usando a semente fixa do enigma
    // Algoritmo Fisher-Yates determinístico
    for (int i = targets.length - 1; i > 0; i--) {
      final int j = rng.nextInt(i + 1);
      final temp = targets[i];
      targets[i] = targets[j];
      targets[j] = temp;
    }

    // 4. Renomeia visualmente os índices de 1 a 5 para não vazar a posição original
    return List.generate(targets.length, (idx) {
      final t = targets[idx];
      return DecoyTarget(
        index: idx + 1,
        label: 'Sinal ${idx + 1}',
        latitude: t.latitude,
        longitude: t.longitude,
        isReal: t.isReal,
      );
    });
  }

  /// Deslocamento geodésico exato esférico (Haversine inverso)
  static LatLng _computeOffset(
    double lat,
    double lng,
    double distanceMeters,
    double bearingDegrees,
  ) {
    const double earthRadius = 6371000.0; // metros
    final double distRatio = distanceMeters / earthRadius;
    final double bearingRad = bearingDegrees * math.pi / 180.0;
    final double latRad = lat * math.pi / 180.0;
    final double lngRad = lng * math.pi / 180.0;

    final double targetLatRad = math.asin(
      math.sin(latRad) * math.cos(distRatio) +
          math.cos(latRad) * math.sin(distRatio) * math.cos(bearingRad),
    );

    final double targetLngRad = lngRad +
        math.atan2(
          math.sin(bearingRad) * math.sin(distRatio) * math.cos(latRad),
          math.cos(distRatio) - math.sin(latRad) * math.sin(targetLatRad),
        );

    return LatLng(
      targetLatRad * 180.0 / math.pi,
      targetLngRad * 180.0 / math.pi,
    );
  }
}

