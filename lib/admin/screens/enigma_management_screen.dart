// lib/admin/screens/enigma_management_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/admin/screens/enigma_form_screen.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class EnigmaManagementScreen extends StatefulWidget {
  final String eventId;
  final String? phaseId; // Nulo para eventos 'Find and Win'
  final String eventType;

  const EnigmaManagementScreen({
    super.key,
    required this.eventId,
    required this.eventType,
    this.phaseId,
  });

  @override
  _EnigmaManagementScreenState createState() => _EnigmaManagementScreenState();
}

class _EnigmaManagementScreenState extends State<EnigmaManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<EnigmaModel>> _enigmasFuture;

  @override
  void initState() {
    super.initState();
    _loadEnigmas();
  }

  void _loadEnigmas() {
    _enigmasFuture = _firebaseService.getEnigmasForParent(
      widget.eventId,
      widget.phaseId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.phaseId == null ? "Enigmas do Evento" : "Enigmas da Fase",
        ),
      ),
      body: FutureBuilder<List<EnigmaModel>>(
        future: _enigmasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Erro ao carregar enigmas: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum enigma criado.",
                style: TextStyle(color: secondaryTextColor),
              ),
            );
          }

          final enigmas = snapshot.data!;

          return ListView.builder(
            itemCount: enigmas.length,
            itemBuilder: (context, index) {
              final enigma = enigmas[index];
              return Card(
                color: cardColor,
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: darkBackground,
                    foregroundColor: primaryAmber,
                    child: Text(
                      enigma.order.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    enigma.instruction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                enigma.type.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: darkBackground,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: primaryAmber,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.key,
                              size: 14,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              enigma.code,
                              style: GoogleFonts.robotoMono(
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      await _firebaseService.deleteEnigma(
                        eventId: widget.eventId,
                        phaseId: widget.phaseId,
                        enigmaId: enigma.id,
                      );
                      setState(() {
                        _loadEnigmas();
                      });
                    },
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EnigmaFormScreen(
                          eventId: widget.eventId,
                          phaseId: widget.phaseId,
                          eventType: widget.eventType,
                          enigma: enigma,
                        ),
                      ),
                    );
                    setState(() {
                      _loadEnigmas();
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EnigmaFormScreen(
                eventId: widget.eventId,
                phaseId: widget.phaseId,
                eventType: widget.eventType,
              ),
            ),
          );
          setState(() {
            _loadEnigmas();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text("Novo Enigma"),
        backgroundColor: primaryAmber,
        foregroundColor: darkBackground,
      ),
    );
  }
}
