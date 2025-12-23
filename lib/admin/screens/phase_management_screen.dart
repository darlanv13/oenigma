// lib/admin/screens/phase_management_screen.dart

import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/enigma_management_screen.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/models/phase_model.dart';
import 'package:oenigma/services/firebase_service.dart';

class PhaseManagementScreen extends StatefulWidget {
  final EventModel event;

  const PhaseManagementScreen({super.key, required this.event});

  @override
  _PhaseManagementScreenState createState() => _PhaseManagementScreenState();
}

class _PhaseManagementScreenState extends State<PhaseManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<PhaseModel>> _phasesFuture;

  @override
  void initState() {
    super.initState();
    _loadPhases();
  }

  void _loadPhases() {
    _phasesFuture = _firebaseService.getPhasesForEvent(widget.event.id);
  }

  void _showAddPhaseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adicionar Nova Fase'),
          content: Text(
            'Uma nova fase será adicionada ao final da lista. Você confirma?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // A ordem será calculada no backend
                await _firebaseService.createOrUpdatePhase(
                  eventId: widget.event.id,
                  data: {},
                );
                setState(() {
                  _loadPhases();
                });
              },
              child: Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fases de: ${widget.event.name}")),
      body: FutureBuilder<List<PhaseModel>>(
        future: _phasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Erro ao carregar fases: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Nenhuma fase criada para este evento."));
          }

          final phases = snapshot.data!;

          return ListView.builder(
            itemCount: phases.length,
            itemBuilder: (context, index) {
              final phase = phases[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(phase.order.toString())),
                  title: Text("Fase ${phase.order}"),
                  subtitle: Text("${phase.enigmas.length} Enigmas"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      await _firebaseService.deletePhase(
                        eventId: widget.event.id,
                        phaseId: phase.id,
                      );
                      setState(() {
                        _loadPhases();
                      });
                    },
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EnigmaManagementScreen(
                          eventId: widget.event.id,
                          phaseId: phase.id,
                          eventType: widget.event.eventType,
                        ),
                      ),
                    );
                    setState(() {
                      _loadPhases();
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPhaseDialog,
        icon: Icon(Icons.add),
        label: Text("Nova Fase"),
      ),
    );
  }
}
