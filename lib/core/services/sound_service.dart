import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Serviço centralizado para controle de áudio da aplicação.
/// Os efeitos sonoros (SFX) pontuais foram removidos/desativados a pedido do usuário,
/// mantendo exclusivamente a trilha ambiente contínua de mistério e suspense.
class SoundService {
  SoundService._();

  // Player dedicado para a trilha ambiente de mistério
  static final AudioPlayer _ambientPlayer = AudioPlayer();
  static bool _ambientInitialized = false;
  static bool isAmbientMuted = false;
  static bool isAmbientPlaying = false;
  static double ambientVolume = 0.35;

  // Controle de efeitos sonoros (SFX): desativados / silenciados
  static bool sfxEnabled = false;
  static bool isMuted = true;

  /// Inicializa o player da trilha ambiente
  static Future<void> _initAmbient() async {
    if (_ambientInitialized) return;
    try {
      await _ambientPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(ambientVolume);
      _ambientInitialized = true;
    } catch (e) {
      debugPrint('[SoundService] Erro ao inicializar player ambiente: $e');
    }
  }

  /// Inicia a reprodução da música ambiente de mistério em loop contínuo
  static Future<void> startAmbient() async {
    if (isAmbientMuted) return;
    try {
      await _initAmbient();
      await _ambientPlayer.setVolume(ambientVolume);
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.play(AssetSource('sounds/ambient_mystery.wav'));
      isAmbientPlaying = true;
      debugPrint('[SoundService] Trilha sonora de mistério iniciada.');
    } catch (e) {
      debugPrint('[SoundService] Falha ao iniciar som ambiente: $e');
    }
  }

  /// Pausa a trilha ambiente (ex: quando o app entra em segundo plano)
  static Future<void> pauseAmbient() async {
    try {
      await _ambientPlayer.pause();
      isAmbientPlaying = false;
    } catch (_) {}
  }

  /// Retoma a trilha ambiente (ex: quando o app volta ao primeiro plano)
  static Future<void> resumeAmbient() async {
    if (isAmbientMuted) return;
    try {
      await _ambientPlayer.resume();
      isAmbientPlaying = true;
    } catch (_) {
      startAmbient();
    }
  }

  /// Para a trilha ambiente
  static Future<void> stopAmbient() async {
    try {
      await _ambientPlayer.stop();
      isAmbientPlaying = false;
    } catch (_) {}
  }

  /// Alterna o estado de mudo da música ambiente de mistério
  static void toggleAmbientMute() {
    isAmbientMuted = !isAmbientMuted;
    if (isAmbientMuted) {
      _ambientPlayer.pause();
      isAmbientPlaying = false;
    } else {
      resumeAmbient();
    }
  }

  /// Ajusta o volume do som ambiente (0.0 a 1.0)
  static Future<void> setAmbientVolume(double volume) async {
    ambientVolume = volume.clamp(0.0, 1.0);
    try {
      await _ambientPlayer.setVolume(ambientVolume);
    } catch (_) {}
  }

  // =========================================================================
  // EFEITOS SONOROS (SFX) REMOVIDOS / SILENCIADOS
  // Mantidos como no-ops para compatibilidade com chamadas existentes no código
  // =========================================================================

  static Future<void> play(String assetRelativePath) async {
    // Efeitos sonoros removidos conforme solicitação
  }

  static Future<void> playSuccess() async {}
  static Future<void> playError() async {}
  static Future<void> playVictory() async {}
  static Future<void> playReward() async {}
  static Future<void> playUnlock() async {}
  static Future<void> playClick() async {}
  static Future<void> playScan() async {}
  static Future<void> playOpen() async {}
  static Future<void> playCopy() async {}
  static Future<void> playBadge() async {}
  static Future<void> playLevelUp() async {}
  static Future<void> playCheckpoint() async {}

  static void toggleMute() {
    toggleAmbientMute();
  }

  /// Libera recursos dos players
  static Future<void> dispose() async {
    try {
      await _ambientPlayer.dispose();
      _ambientInitialized = false;
      isAmbientPlaying = false;
    } catch (_) {}
  }
}

