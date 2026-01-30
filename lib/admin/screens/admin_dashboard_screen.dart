import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/enigma_management_screen.dart';
import 'package:oenigma/admin/screens/event_form_screen.dart';
import 'package:oenigma/admin/screens/phase_management_screen.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? userRole;
  const AdminDashboardScreen({super.key, this.userRole});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  int pendingWithdrawals = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final withdrawals = await _firebaseService.getPendingWithdrawals();
      if (mounted) {
        setState(() {
          pendingWithdrawals = withdrawals.length;
        });
      }
    } catch (e) {
      print("Erro ao buscar stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cards de Resumo
              _buildSummaryCards(),
              const SizedBox(height: 24),

              // 2. Gráficos e Visualizações
              if (['super_admin', 'admin'].contains(widget.userRole)) ...[
                 _buildActivityChart(),
                 const SizedBox(height: 24),
                 _buildDifficultyHeatmap(),
                 const SizedBox(height: 24),
              ],

              // 3. Lista de Eventos
              if (['editor', 'super_admin', 'admin'].contains(widget.userRole))
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Gerenciar Eventos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Novo Evento"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      foregroundColor: darkBackground,
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EventFormScreen(),
                        ),
                      );
                      setState(() {}); // Reload
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEventsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Atividade Recente (Novos Usuários)",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
           height: 250,
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: cardColor,
             borderRadius: BorderRadius.circular(16),
           ),
           child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white10,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                       const style = TextStyle(color: Colors.white54, fontSize: 12);
                       Widget text;
                       switch (value.toInt()) {
                         case 0: text = const Text('Seg', style: style); break;
                         case 1: text = const Text('Ter', style: style); break;
                         case 2: text = const Text('Qua', style: style); break;
                         case 3: text = const Text('Qui', style: style); break;
                         case 4: text = const Text('Sex', style: style); break;
                         case 5: text = const Text('Sab', style: style); break;
                         case 6: text = const Text('Dom', style: style); break;
                         default: text = const Text('', style: style);
                       }
                       return SideTitleWidget(axisSide: meta.axisSide, child: text);
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 12));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _makeGroupData(0, 5),
                _makeGroupData(1, 10),
                _makeGroupData(2, 14),
                _makeGroupData(3, 15),
                _makeGroupData(4, 13),
                _makeGroupData(5, 18),
                _makeGroupData(6, 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [primaryAmber, Colors.deepOrange],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 25, // Max value
            color: Colors.white10,
          ),
        ),
      ],
    );
  }

  // Placeholder for "Heatmap" / Difficulty Zones
  Widget _buildDifficultyHeatmap() {
    // Mock data for "Zones with most difficulty"
    final zones = [
      {'name': 'Praça Central - Enigma #4', 'fails': 45, 'color': Colors.red},
      {'name': 'Biblioteca - Enigma #2', 'fails': 32, 'color': Colors.orange},
      {'name': 'Estação - Enigma #1', 'fails': 15, 'color': Colors.yellow},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Zonas de Alta Dificuldade (Heatmap)",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: zones.map((zone) {
              final fails = zone['fails'] as int;
              final widthFactor = fails / 50.0; // Assuming 50 is max

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        zone['name'] as String,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: widthFactor.clamp(0.0, 1.0),
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: zone['color'] as Color,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: (zone['color'] as Color).withOpacity(0.5),
                                    blurRadius: 6,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$fails falhas",
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    // Define visibility based on role
    final role = widget.userRole;
    final canViewFinance = ['auditor', 'super_admin', 'admin'].contains(role);
    final canViewEvents = ['editor', 'super_admin', 'admin'].contains(role);
    final canViewUsers = ['editor', 'super_admin', 'admin'].contains(role);

    List<Widget> cards = [];

    if (canViewFinance) {
      cards.add(Expanded(
        child: _buildCard(
          "Saques Pendentes",
          pendingWithdrawals.toString(),
          Icons.monetization_on,
          [Colors.orange.shade400, Colors.deepOrange.shade600],
        ),
      ));
    }

    if (canViewEvents) {
      if (cards.isNotEmpty) cards.add(const SizedBox(width: 16));
      cards.add(Expanded(
        child: _buildCard(
          "Eventos Ativos",
          "...", // Placeholder
          Icons.event,
          [Colors.blue.shade400, Colors.indigo.shade600],
        ),
      ));
    }

    if (canViewUsers) {
      if (cards.isNotEmpty) cards.add(const SizedBox(width: 16));
      cards.add(Expanded(
        child: _buildCard(
          "Usuários",
          "...", // Placeholder
          Icons.people,
          [Colors.green.shade400, Colors.teal.shade600],
        ),
      ));
    }

    // If empty (shouldn't happen with correct routing), show nothing
    if (cards.isEmpty) return const SizedBox.shrink();

    return Row(
      children: cards,
    );
  }

  Widget _buildCard(String title, String value, IconData icon, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Icon(icon, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return FutureBuilder<List<dynamic>>(
      future: _firebaseService
          .callFunction('getEventData')
          .then((res) => res.data as List),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryAmber),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "Nenhum evento encontrado.",
              style: TextStyle(color: secondaryTextColor),
            ),
          );
        }

        final events = snapshot.data!
            .map((data) => EventModel.fromMap(Map<String, dynamic>.from(data)))
            .toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventItem(event);
          },
        );
      },
    );
  }

  Widget _buildEventItem(EventModel event) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: darkBackground,
          child: Icon(
            event.eventType == 'classic'
                ? Icons.view_day_outlined
                : Icons.track_changes,
            color: primaryAmber,
          ),
        ),
        title: Text(
          event.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          "Status: ${event.status}",
          style: const TextStyle(color: secondaryTextColor),
        ),
        trailing: PopupMenuButton<String>(
          color: cardColor,
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) async {
            if (value == 'manage') {
              if (event.eventType == 'classic') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PhaseManagementScreen(event: event),
                  ),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EnigmaManagementScreen(
                      eventId: event.id,
                      eventType: event.eventType,
                    ),
                  ),
                );
              }
            } else if (value == 'edit') {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventFormScreen(event: event),
                ),
              );
              setState(() {});
            } else if (value == 'delete') {
              _confirmDelete(event);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'manage',
              child: Text(
                "Gerenciar Fases/Enigmas",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Text(
                "Editar Detalhes",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text("Excluir", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Confirmar Exclusão',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Tem certeza que deseja excluir o evento "${event.name}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebaseService.deleteEvent(event.id);
      setState(() {});
    }
  }
}
