import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Geral',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<AggregateQuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').count().get().asStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.count?.toString() ?? '...';
                    return _buildStatCard('Usuários Ativos', count, Icons.people, Colors.blue);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<AggregateQuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'published').count().get().asStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.count?.toString() ?? '...';
                    return _buildStatCard('Eventos Ativos', count, Icons.event_available, Colors.green);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<AggregateQuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('transactions').where('type', isEqualTo: 'deposit').count().get().asStream(),
                  builder: (context, snapshot) {
                     final count = snapshot.data?.count?.toString() ?? '...';
                    return _buildStatCard('Depósitos Totais', count, Icons.attach_money, primaryAmber);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<AggregateQuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('withdrawals').where('status', isEqualTo: 'pending').count().get().asStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.count?.toString() ?? '...';
                    return _buildStatCard('Saques Pendentes', count, Icons.money_off, Colors.redAccent);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Visão Geral de Engajamento',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
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
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: secondaryTextColor, fontSize: 14),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
