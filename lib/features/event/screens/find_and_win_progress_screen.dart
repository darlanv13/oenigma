import 'dart:async';
// lib/screens/find_and_win_progress_screen.dart

import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oenigma/features/enigma/providers/enigma_repository_provider.dart';
import 'package:intl/intl.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/event_model.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/dialogs/cooldown_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/enigma_success_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/error_dialog.dart';
import 'package:oenigma/features/enigma/screens/enigma_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
 // Para reutilizar o ScannerScreen

class FindAndWinProgressScreen extends ConsumerStatefulWidget {
  final EventModel event;

  const FindAndWinProgressScreen({super.key, required this.event});

  @override
  ConsumerState<FindAndWinProgressScreen> createState() =>
      _FindAndWinProgressScreenState();
}

class _FindAndWinProgressScreenState extends ConsumerState<FindAndWinProgressScreen> {

  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isBlocked = false; // <-- Adicionado para controlar o cooldown

  late final Stream<ParseObject?> _eventStream;

  @override
  void initState() {
    super.initState();
    _eventStream = Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
       final query = QueryBuilder<ParseObject>(ParseObject('Event'))
          ..whereEqualTo('objectId', widget.event.id);
       final response = await query.query();
       if (response.success && response.results != null) {
          return response.results!.first as ParseObject;
       }
       return null;
    });
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
      final result = await ref.read(enigmaRepositoryProvider).callEnigmaFunction('scan_enigma', {
        'eventId': widget.event.id,
        'enigmaId': enigmaId,
        'code': code,
        // Não precisamos de phaseOrder para find_and_win
      });

      final data = Map<String, dynamic>.from(result.result);
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
      body: StreamBuilder<ParseObject?>(
        stream: _eventStream,
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting && !eventSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          if (eventSnapshot.hasError || !eventSnapshot.hasData || eventSnapshot.data == null) {
            return const Center(child: Text("Aguardando carregamento ou evento não encontrado."));
          }

          final eventData = eventSnapshot.data!;
          final currentEnigmaId = eventData.get<String>('currentEnigmaId');
          final eventStatus = eventData.get<String>('status');

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

          return StreamBuilder<ParseObject?>(
            stream: Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
                final q = QueryBuilder<ParseObject>(ParseObject('Enigma'))
                  ..whereEqualTo('objectId', currentEnigmaId);
                final res = await q.query();
                if(res.success && res.results != null) return res.results!.first as ParseObject;
                return null;
            }),
            builder: (context, enigmaSnapshot) {
              if (enigmaSnapshot.connectionState == ConnectionState.waiting && !enigmaSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!enigmaSnapshot.hasData || enigmaSnapshot.data == null) {
                return const Center(
                  child: Text("Enigma atual não encontrado. Aguardando..."),
                );
              }

              final enigmaData = enigmaSnapshot.data!;
              final enigmaMap = <String, dynamic>{
                 'id': enigmaData.objectId,
                 'instruction': enigmaData.get<String>('instruction') ?? '',
                 'prize': enigmaData.get<num>('prize') ?? 0,
                 'imageUrl': enigmaData.get<String>('imageUrl'),
                 'type': enigmaData.get<String>('type') ?? 'text',
              };

              final enigma = EnigmaModel.fromMap(enigmaMap);

              if (enigmaData.get<String>('status') == 'closed') {
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
          FaIcon(FontAwesomeIcons.flag, size: 60, color: primaryAmber),
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
                icon: FaIcon(_isBlocked ? FontAwesomeIcons.clock : FontAwesomeIcons.qrcode,
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
                        : FaIcon(_isBlocked ? FontAwesomeIcons.clock : FontAwesomeIcons.circleCheck,
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
