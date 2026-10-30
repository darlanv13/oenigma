import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/app_cliente/features/wallet/widgets/wallet_credit_options_sheet.dart';
import 'package:oenigma/app_cliente/features/wallet/widgets/wallet_withdraw_sheet.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  void _handleDeposit(ParseUser user) {
    final walletModel = UserWalletModel(
      objectId: user.objectId ?? '',
      name: user.get<String>('name') ?? 'Jogador',
      email: user.get<String>('email') ?? '',
      balance: user.get<num>('balance')?.toDouble() ?? 0.0,
      photoURL: user.get<String>('photoURL'),
      transactions: [user.get('transactions') ?? []],
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreditOptionsSheet(wallet: walletModel),
    );
  }

  void _handleWithdraw(ParseUser user) {
    final balance = user.get<num>('balance')?.toDouble() ?? 0.0;
    if (balance < 5.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Saldo insuficiente para saque. O valor mínimo é de R\$ 5,00.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WalletWithdrawSheet(
        currentBalance: balance,
        onWithdrawSuccess: () {
          ref.invalidate(authStateProvider);
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar Customizada
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Navigator.canPop(context)
                      ? GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.chevronLeft,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(width: 40),
                  Text(
                    'TESOURO',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: authState.when(
                data: (user) {
                  if (user == null) {
                    return Center(
                      child: Text(
                        'Sessão expirada.',
                        style: GoogleFonts.inter(color: AppColors.cinzaMedio),
                      ),
                    );
                  }

                  final balance = user.get<num>('balance')?.toDouble() ?? 0.0;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildBalanceCard(balance),
                              const SizedBox(height: 20),
                              _buildActionButtons(user),
                              const SizedBox(height: 36),
                              _buildTransactionsHistory(user),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.verdeVale),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Erro: $err',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.coins,
                color: AppColors.amareloVale,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'SALDO DISPONÍVEL',
                style: GoogleFonts.inter(
                  color: AppColors.cinzaMedio,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
            style: GoogleFonts.poppins(
              color: AppColors.amareloVale,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ParseUser user) {
    return Row(
      children: [
        Expanded(
          child: _buildWalletButton(
            icon: FontAwesomeIcons.arrowDown,
            label: 'DEPOSITAR',
            backgroundColor: AppColors.verdeVale,
            textColor: Colors.white,
            useGradient: true,
            onTap: () => _handleDeposit(user),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildWalletButton(
            icon: FontAwesomeIcons.arrowUp,
            label: 'SACAR',
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            textColor: Colors.white,
            borderColor: AppColors.verdeVale.withValues(alpha: 0.5),
            onTap: () => _handleWithdraw(user),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletButton({
    required dynamic icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    bool useGradient = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: useGradient ? null : backgroundColor,
          gradient: useGradient ? AppColors.gradienteVerdeVale : null,
          borderRadius: BorderRadius.circular(20),
          border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : null,
          boxShadow: [
            BoxShadow(
              color: useGradient
                  ? AppColors.verdeVale.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 13, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: textColor,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsHistory(ParseUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FaIcon(FontAwesomeIcons.clockRotateLeft, color: AppColors.cinzaMedio, size: 14),
            const SizedBox(width: 8),
            Text(
              'HISTÓRICO RECENTE',
              style: GoogleFonts.inter(
                color: AppColors.cinzaMedio,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FutureBuilder<ParseResponse>(
          future: (QueryBuilder<ParseObject>(ParseObject('Transaction'))
                ..whereEqualTo('user', user.toPointer())
                ..orderByDescending('createdAt')
                ..setLimit(10))
              .query(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.verdeVale),
                ),
              );
            }

            final results = snapshot.data?.results as List<ParseObject>? ?? [];

            if (snapshot.hasError || results.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.darkCardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    FaIcon(FontAwesomeIcons.receipt, color: Colors.white.withValues(alpha: 0.2), size: 36),
                    const SizedBox(height: 14),
                    Text(
                      'Nenhuma transação ainda.',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seus ganhos e depósitos aparecerão aqui.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.darkCardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                itemBuilder: (context, index) {
                  final tx = results[index];
                  final type = tx.get<String>('type') ?? 'deposit';
                  final status = tx.get<String>('status') ?? 'pending';
                  final amount = tx.get<num>('amount')?.toDouble() ?? 0.0;
                  final date = tx.createdAt;

                  final isDeposit = type == 'reward' || type == 'deposit';
                  final icon = isDeposit ? FontAwesomeIcons.arrowTrendUp : FontAwesomeIcons.arrowTrendDown;
                  final color = isDeposit ? AppColors.verdeVale : AppColors.danger;

                  String dateStr = '';
                  if (date != null) {
                    dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: FaIcon(icon, color: color, size: 14),
                    ),
                    title: Text(
                      isDeposit ? (type == 'reward' ? 'Prêmio Recebido' : 'Depósito via PIX') : 'Saque / Ferramenta',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '$dateStr • ${status.toUpperCase()}',
                      style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      '${isDeposit ? '+' : '-'} R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
