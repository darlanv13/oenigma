import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'package:oenigma/widgets/dialogs/error_dialog.dart';
// Importe os outros widgets de enigma que você já tem
import 'enigma_screen.dart'; // Para reutilizar o ScannerScreen, por exemplo

class FindAndWinProgressScreen extends StatefulWidget {
  final EventModel event;

  const FindAndWinProgressScreen({super.key, required this.event});

  @override
  State<FindAndWinProgressScreen> createState() =>
      _FindAndWinProgressScreenState();
}

class _FindAndWinProgressScreenState extends State<FindAndWinProgressScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  // Stream para escutar o documento do evento em tempo real
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _eventStream;

  @override
  void initState() {
    super.initState();
    _eventStream = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .snapshots();
  }

  Future<void> _validateCode(String enigmaId, String code) async {
    setState(() => _isLoading = true);
    try {
      final result = await _firebaseService.callEnigmaFunction('validateCode', {
        'eventId': widget.event.id,
        'enigmaId': enigmaId,
        'code': code,
      });
      final data = Map<String, dynamic>.from(result.data);
      if (mounted && !(data['success'] as bool)) {
        showErrorDialog(
          context,
          message: data['message'] ?? "Código incorreto.",
        );
      } else {
        // O StreamBuilder cuidará da atualização da tela
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event.name)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _eventStream,
        builder: (context, eventSnapshot) {
          if (!eventSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          final eventData = eventSnapshot.data!.data();
          final currentEnigmaId = eventData?['currentEnigmaId'] as String?;

          if (currentEnigmaId == null || currentEnigmaId.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, size: 60, color: primaryAmber),
                  SizedBox(height: 16),
                  Text(
                    "Evento Finalizado!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Todos os enigmas foram resolvidos.",
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ],
              ),
            );
          }

          // Busca os detalhes do enigma atual
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('events')
                .doc(widget.event.id)
                .collection('enigmas')
                .doc(currentEnigmaId)
                .get(),
            builder: (context, enigmaSnapshot) {
              if (!enigmaSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final enigma = EnigmaModel.fromMap({
                'id': enigmaSnapshot.data!.id,
                ...enigmaSnapshot.data!.data()!,
              });

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PrizeHeader(prize: enigma.prize),
                    const SizedBox(height: 20),
                    // Reutilizamos a lógica de exibição do EnigmaScreen
                    _buildEnigmaCard(enigma),
                    const SizedBox(height: 20),
                    _buildActionArea(enigma),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget para destacar o prêmio do enigma
  Widget _PrizeHeader({required double prize}) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryAmber, Colors.orangeAccent],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "PRÊMIO DESTE ENIGMA",
            style: TextStyle(color: darkBackground, letterSpacing: 1.5),
          ),
          Text(
            currencyFormat.format(prize),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: darkBackground,
            ),
          ),
        ],
      ),
    );
  }

  // Widgets reutilizados/adaptados da EnigmaScreen original
  Widget _buildEnigmaCard(EnigmaModel enigma) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (enigma.imageUrl != null && enigma.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(enigma.imageUrl!),
              ),
            const SizedBox(height: 16),
            Text(
              enigma.instruction,
              style: const TextStyle(fontSize: 18, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(EnigmaModel enigma) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (enigma.type == 'qr_code_gps')
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScannerScreen(
                            onScan: (scannedCode) =>
                                _validateCode(enigma.id, scannedCode),
                          ),
                        ),
                      ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Escanear QR Code"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            if (enigma.type == 'photo_location')
              Column(
                children: [
                  TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: "Digite a resposta aqui",
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _validateCode(
                            enigma.id,
                            _codeController.text.trim(),
                          ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Validar Resposta"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
