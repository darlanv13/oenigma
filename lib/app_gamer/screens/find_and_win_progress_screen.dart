// lib/app_gamer/screens/find_and_win_progress_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'package:oenigma/app_gamer/widgets/dialogs/cooldown_dialog.dart';
import 'package:oenigma/app_gamer/widgets/dialogs/enigma_success_dialog.dart';
import 'package:oenigma/app_gamer/widgets/dialogs/error_dialog.dart';
import 'enigma_screen.dart'; // For ScannerScreen
import '../stores/find_and_win_store.dart';

class FindAndWinProgressScreen extends StatefulWidget {
  final EventModel event;

  const FindAndWinProgressScreen({super.key, required this.event});

  @override
  State<FindAndWinProgressScreen> createState() =>
      _FindAndWinProgressScreenState();
}

class _FindAndWinProgressScreenState extends State<FindAndWinProgressScreen> {
  final FindAndWinStore _store = FindAndWinStore();
  final TextEditingController _codeController = TextEditingController();
  
  ReactionDisposer? _blockedDisposer;
  ReactionDisposer? _errorDisposer;
  ReactionDisposer? _successDisposer;

  @override
  void initState() {
    super.initState();
    _store.init(widget.event.id);
    
    _blockedDisposer = reaction<bool>(
      (_) => _store.isBlocked,
      (isBlocked) {
        if (isBlocked && _store.cooldownUntil != null) {
          _handleCooldown(_store.cooldownUntil!);
        }
      },
    );
    
    _errorDisposer = reaction<String?>(
      (_) => _store.errorMessage,
      (message) {
        if (message != null) {
          showErrorDialog(context, message: message);
          _store.resetError();
        }
      },
    );
    
    _successDisposer = reaction<bool>(
      (_) => _store.success,
      (success) {
        if (success) {
           _codeController.clear();
           showEnigmaSuccessDialog(
              context,
              onContinue: () {
                Navigator.of(context).pop();
              },
           );
           _store.resetSuccess();
        }
      },
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _store.dispose();
    _blockedDisposer?.call();
    _errorDisposer?.call();
    _successDisposer?.call();
    super.dispose();
  }

  void _handleCooldown(String cooldownUntilStr) {
    final cooldownUntil = DateTime.parse(cooldownUntilStr);
    if (cooldownUntil.isAfter(DateTime.now())) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CooldownDialog(
          cooldownUntil: cooldownUntil,
          onCooldownFinished: () {
            if (mounted) {
              _store.setBlocked(false);
            }
          },
        ),
      );
    } else {
        _store.setBlocked(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event.name)),
      body: Observer(
        builder: (_) {
          if (_store.eventData == null) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }

          final currentEnigmaId = _store.currentEnigmaId;
          final eventStatus = _store.eventStatus;

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
          
          if (_store.currentEnigmaData == null) {
               return const Center(
                 child: Text("Enigma atual não encontrado. Aguardando..."),
               );
          }
          
          final enigmaData = _store.currentEnigmaData!;
          final enigma = EnigmaModel.fromMap(enigmaData);

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

  Widget _buildActionArea(EnigmaModel enigma) {
    final supportedTypes = ['qr_code_gps', 'photo_location', 'text'];
    if (!supportedTypes.contains(enigma.type)) {
      return const SizedBox.shrink();
    }
    
    return Observer(
        builder: (_) => Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (enigma.type == 'qr_code_gps')
                  ElevatedButton.icon(
                    onPressed: _store.isLoading || _store.isBlocked
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ScannerScreen(
                                onScan: (scannedCode) =>
                                    _store.validateCode(widget.event.id, enigma.id, scannedCode),
                              ),
                            ),
                          ),
                    icon: Icon(
                      _store.isBlocked ? Icons.timer_off_outlined : Icons.qr_code_scanner,
                    ),
                    label: Text(_store.isBlocked ? 'Aguarde' : 'Escanear QR Code'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: _codeController,
                        enabled: !_store.isBlocked,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: "Digite a resposta aqui",
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _store.isLoading || _store.isBlocked
                            ? null
                            : () => _store.validateCode(
                                widget.event.id,
                                enigma.id,
                                _codeController.text.trim(),
                              ),
                        icon: _store.isLoading
                            ? Container(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _store.isBlocked
                                    ? Icons.timer_off_outlined
                                    : Icons.check_circle_outline,
                              ),
                        label: Text(_store.isBlocked ? 'Aguarde' : 'Validar Resposta'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
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
