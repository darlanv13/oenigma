import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Serviço centralizado para reprodução de efeitos sonoros (SFX) na aplicação.
/// Utiliza o pacote `audioplayers` com modo de baixa latência.
class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;
  static bool isMuted = false;

  static Future<void> _init() async {
    if (_initialized) return;
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setReleaseMode(ReleaseMode.stop);
      _initialized = true;
    } catch (e) {
      debugPrint('[SoundService] Erro ao inicializar player: $e');
    }
  }

  /// Toca um arquivo de som contido na pasta de assets.
  /// O `AssetSource` utiliza por padrão o prefixo 'assets/'.
  static Future<void> play(String assetRelativePath) async {
    if (isMuted) return;
    try {
      await _init();
      await _player.stop();
      await _player.play(AssetSource(assetRelativePath));
    } catch (e) {
      debugPrint('[SoundService] Falha ao reproduzir áudio ($assetRelativePath): $e');
    }
  }

  /// Som de sucesso / resposta correta / QR code validado
  static Future<void> playSuccess() => play('sounds/success.mp3');

  /// Som de erro / resposta incorreta / bloqueio / falha
  static Future<void> playError() => play('sounds/error.mp3');

  /// Som triunfante de vitória / encerramento de evento com conquista
  static Future<void> playVictory() => play('sounds/victory.mp3');

  /// Som de recompensa / baú físico aberto / premiação em dinheiro
  static Future<void> playReward() => play('sounds/reward.mp3');

  /// Som de desbloqueio de dica ou equipamento tático (bússola / radar)
  static Future<void> playUnlock() => play('sounds/unlock.mp3');

  /// Som de clique / seleção de abas, filtros e botões
  static Future<void> playClick() => play('sounds/click.mp3');

  /// Som de ativação da mira holográfica e escaneamento QR
  static Future<void> playScan() => play('sounds/scanning.mp3');

  /// Som de abertura de baú, gaveta ou modal de código
  static Future<void> playOpen() => play('sounds/open.mp3');

  /// Som de cópia de chave Pix ou compartilhamento
  static Future<void> playCopy() => play('sounds/copy.mp3');

  /// Som de distintivo / conquista de explorador ou pódio
  static Future<void> playBadge() => play('sounds/badge.mp3');

  /// Som de evolução de nível / ganho de XP
  static Future<void> playLevelUp() => play('sounds/level_up.mp3');

  /// Som de checkpoint ou nova fase liberada
  static Future<void> playCheckpoint() => play('sounds/checkpoint.mp3');

  /// Alterna o estado de mudo dos efeitos sonoros
  static void toggleMute() {
    isMuted = !isMuted;
    if (isMuted) {
      _player.stop();
    }
  }

  /// Libera recursos do player
  static Future<void> dispose() async {
    try {
      await _player.dispose();
      _initialized = false;
    } catch (_) {}
  }
}

