// lib/admin/screens/phase_management_screen.dart

import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/enigma_management_screen.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/models/phase_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';

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
        return Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle, color: primaryAmber, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "Adicionar Nova Fase",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Uma nova fase será adicionada sequencialmente ao final da lista. Deseja confirmar?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondaryTextColor),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        foregroundColor: darkBackground,
                      ),
                      child: const Text("Confirmar"),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Erro ao carregar fases: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Nenhuma fase criada para este evento.",
                style: TextStyle(color: secondaryTextColor),
              ),
            );
          }

          final phases = snapshot.data!;

          return ListView.builder(
            itemCount: phases.length,
            itemBuilder: (context, index) {
              final phase = phases[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor, cardColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: primaryAmber,
                    foregroundColor: darkBackground,
                    radius: 24,
                    child: Text(
                      phase.order.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    "Fase ${phase.order}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.extension,
                          size: 16,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${phase.enigmas.length} Enigmas",
                          style: const TextStyle(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
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
        icon: const Icon(Icons.add),
        label: const Text("Nova Fase"),
        backgroundColor: primaryAmber,
        foregroundColor: darkBackground,
      ),
    );
  }
}
