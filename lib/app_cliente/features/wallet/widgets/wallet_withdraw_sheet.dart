import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class WalletWithdrawSheet extends StatefulWidget {
  final double currentBalance;
  final VoidCallback onWithdrawSuccess;

  const WalletWithdrawSheet({
    super.key,
    required this.currentBalance,
    required this.onWithdrawSuccess,
  });

  @override
  State<WalletWithdrawSheet> createState() => _WalletWithdrawSheetState();
}

class _WalletWithdrawSheetState extends State<WalletWithdrawSheet> {
  final _amountController = TextEditingController();
  final _pixKeyController = TextEditingController();

  String _pixKeyType = 'CPF'; // CPF, EMAIL, TELEFONE, CHAVE_ALEATORIA
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _pixKeyController.dispose();
    super.dispose();
  }

  void _setAmount(double value) {
    if (value > widget.currentBalance) {
      _amountController.text = widget.currentBalance.toStringAsFixed(2);
    } else {
      _amountController.text = value.toStringAsFixed(2);
    }
    setState(() => _errorMessage = null);
  }

  Future<void> _submitWithdrawal() async {
    final amountText = _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(amountText);
    final pixKey = _pixKeyController.text.trim();

    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Informe um valor válido para o saque.');
      return;
    }

    if (amount < 5.0) {
      setState(() => _errorMessage = 'O valor mínimo para saque é de R\$ 5,00.');
      return;
    }

    if (amount > widget.currentBalance) {
      setState(() => _errorMessage = 'Saldo insuficiente para realizar este saque.');
      return;
    }

    if (pixKey.isEmpty) {
      setState(() => _errorMessage = 'Digite a sua chave Pix.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ParseCloudFunction('requestWithdrawal').execute(
        parameters: {
          'amount': amount,
          'pixKey': pixKey,
          'pixKeyType': _pixKeyType,
        },
      );

      if (!mounted) return;

      if (res.success) {
        Navigator.pop(context); // fecha sheet
        widget.onWithdrawSuccess();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.darkCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.verdeVale.withValues(alpha: 0.3)),
            ),
            title: Row(
              children: [
                const FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.verdeVale, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Solicitação Enviada!',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              'Sua solicitação de saque no valor de R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')} foi recebida com sucesso e está em análise para transferência Pix.',
              style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeVale,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res.error?.message ?? 'Falha ao solicitar saque. Tente novamente.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao processar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.pix, color: Color(0xFF32BCAD), size: 18),
                const SizedBox(width: 8),
                Text(
                  'SACAR VIA PIX',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Transfira seus ganhos diretamente para sua conta bancária.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
            ),
            const SizedBox(height: 18),

            // Card de Saldo Disponível
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo Disponível:',
                    style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
                  ),
                  Text(
                    'R\$ ${widget.currentBalance.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.poppins(
                      color: AppColors.amareloVale,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Valor do Saque
            Text(
              'Valor do Saque (R\$):',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            const SizedBox(height: 10),

            // Chips de Valores Rápidos
            Row(
              children: [
                _buildQuickAmountChip('R\$ 10', 10.0),
                const SizedBox(width: 8),
                _buildQuickAmountChip('R\$ 20', 20.0),
                const SizedBox(width: 8),
                _buildQuickAmountChip('R\$ 50', 50.0),
                const SizedBox(width: 8),
                _buildQuickAmountChip('Tudo', widget.currentBalance),
              ],
            ),
            const SizedBox(height: 18),

            // Tipo de Chave Pix
            Text(
              'Tipo de Chave Pix:',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPixTypeChip('CPF', 'CPF'),
                  const SizedBox(width: 8),
                  _buildPixTypeChip('E-mail', 'EMAIL'),
                  const SizedBox(width: 8),
                  _buildPixTypeChip('Celular', 'TELEFONE'),
                  const SizedBox(width: 8),
                  _buildPixTypeChip('Chave Aleatória', 'CHAVE_ALEATORIA'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Campo Chave Pix
            TextField(
              controller: _pixKeyController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: _getPixKeyHint(),
                hintStyle: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
                prefixIcon: const Icon(Icons.key, color: AppColors.verdeVale, size: 18),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.25),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.verdeVale)),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Botão Confirmar Saque
            ElevatedButton(
              onPressed: _isLoading ? null : _submitWithdrawal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeVale,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(FontAwesomeIcons.paperPlane, size: 14),
                        const SizedBox(width: 10),
                        Text(
                          'SOLICITAR SAQUE PIX',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, double value) {
    return Expanded(
      child: InkWell(
        onTap: () => _setAmount(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPixTypeChip(String label, String type) {
    final isSelected = _pixKeyType == type;
    return InkWell(
      onTap: () => setState(() => _pixKeyType = type),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.verdeVale.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.verdeVale : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppColors.cinzaMedio,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getPixKeyHint() {
    switch (_pixKeyType) {
      case 'CPF':
        return 'Digite seu CPF (apenas números)';
      case 'EMAIL':
        return 'Digite seu e-mail cadastrado no Pix';
      case 'TELEFONE':
        return 'Digite seu celular com DDD (Ex: 94991234567)';
      case 'CHAVE_ALEATORIA':
      default:
        return 'Cole sua chave Pix aleatória';
    }
  }
}
