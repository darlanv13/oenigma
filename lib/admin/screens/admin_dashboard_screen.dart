import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/enigma_management_screen.dart';
import 'package:oenigma/admin/screens/event_form_screen.dart';
import 'package:oenigma/admin/screens/phase_management_screen.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

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

              // 2. Gráfico de Atividade (Mock)
              const Text("Atividade Recente (Novos Usuários)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                    switch(val.toInt()) {
                                        case 0: return const Text('Seg', style: TextStyle(color: secondaryTextColor));
                                        case 1: return const Text('Ter', style: TextStyle(color: secondaryTextColor));
                                        case 2: return const Text('Qua', style: TextStyle(color: secondaryTextColor));
                                        case 3: return const Text('Qui', style: TextStyle(color: secondaryTextColor));
                                        case 4: return const Text('Sex', style: TextStyle(color: secondaryTextColor));
                                        case 5: return const Text('Sab', style: TextStyle(color: secondaryTextColor));
                                        case 6: return const Text('Dom', style: TextStyle(color: secondaryTextColor));
                                    }
                                    return const Text('');
                                }
                            )
                        )
                    ),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 5, color: primaryAmber, width: 15, borderRadius: BorderRadius.circular(4))]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: primaryAmber, width: 15, borderRadius: BorderRadius.circular(4))]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: primaryAmber, width: 15, borderRadius: BorderRadius.circular(4))]),
                      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: primaryAmber, width: 15, borderRadius: BorderRadius.circular(4))]),
                      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 13, color: primaryAmber, width: 15, borderRadius: BorderRadius.circular(4))]),
                      BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 18, color: primaryAmber, width: 15, borderRadius: BorderRadius.circular(4))]),
                      BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 22, color: primaryAmber, width: 15, borderRadius: BorderRadius.circular(4))]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Lista de Eventos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    const Text("Gerenciar Eventos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Novo Evento"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAmber,
                          foregroundColor: darkBackground
                        ),
                        onPressed: () async {
                             await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventFormScreen()));
                             setState(() {}); // Reload
                        },
                    )
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

  Widget _buildSummaryCards() {
      return Row(
          children: [
              Expanded(child: _buildCard("Saques Pendentes", pendingWithdrawals.toString(), Icons.monetization_on, Colors.orange)),
              const SizedBox(width: 16),
              const Expanded(child: _buildCard("Eventos Ativos", "...", Icons.event, Colors.blue)),
              const SizedBox(width: 16),
              const Expanded(child: _buildCard("Usuários", "...", Icons.people, Colors.green)),
          ],
      );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3))
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Icon(icon, color: color),
                  const SizedBox(height: 8),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(title, style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
              ],
          ),
      );
  }

  Widget _buildEventsList() {
      return FutureBuilder<List<dynamic>>(
        future: _firebaseService.callFunction('getEventData').then((res) => res.data as List),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryAmber));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum evento encontrado.", style: TextStyle(color: secondaryTextColor)));
          }

          final events = snapshot.data!.map(
                (data) => EventModel.fromMap(Map<String, dynamic>.from(data)),
              ).toList();

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
                event.eventType == 'classic' ? Icons.view_day_outlined : Icons.track_changes,
                color: primaryAmber,
              ),
            ),
            title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text("Status: ${event.status}", style: const TextStyle(color: secondaryTextColor)),
            trailing: PopupMenuButton<String>(
                color: cardColor,
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                    if (value == 'manage') {
                        if (event.eventType == 'classic') {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => PhaseManagementScreen(event: event)));
                        } else {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => EnigmaManagementScreen(eventId: event.id, eventType: event.eventType)));
                        }
                    } else if (value == 'edit') {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventFormScreen(event: event)));
                        setState(() {});
                    } else if (value == 'delete') {
                         _confirmDelete(event);
                    }
                },
                itemBuilder: (context) => [
                    const PopupMenuItem(value: 'manage', child: Text("Gerenciar Fases/Enigmas", style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'edit', child: Text("Editar Detalhes", style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text("Excluir", style: TextStyle(color: Colors.red))),
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
                                title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
                                content: Text(
                                  'Tem certeza que deseja excluir o evento "${event.name}"? Esta ação não pode ser desfeita.',
                                  style: const TextStyle(color: secondaryTextColor),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
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
