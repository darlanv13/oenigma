// lib/screens/find_and_win_progress_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/services/firebase_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/dialogs/cooldown_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/enigma_success_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/error_dialog.dart';
import 'package:oenigma/features/enigma/screens/enigma_screen.dart'; // Para reutilizar o ScannerScreen

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
  bool _isBlocked = false; // <-- Adicionado para controlar o cooldown

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _eventStream;

  @override
  void initState() {
    super.initState();
    _eventStream = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .snapshots();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE COOLDOWN ADICIONADA ---
  void _handleCooldown(String cooldownUntilStr) {
    final cooldownUntil = DateTime.parse(cooldownUntilStr);
    if (cooldownUntil.isAfter(DateTime.now())) {
      setState(() => _isBlocked = true);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CooldownDialog(
          cooldownUntil: cooldownUntil,
          onCooldownFinished: () {
            if (mounted) {
              setState(() => _isBlocked = false);
            }
          },
        ),
      );
    }
  }

  // --- LÓGICA DE VALIDAÇÃO ATUALIZADA ---
  Future<void> _validateCode(String enigmaId, String code) async {
    if (code.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final result = await _firebaseService.callFunction('handleEnigmaAction', {
        'eventId': widget.event.id,
        'enigmaId': enigmaId,
        'code': code,
        // Não precisamos de phaseOrder para find_and_win
      });

      final data = Map<String, dynamic>.from(result.data);
      if (mounted && !(data['success'] as bool)) {
        final message = data['message'] ?? "Código incorreto.";
        // Verifica se a resposta contém um tempo de cooldown
        if (data['cooldownUntil'] != null) {
          _handleCooldown(data['cooldownUntil']);
        } else {
          showErrorDialog(context, message: message);
        }
      } else if (mounted) {
        _codeController.clear();
        // Mostra um diálogo de sucesso antes de carregar o próximo
        showEnigmaSuccessDialog(
          context,
          onContinue: () {
            Navigator.of(context).pop();
          },
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, message: "Ocorreu um erro: ${e.toString()}");
      }
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
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          if (eventSnapshot.hasError) {
            return const Center(child: Text("Erro ao carregar o evento."));
          }
          if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
            return const Center(child: Text("Evento não encontrado."));
          }

          final eventData = eventSnapshot.data!.data();
          final currentEnigmaId = eventData?['currentEnigmaId'] as String?;
          final eventStatus = eventData?['status'] as String?;

          if (eventStatus == 'closed' &&
              (currentEnigmaId == null || currentEnigmaId.isEmpty)) {
            return _buildEventFinishedWidget();
          }

          if (currentEnigmaId == null || currentEnigmaId.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryAmber),
                  SizedBox(height: 16),
                  Text(
                    "Preparando próximo enigma...",
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .doc(widget.event.id)
                .collection('enigmas')
                .doc(currentEnigmaId)
                .snapshots(),
            builder: (context, enigmaSnapshot) {
              if (enigmaSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!enigmaSnapshot.hasData || !enigmaSnapshot.data!.exists) {
                return const Center(
                  child: Text("Enigma atual não encontrado. Aguardando..."),
                );
              }

              final enigmaData = enigmaSnapshot.data!.data()!;
              final enigma = EnigmaModel.fromMap({
                'id': enigmaSnapshot.data!.id,
                ...enigmaData,
              });

              if (enigmaData['status'] == 'closed') {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Outro jogador resolveu este enigma!"),
                      Text("Aguardando o próximo..."),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PrizeHeader(prize: enigma.prize),
                    const SizedBox(height: 20),
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

  Widget _buildEventFinishedWidget() {
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

  // --- ÁREA DE AÇÃO ATUALIZADA COM VERIFICAÇÃO DE BLOQUEIO ---
  Widget _buildActionArea(EnigmaModel enigma) {
    final supportedTypes = ['qr_code_gps', 'photo_location', 'text'];
    if (!supportedTypes.contains(enigma.type)) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (enigma.type == 'qr_code_gps')
              ElevatedButton.icon(
                onPressed: _isLoading || _isBlocked
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScannerScreen(
                            onScan: (scannedCode) =>
                                _validateCode(enigma.id, scannedCode),
                          ),
                        ),
                      ),
                icon: Icon(
                  _isBlocked ? Icons.timer_off_outlined : Icons.qr_code_scanner,
                ),
                label: Text(_isBlocked ? 'Aguarde' : 'Escanear QR Code'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              )
            else
              Column(
                children: [
                  TextField(
                    controller: _codeController,
                    enabled: !_isBlocked,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: "Digite a resposta aqui",
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading || _isBlocked
                        ? null
                        : () => _validateCode(
                            enigma.id,
                            _codeController.text.trim(),
                          ),
                    icon: _isLoading
                        ? Container(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isBlocked
                                ? Icons.timer_off_outlined
                                : Icons.check_circle_outline,
                          ),
                    label: Text(_isBlocked ? 'Aguarde' : 'Validar Resposta'),
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
