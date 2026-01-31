import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/admin/screens/enigma_deck_screen.dart';
import 'package:oenigma/admin/stores/phase_store.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/utils/app_colors.dart';

class PhaseTimelineScreen extends StatefulWidget {
  final EventModel event;
  const PhaseTimelineScreen({super.key, required this.event});

  @override
  State<PhaseTimelineScreen> createState() => _PhaseTimelineScreenState();
}

class _PhaseTimelineScreenState extends State<PhaseTimelineScreen> {
  final PhaseStore _store = PhaseStore();

  @override
  void initState() {
    super.initState();
    _store.loadPhases(widget.event.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: Text(
          "TIMELINE: ${widget.event.name.toUpperCase()}",
          style: GoogleFonts.orbitron(fontSize: 14),
        ),
        backgroundColor: cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _store.loadPhases(widget.event.id),
          ),
        ],
      ),
      body: Observer(
        builder: (_) {
          if (_store.isLoading && _store.phases.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }

          if (_store.phases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timeline, size: 60, color: Colors.white12),
                  const SizedBox(height: 16),
                  const Text(
                    "Nenhuma fase na timeline.",
                    style: TextStyle(color: secondaryTextColor),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Criar Fase 1"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _store.addPhase(widget.event.id),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            header: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Arraste para reordenar a sequência do jogo",
                style: GoogleFonts.orbitron(color: primaryAmber, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            itemCount: _store.phases.length,
            onReorder: (oldIndex, newIndex) =>
                _store.reorderPhases(widget.event.id, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final phase = _store.phases[index];
              return Container(
                key: ValueKey(phase.id),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryAmber.withOpacity(0.1),
                      border: Border.all(color: primaryAmber),
                    ),
                    child: Text(
                      "${index + 1}",
                      style: GoogleFonts.orbitron(
                        color: primaryAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    "FASE ${phase.order}",
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "${phase.enigmas.length} Enigmas Configurados",
                    style: const TextStyle(color: secondaryTextColor),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EnigmaDeckScreen(
                                eventId: widget.event.id,
                                phaseId: phase.id,
                                eventType: widget.event.eventType,
                              ),
                            ),
                          ).then((_) => _store.loadPhases(widget.event.id));
                        },
                      ),
                      const Icon(Icons.drag_handle, color: Colors.white24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryAmber,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          "NOVA FASE",
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => _store.addPhase(widget.event.id),
      ),
    );
  }
}
