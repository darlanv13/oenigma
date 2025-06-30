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

          // Agora o snapshot.data é um Mapa e o código abaixo funcionará
          final List<EventModel> events = (snapshot.data!['events'] as List)
              .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e)))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildStatsRow(snapshot.data!),
              const SizedBox(height: 32),
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
                      if (result == true) {
                        _loadDashboardData(); // Recarrega se um evento foi salvo
                      }
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
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: _buildStatCard(
            "Total de Eventos",
            (data['events'] as List).length.toString(),
            Icons.event,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            "Total de Jogadores",
            (data['playerCount'] ?? 0).toString(),
            Icons.person_outline,
          ),
        ),
        const SizedBox(width: 20),
        // --- NOVO CARD/BOTÃO ADICIONADO AQUI ---
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PlayerManagementScreen(),
                ),
              );
            },
            child: _buildStatCard(
              "Gerenciar",
              "Jogadores",
              Icons.admin_panel_settings,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: primaryAmber),
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

  Widget _buildEventsTable(List<EventModel> events) {
    return Card(
      elevation: 2,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nome')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Inscrições')),
          DataColumn(label: Text('Ações')),
        ],
        rows: events.map((event) {
          return DataRow(
            cells: [
              DataCell(Text(event.name)),
              DataCell(Text(event.status)),
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
                        if (result == true) {
                          _loadDashboardData(); // Recarrega se um evento foi salvo
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
