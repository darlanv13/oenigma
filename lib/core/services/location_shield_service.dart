import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationShieldStatus {
  ok,
  mockDetected,
  serviceDisabled,
  permissionDenied,
  timeout,
  unknownError,
}

class LocationShieldResult {
  final Position? position;
  final bool isMocked;
  final LocationShieldStatus status;
  final String? errorMessage;

  const LocationShieldResult({
    this.position,
    required this.isMocked,
    required this.status,
    this.errorMessage,
  });

  bool get isSafe => status == LocationShieldStatus.ok && !isMocked && position != null;
}

/// Escudo de Integridade Geográfica (Zero-Trust Anti-Spoofing Shield)
/// Detecta GPS falsificado (Mock Location), permissões ausentes e inconsistências de telemetria.
class LocationShieldService {
  static final LocationShieldService _instance = LocationShieldService._internal();
  factory LocationShieldService() => _instance;
  LocationShieldService._internal();

  /// Obtém e valida a posição do dispositivo contra ferramentas de spoofing
  Future<LocationShieldResult> getVerifiedPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationShieldResult(
          isMocked: false,
          status: LocationShieldStatus.serviceDisabled,
          errorMessage: kIsWeb
              ? 'Acesso à localização desabilitado no navegador. Verifique se o site usa HTTPS e se a localização está ativa.'
              : 'O GPS do dispositivo está desativado. Ative a localização para continuar.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationShieldResult(
            isMocked: false,
            status: LocationShieldStatus.permissionDenied,
            errorMessage: kIsWeb
                ? 'Permissão de localização necessária. Autorize o acesso quando solicitado pelo navegador.'
                : 'Permissão de localização negada.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationShieldResult(
          isMocked: false,
          status: LocationShieldStatus.permissionDenied,
          errorMessage: kIsWeb
              ? 'Permissão de localização bloqueada no navegador. Clique no ícone de cadeado ou configurações do site na barra de endereços para permitir.'
              : 'Permissão de localização permanentemente negada. Habilite nas configurações do sistema.',
        );
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
            timeLimit: Duration(seconds: kIsWeb ? 25 : 12),
          ),
        );
      } catch (posError) {
        if (kIsWeb) {
          // Fallback para precisão baixa/média no navegador caso a primeira tentativa falhe
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 20),
            ),
          );
        } else {
          rethrow;
        }
      }

      // Verificação de Mock Location (Fake GPS)
      if (position.isMocked) {
        debugPrint('⚠️ [LocationShield] Mock Location detectada no dispositivo!');
        return LocationShieldResult(
          position: position,
          isMocked: true,
          status: LocationShieldStatus.mockDetected,
          errorMessage: 'Localização simulada detectada! Desative aplicativos de Fake GPS para jogar.',
        );
      }

      return LocationShieldResult(
        position: position,
        isMocked: false,
        status: LocationShieldStatus.ok,
      );
    } on TimeoutException {
      return LocationShieldResult(
        isMocked: false,
        status: LocationShieldStatus.timeout,
        errorMessage: kIsWeb
            ? 'Tempo limite ao obter localização do navegador. Recarregue a página e autorize o acesso.'
            : 'Tempo limite ao calibrar satélites GPS. Tente novamente a céu aberto.',
      );
    } catch (e) {
      return LocationShieldResult(
        isMocked: false,
        status: LocationShieldStatus.unknownError,
        errorMessage: 'Falha ao validar integridade do GPS: $e',
      );
    }
  }
}
