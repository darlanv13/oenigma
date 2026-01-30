// lib/admin/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/enigma_management_screen.dart';
import 'package:oenigma/admin/screens/event_form_screen.dart';
import 'package:oenigma/admin/screens/phase_management_screen.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard de Eventos"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _firebaseService
            .callFunction('getEventData')
            .then((res) => res.data as List),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(child: Text("Nenhum evento encontrado."));
          }

          final events = snapshot.data!
              .map(
                (data) => EventModel.fromMap(Map<String, dynamic>.from(data)),
              )
              .toList();

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              // O novo código com a lógica de navegação
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Icon(
                      event.eventType == 'classic'
                          ? Icons.view_day_outlined
                          : Icons.track_changes,
                      color: primaryAmber,
                    ),
                    title: Text(
                      event.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Tipo: ${event.eventType} | Status: ${event.status}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botão para Gerenciar Fases/Enigmas
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardColor,
                            side: const BorderSide(color: primaryAmber),
                          ),
                          onPressed: () {
                            // LÓGICA DE NAVEGAÇÃO CONDICIONAL
                            if (event.eventType == 'classic') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PhaseManagementScreen(event: event),
                                ),
                              );
                            } else {
                              // find_and_win
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EnigmaManagementScreen(
                                    eventId: event.id,
                                    eventType: event.eventType,
                                    // phaseId é nulo porque não há fases neste modo
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "Gerenciar",
                            style: TextStyle(color: primaryAmber),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botão de Edição do Evento
                        IconButton(
                          icon: const Icon(Icons.edit_note),
                          tooltip: 'Editar Detalhes do Evento',
                          onPressed: () async {
                            final reloaded = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EventFormScreen(event: event),
                                  ),
                                );
                            if (reloaded == true) {
                              setState(() {});
                            }
                          },
                        ),
                        // Botão de Exclusão do Evento
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade300,
                          ),
                          tooltip: 'Excluir Evento',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirmar Exclusão'),
                                content: Text(
                                  'Tem certeza que deseja excluir o evento "${event.name}"? Esta ação não pode ser desfeita.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Excluir'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _firebaseService.deleteEvent(event.id);
                              setState(() {}); // Recarrega a lista
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => EventFormScreen()));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
