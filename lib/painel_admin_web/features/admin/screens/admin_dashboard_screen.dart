import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import '../repositories/admin_repository.dart';

final adminDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getComprehensiveDashboardData();
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const AdminDashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return dashboardAsync.when(
      data: (data) => _buildDashboardContent(data),
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.verdeVale),
            SizedBox(height: 16),
            Text(
              'Sincronizando dados táticos do Enigma...',
              style: TextStyle(color: AppColors.cinzaMedio, fontSize: 14),
            ),
          ],
        ),
      ),
      error: (err, stack) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.circleExclamation,
                color: AppColors.danger,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                'Falha ao carregar métricas do dashboard',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.cinzaMedio, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(adminDashboardProvider),
                icon: const FaIcon(FontAwesomeIcons.rotate, size: 14),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(Map<String, dynamic> data) {
    final pendingWithdrawalsCount =
        (data['pendingWithdrawalsCount'] as int?) ?? 0;
    final pendingWithdrawalsAmount =
        (data['pendingWithdrawalsAmount'] as double?) ?? 0.0;
    final activeEvents = (data['activeEvents'] as int?) ?? 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top HUD / Header com Status do Jogo e Refresh
          _buildTopHud(data),
          const SizedBox(height: 20),

          // 2. Alertas Críticos Operacionais
          if (pendingWithdrawalsCount > 0)
            _buildAlertBanner(
              icon: FontAwesomeIcons.triangleExclamation,
              color: AppColors.amareloVale,
              title: 'Atenção Financeira Requerida',
              message:
                  '$pendingWithdrawalsCount solicitações de saque PIX aguardando aprovação (${_currencyFormat.format(pendingWithdrawalsAmount)}).',
              actionLabel: 'Revisar Saques',
              onAction: () => widget.onNavigateTab?.call(4),
            ),
          if (activeEvents == 0)
            _buildAlertBanner(
              icon: FontAwesomeIcons.circleInfo,
              color: AppColors.verdeVale,
              title: 'Nenhuma Caçada Ativa no Momento',
              message:
                  'Não há eventos com status aberto no servidor. Inicie ou publique um novo evento.',
              actionLabel: 'Criar Evento',
              onAction: () => widget.onNavigateTab?.call(1),
            ),

          // 3. Barra de Ações Rápidas
          _buildQuickActionBar(),
          const SizedBox(height: 24),

          // 4. Grade de KPIs Principais
          _buildKpiGrid(data),
          const SizedBox(height: 30),

          // 5. Monitor de Caçadas Ativas & Eventos
          _buildEventsMonitor(data),
          const SizedBox(height: 30),

          // 6. Raio-X dos Enigmas e Arsenal Tático
          _buildEnigmasArsenalSection(data),
          const SizedBox(height: 30),

          // 7. Painéis Duplos: Atividades Recentes e Caçadores
          _buildBottomTwinPanels(data),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. TOP HUD / CABEÇALHO TÁTICO
  // =========================================================================
  Widget _buildTopHud(Map<String, dynamic> data) {
    final DateTime lastUpdated =
        data['lastUpdated'] is DateTime ? data['lastUpdated'] : DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.verdeVale.withValues(alpha: 0.3),
                  ),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.chessRook,
                    color: AppColors.verdeVale,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'CENTRO DE COMANDO',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.amareloVale.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.amareloVale.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'TEMPO REAL',
                          style: GoogleFonts.poppins(
                            color: AppColors.amareloVale,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitoramento operacional do ecossistema O Enigma • Atualizado às ${DateFormat('HH:mm:ss').format(lastUpdated)}',
                    style: GoogleFonts.poppins(
                      color: AppColors.cinzaMedio,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          InkWell(
            onTap: () {
              ref.invalidate(adminDashboardProvider);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.verdeVale.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.verdeVale.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.rotate,
                    color: AppColors.verdeVale,
                    size: 13,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recarregar Dados',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. BANNER DE ALERTA OPERACIONAL
  // =========================================================================
  Widget _buildAlertBanner({
    required dynamic icon,
    required Color color,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: AppColors.cinzaMedio,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor:
                  color == AppColors.amareloVale ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. BARRA DE ATALHOS RÁPIDOS
  // =========================================================================
  Widget _buildQuickActionBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.bolt,
              color: AppColors.amareloVale,
              size: 13,
            ),
            const SizedBox(width: 8),
            Text(
              'AÇÕES RÁPIDAS DE GESTÃO',
              style: GoogleFonts.orbitron(
                color: AppColors.amareloVale,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _buildQuickActionButton(
              icon: FontAwesomeIcons.plus,
              label: 'Novo Evento',
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            _buildQuickActionButton(
              icon: FontAwesomeIcons.puzzlePiece,
              label: 'Gerenciar Enigmas & Fases',
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            _buildQuickActionButton(
              icon: FontAwesomeIcons.image,
              label: 'Campanhas & Banners',
              onTap: () => widget.onNavigateTab?.call(2),
            ),
            _buildQuickActionButton(
              icon: FontAwesomeIcons.creditCard,
              label: 'Configurar Gateways',
              onTap: () => widget.onNavigateTab?.call(3),
            ),
            _buildQuickActionButton(
              icon: FontAwesomeIcons.moneyBillTransfer,
              label: 'Saques & Depósitos',
              onTap: () => widget.onNavigateTab?.call(4),
            ),
            _buildQuickActionButton(
              icon: FontAwesomeIcons.users,
              label: 'Base de Caçadores',
              onTap: () => widget.onNavigateTab?.call(5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.verdeVale.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, color: AppColors.verdeVale, size: 13),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 4. GRADE DE KPIS PRINCIPAIS
  // =========================================================================
  Widget _buildKpiGrid(Map<String, dynamic> data) {
    final totalPlayers = data['totalPlayers']?.toString() ?? '0';
    final totalUsersBalance =
        (data['totalUsersBalance'] as double?) ?? 0.0;
    final activeEvents = data['activeEvents']?.toString() ?? '0';
    final totalEvents = data['totalEvents']?.toString() ?? '0';
    final totalEnigmas = data['totalEnigmas']?.toString() ?? '0';
    final activeEnigmas = data['activeEnigmas']?.toString() ?? '0';
    final totalPrizePool =
        (data['totalPrizePool'] as double?) ?? 0.0;
    final totalDepositedAmount =
        (data['totalDepositedAmount'] as double?) ?? 0.0;
    final totalDepositsCount =
        data['totalDepositsCount']?.toString() ?? '0';
    final pendingWithdrawalsCount =
        (data['pendingWithdrawalsCount'] as int?) ?? 0;
    final pendingWithdrawalsAmount =
        (data['pendingWithdrawalsAmount'] as double?) ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: constraints.maxWidth > 1200 ? 2.1 : 2.0,
          children: [
            _buildKpiCard(
              title: 'CAÇADORES REGISTRADOS',
              value: totalPlayers,
              subtitle: 'Saldo Total: ${_currencyFormat.format(totalUsersBalance)}',
              icon: FontAwesomeIcons.users,
              color: AppColors.verdeVale,
              badgeText: 'Jogadores Ativos',
              onTap: () => widget.onNavigateTab?.call(5),
            ),
            _buildKpiCard(
              title: 'CAÇADAS EM ANDAMENTO',
              value: '$activeEvents / $totalEvents',
              subtitle: 'Eventos abertos para o público',
              icon: FontAwesomeIcons.trophy,
              color: AppColors.amareloVale,
              badgeText: 'Ao Vivo',
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            _buildKpiCard(
              title: 'ENIGMAS & DESAFIOS',
              value: totalEnigmas,
              subtitle: '$activeEnigmas enigmas em fases abertas',
              icon: FontAwesomeIcons.puzzlePiece,
              color: AppColors.verdeVale,
              badgeText: 'Pistas e Relíquias',
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            _buildKpiCard(
              title: 'PRÊMIOS EM DISPUTA',
              value: _currencyFormat.format(totalPrizePool),
              subtitle: 'Acumulado nas caçadas ativas',
              icon: FontAwesomeIcons.sackDollar,
              color: AppColors.amareloVale,
              badgeText: 'Premiação R\$',
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            _buildKpiCard(
              title: 'DEPÓSITOS REALIZADOS',
              value: _currencyFormat.format(totalDepositedAmount),
              subtitle: '$totalDepositsCount entradas via PIX aprovadas',
              icon: FontAwesomeIcons.moneyBillTrendUp,
              color: AppColors.verdeVale,
              badgeText: 'Receita Pix',
              onTap: () => widget.onNavigateTab?.call(4),
            ),
            _buildKpiCard(
              title: 'SAQUES PENDENTES',
              value: pendingWithdrawalsCount.toString(),
              subtitle:
                  'Volume: ${_currencyFormat.format(pendingWithdrawalsAmount)}',
              icon: FontAwesomeIcons.handHoldingDollar,
              color: pendingWithdrawalsCount > 0
                  ? AppColors.danger
                  : AppColors.cinzaMedio,
              badgeText: pendingWithdrawalsCount > 0
                  ? 'Requer Liberação'
                  : 'Em Dia',
              onTap: () => widget.onNavigateTab?.call(4),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required dynamic icon,
    required Color color,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: AppColors.cinzaMedio,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: FaIcon(icon, color: color, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 5. MONITOR DE CAÇADAS ATIVAS (EVENTOS AO VIVO)
  // =========================================================================
  Widget _buildEventsMonitor(Map<String, dynamic> data) {
    final recentEvents = (data['recentEvents'] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.compass,
                    color: AppColors.verdeVale,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'STATUS DAS CAÇADAS & EVENTOS ATIVOS',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => widget.onNavigateTab?.call(1),
                child: Row(
                  children: [
                    Text(
                      'Gerenciar Todos os Eventos',
                      style: GoogleFonts.poppins(
                        color: AppColors.amareloVale,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const FaIcon(
                      FontAwesomeIcons.arrowRight,
                      color: AppColors.amareloVale,
                      size: 11,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (recentEvents.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Column(
                children: [
                  FaIcon(
                    FontAwesomeIcons.mapLocationDot,
                    color: AppColors.cinzaMedio.withValues(alpha: 0.4),
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhum evento registrado no sistema',
                    style: GoogleFonts.poppins(
                      color: AppColors.cinzaMedio,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => widget.onNavigateTab?.call(1),
                    icon: const FaIcon(FontAwesomeIcons.plus, size: 12),
                    label: const Text('Criar Primeira Caçada'),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 140,
                  ),
                  itemCount: recentEvents.length,
                  itemBuilder: (context, index) {
                    final ev = recentEvents[index] as Map<String, dynamic>;
                    return _buildEventItemCard(ev);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventItemCard(Map<String, dynamic> ev) {
    final name = ev['name']?.toString() ?? 'Sem Título';
    final location = ev['location']?.toString() ?? 'Brasil';
    final prize = ev['prize']?.toString() ?? 'R\$ 0,00';
    final eventType = ev['eventType']?.toString() ?? 'classic';
    final isOpen = ev['isOpen'] == true;
    final playerCount = (ev['playerCount'] as int?) ?? 0;

    final isFindAndWin = eventType.toLowerCase() == 'find_and_win';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen
              ? AppColors.verdeVale.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isFindAndWin
                  ? AppColors.amareloVale.withValues(alpha: 0.15)
                  : AppColors.verdeVale.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFindAndWin
                    ? AppColors.amareloVale.withValues(alpha: 0.3)
                    : AppColors.verdeVale.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: FaIcon(
                isFindAndWin
                    ? FontAwesomeIcons.crosshairs
                    : FontAwesomeIcons.layerGroup,
                color:
                    isFindAndWin ? AppColors.amareloVale : AppColors.verdeVale,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFindAndWin
                            ? AppColors.amareloVale.withValues(alpha: 0.15)
                            : AppColors.verdeVale.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isFindAndWin ? 'FIND & WIN' : 'MODO CLÁSSICO',
                        style: GoogleFonts.orbitron(
                          color: isFindAndWin
                              ? AppColors.amareloVale
                              : AppColors.verdeVale,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? AppColors.success.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isOpen ? Colors.greenAccent : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOpen ? 'ABERTO' : 'FECHADO',
                            style: GoogleFonts.poppins(
                              color: isOpen ? Colors.greenAccent : Colors.grey,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.locationDot,
                      color: AppColors.cinzaMedio,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        color: AppColors.cinzaMedio,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const FaIcon(
                      FontAwesomeIcons.userGroup,
                      color: AppColors.cinzaMedio,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$playerCount inscritos',
                      style: GoogleFonts.poppins(
                        color: AppColors.cinzaMedio,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Prêmio',
                style: GoogleFonts.poppins(
                  color: AppColors.cinzaMedio,
                  fontSize: 10,
                ),
              ),
              Text(
                prize,
                style: GoogleFonts.orbitron(
                  color: AppColors.amareloVale,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => widget.onNavigateTab?.call(1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.verdeVale.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Gerenciar',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. RAIO-X DOS ENIGMAS E ARSENAL TÁTICO
  // =========================================================================
  Widget _buildEnigmasArsenalSection(Map<String, dynamic> data) {
    final difficultyCounts =
        (data['difficultyCounts'] as Map<String, dynamic>?) ?? {};
    final facil = (difficultyCounts['FÁCIL'] as int?) ?? 0;
    final media = (difficultyCounts['MÉDIA'] as int?) ?? 0;
    final dificil = (difficultyCounts['DIFÍCIL'] as int?) ?? 0;
    final totalDiff = facil + media + dificil;

    final withCompass = (data['withCompass'] as int?) ?? 0;
    final withRadar = (data['withRadar'] as int?) ?? 0;
    final withMap = (data['withMap'] as int?) ?? 0;
    final withAudio = (data['withAudio'] as int?) ?? 0;
    final withGps = (data['withGps'] as int?) ?? 0;
    final totalHints = (data['totalHints'] as int?) ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel A: Distribuição de Dificuldade
            Expanded(
              flex: isWide ? 1 : 1,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.darkCardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.brain,
                          color: AppColors.amareloVale,
                          size: 15,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'GRAU DE DIFICULDADE DOS ENIGMAS',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDifficultyBar(
                      label: 'Fácil',
                      count: facil,
                      total: totalDiff,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(height: 14),
                    _buildDifficultyBar(
                      label: 'Média',
                      count: media,
                      total: totalDiff,
                      color: AppColors.amareloVale,
                    ),
                    const SizedBox(height: 14),
                    _buildDifficultyBar(
                      label: 'Difícil',
                      count: dificil,
                      total: totalDiff,
                      color: AppColors.danger,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            // Painel B: Arsenal Tático dos Enigmas
            Expanded(
              flex: isWide ? 1 : 1,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.darkCardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.screwdriverWrench,
                          color: AppColors.verdeVale,
                          size: 15,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ARSENAL TÁTICO HABILITADO NO JOGO',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildArsenalChip(
                          icon: FontAwesomeIcons.compass,
                          label: 'Bússola Digital',
                          count: withCompass,
                          color: AppColors.amareloVale,
                        ),
                        _buildArsenalChip(
                          icon: FontAwesomeIcons.satelliteDish,
                          label: 'Radar Tático',
                          count: withRadar,
                          color: AppColors.verdeVale,
                        ),
                        _buildArsenalChip(
                          icon: FontAwesomeIcons.mapLocation,
                          label: 'Raio de Mapa GPS',
                          count: withMap,
                          color: Colors.cyanAccent,
                        ),
                        _buildArsenalChip(
                          icon: FontAwesomeIcons.volumeHigh,
                          label: 'Pistas em Áudio',
                          count: withAudio,
                          color: Colors.purpleAccent,
                        ),
                        _buildArsenalChip(
                          icon: FontAwesomeIcons.locationCrosshairs,
                          label: 'Coordenadas Fixas',
                          count: withGps,
                          color: Colors.orangeAccent,
                        ),
                        _buildArsenalChip(
                          icon: FontAwesomeIcons.lightbulb,
                          label: 'Pistas / Dicas',
                          count: totalHints,
                          color: Colors.amberAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDifficultyBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final double percentage = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(0)}%)',
              style: GoogleFonts.orbitron(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: AppColors.sidebarBackground,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildArsenalChip({
    required dynamic icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.orbitron(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 7. PAINÉIS DUPLOS: ATIVIDADES RECENTES E CAÇADORES EM DESTAQUE
  // =========================================================================
  Widget _buildBottomTwinPanels(Map<String, dynamic> data) {
    final recentActivity =
        (data['recentActivity'] as List<dynamic>?) ?? [];
    final topPlayers = (data['topPlayers'] as List<dynamic>?) ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel 1: Transações & Atividade Recente
            Expanded(
              flex: isWide ? 1 : 1,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.darkCardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.clockRotateLeft,
                              color: AppColors.verdeVale,
                              size: 15,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'MOVIMENTAÇÕES RECENTES',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => widget.onNavigateTab?.call(4),
                          child: Text(
                            'Ver Finanças',
                            style: GoogleFonts.poppins(
                              color: AppColors.amareloVale,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (recentActivity.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: Text(
                          'Nenhuma movimentação registrada recentemente.',
                          style: GoogleFonts.poppins(
                            color: AppColors.cinzaMedio,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentActivity.length,
                        separatorBuilder: (context, i) =>
                            const Divider(color: Colors.white10, height: 16),
                        itemBuilder: (context, index) {
                          final item =
                              recentActivity[index] as Map<String, dynamic>;
                          return _buildActivityItem(item);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            // Painel 2: Caçadores em Destaque
            Expanded(
              flex: isWide ? 1 : 1,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.darkCardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.rankingStar,
                              color: AppColors.amareloVale,
                              size: 15,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'CAÇADORES EM DESTAQUE',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => widget.onNavigateTab?.call(5),
                          child: Text(
                            'Ver Base de Usuários',
                            style: GoogleFonts.poppins(
                              color: AppColors.amareloVale,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (topPlayers.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: Text(
                          'Nenhum jogador cadastrado ainda.',
                          style: GoogleFonts.poppins(
                            color: AppColors.cinzaMedio,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topPlayers.length,
                        separatorBuilder: (context, i) =>
                            const Divider(color: Colors.white10, height: 16),
                        itemBuilder: (context, index) {
                          final player =
                              topPlayers[index] as Map<String, dynamic>;
                          return _buildPlayerItem(player, index + 1);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> item) {
    final type = item['type']?.toString().toLowerCase() ?? 'deposit';
    final amount = (item['amount'] as double?) ?? 0.0;
    final userName = item['userName']?.toString() ?? 'Jogador';
    final status = item['status']?.toString().toLowerCase() ?? 'completed';
    final description = item['description']?.toString() ?? 'Transação';
    final DateTime createdAt = item['createdAt'] is DateTime
        ? item['createdAt']
        : DateTime.now();

    final isWithdrawal = type == 'withdrawal';
    final isApproved = status == 'approved' || status == 'completed';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isWithdrawal
                ? AppColors.amareloVale.withValues(alpha: 0.15)
                : AppColors.verdeVale.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(
              isWithdrawal
                  ? FontAwesomeIcons.arrowDown
                  : FontAwesomeIcons.arrowUp,
              color:
                  isWithdrawal ? AppColors.amareloVale : AppColors.verdeVale,
              size: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$description • ${_dateFormat.format(createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: AppColors.cinzaMedio,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isWithdrawal ? '-' : '+'}${_currencyFormat.format(amount)}',
              style: GoogleFonts.orbitron(
                color: isWithdrawal
                    ? AppColors.amareloVale
                    : Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isApproved
                    ? Colors.greenAccent.withValues(alpha: 0.1)
                    : AppColors.amareloVale.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isApproved ? 'APROVADO' : 'PENDENTE',
                style: GoogleFonts.poppins(
                  color: isApproved
                      ? Colors.greenAccent
                      : AppColors.amareloVale,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerItem(Map<String, dynamic> player, int rank) {
    final name = player['name']?.toString() ?? 'Caçador';
    final email = player['email']?.toString() ?? '';
    final balance = (player['walletBalance'] as num?)?.toDouble() ?? 0.0;
    final isAdmin = player['isAdmin'] == true;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: rank == 1
                ? AppColors.amareloVale.withValues(alpha: 0.2)
                : AppColors.verdeVale.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: rank == 1
                  ? AppColors.amareloVale
                  : AppColors.verdeVale.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.orbitron(
                color: rank == 1 ? AppColors.amareloVale : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.amareloVale.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ADM',
                        style: GoogleFonts.orbitron(
                          color: AppColors.amareloVale,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: AppColors.cinzaMedio,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Saldo',
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontSize: 10,
              ),
            ),
            Text(
              _currencyFormat.format(balance),
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
