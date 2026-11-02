import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/services/decoy_location_service.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/compass_widget.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_audio_dialog.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/map_radius_widget.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/radar_widget.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';
import 'package:oenigma/app_cliente/features/wallet/screens/wallet_screen.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Central de diálogos e modais para a expedição Enigma (Estilo Indiana Jones / Cores Vale).
class EnigmaDialogs {
  /// Diálogo de confirmação de aquisição (Pista ou Instrumento de Expedição)
  static Future<bool?> showPurchaseConfirmation(
    BuildContext context, {
    required double cost,
    String type = 'Pista',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: AppColors.amareloVale.withValues(alpha: 0.6),
            width: 1.4,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.coins, color: AppColors.amareloVale, size: 18),
            const SizedBox(width: 10),
            Text(
              'Desbloquear $type',
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Desbloquear $type por R\$ ${cost.toStringAsFixed(2)}?\n\nEste valor será deduzido do saldo da sua carteira de explorador.',
          style: GoogleFonts.poppins(color: AppColors.cinzaMedio, height: 1.4, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'VOLTAR',
              style: GoogleFonts.cinzel(color: AppColors.cinzaMedio, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amareloVale,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'SIM, DESBLOQUEAR',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo de saldo insuficiente com atalho para a carteira
  static void showInsufficientFunds(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: AppColors.amareloVale.withValues(alpha: 0.6),
            width: 1.4,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.wallet, color: AppColors.amareloVale, size: 20),
            const SizedBox(width: 10),
            Text(
              'Moedas Insuficientes',
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Você não possui saldo suficiente para desbloquear este segredo. Deseja adicionar moedas à sua carteira?',
          style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'AGORA NÃO',
              style: GoogleFonts.cinzel(color: AppColors.cinzaMedio, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amareloVale,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'RECARREGAR CARTEIRA',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo informativo após ativação de instrumento (Bússola, Radar ou Mapa)
  static void showToolActivated(BuildContext context, String toolType) {
    Color accentColor = AppColors.verdeVale;
    String title = 'Mapa da Expedição Aberto!';
    dynamic icon = FontAwesomeIcons.mapLocationDot;
    String description =
        '1. O perímetro da câmara foi traçado no mapa.\n2. A relíquia está dentro deste raio estimado.\n3. Desloque-se até o local e procure a inscrição física.';

    if (toolType == 'compass') {
      accentColor = AppColors.amareloVale;
      title = 'Bússola Dourada Ativada!';
      icon = FontAwesomeIcons.compass;
      description =
          '1. A agulha dourada aponta para a relíquia sagrada.\n2. O ponto brilhante é o local exato.\n3. Gire o celular para orientar a direção.\n4. O medidor rúnico indicará a distância.';
    } else if (toolType == 'radar') {
      accentColor = AppColors.verdeVale;
      title = 'Radar Místico Ativado!';
      icon = FontAwesomeIcons.satelliteDish;
      description =
          '1. O sonar tático faz a varredura 360° do terreno.\n2. O pulso luminoso revela o eco da relíquia.\n3. Aproxime-se guiando-se pelas barras de intensidade do sinal.\n4. Use o botão Pulsar Sonar para disparar varreduras imediatas.';
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        title: Text(
          title,
          style: GoogleFonts.cinzel(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 54,
              color: accentColor,
            ),
            const SizedBox(height: 18),
            Text(
              description,
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: toolType == 'compass' ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'CONTINUAR EXPEDIÇÃO',
                style: GoogleFonts.cinzel(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo de pré-visualização de mídia (imagem ou áudio)
  static void showMediaPreview(
    BuildContext context, {
    required String type,
    required String url,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: type == 'image'
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.network(url, fit: BoxFit.contain),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          radius: 18,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : EnigmaAudioDialog(url: url),
        );
      },
    );
  }

  /// Diálogo de Baú Conquistado (Find & Win)
  static Future<void> showChestWon(
    BuildContext context, {
    required double prizeWon,
    required VoidCallback onDismiss,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.amareloVale, width: 1.5),
        ),
        backgroundColor: AppColors.darkCardColor,
        title: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.trophy,
              color: AppColors.amareloVale,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Baú Conquistado!',
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parabéns, explorador! Você localizou e validou a relíquia sagrada deste baú com glória!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            if (prizeWon > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.coins, color: AppColors.amareloVale, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Recompensa de R\$ ${prizeWon.toStringAsFixed(2).replaceAll('.', ',')} creditada na sua carteira!',
                        style: GoogleFonts.poppins(
                          color: AppColors.verdeVale,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '+50 XP de honra adicionados ao seu perfil de explorador!',
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onDismiss();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'RETORNAR AO ACAMPAMENTO',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo de Jornada Concluída (Final do Evento - Explorador não vencedor)
  static Future<void> showJourneyCompleted(
    BuildContext context, {
    required EventModel event,
    required String winnerName,
    required VoidCallback onDismiss,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.amareloVale, width: 1.5),
        ),
        backgroundColor: AppColors.darkCardColor,
        title: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.trophy,
              color: AppColors.amareloVale,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Expedição Concluída!',
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parabéns! Você decifrou todos os enigmas de todas as câmaras da expedição.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'O grande tesouro de ${event.prize} foi conquistado pelo 1º colocado ($winnerName), mas sua coragem rendeu experiência inestimável!',
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onDismiss();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              'VOLTAR AO INÍCIO',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo de Enigma Resolvido (Avanço para a próxima câmara)
  static Future<void> showNextEnigmaUnlocked(
    BuildContext context, {
    required VoidCallback onNextPressed,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.verdeVale.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.verdeVale, width: 2),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.check,
                    color: AppColors.verdeVale,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enigma Decifrado!',
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Excelente dedução, explorador! A passagem para o próximo enigma foi revelada.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.cinzaMedio,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeVale,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onNextPressed();
                  },
                  child: Text(
                    'PRÓXIMO ENIGMA',
                    style: GoogleFonts.cinzel(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre o Mapa da Expedição em tela cheia
  static void openMapExpanded(
    BuildContext context, {
    required double latitude,
    required double longitude,
    List<DecoyTarget>? targets,
    int remainingSeconds = 900,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.verdeVale.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.mapLocationDot,
                        color: AppColors.verdeVale,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'MAPA DA EXPEDIÇÃO',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MapRadiusWidget(
                  destinationLatitude: latitude,
                  destinationLongitude: longitude,
                  targets: targets,
                  remainingSeconds: remainingSeconds,
                  isCompact: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre a Bússola Dourada expandida em modal com timer
  static void openCompassExpanded(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required int durationSeconds,
    required ValueChanged<int> onTick,
    required VoidCallback onTimeUp,
    List<DecoyTarget>? targets,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.amareloVale.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.compass,
                        color: AppColors.amareloVale,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'BÚSSOLA DOURADA 360°',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CompassWidget(
                targetLatitude: latitude,
                targetLongitude: longitude,
                destinationLongitude: longitude,
                destinationLatitude: latitude,
                durationSeconds: durationSeconds,
                targets: targets,
                isCompact: false,
                onTick: onTick,
                onTimeUp: () {
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.of(dialogContext).pop();
                    onTimeUp();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diálogo expandido em tela cheia do Radar Místico (Sonar 360°)
  static void openRadarExpanded(
    BuildContext context, {
    required double? latitude,
    required double? longitude,
    double? initialDistance,
    List<DecoyTarget>? targets,
    int remainingSeconds = 900,
    VoidCallback? onTimeUp,
    Function(int)? onTick,
  }) {
    SoundService.playOpen();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.verdeVale.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.satelliteDish,
                        color: AppColors.verdeVale,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SONAR TÁTICO DE RELÍQUIAS',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RadarWidget(
                targetLatitude: latitude,
                targetLongitude: longitude,
                initialDistance: initialDistance,
                targets: targets,
                remainingSeconds: remainingSeconds,
                onTimeUp: onTimeUp,
                onTick: onTick,
                isCompact: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre o modal para inscrever código da relíquia manualmente
  static void openManualCodeSheet(
    BuildContext context, {
    required ValueChanged<String> onCodeSubmitted,
  }) {
    SoundService.playOpen();
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.amareloVale, width: 1.3),
      ),
      builder: (modalCtx) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: RelicCornerPainter(
                    color: AppColors.amareloVale.withValues(alpha: 0.3),
                    cornerLength: 20,
                    strokeWidth: 2,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.keyboard,
                              color: AppColors.amareloVale,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'INSCREVER CÓDIGO DA RELÍQUIA',
                              style: GoogleFonts.cinzel(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                          onPressed: () => Navigator.of(modalCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Digite a inscrição gravada na relíquia física que você encontrou no local:',
                      style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12.5),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.cinzel(
                        color: AppColors.amareloVale,
                        fontSize: 18,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.6),
                        hintText: 'EX: RELIQUIA-01',
                        hintStyle: GoogleFonts.cinzel(color: Colors.white24, fontSize: 13),
                        prefixIcon: const Icon(Icons.tag, color: AppColors.amareloVale),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.amareloVale),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.amareloVale.withValues(alpha: 0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.amareloVale, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final code = textController.text.trim();
                        if (code.isNotEmpty) {
                          Navigator.of(modalCtx).pop();
                          onCodeSubmitted(code);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amareloVale,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'DECIFRAR RELÍQUIA',
                        style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
