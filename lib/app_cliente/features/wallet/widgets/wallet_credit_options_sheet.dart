import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/app_cliente/features/wallet/providers/wallet_provider.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class CreditOptionsSheet extends StatefulWidget {
  final UserWalletModel wallet;
  final VoidCallback? onPaymentSuccess;

  const CreditOptionsSheet({
    super.key,
    required this.wallet,
    this.onPaymentSuccess,
  });

  @override
  State<CreditOptionsSheet> createState() => _CreditOptionsSheetState();
}

class _CreditOptionsSheetState extends State<CreditOptionsSheet> {
  final _customAmountController = TextEditingController();
  bool _showCustomInput = false;
  String? _customError;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _openPayment(double amount) {
    SoundService.playClick();
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return PaymentBottomSheet(
          amount: amount,
          wallet: widget.wallet,
          onPaymentSuccess: widget.onPaymentSuccess,
        );
      },
    );
  }

  void _submitCustomAmount() {
    final text = _customAmountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      setState(() => _customError = 'Informe um valor válido.');
      return;
    }
    if (amount < 2.0) {
      setState(() => _customError = 'O valor mínimo de depósito é de R\$ 2,00.');
      return;
    }
    setState(() => _customError = null);
    _openPayment(amount);
  }

  @override
  Widget build(BuildContext context) {
    final amounts = [5.0, 10.0, 15.0, 20.0, 50.0, 100.0];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "ADICIONAR SALDO",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Escolha o valor que deseja adicionar à sua carteira via Pix instantâneo.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Opções predefinidas
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: amounts.length,
              itemBuilder: (context, index) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeVale.withValues(alpha: 0.12),
                    foregroundColor: AppColors.verdeVale,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.verdeVale.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                  ),
                  onPressed: () => _openPayment(amounts[index]),
                  child: Text(
                    "R\$ ${amounts[index].toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // Botão para alternar input de outro valor
            if (!_showCustomInput)
              TextButton.icon(
                icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 14, color: AppColors.amareloVale),
                label: Text(
                  "Digitar outro valor personalizado",
                  style: GoogleFonts.inter(color: AppColors.amareloVale, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                onPressed: () => setState(() => _showCustomInput = true),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Valor Personalizado (R\$):',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: 'R\$ ',
                        prefixStyle: GoogleFonts.poppins(color: AppColors.amareloVale, fontSize: 18, fontWeight: FontWeight.bold),
                        hintText: '0,00',
                        hintStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.3)),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.25),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.verdeVale)),
                      ),
                    ),
                    if (_customError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _customError!,
                        style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verdeVale,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _submitCustomAmount,
                      child: Text(
                        'CONTINUAR COM ESTE VALOR',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class PaymentBottomSheet extends ConsumerStatefulWidget {
  final double amount;
  final UserWalletModel wallet;
  final VoidCallback? onPaymentSuccess;

  const PaymentBottomSheet({
    super.key,
    required this.amount,
    required this.wallet,
    this.onPaymentSuccess,
  });

  @override
  ConsumerState<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends ConsumerState<PaymentBottomSheet> {
  bool _isLoading = true;
  String? _error;
  String? _copiaCola;
  String? _txid;
  bool _isApproved = false;
  bool _isVerifyingManual = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    try {
      final result = await ParseCloudFunction('createPixCharge').execute(
        parameters: {'amount': widget.amount},
      );
      if (!result.success) throw result.error ?? ParseError();

      final data = Map<String, dynamic>.from(result.result as Map);

      if (mounted) {
        setState(() {
          _copiaCola = data['copiaCola'] ?? data['qrCode'];
          _txid = data['transactionId'];
          _isLoading = false;
        });

        // Inicia monitoramento automático de status do pagamento a cada 3.5 segundos
        _startPaymentPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startPaymentPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      _checkPaymentStatus(isManual: false);
    });
  }

  Future<void> _checkPaymentStatus({bool isManual = false}) async {
    if (_txid == null || _isApproved) return;

    if (isManual) {
      setState(() => _isVerifyingManual = true);
    }

    try {
      final res = await ParseCloudFunction('checkPixPaymentStatus').execute(
        parameters: {'transactionId': _txid},
      );

      if (res.success && res.result != null) {
        final data = Map<String, dynamic>.from(res.result as Map);
        final status = data['status'];

        if (status == 'approved' || status == 'completed') {
          _pollingTimer?.cancel();
          if (mounted) {
            setState(() {
              _isApproved = true;
              _isVerifyingManual = false;
            });
            SoundService.playReward();
            // Atualiza o estado da carteira no aplicativo imediatamente
            ref.read(authRepositoryProvider).reloadUser().then((_) {
              if (mounted) {
                ref.invalidate(walletProvider);
              }
            }).catchError((_) {});
            widget.onPaymentSuccess?.call();
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('[PaymentStatusCheck] Erro ao checar: $e');
    }

    if (mounted && isManual) {
      setState(() => _isVerifyingManual = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pagamento ainda não identificado. Se acabou de pagar, aguarde alguns instantes.'),
          backgroundColor: AppColors.amareloVale,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_isApproved)
            _buildSuccessState()
          else
            _buildPaymentState(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.verdeVale),
        const SizedBox(height: 16),
        Text(
          "Gerando Cobrança Pix...",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          "Comunicando com o gateway financeiro...",
          style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const FaIcon(
          FontAwesomeIcons.circleExclamation,
          color: AppColors.danger,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          "Erro ao gerar Pix",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? "Erro desconhecido",
          style: GoogleFonts.inter(color: AppColors.cinzaMedio),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("FECHAR", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentState() {
    return Column(
      children: [
        Text(
          "PAGAMENTO VIA PIX",
          style: GoogleFonts.inter(
            color: AppColors.cinzaMedio,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "R\$ ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')}",
          style: GoogleFonts.poppins(
            color: AppColors.amareloVale,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),

        // QR Code renderizado de forma nativa e nítida usando qr_flutter
        if (_copiaCola != null && _copiaCola!.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.verdeVale, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.verdeVale.withValues(alpha: 0.3),
                  blurRadius: 16,
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: QrImageView(
              data: _copiaCola!,
              version: QrVersions.auto,
              size: 190,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.verdeVale,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Aguardando confirmação automática...",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Botão Copiar Código Pix
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: AppColors.gradienteVerdeVale,
            boxShadow: [
              BoxShadow(
                color: AppColors.verdeVale.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.copy, color: Colors.white, size: 16),
            label: const Text(
              "COPIAR CÓDIGO PIX (COPIA E COLA)",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () async {
              if (_copiaCola != null) {
                await Clipboard.setData(ClipboardData(text: _copiaCola!));
                SoundService.playCopy();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "Código Pix copiado para a área de transferência!",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: AppColors.verdeVale,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
          ),
        ),

        const SizedBox(height: 12),

        // Botão para verificação manual instantânea
        OutlinedButton.icon(
          icon: _isVerifyingManual
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const FaIcon(FontAwesomeIcons.arrowsRotate, size: 13, color: Colors.white70),
          label: Text(
            _isVerifyingManual ? "Verificando..." : "Já realizei o pagamento / Verificar agora",
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onPressed: _isVerifyingManual ? null : () => _checkPaymentStatus(isManual: true),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const FaIcon(
          FontAwesomeIcons.circleCheck,
          color: AppColors.verdeVale,
          size: 70,
        ),
        const SizedBox(height: 16),
        Text(
          "PAGAMENTO CONFIRMADO!",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "O valor de R\$ ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')} já foi creditado na sua carteira.",
          style: GoogleFonts.inter(color: AppColors.cinzaMedio),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentSuccess?.call();
            },
            child: const Text(
              "CONCLUIR",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}
