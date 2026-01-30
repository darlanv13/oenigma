// lib/admin/screens/enigma_management_screen.dart

import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/enigma_form_screen.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/services/firebase_service.dart';
// Crie a tela EnigmaFormScreen a seguir
// import 'enigma_form_screen.dart';

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
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Erro ao carregar enigmas: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Nenhum enigma criado."));
          }

          final enigmas = snapshot.data!;

          return ListView.builder(
            itemCount: enigmas.length,
            itemBuilder: (context, index) {
              final enigma = enigmas[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(enigma.order.toString())),
                  title: Text(
                    enigma.instruction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "Tipo: ${enigma.type} | Código: ${enigma.code}",
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
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
        icon: Icon(Icons.add),
        label: Text("Novo Enigma"),
      ),
    );
  }
}
