import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WinnerCertificateScreen extends StatefulWidget {
  final EventModel event;
  final double prizeWon;
  final List<PhaseModel> allPhases;

  const WinnerCertificateScreen({
    super.key,
    required this.event,
    required this.prizeWon,
    required this.allPhases,
  });

  @override
  State<WinnerCertificateScreen> createState() =>
      _WinnerCertificateScreenState();
}

class _WinnerCertificateScreenState extends State<WinnerCertificateScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _shareCertificate() async {
    final Uint8List? image = await _screenshotController.capture();
    if (image == null) return;

    final directory = await getTemporaryDirectory();
    final imagePath = await File(
      '${directory.path}/certificado_oenigma.png',
    ).create();
    await imagePath.writeAsBytes(image);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(imagePath.path)],
        text:
            'Eu venci o evento "${widget.event.name}" no OEnigma! #OEnigmaApp #CaçadorDeEnigmas',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String winnerFullName = widget.event.winnerName ?? "Vencedor";
    final String winnerFirstName = winnerFullName.split(' ').first;
    final String? winnerPhotoURL = widget.event.winnerPhotoURL;
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "Parabéns, Caçador!",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.amareloVale.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amareloVale.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildEnigmaCityLogo(),
                        const SizedBox(height: 10),
                        Lottie.asset(
                          'assets/animations/trofel.json',
                          height: 120,
                        ),
                        Text(
                          "CERTIFICADO DE CONQUISTA",
                          style: GoogleFonts.poppins(
                            color: AppColors.amareloVale,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.amareloVale,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.amareloVale.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: AppColors.darkBackground,
                                backgroundImage: winnerPhotoURL != null
                                    ? NetworkImage(winnerPhotoURL)
                                    : null,
                                child: winnerPhotoURL == null
                                    ? const FaIcon(
                                        FontAwesomeIcons.solidUser,
                                        size: 40,
                                        color: AppColors.amareloVale,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              top: -2,
                              child: FaIcon(
                                FontAwesomeIcons.medal,
                                color: AppColors.amareloVale,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          winnerFirstName.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "O CAÇADOR Nº 1",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.amareloVale,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        _buildStatItem(
                          "Prêmio Recebido",
                          currencyFormat.format(widget.prizeWon),
                          FontAwesomeIcons.trophy,
                          valueColor: AppColors.amareloVale,
                        ),
                        _buildStatItem(
                          "Posição Final",
                          "#1",
                          FontAwesomeIcons.chartSimple,
                          valueColor: AppColors.verdeVale,
                        ),
                        _buildStatItem(
                          "Fases Concluídas",
                          "${widget.allPhases.length}",
                          FontAwesomeIcons.circleCheck,
                          valueColor: AppColors.verdeVale,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Evento: "${widget.event.name}"',
                          style: GoogleFonts.inter(
                            color: AppColors.cinzaMedio,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: AppColors.gradienteVerdeVale,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.verdeVale.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _shareCertificate,
                    icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 16),
                    label: Text(
                      "Compartilhar Conquista",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildInstructionsCard(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "Voltar para o Início",
                    style: GoogleFonts.poppins(
                      color: AppColors.verdeVale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.1,
              colors: const [
                AppColors.verdeVale,
                AppColors.amareloVale,
                Colors.white,
                Colors.tealAccent,
                Colors.orangeAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnigmaCityLogo() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
        children: const <TextSpan>[
          TextSpan(
            text: 'ENIGMA ',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'CITY',
            style: TextStyle(color: AppColors.amareloVale),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    FaIconData icon, {
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, color: AppColors.cinzaMedio, size: 16),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: GoogleFonts.inter(
              color: AppColors.cinzaMedio,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.circleQuestion,
                color: AppColors.amareloVale,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(
                "Como Receber seu Prêmio",
                style: GoogleFonts.poppins(
                  color: AppColors.amareloVale,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "O valor do prêmio já foi adicionado ao seu saldo na carteira do aplicativo.\n\nVocê pode usá-lo para se inscrever em novos eventos ou solicitar um saque. Para sacar, vá até a sua Carteira e clique no botão 'Sacar'.",
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
