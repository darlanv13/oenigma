import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Passaporte do Caçador: Card celebrativo para compartilhamento em redes sociais
/// (Instagram Stories, WhatsApp, TikTok e Twitter)
class HunterShareCard extends StatefulWidget {
  final String playerName;
  final String eventTitle;
  final double prizeWon;
  final int xpGained;
  final String? referralCode;

  const HunterShareCard({
    super.key,
    required this.playerName,
    required this.eventTitle,
    this.prizeWon = 0.0,
    this.xpGained = 50,
    this.referralCode,
  });

  /// Abre o modal interativo com prévia do card e botão de exportação direta
  static Future<void> show(
    BuildContext context, {
    required String playerName,
    required String eventTitle,
    double prizeWon = 0.0,
    int xpGained = 50,
    String? referralCode,
  }) async {
    SoundService.playReward();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HunterShareCard(
        playerName: playerName,
        eventTitle: eventTitle,
        prizeWon: prizeWon,
        xpGained: xpGained,
        referralCode: referralCode,
      ),
    );
  }

  @override
  State<HunterShareCard> createState() => _HunterShareCardState();
}

class _HunterShareCardState extends State<HunterShareCard> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;

  Future<void> _exportAndShare() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 150),
        pixelRatio: 2.5,
      );

      if (imageBytes == null) {
        throw Exception('Falha ao renderizar imagem do cartão.');
      }

      final shareText = '🏆 Acabei de desvendar um enigma em "${widget.eventTitle}" no app O Enigma! '
          '${widget.prizeWon > 0 ? "Ganhei R\$ ${widget.prizeWon.toStringAsFixed(2).replaceAll('.', ',')} reais em prêmio real! " : ""}'
          'Baixe o app e dispute prêmios você também: https://darlanv13.github.io/oenigma';

      if (kIsWeb) {
        await Share.share(shareText, subject: 'Conquista O Enigma');
      } else {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/oenigma_conquista_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = io.File(filePath);
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(filePath, mimeType: 'image/png')],
          text: shareText,
        );
      }

      SoundService.playSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inviteCode = widget.referralCode ?? 'ENIGMA-EXPLORER';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F181D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMPARTILHAR VITÓRIA',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amareloVale,
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cartão do Caçador (Preview Capturável)
          Screenshot(
            controller: _screenshotController,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF16252E), Color(0xFF0D171C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.amareloVale.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header do Cartão
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.amareloVale.withValues(alpha: 0.15),
                              border: Border.all(color: AppColors.amareloVale, width: 1),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.compass,
                              color: AppColors.amareloVale,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'O ENIGMA',
                            style: GoogleFonts.cinzel(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.verdeVale.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.verdeVale, width: 1),
                        ),
                        child: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.shieldHalved, size: 10, color: AppColors.verdeVale),
                            const SizedBox(width: 5),
                            Text(
                              'VERIFICADO',
                              style: GoogleFonts.orbitron(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.verdeVale,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Ícone de Troféu Central
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.amareloVale.withValues(alpha: 0.35),
                          AppColors.amareloVale.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.trophy,
                        color: AppColors.amareloVale,
                        size: 34,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'ENIGMA DESVENDADO!',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.amareloVale,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.eventTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Métricas / Recompensas
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'EXPLORADOR',
                              style: GoogleFonts.orbitron(
                                fontSize: 9,
                                color: AppColors.cinzaMedio,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.playerName.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 26, color: Colors.white24),
                        Column(
                          children: [
                            Text(
                              widget.prizeWon > 0 ? 'PRÊMIO' : 'HONRA',
                              style: GoogleFonts.orbitron(
                                fontSize: 9,
                                color: AppColors.cinzaMedio,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.prizeWon > 0
                                  ? 'R\$ ${widget.prizeWon.toStringAsFixed(2).replaceAll('.', ',')}'
                                  : '+${widget.xpGained} XP',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: widget.prizeWon > 0 ? AppColors.verdeVale : AppColors.amareloVale,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footer com QR Code e Convite
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: QrImageView(
                          data: 'https://darlanv13.github.io/oenigma?ref=$inviteCode',
                          version: QrVersions.auto,
                          size: 52,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CÓDIGO DE CONVITE',
                              style: GoogleFonts.orbitron(
                                fontSize: 8.5,
                                color: AppColors.cinzaMedio,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              inviteCode,
                              style: GoogleFonts.orbitron(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.amareloVale,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              'Participe da caçada ao tesouro real!',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botão de Compartilhar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportAndShare,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const FaIcon(FontAwesomeIcons.shareNodes, size: 16, color: Colors.black),
              label: Text(
                _isExporting ? 'GERANDO CARD...' : 'COMPARTILHAR NO INSTAGRAM / WHATSAPP',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloVale,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
