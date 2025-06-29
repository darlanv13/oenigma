import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/models/phase_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

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
  // Controlador para capturar o widget do certificado como imagem
  final ScreenshotController _screenshotController = ScreenshotController();
  final AuthService _authService = AuthService();

  Future<void> _shareCertificate() async {
    // Captura o widget como uma imagem (Uint8List)
    final Uint8List? image = await _screenshotController.capture();
    if (image == null) return;

    // Salva a imagem em um arquivo temporário
    final directory = await getTemporaryDirectory();
    final imagePath = await File(
      '${directory.path}/certificado_oenigma.png',
    ).create();
    await imagePath.writeAsBytes(image);

    // Usa o share_plus para compartilhar o arquivo
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
    final winnerName = _authService.currentUser?.displayName ?? "Jogador";
    final winnerPhotoURL = _authService.currentUser?.photoURL;
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parabéns, Caçador!"),
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove a seta de voltar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- O Certificado ---
            Screenshot(
              controller: _screenshotController,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryAmber.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Lottie.asset('assets/animations/trofel.json', height: 120),
                    const Text(
                      "CERTIFICADO DE CONQUISTA",
                      style: TextStyle(
                        color: primaryAmber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: darkBackground,
                      backgroundImage: winnerPhotoURL != null
                          ? NetworkImage(winnerPhotoURL)
                          : null,
                      child: winnerPhotoURL == null
                          ? const Icon(Icons.person, size: 45)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      winnerName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "O CAÇADOR Nº 1",
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 30, color: secondaryTextColor),
                    _buildStatItem(
                      "Prêmio Recebido",
                      currencyFormat.format(widget.prizeWon),
                      Icons.emoji_events_outlined,
                    ),
                    _buildStatItem(
                      "Posição Final",
                      "#1",
                      Icons.leaderboard_outlined,
                    ),
                    _buildStatItem(
                      "Fases Concluídas",
                      "${widget.allPhases.length}",
                      Icons.check_circle_outline,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Evento: "${widget.event.name}"',
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // --- Botão de Compartilhar ---
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE1306C), // Cor do Instagram
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: _shareCertificate,
              icon: const Icon(Icons.share),
              label: const Text(
                "Compartilhar Conquista",
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            // --- Instruções de Saque ---
            _buildInstructionsCard(),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Voltar para o Início",
                style: TextStyle(color: primaryAmber),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: secondaryTextColor, size: 20),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(color: secondaryTextColor, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
        color: darkBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: primaryAmber),
              SizedBox(width: 10),
              Text(
                "Como Receber seu Prêmio",
                style: TextStyle(
                  color: primaryAmber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "O valor do prêmio já foi adicionado ao seu saldo na carteira do aplicativo.\n\nVocê pode usá-lo para se inscrever em novos eventos ou solicitar um saque. Para sacar, vá até a sua Carteira e clique no botão 'Sacar'.",
            style: TextStyle(color: Colors.grey[300], height: 1.5),
          ),
        ],
      ),
    );
  }
}
