import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/wallet/providers/wallet_provider.dart';
import 'package:oenigma/features/wallet/widgets/wallet_balance_card.dart';
import 'package:oenigma/features/wallet/widgets/wallet_credit_options_sheet.dart';
import 'package:oenigma/features/wallet/widgets/wallet_history_list.dart';
import 'package:oenigma/features/wallet/widgets/wallet_profile_header.dart';
import 'package:oenigma/features/wallet/widgets/wallet_prizes_section.dart';
import 'package:oenigma/features/wallet/widgets/wallet_section_header.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _refreshWalletData() async {
    return await ref.refresh(walletProvider.future);
  }

  void _showAddFundsDialog(UserWalletModel wallet) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CreditOptionsSheet(wallet: wallet);
      },
    ).then((_) {
      _refreshWalletData();
    });
  }

  void _showWithdrawDialog(UserWalletModel wallet) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: WithdrawSheet(wallet: wallet),
        );
      },
    ).then((_) {
      _refreshWalletData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(
              FontAwesomeIcons.gem,
              color: Color(0xFFFFD54F),
              size: 18,
            ),
            const SizedBox(width: 10),
            const Text(
              'O TESOURO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD54F),
                letterSpacing: 2.0,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: walletAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.circleExclamation,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar tesouro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshWalletData,
                icon: const FaIcon(
                  FontAwesomeIcons.rotateRight,
                  color: Colors.black,
                ),
                label: const Text(
                  'TENTAR NOVAMENTE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (walletData) {
          _fadeController.forward();
          return RefreshIndicator(
            onRefresh: _refreshWalletData,
            color: const Color(0xFFFFD54F),
            backgroundColor: const Color(0xFF1E1E1E),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      WalletProfileHeader(wallet: walletData),
                      const SizedBox(height: 24),
                      WalletBalanceCard(wallet: walletData),
                      const SizedBox(height: 24),
                      _buildActionButtons(walletData),
                      const SizedBox(height: 40),
                      const WalletSectionHeader(title: 'MEUS PRÊMIOS'),
                      WalletPrizesSection(wallet: walletData),
                      const SizedBox(height: 32),
                      const WalletSectionHeader(title: 'HISTÓRICO RECENTE'),
                      WalletHistoryList(wallet: walletData),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(UserWalletModel wallet) {
    return Row(
      children: [
        // BOTÃO DE DEPÓSITO (Dourado)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showAddFundsDialog(wallet),
              icon: const FaIcon(
                FontAwesomeIcons.coins,
                color: Colors.black,
                size: 16,
              ),
              label: const Text(
                'DEPOSITAR',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // BOTÃO DE SAQUE (Escuro/Platinado)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF1E1E1E),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showWithdrawDialog(wallet),
              icon: const FaIcon(
                FontAwesomeIcons.handHoldingDollar,
                color: Colors.white,
                size: 16,
              ),
              label: const Text(
                'SACAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- WIDGET DO MODAL DE SAQUE ---
class WithdrawSheet extends StatefulWidget {
  final UserWalletModel wallet;

  const WithdrawSheet({super.key, required this.wallet});

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _pixKeyController = TextEditingController();
  String _pixKeyType = 'cpf';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _pixKeyController.dispose();
    super.dispose();
  }

  Future<void> _requestWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    if (amount < 20.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O valor mínimo para saque é R\$ 20,00.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (amount > widget.wallet.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saldo insuficiente para este saque.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Salva a requisição de saque na tabela Withdrawal do Parse
      final currentUser = await ParseUser.currentUser() as ParseUser?;
      if (currentUser != null) {
        final withdrawal = ParseObject('Withdrawal')
          ..set('amount', amount)
          ..set('pixKey', _pixKeyController.text.trim())
          ..set('pixKeyType', _pixKeyType)
          ..set('status', 'pending')
          ..set(
            'objectId',
            currentUser.objectId,
          ); // Passa o ID pra referência rápida do Admin

        final response = await withdrawal.save();

        if (response.success && mounted) {
          // Desconta o saldo do usuário localmente no banco
          currentUser.set('balance', widget.wallet.balance - amount);
          await currentUser.save();

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Saque solicitado com sucesso! Em breve o valor estará na sua conta.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(
            response.error?.message ?? 'Erro ao processar saque.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "RESGATAR TESOURO",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Saldo disponível: R\$ ${widget.wallet.balance.toStringAsFixed(2).replaceAll('.', ',')}",
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Campo de Valor
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: FaIcon(
                    FontAwesomeIcons.brazilianRealSign,
                    color: Colors.grey,
                    size: 18,
                  ),
                ),
                labelText: 'Valor do Saque',
                labelStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Informe o valor.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dropdown Tipo de Chave PIX
            DropdownButtonFormField<String>(
              value: _pixKeyType,
              dropdownColor: const Color(0xFF121212),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Tipo de Chave PIX',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'cpf', child: Text('CPF/CNPJ')),
                DropdownMenuItem(value: 'phone', child: Text('Telefone')),
                DropdownMenuItem(value: 'email', child: Text('E-mail')),
                DropdownMenuItem(
                  value: 'random',
                  child: Text('Chave Aleatória'),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  _pixKeyType = val!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Campo Chave PIX
            TextFormField(
              controller: _pixKeyController,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: FaIcon(
                    FontAwesomeIcons.pix,
                    color: Colors.grey,
                    size: 18,
                  ),
                ),
                labelText: 'Sua Chave PIX',
                labelStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Informe sua chave PIX.';
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Botão Confirmar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CONFIRMAR SAQUE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
