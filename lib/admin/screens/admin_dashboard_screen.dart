import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oenigma/admin/screens/event_studio_screen.dart';
import 'package:oenigma/admin/screens/user_list_screen.dart';
import 'package:oenigma/admin/screens/widgets/admin_layout.dart';
import 'package:oenigma/admin/screens/withdrawal_requests_screen.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, String? userRole});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _pendingWithdrawals = [];

  // Dados simulados para o gráfico (seriam substituídos por dados reais da API)
  final List<Color> gradientColors = [primaryAmber, Colors.orangeAccent];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Carrega dados agregados (KPIs)
      final dashboardData = await _firebaseService.getAdminDashboardData();
      // Carrega saques pendentes
      final withdrawals = await _firebaseService.getPendingWithdrawals();

      if (mounted) {
        setState(() {
          _dashboardData = dashboardData;
          _pendingWithdrawals = withdrawals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Centro de Comando',
      currentRoute: AdminRoute.dashboard, // Define qual item do menu fica aceso
      // Adicione a ação de refresh aqui
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: secondaryTextColor),
          onPressed: _loadDashboardData,
        ),
        const SizedBox(width: 10),
      ],
      body: _isLoading
          ? _buildLoadingSkeleton()
          : RefreshIndicator(
              color: primaryAmber,
              backgroundColor: cardColor,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildKPIGrid(),
                    const SizedBox(height: 24),
                    _buildRevenueChart(),
                    const SizedBox(height: 24),
                    if (_pendingWithdrawals.isNotEmpty) ...[
                      _buildPendingWithdrawalsAlert(),
                      const SizedBox(height: 24),
                    ],
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Visão Geral Operacional",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Última atualização: ${DateFormat('HH:mm').format(DateTime.now())}",
          style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildKPIGrid() {
    // Valores seguros com fallback
    final activePlayers = _dashboardData['activePlayers'] ?? 0;
    final totalRevenue = _dashboardData['totalRevenue'] ?? 0.0;
    final activeEvents = _dashboardData['activeEvents'] ?? 0;
    final completionRate = _dashboardData['completionRate'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildPremiumCard(
          "Jogadores",
          activePlayers.toString(),
          Icons.people_alt_rounded,
          Colors.blueAccent,
        ),
        _buildPremiumCard(
          "Receita",
          "R\$ ${totalRevenue.toStringAsFixed(0)}",
          Icons.attach_money_rounded,
          Colors.greenAccent,
        ),
        _buildPremiumCard(
          "Eventos Ativos",
          activeEvents.toString(),
          Icons.local_activity_rounded,
          Colors.purpleAccent,
        ),
        _buildPremiumCard(
          "Conclusão",
          "$completionRate%",
          Icons.flag_rounded,
          Colors.orangeAccent,
        ),
      ],
    );
  }

  Widget _buildPremiumCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColor, color.withOpacity(0.1)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 80, color: color.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.orbitron(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tendência de Receita",
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "+12.5%",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: secondaryTextColor,
                          fontSize: 10,
                        );
                        switch (value.toInt()) {
                          case 0:
                            return const Text('SEG', style: style);
                          case 2:
                            return const Text('QUA', style: style);
                          case 4:
                            return const Text('SEX', style: style);
                          case 6:
                            return const Text('DOM', style: style);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}k',
                          style: const TextStyle(
                            color: secondaryTextColor,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 1),
                      FlSpot(2, 4),
                      FlSpot(3, 2),
                      FlSpot(4, 5),
                      FlSpot(5, 3),
                      FlSpot(6, 4),
                    ],
                    isCurved: true,
                    gradient: LinearGradient(colors: gradientColors),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: gradientColors
                            .map((color) => color.withOpacity(0.2))
                            .toList(),
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildPendingWithdrawalsAlert() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.priority_high_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          "${_pendingWithdrawals.length} Solicitações de Saque",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          "Aguardando aprovação financeira",
          style: TextStyle(color: secondaryTextColor, fontSize: 12),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WithdrawalRequestsScreen(),
              ),
            ).then((_) => _loadDashboardData());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text("Verificar"),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gestão Rápida",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildActionButton(
              "Criar Evento",
              Icons.add_location_alt_outlined,
              primaryAmber,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventStudioScreen()),
              ),
            ),
            _buildActionButton(
              "Usuários",
              Icons.manage_accounts_outlined,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserListScreen()),
              ),
            ),
            _buildActionButton(
              "Enigmas",
              Icons.extension_outlined,
              Colors.purple,
              () {
                // Navegação placeholder - idealmente passaria um ID de evento ou abriria seletor
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecione um evento para gerenciar enigmas'),
                  ),
                );
              },
            ),
            _buildActionButton(
              "Configurações",
              Icons.settings_outlined,
              Colors.grey,
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: cardColor,
      highlightColor: Colors.grey[800]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(height: 100, color: Colors.white),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: List.generate(
                4,
                (index) => Container(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 200, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
