// lib/widgets/cooldown_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../utils/app_colors.dart';

class CooldownDialog extends StatefulWidget {
  final DateTime cooldownUntil;
  final VoidCallback onCooldownFinished;

  const CooldownDialog({
    super.key,
    required this.cooldownUntil,
    required this.onCooldownFinished,
  });

  @override
  State<CooldownDialog> createState() => _CooldownDialogState();
}

class _CooldownDialogState extends State<CooldownDialog> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    // Calcula a duração restante inicial
    _remaining = widget.cooldownUntil.difference(DateTime.now());

    // Inicia um timer que atualiza a cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remaining = widget.cooldownUntil.difference(DateTime.now());

      if (_remaining.isNegative || _remaining.inSeconds == 0) {
        timer.cancel();
        widget.onCooldownFinished();
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      } else {
        // Força a reconstrução do widget para mostrar o tempo atualizado
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "00:00";
    // Formata a duração para o formato MM:SS
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/ampulheta.json', // Use uma animação de relógio/ampulheta se tiver
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'Muitas Tentativas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryAmber,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Por favor, aguarde para tentar novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 24),
            Text(
              _formatDuration(_remaining),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
