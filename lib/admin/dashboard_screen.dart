import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/admin/event_editor_screen.dart';
import 'package:oenigma/admin/player_management_screen.dart';
import 'package:oenigma/models/event_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  Future<Map<String, dynamic>>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    setState(() {
      _dashboardFuture = _firebaseService.getAdminDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard de Gerenciamento"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text("Erro ao carregar dados: ${snapshot.error}"),
            );
          }

          final dashboardData = snapshot.data!;
          final List<EventModel> events = (dashboardData['events'] as List)
              .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildStatsRow(dashboardData),
              const SizedBox(height: 32),
              if (events.isNotEmpty) ...[
                Text(
                  "Popularidade dos Eventos",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildEventPopularityChart(events),
                const SizedBox(height: 32),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Eventos",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EventEditorScreen(),
                        ),
                      );
                      if (result == true) _loadDashboardData();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Criar Novo Evento"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      foregroundColor: darkBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEventsTable(events),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Total de Eventos",
            (data['events'] as List).length.toString(),
            Icons.event,
            Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            "Total de Jogadores",
            (data['playerCount'] ?? 0).toString(),
            Icons.person_outline,
            Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlayerManagementScreen()),
            ),
            child: _buildStatCard(
              "Gerenciar",
              "Jogadores",
              Icons.admin_panel_settings,
              Colors.orangeAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: secondaryTextColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventPopularityChart(List<EventModel> events) {
    // Ordena os eventos por popularidade para um melhor visual
    final sortedEvents = List<EventModel>.from(events)
      ..sort((a, b) => b.playerCount.compareTo(a.playerCount));

    return SizedBox(
      height: 300,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: sortedEvents.asMap().entries.map((entry) {
                final event = entry.value;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: event.playerCount.toDouble(),
                      color: primaryAmber,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < sortedEvents.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            sortedEvents[index].name.split(' ').first,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsTable(List<EventModel> events) {
    return Card(
      elevation: 2,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nome do Evento')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Inscrições')),
          DataColumn(label: Text('Ações')),
        ],
        rows: events.map((event) {
          return DataRow(
            cells: [
              DataCell(Text(event.name)),
              DataCell(
                DropdownButton<String>(
                  value: event.status,
                  items: ['dev', 'open', 'closed'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      _firebaseService
                          .toggleEventStatus(
                            eventId: event.id,
                            newStatus: newStatus,
                          )
                          .then((_) => _loadDashboardData());
                    }
                  },
                ),
              ),
              DataCell(Center(child: Text(event.playerCount.toString()))),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: primaryAmber),
                      tooltip: "Editar Evento",
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventEditorScreen(event: event),
                          ),
                        );
                        if (result == true) _loadDashboardData();
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      tooltip: "Excluir Evento",
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Confirmar Exclusão"),
                            content: Text(
                              "Tem certeza que deseja excluir o evento '${event.name}'? Esta ação não pode ser desfeita.",
                            ),
                            actions: [
                              TextButton(
                                child: const Text("Cancelar"),
                                onPressed: () => Navigator.of(ctx).pop(false),
                              ),
                              ElevatedButton(
                                child: const Text("Excluir"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _firebaseService.deleteEvent(event.id);
                          _loadDashboardData();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
