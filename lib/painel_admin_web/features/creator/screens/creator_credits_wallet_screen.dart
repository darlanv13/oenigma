import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/models/credit_package_model.dart';
import 'package:oenigma/painel_admin_web/features/player/widgets/pix_checkout_dialog.dart';

class CreatorCreditsWalletScreen extends StatefulWidget {
  const CreatorCreditsWalletScreen({super.key});

  @override
  State<CreatorCreditsWalletScreen> createState() =>
      _CreatorCreditsWalletScreenState();
}

class _CreatorCreditsWalletScreenState
    extends State<CreatorCreditsWalletScreen> {
  bool _isLoading = true;
  int _creditBalance = 0;
  List<Map<String, dynamic>> _transactions = [];
  ParseUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      _currentUser = user;

      if (user != null) {
        final fn = ParseCloudFunction('getCreditTransactions');
        final res = await fn.execute();

        if (res.success && res.result != null && res.result is Map) {
          final data = Map<String, dynamic>.from(res.result);
          _creditBalance = (data['creditBalance'] as num?)?.toInt() ?? 0;
          final rawTxs = data['transactions'] as List? ?? [];
          _transactions = rawTxs.map((t) => Map<String, dynamic>.from(t)).toList();
        } else {
          await user.fetch();
          _creditBalance = (user.get<num>('creditBalance') ?? 0).toInt();
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar carteira de créditos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _buyPackage(CreditPackageModel pkg) async {
    try {
      final fn = ParseCloudFunction('createCreditPackagePix');
      final res = await fn.execute(parameters: {'packageId': pkg.id});

      if (res.success && res.result != null && res.result is Map) {
        final data = Map<String, dynamic>.from(res.result);
        final txId = data['transactionId'] ?? '';
        final copiaCola = data['copiaCola'] ?? '';

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => PixCheckoutDialog(
              title: 'Recarga de Créditos (${pkg.name})',
              subtitle: '${pkg.credits} Créditos para publicar experiências',
              amount: pkg.price,
              transactionId: txId,
              copiaCola: copiaCola,
              onPaymentApproved: () {
                _loadWalletData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 +${pkg.credits} créditos adicionados com sucesso!'),
                    backgroundColor: Colors.greenAccent,
                  ),
                );
              },
            ),
          );
        }
      } else {
        throw Exception(res.error?.message ?? 'Falha ao gerar cobrança Pix.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar compra: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amareloVale),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de Saldo de Créditos
          _buildCreditsHeroCard(),

          const SizedBox(height: 24),

          // Tabela de Consumo por Modalidade
          _buildModalityCostInfoCard(),

          const SizedBox(height: 24),

          // Vitrine de Pacotes de Créditos Oficiais (PRD v1.0 - Seção 8.1)
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.coins, color: AppColors.amareloVale, size: 16),
              const SizedBox(width: 10),
              Text(
                'Pacotes de Créditos Disponíveis',
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  children: CreditPackageModel.officialPackages.map((pkg) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildPackageCard(pkg),
                      ),
                    );
                  }).toList(),
                );
              }

              return Column(
                children: CreditPackageModel.officialPackages.map((pkg) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPackageCard(pkg),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 28),

          // Extrato de Movimentações Contábeis de Crédito
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.clockRotateLeft, color: AppColors.cinzaMedio, size: 14),
              const SizedBox(width: 8),
              Text(
                'Extrato de Créditos',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_transactions.isEmpty)
            _buildEmptyTransactionsCard()
          else
            _buildTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildCreditsHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF131D24), Color(0xFF0F171D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.amareloVale.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.amareloVale.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amareloVale.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'CARTEIRA DO CRIADOR',
                      style: GoogleFonts.orbitron(
                        color: AppColors.amareloVale,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Saldo de Créditos',
                style: GoogleFonts.inter(
                  color: AppColors.cinzaMedio,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$_creditBalance',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _creditBalance == 1 ? 'crédito' : 'créditos',
                    style: GoogleFonts.inter(
                      color: AppColors.amareloVale,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E2B33),
              border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.5), width: 1.5),
            ),
            child: const FaIcon(
              FontAwesomeIcons.coins,
              color: AppColors.amareloVale,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalityCostInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1419),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3A45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.circleInfo, size: 12, color: Colors.lightBlueAccent),
              const SizedBox(width: 8),
              Text(
                'Consumo de Créditos por Modalidade de Experiência (PRD v1.0):',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildModalityCostChip('QUIZ', '1 Crédito', Colors.blueAccent),
              _buildModalityCostChip('CHALLENGE', '1 Crédito', Colors.purpleAccent),
              _buildModalityCostChip('MISSION', '1 Crédito', Colors.greenAccent),
              _buildModalityCostChip('HUNT', '2 Créditos', AppColors.amareloVale),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModalityCostChip(String name, String cost, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            cost,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(CreditPackageModel pkg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pkg.id == 'criador'
              ? AppColors.amareloVale
              : const Color(0xFF1E3A45),
          width: pkg.id == 'criador' ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pkg.name,
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amareloVale.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pkg.badge,
                  style: GoogleFonts.orbitron(
                    color: AppColors.amareloVale,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${pkg.credits}',
                style: GoogleFonts.orbitron(
                  color: AppColors.amareloVale,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                pkg.credits == 1 ? 'crédito' : 'créditos',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'R\$ ${pkg.price.toStringAsFixed(2).replaceAll('.', ',')}',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pkg.description,
            style: GoogleFonts.inter(
              color: AppColors.cinzaMedio,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: pkg.id == 'criador'
                    ? AppColors.amareloVale
                    : AppColors.verdeVale,
                foregroundColor: pkg.id == 'criador' ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const FaIcon(FontAwesomeIcons.bolt, size: 12),
              label: Text(
                'Comprar no Pix',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: () => _buyPackage(pkg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3A45)),
      ),
      child: Center(
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.receipt, color: AppColors.cinzaMedio, size: 32),
            const SizedBox(height: 12),
            Text(
              'Nenhuma movimentação de créditos ainda',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Suas compras de pacotes e publicações de experiências aparecerão aqui.',
              style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3A45)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transactions.length,
        separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E3A45), height: 1),
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          final type = tx['type']?.toString() ?? 'PURCHASE';
          final isCredit = type == 'PURCHASE' || type == 'BONUS';
          final amount = tx['amount'] ?? 0;
          final desc = tx['description'] ?? 'Movimentação';

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isCredit ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                isCredit ? FontAwesomeIcons.plus : FontAwesomeIcons.minus,
                color: isCredit ? Colors.greenAccent : Colors.redAccent,
                size: 13,
              ),
            ),
            title: Text(
              desc,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Tipo: $type • Saldo após: ${tx['balanceAfter'] ?? 0}',
              style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11),
            ),
            trailing: Text(
              '${isCredit ? "+" : "-"}$amount',
              style: GoogleFonts.orbitron(
                color: isCredit ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          );
        },
      ),
    );
  }
}
