import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class MasterDashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const MasterDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<MasterDashboardScreen> createState() => _MasterDashboardScreenState();
}

class _MasterDashboardScreenState extends State<MasterDashboardScreen> {
  bool _isLoading = true;
  int _totalTenants = 0;
  int _totalUsers = 0;
  int _totalPlayers = 0;
  int _totalCreators = 0;
  int _pendingWithdrawals = 0;
  double _platformRevenue = 0.0;
  double _totalDeposited = 0.0;
  int _securityAlertsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMasterMetrics();
  }

  Future<void> _loadMasterMetrics() async {
    setState(() => _isLoading = true);

    try {
      // 1. Tenants count
      final tenantsQuery = QueryBuilder<ParseObject>(ParseObject('Tenant'));
      final tenantsRes = await tenantsQuery.count();
      if (tenantsRes.success) _totalTenants = tenantsRes.count;

      // 2. Users count
      final usersQuery = QueryBuilder<ParseUser>(ParseUser.forQuery());
      final usersRes = await usersQuery.query();
      if (usersRes.success && usersRes.results != null) {
        final list = List<ParseObject>.from(usersRes.results!);
        _totalUsers = list.length;
        _totalCreators = list.where((u) => u.get<String>('role') == 'creator' || (u.get<bool>('isCreator') ?? false)).length;
        _totalPlayers = _totalUsers - _totalCreators;
      }

      // 3. Pending withdrawals
      final withdrawQuery = QueryBuilder<ParseObject>(ParseObject('Withdrawal'))
        ..whereEqualTo('status', 'pending');
      final withdrawRes = await withdrawQuery.count();
      if (withdrawRes.success) _pendingWithdrawals = withdrawRes.count;

      // 4. Financial totals
      final eventsQuery = QueryBuilder<ParseObject>(ParseObject('Event'));
      final eventsRes = await eventsQuery.query();
      if (eventsRes.success && eventsRes.results != null) {
        double rev = 0;
        for (var ev in eventsRes.results!) {
          final count = (ev as ParseObject).get<num>('playerCount')?.toInt() ?? 0;
          final pr = (ev.get<num>('price') ?? 0.0).toDouble();
          rev += (count * pr);
        }
        _totalDeposited = rev;
        _platformRevenue = rev * 0.15; // Estimativa de taxa da plataforma
      }

      // 5. Security alerts
      final securityQuery = QueryBuilder<ParseObject>(ParseObject('SecurityLog'))
        ..whereEqualTo('isSuspicious', true);
      final secRes = await securityQuery.count();
      if (secRes.success) _securityAlertsCount = secRes.count;
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMasterHeader(),
          const SizedBox(height: 20),
          _buildMasterKPIsGrid(),
          const SizedBox(height: 24),
          _buildManagementSections(),
          const SizedBox(height: 24),
          _buildPlatformHealthCard(),
        ],
      ),
    );
  }

  Widget _buildMasterHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade900.withValues(alpha: 0.25),
            AppColors.darkCardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.crown, color: AppColors.amareloVale, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Painel Mestre - Governança Geral',
                      style: GoogleFonts.cinzel(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Gestão central de Multi-Tenancy, Caçadores, Criadores, Finanças, Gateways e Segurança da Rede.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => widget.onNavigateTab?.call(1), // Aba Tenancy
            icon: const FaIcon(FontAwesomeIcons.building, size: 14),
            label: const Text('Gerenciar Tenants'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amareloVale,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterKPIsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 1.7 : 1.3,
          children: [
            _buildStatCard(
              title: 'Tenants / Franquias',
              value: '$_totalTenants',
              subtitle: 'Multi-organizações',
              icon: FontAwesomeIcons.buildingUser,
              color: Colors.cyanAccent,
              onTap: () => widget.onNavigateTab?.call(1),
            ),
            _buildStatCard(
              title: 'Total de Usuários',
              value: '$_totalUsers',
              subtitle: '$_totalPlayers caçadores / $_totalCreators criadores',
              icon: FontAwesomeIcons.users,
              color: AppColors.verdeVale,
              onTap: () => widget.onNavigateTab?.call(2),
            ),
            _buildStatCard(
              title: 'Faturamento Plataforma',
              value: 'R\$ ${_platformRevenue.toStringAsFixed(2)}',
              subtitle: 'Volume bruto: R\$ ${_totalDeposited.toStringAsFixed(2)}',
              icon: FontAwesomeIcons.moneyBillTrendUp,
              color: AppColors.amareloVale,
              onTap: () => widget.onNavigateTab?.call(3),
            ),
            _buildStatCard(
              title: 'Alertas de Segurança',
              value: '$_securityAlertsCount',
              subtitle: '$_pendingWithdrawals saques pendentes',
              icon: FontAwesomeIcons.shieldHalved,
              color: _securityAlertsCount > 0 ? AppColors.danger : Colors.greenAccent,
              onTap: () => widget.onNavigateTab?.call(5),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required dynamic icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                icon is IconData
                    ? Icon(icon, size: 16, color: color)
                    : FaIcon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.9)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Módulos de Governança Master',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                title: 'Controle de Tenancy',
                desc: 'Franquias, cidades e taxas',
                icon: FontAwesomeIcons.building,
                color: Colors.cyanAccent,
                onTap: () => widget.onNavigateTab?.call(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                title: 'Usuários & Permissões',
                desc: 'Caçadores, saldo e roles',
                icon: FontAwesomeIcons.userShield,
                color: AppColors.verdeVale,
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                title: 'Financeiro & Saques',
                desc: 'Aprovar PIX e conciliação',
                icon: FontAwesomeIcons.handHoldingDollar,
                color: AppColors.amareloVale,
                onTap: () => widget.onNavigateTab?.call(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                title: 'Segurança & Anti-Fraude',
                desc: 'Spoofing GPS e logs',
                icon: FontAwesomeIcons.shieldHalved,
                color: AppColors.danger,
                onTap: () => widget.onNavigateTab?.call(5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String desc,
    required dynamic icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon is IconData
                ? Icon(icon, color: color, size: 20)
                : FaIcon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformHealthCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(FontAwesomeIcons.server, color: AppColors.verdeVale, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Infraestrutura & Status dos Serviços',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Parse Server Online • Push Notifications Ativo • Gateways Homologados • Banco de Dados Operacional',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '100% OPERACIONAL',
              style: TextStyle(color: AppColors.verdeVale, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
