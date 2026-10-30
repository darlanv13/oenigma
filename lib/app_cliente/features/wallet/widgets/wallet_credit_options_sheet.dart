import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class CreditOptionsSheet extends StatelessWidget {
  final UserWalletModel wallet;

  const CreditOptionsSheet({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    final amounts = [5.0, 10.0, 15.0, 20.0, 50.0, 100.0];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
          Text(
            "ADICIONAR SALDO",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Escolha o valor que deseja adicionar à sua carteira.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
          ),
          const SizedBox(height: 24),
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
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return PaymentBottomSheet(
                        amount: amounts[index],
                        wallet: wallet,
                      );
                    },
                  );
                },
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class PaymentBottomSheet extends StatefulWidget {
  final double amount;
  final UserWalletModel wallet;

  const PaymentBottomSheet({
    super.key,
    required this.amount,
    required this.wallet,
  });

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  bool _isLoading = true;
  String? _error;
  String? _qrCodeBase64;
  String? _copiaCola;
  String? _txid;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    try {
      final result = await ParseCloudFunction(
        'createPixCharge',
      ).execute(parameters: {'amount': widget.amount});
      if (!result.success) throw result.error ?? ParseError();

      final data = result.result as Map<dynamic, dynamic>;

      if (mounted) {
        setState(() {
          _qrCodeBase64 = data['qrCodeImage'];
          _copiaCola = data['copiaCola'];
          _txid = data['txid'];
          _isLoading = false;
        });
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "FECHAR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentState() {
    return StreamBuilder<ParseObject?>(
      stream: Stream.periodic(const Duration(seconds: 3)).asyncMap((_) async {
        final q = QueryBuilder<ParseObject>(ParseObject('Transaction'))
          ..whereEqualTo('objectId', _txid);
        final res = await q.query();
        if (res.success && res.results != null) {
          return res.results!.first as ParseObject;
        }
        return null;
      }),
      builder: (context, snapshot) {
        String status = 'pending';
        if (snapshot.hasData && snapshot.data != null) {
          final transData = snapshot.data!;
          status = transData.get<String>('status') ?? 'pending';
        }

        if (status == 'approved') {
          return _buildSuccessState();
        }

        return Column(
          children: [
            Text(
              "PAGAMENTO PIX",
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
            if (_qrCodeBase64 != null)
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
                padding: const EdgeInsets.all(16),
                child: Image.memory(
                  base64Decode(_qrCodeBase64!.split(',').last),
                  height: 180,
                  width: 180,
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
                  "Aguardando confirmação...",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                icon: const FaIcon(
                  FontAwesomeIcons.copy,
                  color: Colors.white,
                  size: 16,
                ),
                label: const Text(
                  "COPIAR CÓDIGO PIX",
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  if (_copiaCola != null) {
                    await Clipboard.setData(ClipboardData(text: _copiaCola!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "Código Pix copiado!",
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
          ],
        );
      },
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
          "O valor de R\$ ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')} já está na sua carteira.",
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CONCLUIR",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
