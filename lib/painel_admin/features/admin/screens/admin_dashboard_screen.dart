import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/painel_admin/core/utils/app_colors.dart';

import '../repositories/admin_repository.dart';

final adminDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) {
    final repo = ref.read(adminRepositoryProvider);
    return repo.getAdminDashboardData();
  },
);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(adminDashboardProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dashboardData.when(
            data: (data) => LayoutBuilder(
              builder: (context, constraints) {
                // Responsividade basica (grid de 4 ou menos dependendo da tela)
                int crossAxisCount = 4;
                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1;
                } else if (constraints.maxWidth < 900) {
                  crossAxisCount = 2;
                } else if (constraints.maxWidth < 1200) {
                  crossAxisCount = 3;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      'Eventos',
                      data['activeEvents']?.toString() ?? '...',
                      FontAwesomeIcons.calendar,
                    ),
                    _buildStatCard(
                      'Usuários',
                      data['users']?.toString() ?? '...',
                      FontAwesomeIcons.user,
                    ),
                    _buildStatCard(
                      'Depósitos',
                      data['totalDeposits']?.toString() ?? '...',
                      FontAwesomeIcons.dollarSign,
                    ),
                    _buildStatCard(
                      'Saques',
                      data['pendingWithdrawals']?.toString() ?? '...',
                      FontAwesomeIcons.moneyBillTrendUp,
                    ),
                  ],
                );
              }
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: primaryAmber)),
            error: (err, stack) => Center(
              child: Text(
                'Erro ao carregar dashboard: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.clock, color: primaryAmber, size: 16),
              const SizedBox(width: 10),
              Text(
                'Visão Geral de Engajamento',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryAmber,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryAmber.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: itemCardBackground.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryAmber.withValues(alpha: 0.04),
              ),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 22),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 1),
                      FlSpot(2, 4),
                      FlSpot(3, 2),
                      FlSpot(4, 5),
                      FlSpot(5, 3),
                      FlSpot(6, 6),
                    ],
                    isCurved: true,
                    color: primaryAmber,
                    barWidth: 4,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryAmber.withValues(alpha: 0.2),
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

  Widget _buildStatCard(String title, String value, dynamic icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: itemCardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryAmber.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: highlightTextColor,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: primaryAmber, size: 11),
              const SizedBox(width: 4),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
