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
                               Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AdminPhasesScreen(eventId: eventId, eventTitle: title)),
                               );
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

class AdminPhasesScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;

  const AdminPhasesScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: Text('Fases: $eventTitle'),
        backgroundColor: cardColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             ElevatedButton.icon(
              onPressed: () {
                _showPhaseDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova Fase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAmber,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .doc(eventId)
                    .collection('phases')
                    .orderBy('order')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final phases = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: phases.length,
                    itemBuilder: (context, index) {
                      final phase = phases[index].data() as Map<String, dynamic>;
                      final phaseId = phases[index].id;
                      final order = phase['order'] ?? 0;
                      final isBlocked = phase['isBlocked'] ?? false;

                      return Card(
                        color: cardColor,
                        child: ExpansionTile(
                          title: Text('Fase $order', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Status: ${isBlocked ? "Bloqueada" : "Ativa"}', style: const TextStyle(color: secondaryTextColor)),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: primaryAmber),
                            onPressed: () => _showPhaseDialog(context, docId: phaseId, initialData: phase),
                          ),
                          children: [
                             Padding(
                               padding: const EdgeInsets.all(16.0),
                               child: AdminEnigmasList(eventId: eventId, phaseId: phaseId),
                             )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhaseDialog(BuildContext context, {String? docId, Map<String, dynamic>? initialData}) {
    final orderCtrl = TextEditingController(text: initialData?['order']?.toString() ?? '1');
    bool isBlocked = initialData?['isBlocked'] ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(docId == null ? 'Nova Fase' : 'Editar Fase', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: orderCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ordem (Nº da Fase)', labelStyle: TextStyle(color: secondaryTextColor)),
              ),
              // Simpler switch mock for blocked
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'order': int.tryParse(orderCtrl.text) ?? 1,
                  'isBlocked': isBlocked,
                };

                final ref = FirebaseFirestore.instance.collection('events').doc(eventId).collection('phases');

                if (docId == null) {
                  await ref.add(data);
                } else {
                  await ref.doc(docId).update(data);
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

class AdminEnigmasList extends StatelessWidget {
  final String eventId;
  final String phaseId;

  const AdminEnigmasList({super.key, required this.eventId, required this.phaseId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showEnigmaDialog(context),
          icon: const Icon(Icons.add_task, size: 16),
          label: const Text('Adicionar Enigma/Desafio'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .collection('phases')
              .doc(phaseId)
              .collection('enigmas')
              .orderBy('order')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Carregando...', style: TextStyle(color: Colors.white));
            final enigmas = snapshot.data!.docs;
            if (enigmas.isEmpty) return const Text('Nenhum enigma cadastrado nesta fase.', style: TextStyle(color: secondaryTextColor));

            return Column(
              children: enigmas.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['title'] ?? 'Enigma', style: const TextStyle(color: Colors.white)),
                  subtitle: Text('Tipo: ${data['type']}', style: const TextStyle(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _showEnigmaDialog(context, docId: doc.id, initialData: data)),
                      IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => doc.reference.delete()),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showEnigmaDialog(BuildContext context, {String? docId, Map<String, dynamic>? initialData}) {
    final titleCtrl = TextEditingController(text: initialData?['title'] ?? '');
    final typeCtrl = TextEditingController(text: initialData?['type'] ?? 'qr_code_gps');
    final codeCtrl = TextEditingController(text: initialData?['correctCode'] ?? '');
    final orderCtrl = TextEditingController(text: initialData?['order']?.toString() ?? '1');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Configurar Enigma', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Título da Pista/Enigma')),
                TextField(controller: typeCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Tipo (qr_code_gps, password, image)')),
                TextField(controller: codeCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Código/Senha Correta')),
                TextField(controller: orderCtrl, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ordem')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'title': titleCtrl.text,
                  'type': typeCtrl.text,
                  'correctCode': codeCtrl.text,
                  'order': int.tryParse(orderCtrl.text) ?? 1,
                };
                final ref = FirebaseFirestore.instance.collection('events').doc(eventId).collection('phases').doc(phaseId).collection('enigmas');
                if (docId == null) {
                  await ref.add(data);
                } else {
                  await ref.doc(docId).update(data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}
