import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

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
    SoundService.playError();
    _startTimer();
  }

  void _startTimer() {
    _remaining = widget.cooldownUntil.difference(DateTime.now());

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remaining = widget.cooldownUntil.difference(DateTime.now());

      if (_remaining.isNegative || _remaining.inSeconds == 0) {
        timer.cancel();
        widget.onCooldownFinished();
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      } else {
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
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.amareloVale.withValues(alpha: 0.35), width: 1.5),
      ),
      backgroundColor: AppColors.darkCardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/ampulheta.json',
              height: 110,
            ),
            const SizedBox(height: 16),
            Text(
              'Muitas Tentativas',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.amareloVale,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor, aguarde para tentar novamente.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.3)),
              ),
              child: Text(
                _formatDuration(_remaining),
                style: GoogleFonts.orbitron(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amareloVale,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
