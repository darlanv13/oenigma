import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';

class PixCheckoutDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final double amount;
  final String transactionId;
  final String copiaCola;
  final VoidCallback onPaymentApproved;

  const PixCheckoutDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.transactionId,
    required this.copiaCola,
    required this.onPaymentApproved,
  });

  @override
  State<PixCheckoutDialog> createState() => _PixCheckoutDialogState();
}

class _PixCheckoutDialogState extends State<PixCheckoutDialog> {
  Timer? _pollingTimer;
  bool _isApproved = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Consulta o status a cada 3 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (_isChecking || _isApproved) return;
    _isChecking = true;

    try {
      final function = ParseCloudFunction('checkPixPaymentStatus');
      final res = await function.execute(parameters: {
        'transactionId': widget.transactionId,
      });

      if (res.success && res.result != null) {
        final data = res.result;
        final status = data is Map ? data['status'] : null;

        if (status == 'approved' || status == 'completed') {
          _pollingTimer?.cancel();
          if (mounted) {
            setState(() => _isApproved = true);
            await Future.delayed(const Duration(milliseconds: 1400));
            if (mounted) {
              Navigator.pop(context);
              widget.onPaymentApproved();
            }
          }
        }
      }
    } catch (_) {
      // Ignora erro temporário de rede na sondagem
    } finally {
      _isChecking = false;
    }
  }

  void _copyPix() {
    Clipboard.setData(ClipboardData(text: widget.copiaCola));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código Pix Copia e Cola copiado! Abra o app do seu banco para pagar.'),
        backgroundColor: AppColors.verdeVale,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.verdeVale, width: 1.5),
      ),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: _isApproved ? _buildSuccessView() : _buildPaymentView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const FaIcon(
            FontAwesomeIcons.circleCheck,
            color: Colors.greenAccent,
            size: 48,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Pagamento Confirmado!',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Liberando acesso imediato...',
          style: GoogleFonts.poppins(
            color: AppColors.cinzaMedio,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.poppins(
                    color: AppColors.cinzaMedio,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.xmark, color: AppColors.cinzaMedio, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Valor a Pagar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.amareloVale.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VALOR A PAGAR:',
                style: GoogleFonts.poppins(
                  color: AppColors.cinzaMedio,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'R\$ ${widget.amount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  color: AppColors.amareloVale,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // QR Code
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: QrImageView(
            data: widget.copiaCola,
            version: QrVersions.auto,
            size: 170.0,
          ),
        ),
        const SizedBox(height: 14),

        // Botão Pix Copia e Cola
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.copy, size: 14),
            label: const Text('Copiar Código Pix Copia e Cola'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _copyPix,
          ),
        ),
        const SizedBox(height: 14),

        // Indicador de Status com Pulso
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.amareloVale,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Aguardando pagamento no seu banco...',
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
