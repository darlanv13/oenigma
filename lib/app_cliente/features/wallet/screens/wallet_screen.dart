import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/app_cliente/features/wallet/widgets/wallet_credit_options_sheet.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';
// Importação restaurada do seu widget de depósito original

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
      photoURL: user.get<String>('photoURL'), transactions: [user.get('transactions') ?? []],
    );
    // Chamada restaurada para a sua tela/sheet de créditos original
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CreditOptionsSheet(wallet: walletModel,), // Certifique-se de que walletModel está definido corretamente),
    );
  }

  void _handleWithdraw() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Função de Saque em breve!'),
        backgroundColor: primaryAmber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Fundo base escuro
      body: Stack(
        children: [
          // Fundo com o mapa idêntico ao da HomePage
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Camada de escurecimento suave para dar leitura aos textos
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // AppBar Customizada para casar com o design
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primaryAmber.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.chevronLeft,
                              color: primaryAmber,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'TESOURO',
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryAmber,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 36), // Espaçamento para centralizar o título
                    ],
                  ),
                ),
                
                Expanded(
                  child: authState.when(
                    data: (user) {
                      if (user == null) {
                        return const Center(
                          child: Text('Sessão expirada.', style: TextStyle(color: Colors.white)),
                        );
                      }

                      final balance = user.get<num>('balance')?.toDouble() ?? 0.0;

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildBalanceCard(balance),
                                  const SizedBox(height: 24),
                                  _buildActionButtons(user),
                                  const SizedBox(height: 40),
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
                      child: CircularProgressIndicator(color: primaryAmber),
                    ),
                    error: (err, stack) => Center(
                      child: Text('Erro: $err', style: const TextStyle(color: dangerColor)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.8), // Fundo escuro translúcido como na Home
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryAmber.withOpacity(0.3), // Borda fina dourada
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.coins, color: primaryAmber, size: 16),
              const SizedBox(width: 8),
              Text(
                'SALDO DISPONÍVEL',
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
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
            color: primaryAmber,
            onTap: () => _handleDeposit(user),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildWalletButton(
            icon: FontAwesomeIcons.arrowUp,
            label: 'SACAR',
            color: Colors.white70,
            onTap: _handleWithdraw,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletButton({
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Design vazado (Outlined) idêntico ao botão "Entrada Grátis" da sua Home
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 13,
                letterSpacing: 1.0,
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
            const FaIcon(FontAwesomeIcons.clockRotateLeft, color: primaryAmber, size: 16),
            const SizedBox(width: 10),
            Text(
              'HISTÓRICO RECENTE',
              style: GoogleFonts.orbitron(
                color: primaryAmber,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
                  child: CircularProgressIndicator(color: primaryAmber),
                ),
              );
            }

            final results = snapshot.data?.results as List<ParseObject>? ?? [];

            if (snapshot.hasError || results.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    FaIcon(FontAwesomeIcons.receipt, color: Colors.white.withOpacity(0.1), size: 40),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma transação ainda.',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seus ganhos e depósitos aparecerão aqui.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                itemBuilder: (context, index) {
                  final tx = results[index];
                  final type = tx.get<String>('type') ?? 'deposit';
                  final status = tx.get<String>('status') ?? 'pending';
                  final amount = tx.get<num>('amount')?.toDouble() ?? 0.0;
                  final date = tx.createdAt;

                  final isDeposit = type == 'deposit' || type == 'reward';
                  final icon = isDeposit ? FontAwesomeIcons.arrowTrendUp : FontAwesomeIcons.arrowTrendDown;
                  final color = isDeposit ? successColor : dangerColor;
                  
                  String dateStr = '';
                  if (date != null) {
                    dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(icon, color: color, size: 16),
                    ),
                    title: Text(
                      isDeposit ? (type == 'reward' ? 'Prêmio Recebido' : 'Depósito via PIX') : 'Saque / Ferramenta',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '$dateStr • ${status.toUpperCase()}',
                      style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${isDeposit ? '+' : '-'} R\$ ${amount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 14),
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