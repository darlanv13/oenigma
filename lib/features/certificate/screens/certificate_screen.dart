// lib/screens/certificate_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oenigma/core/utils/app_colors.dart';
// Importe o plugin de compartilhamento (você precisará adicioná-lo ao pubspec.yaml)
// import 'package:share_plus/share_plus.dart';

class CertificateScreen extends StatelessWidget {
  final String eventName;
  final double prize;

  const CertificateScreen({
    super.key,
    required this.eventName,
    required this.prize,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificado'),
        automaticallyImplyLeading: false, // Oculta o botão de voltar padrão
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.check_circle_outline,
                    size: 72.0,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24.0),
                  const Text(
                    'Parabéns!',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: primaryAmber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Você desvendou um enigma no evento:',
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    eventName,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'E ganhou:',
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    currencyFormat.format(prize),
                    style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32.0),
                  // Adicione o botão de compartilhamento aqui
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar'),
                    onPressed: () {
                      // Implementar a lógica de compartilhamento aqui usando um plugin como share_plus
                      // Exemplo (comente este bloco se você ainda não adicionou o plugin):
                      /*
                      Share.share('Eu desvendei um enigma no evento "$eventName" e ganhei ${currencyFormat.format(prize)}! #OEnigma');
                      */
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Funcionalidade de compartilhamento ainda não implementada neste exemplo.',
                          ),
                          backgroundColor: Colors.grey,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      foregroundColor: darkBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(); // Volta para a tela de progresso
                    },
                    child: const Text('Continuar Jogando'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
