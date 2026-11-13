import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class CooldownDialog extends StatefulWidget {
  final DateTime cooldownUntil;
  final VoidCallback onCooldownFinished;
  final String? eventId;

  const CooldownDialog({
    super.key,
    required this.cooldownUntil,
    required this.onCooldownFinished,
    this.eventId,
  });

  @override
  State<CooldownDialog> createState() => _CooldownDialogState();
}

class _CooldownDialogState extends State<CooldownDialog> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isSkipping = false;

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

  Future<void> _skipCooldownWithBalance() async {
    if (widget.eventId == null || _isSkipping) return;

    setState(() => _isSkipping = true);
    try {
      final function = ParseCloudFunction('handleEnigmaAction');
      final response = await function.execute(parameters: {
        'action': 'skipCooldown',
        'eventId': widget.eventId,
      });

      if (response.success && response.result != null) {
        final data = Map<String, dynamic>.from(response.result as Map);
        if (data['success'] == true) {
          SoundService.playSuccess();
          if (mounted) {
            _timer?.cancel();
            widget.onCooldownFinished();
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚡ Penalidade de tempo cancelada com sucesso! Continue caçando!'),
                backgroundColor: AppColors.verdeVale,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      final errorMsg = response.error?.message ?? 'Saldo insuficiente para pular o cooldown.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSkipping = false);
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/ampulheta.json',
              height: 100,
            ),
            const SizedBox(height: 12),
            Text(
              'Penalidade de Tempo',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.amareloVale,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Código incorreto. Aguarde a ampulheta esgotar ou use seu saldo para pular instantaneamente.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), height: 1.35),
            ),
            const SizedBox(height: 16),
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
            if (widget.eventId != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSkipping ? null : _skipCooldownWithBalance,
                  icon: _isSkipping
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const FaIcon(FontAwesomeIcons.bolt, size: 14, color: Colors.black),
                  label: Text(
                    _isSkipping ? 'PULANDO...' : 'PULAR ESPERA (R\$ 1,99)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amareloVale,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
