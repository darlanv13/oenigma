import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class WinnerStoryCardDialog extends StatelessWidget {
  final String playerName;
  final String challengeTitle;
  final String creatorName;
  final String elapsedFormatted;
  final String prize;
  final String challengeUrl;

  const WinnerStoryCardDialog({
    super.key,
    required this.playerName,
    required this.challengeTitle,
    required this.creatorName,
    required this.elapsedFormatted,
    required this.prize,
    required this.challengeUrl,
  });

  void _copyStoryLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: challengeUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link do desafio copiado! Cole no adesivo de Link dos Stories.'),
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior com botão fechar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CARTÃO PARA STORIES (9:16)',
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // O CARD 9:16 PROPRIAMENTE DITO
              Container(
                width: 320,
                height: 520,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF070B0E), Color(0xFF101C24), Color(0xFF0A1218)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(
                    color: AppColors.amareloVale.withValues(alpha: 0.6),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amareloVale.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Topo do Story
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.compass,
                              color: AppColors.amareloVale,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'O ENIGMA • MESTRE SUPREMO',
                              style: GoogleFonts.cinzel(
                                color: AppColors.amareloVale,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'ENIGMA OFICIAL DECIFRADO',
                            style: GoogleFonts.orbitron(
                              color: Colors.greenAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Centro: Troféu, Jogador e Tempo
                    Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF14241F),
                            border: Border.all(color: AppColors.amareloVale, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.amareloVale.withValues(alpha: 0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.trophy,
                              color: AppColors.amareloVale,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          playerName.isNotEmpty ? playerName : 'Caçador Lendário',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quebrou o enigma de $creatorName',
                          style: GoogleFonts.inter(
                            color: AppColors.cinzaMedio,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Placar de Tempo Recorde
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF091014),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1E3A45)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'TEMPO RECORDE',
                                style: GoogleFonts.orbitron(
                                  color: AppColors.cinzaMedio,
                                  fontSize: 8.5,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                elapsedFormatted,
                                style: GoogleFonts.orbitron(
                                  color: Colors.greenAccent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Prêmio Pix: $prize',
                                style: GoogleFonts.inter(
                                  color: AppColors.amareloVale,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Rodapé do Story: QR Code para os amigos jogarem
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1419),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E3A45)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: QrImageView(
                              data: challengeUrl,
                              version: QrVersions.auto,
                              size: 46,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CONSEGUE ME SUPERAR?',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Aponte a câmera e tente quebrar meu tempo no Enigma!',
                                  style: GoogleFonts.inter(
                                    color: AppColors.cinzaMedio,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Botões de Ação
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloVale,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.copy, size: 14),
                    label: Text(
                      'Copiar Link dos Stories',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () => _copyStoryLink(context),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.instagram, size: 14),
                    label: Text(
                      'Postar no Insta',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () => _copyStoryLink(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
