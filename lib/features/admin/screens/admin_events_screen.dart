import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminEventsScreen extends StatelessWidget {
  const AdminEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gestão de Eventos',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showEventDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo Evento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAmber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('events').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Nenhum evento encontrado.', style: TextStyle(color: secondaryTextColor)),
                );
              }

              final events = snapshot.data!.docs;

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index].data() as Map<String, dynamic>;
                  final eventId = events[index].id;
                  final title = event['title'] ?? 'Sem Título';
                  final status = event['status'] ?? 'draft';
                  final prizePool = event['prizePool'] ?? 0;

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        status == 'published' ? Icons.play_circle_fill : Icons.pause_circle_filled,
                        color: status == 'published' ? Colors.green : Colors.orange,
                        size: 40,
                      ),
                      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('Status: $status • Prêmio: R\$ $prizePool', style: const TextStyle(color: secondaryTextColor)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.list, color: Colors.blueAccent),
                            onPressed: () {
                              // Action to view/edit phases and enigmas
                            },
                            tooltip: 'Gerenciar Fases/Enigmas',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: primaryAmber),
                            onPressed: () {
                              _showEventDialog(context, docId: eventId, initialData: event);
                            },
                            tooltip: 'Editar Evento',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                               // Action to delete event
                               FirebaseFirestore.instance.collection('events').doc(eventId).delete();
                            },
                            tooltip: 'Excluir Evento',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEventDialog(BuildContext context, {String? docId, Map<String, dynamic>? initialData}) {
    final titleCtrl = TextEditingController(text: initialData?['title'] ?? '');
    final descriptionCtrl = TextEditingController(text: initialData?['description'] ?? '');
    final prizeCtrl = TextEditingController(text: initialData?['prizePool']?.toString() ?? '0');
    final cityCtrl = TextEditingController(text: initialData?['city'] ?? '');
    String status = initialData?['status'] ?? 'draft';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(docId == null ? 'Novo Evento' : 'Editar Evento', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Título', labelStyle: TextStyle(color: secondaryTextColor)),
                ),
                TextField(
                  controller: descriptionCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Descrição', labelStyle: TextStyle(color: secondaryTextColor)),
                ),
                TextField(
                  controller: prizeCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prêmio Final (R\$)', labelStyle: TextStyle(color: secondaryTextColor)),
                ),
                TextField(
                  controller: cityCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Cidade', labelStyle: TextStyle(color: secondaryTextColor)),
                ),
                // Em um cenário real, adicionaríamos um Dropdown para o Status e um FilePicker para a Imagem
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'title': titleCtrl.text,
                  'description': descriptionCtrl.text,
                  'prizePool': num.tryParse(prizeCtrl.text) ?? 0,
                  'city': cityCtrl.text,
                  'status': status,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (docId == null) {
                  data['createdAt'] = FieldValue.serverTimestamp();
                  await FirebaseFirestore.instance.collection('events').add(data);
                } else {
                  await FirebaseFirestore.instance.collection('events').doc(docId).update(data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryAmber, foregroundColor: Colors.black),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}
