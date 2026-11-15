import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class CreatorPromoStoryGenerator extends StatelessWidget {
  final String challengeTitle;
  final String creatorName;
  final String prize;
  final String challengeUrl;

  const CreatorPromoStoryGenerator({
    super.key,
    required this.challengeTitle,
    required this.creatorName,
    required this.prize,
    required this.challengeUrl,
  });

  void _copyStoryLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: challengeUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copiado! Cole na figurinha de Link nos Stories.'),
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.wandMagicSparkles, color: AppColors.amareloVale, size: 16),
              const SizedBox(width: 10),
              Text(
                'GERADOR DE STORIES PARA INSTAGRAM & TIKTOK (9:16)',
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Material pronto para você divulgar em suas redes sociais e atrair milhares de jogadores.',
            style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12),
          ),
          const SizedBox(height: 18),

          Center(
            child: Container(
              width: 290,
              height: 480,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF070B0E), Color(0xFF122029), Color(0xFF091116)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(
                  color: AppColors.amareloVale.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amareloVale.withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Topo
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(FontAwesomeIcons.compass, color: AppColors.amareloVale, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'O ENIGMA // OFICIAL',
                            style: GoogleFonts.cinzel(
                              color: AppColors.amareloVale,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LANÇADO POR $creatorName',
                        style: GoogleFonts.orbitron(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),

                  // Centro
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF16252F),
                          border: Border.all(color: AppColors.amareloVale, width: 2),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.vault,
                          size: 38,
                          color: AppColors.amareloVale,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        challengeTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'PRÊMIO PIX: $prize',
                          style: GoogleFonts.orbitron(
                            color: Colors.greenAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Base com QR Code
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1318),
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
                            size: 42,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ESCANEE PARA JOGAR',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ou arraste para cima e teste sua inteligência!',
                                style: GoogleFonts.inter(
                                  color: AppColors.cinzaMedio,
                                  fontSize: 8,
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
          ),

          const SizedBox(height: 18),

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
                  'Copiar Link para Figurinhas',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: () => _copyStoryLink(context),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF1E3A45)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const FaIcon(FontAwesomeIcons.instagram, size: 14),
                label: Text(
                  'Dicas para Stories',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF101B22),
                      title: Text(
                        'Estratégia de Divulgação Viral',
                        style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        '1. Tire print do card acima e poste nos seus Stories.\n'
                        '2. Adicione a figurinha de LINK do Instagram apontando para o seu link único.\n'
                        '3. Desafie seus seguidores: "Quem conseguir decifrar primeiro leva $prize no Pix!".\n'
                        '4. Abra o Modo Live Streamer durante suas transmissões ao vivo para que a audiência participe em tempo real.',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Entendido!'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
