import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/app_cliente/features/wallet/providers/wallet_provider.dart';
import 'package:oenigma/app_cliente/features/wallet/widgets/wallet_credit_options_sheet.dart';
import 'package:oenigma/app_cliente/features/wallet/widgets/wallet_withdraw_sheet.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  Future<void> _refreshWallet() async {
    if (!mounted) return;
    try {
      await ref.read(authRepositoryProvider).reloadUser();
    } catch (_) {}
    if (!mounted) return;
    ref.invalidate(walletProvider);
    if (mounted) setState(() {});
  }

  Future<void> _handleDeposit(ParseUser user) async {
    SoundService.playOpen();
    final walletModel = UserWalletModel(
      objectId: user.objectId ?? '',
      name: user.get<String>('name') ?? 'Jogador',
      email: user.get<String>('email') ?? '',
      balance: user.get<num>('balance')?.toDouble() ?? 0.0,
      photoURL: user.get<String>('photoURL'),
      transactions: [user.get('transactions') ?? []],
    );
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreditOptionsSheet(
        wallet: walletModel,
        onPaymentSuccess: _refreshWallet,
      ),
    );
    if (mounted) {
      await _refreshWallet();
    }
  }

  Future<void> _handleWithdraw(ParseUser user) async {
    final balance = user.get<num>('balance')?.toDouble() ?? 0.0;
    if (balance < 5.0) {
      SoundService.playError();
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

    SoundService.playOpen();
    final withdrawnAmount = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WalletWithdrawSheet(
        currentBalance: balance,
      ),
    );

    if (withdrawnAmount != null && mounted) {
      await _refreshWallet();
      if (!mounted) return;
      _showWithdrawSuccessDialog(withdrawnAmount);
    }
  }

  void _showWithdrawSuccessDialog(double amount) {
    if (!mounted) return;
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
          'Sua solicitação de saque no valor de R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')} foi enviada com sucesso! O valor foi reservado e a transferência Pix será realizada após aprovação.',
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
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.4,
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.arrowsRotate, color: Colors.white70, size: 16),
                    tooltip: 'Atualizar Saldo',
                    onPressed: _refreshWallet,
                  ),
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

                  return RefreshIndicator(
                    onRefresh: _refreshWallet,
                    color: AppColors.verdeVale,
                    backgroundColor: AppColors.darkCardColor,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                    ),
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
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16252E),
            Color(0xFF0F171B),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Brilho decorativo no canto superior direito
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amareloVale.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amareloVale.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.amareloVale.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.coins,
                            color: AppColors.amareloVale,
                            size: 11,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SALDO DISPONÍVEL',
                            style: GoogleFonts.inter(
                              color: AppColors.amareloVale,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.bolt,
                            color: AppColors.verdeVale,
                            size: 9,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PIX INSTANTÂNEO',
                            style: GoogleFonts.poppins(
                              color: AppColors.verdeVale,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Valor Grande
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'R\$ ',
                      style: GoogleFonts.poppins(
                        color: AppColors.amareloVale.withValues(alpha: 0.8),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        balance.toStringAsFixed(2).replaceAll('.', ','),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: AppColors.amareloVale,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Rodapé de Segurança
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.shieldHalved,
                        color: AppColors.verdeVale,
                        size: 11,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Transações protegidas por criptografia e liquidação Pix imediata.',
                          style: GoogleFonts.inter(
                            color: AppColors.cinzaMedio,
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            subLabel: 'Adicionar saldo',
            backgroundColor: AppColors.verdeVale,
            textColor: Colors.white,
            useGradient: true,
            onTap: () => _handleDeposit(user),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildWalletButton(
            icon: FontAwesomeIcons.arrowUp,
            label: 'SACAR',
            subLabel: 'Chave Pix (Mín R\$ 5)',
            backgroundColor: const Color(0xFF131D24),
            textColor: Colors.white,
            borderColor: AppColors.verdeVale.withValues(alpha: 0.45),
            onTap: () => _handleWithdraw(user),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletButton({
    required dynamic icon,
    required String label,
    required String subLabel,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    bool useGradient = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: useGradient ? null : backgroundColor,
          gradient: useGradient
              ? const LinearGradient(
                  colors: [Color(0xFF00DF82), Color(0xFF00A862)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : null,
          boxShadow: [
            BoxShadow(
              color: useGradient
                  ? AppColors.verdeVale.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: useGradient ? 0.22 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  size: 13,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      fontSize: 12.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    subLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: textColor.withValues(alpha: useGradient ? 0.85 : 0.6),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
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

  Widget _buildTransactionsHistory(ParseUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 12, color: AppColors.cinzaMedio),
              tooltip: 'Recarregar Extrato',
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<ParseResponse>(
          future: ParseCloudFunction('getUserTransactions').execute(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.verdeVale),
                ),
              );
            }

            final rawData = snapshot.data?.result;
            final List<Map<String, dynamic>> results = [];
            if (rawData is List) {
              for (final item in rawData) {
                if (item is Map) {
                  results.add(Map<String, dynamic>.from(item));
                } else if (item is ParseObject) {
                  results.add({
                    'type': item.get<String>('type'),
                    'status': item.get<String>('status'),
                    'amount': item.get<num>('amount')?.toDouble(),
                    'description': item.get<String>('description'),
                    'createdAt': item.createdAt,
                  });
                }
              }
            } else if (snapshot.data?.results is List) {
              for (final item in snapshot.data!.results!) {
                if (item is ParseObject) {
                  results.add({
                    'type': item.get<String>('type'),
                    'status': item.get<String>('status'),
                    'amount': item.get<num>('amount')?.toDouble(),
                    'description': item.get<String>('description'),
                    'createdAt': item.createdAt,
                  });
                }
              }
            }

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
                      'Seus depósitos, ganhos e saques aparecerão aqui.',
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
                  final type = tx['type']?.toString() ?? 'deposit';
                  final status = tx['status']?.toString() ?? 'pending';
                  final amount = (tx['amount'] is num)
                      ? (tx['amount'] as num).toDouble()
                      : (double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0);
                  final description = tx['description']?.toString();
                  DateTime? date;
                  if (tx['createdAt'] is DateTime) {
                    date = tx['createdAt'] as DateTime;
                  } else if (tx['createdAt'] is String) {
                    date = DateTime.tryParse(tx['createdAt'] as String);
                  }

                  final isDeposit = type == 'reward' || type == 'deposit';
                  final isWithdrawal = type == 'withdrawal';

                  // Configurações visuais por status
                  Color statusColor = AppColors.cinzaMedio;
                  String statusLabel = 'PENDENTE';

                  if (status == 'approved' || status == 'completed') {
                    statusColor = AppColors.verdeVale;
                    statusLabel = isWithdrawal ? 'CONCLUÍDO' : 'APROVADO';
                  } else if (status == 'pending') {
                    statusColor = AppColors.amareloVale;
                    statusLabel = 'EM ANÁLISE';
                  } else if (status == 'rejected') {
                    statusColor = Colors.redAccent;
                    statusLabel = 'ESTORNADO';
                  } else if (status == 'cancelled') {
                    statusColor = Colors.white38;
                    statusLabel = 'CANCELADO';
                  }

                  final icon = isDeposit
                      ? FontAwesomeIcons.arrowTrendUp
                      : (status == 'rejected' ? FontAwesomeIcons.arrowRotateLeft : FontAwesomeIcons.arrowTrendDown);

                  final amountColor = isDeposit
                      ? AppColors.verdeVale
                      : (status == 'rejected' ? Colors.white60 : Colors.redAccent);

                  String dateStr = '';
                  if (date != null) {
                    final day = date.day.toString().padLeft(2, '0');
                    final month = date.month.toString().padLeft(2, '0');
                    final year = date.year;
                    final hour = date.hour.toString().padLeft(2, '0');
                    final min = date.minute.toString().padLeft(2, '0');
                    dateStr = '$day/$month/$year $hour:$min';
                  }

                  String title = 'Transação';
                  if (type == 'reward') {
                    title = 'Premiação de Evento';
                  } else if (type == 'deposit') {
                    title = 'Depósito via Pix';
                  } else if (type == 'withdrawal') {
                    title = 'Saque via Pix';
                  }

                  if (description != null && description.isNotEmpty) {
                    title = description;
                  }

                  return InkWell(
                    onTap: () => _showTransactionDetails(
                      context,
                      title: title,
                      dateStr: dateStr,
                      statusLabel: statusLabel,
                      statusColor: statusColor,
                      amount: amount,
                      isDeposit: isDeposit,
                      description: description,
                      txType: type,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Ícone com badge de status
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: FaIcon(icon, color: statusColor, size: 13),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Coluna central: Título + Badge de Status e Data (Zero risco de overflow)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: statusColor.withValues(alpha: 0.3),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: GoogleFonts.inter(
                                          color: statusColor,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    if (dateStr.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          dateStr,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: AppColors.cinzaMedio,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Coluna lateral: Valor Formatado com FittedBox e restrição de largura
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${isDeposit ? '+' : '-'} R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: GoogleFonts.poppins(
                                  color: amountColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  void _showTransactionDetails(
    BuildContext context, {
    required String title,
    required String dateStr,
    required String statusLabel,
    required Color statusColor,
    required double amount,
    required bool isDeposit,
    String? description,
    required String txType,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF131D24),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: AppColors.verdeVale.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador central
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Cabeçalho da Transação
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: Center(
                      child: FaIcon(
                        isDeposit ? FontAwesomeIcons.arrowTrendUp : FontAwesomeIcons.arrowTrendDown,
                        color: statusColor,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              color: AppColors.cinzaMedio,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 18),

              // Valor e Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Valor:',
                    style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
                  ),
                  Text(
                    '${isDeposit ? '+' : '-'} R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.poppins(
                      color: isDeposit ? AppColors.verdeVale : Colors.redAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status:',
                    style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Descrição:',
                      style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        description,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeVale,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'FECHAR',
                  style: GoogleFonts.cinzel(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
