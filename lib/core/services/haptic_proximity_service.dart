import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serviço inteligente de feedback háptico (vibração tátil tipo Sensor Geiger)
/// Gera pulsos táteis acelerados conforme o explorador se aproxima do enigma físico no mundo real.
class HapticProximityService {
  static final HapticProximityService _instance = HapticProximityService._internal();
  factory HapticProximityService() => _instance;
  HapticProximityService._internal();

  Timer? _pulseTimer;
  double _lastDistanceMeters = double.infinity;
  bool _isEnabled = true;
  bool _isActive = false;

  bool get isEnabled => _isEnabled;
  bool get isActive => _isActive;

  void toggleEnabled() {
    _isEnabled = !_isEnabled;
    if (!_isEnabled) {
      stop();
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!_isEnabled) {
      stop();
    }
  }

  /// Inicia ou atualiza a proximidade com o alvo em metros
  void updateDistance(double distanceMeters) {
    if (!_isEnabled || kIsWeb) return;
    _lastDistanceMeters = distanceMeters;

    if (!_isActive) {
      _isActive = true;
      _scheduleNextPulse();
    }
  }

  void _scheduleNextPulse() {
    _pulseTimer?.cancel();
    if (!_isActive || !_isEnabled || kIsWeb) return;

    final distance = _lastDistanceMeters;
    if (distance > 250) {
      // Fora da zona sensorial de proximidade (> 250m)
      _pulseTimer = Timer(const Duration(seconds: 4), _scheduleNextPulse);
      return;
    }

    int intervalMs = 2500;
    if (distance <= 10) {
      // Proximidade crítica (< 10m): Pulso frenético contínuo
      HapticFeedback.heavyImpact();
      intervalMs = 260;
    } else if (distance <= 25) {
      // Muito próximo (10m - 25m)
      HapticFeedback.heavyImpact();
      intervalMs = 450;
    } else if (distance <= 60) {
      // Zona quente (25m - 60m)
      HapticFeedback.mediumImpact();
      intervalMs = 850;
    } else if (distance <= 120) {
      // Zona morna (60m - 120m)
      HapticFeedback.selectionClick();
      intervalMs = 1400;
    } else {
      // Entrada no radar (120m - 250m)
      HapticFeedback.selectionClick();
      intervalMs = 2400;
    }

    _pulseTimer = Timer(Duration(milliseconds: intervalMs), _scheduleNextPulse);
  }

  /// Para o loop de vibração (ex: ao fechar a tela ou validar o código)
  void stop() {
    _isActive = false;
    _pulseTimer?.cancel();
    _pulseTimer = null;
  }
}

