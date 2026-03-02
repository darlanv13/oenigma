import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminToolsScreen extends StatelessWidget {
  const AdminToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gestão de Dicas (Caixa Global)',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showHintDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova Dica'),
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
            stream: FirebaseFirestore.instance.collection('hints_pool').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Nenhuma dica global cadastrada.', style: TextStyle(color: secondaryTextColor)),
                );
              }

              final hints = snapshot.data!.docs;

              return ListView.builder(
                itemCount: hints.length,
                itemBuilder: (context, index) {
                  final hint = hints[index].data() as Map<String, dynamic>;
                  final hintId = hints[index].id;
                  final title = hint['title'] ?? 'Sem Título';
                  final type = hint['type'] ?? 'text'; // text, image_url, audio_url
                  final content = hint['content'] ?? '';

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        type == 'image_url' ? Icons.image : type == 'audio_url' ? Icons.audiotrack : Icons.text_snippet,
                        color: primaryAmber,
                        size: 40,
                      ),
                      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('Tipo: $type\nConteúdo: $content', style: const TextStyle(color: secondaryTextColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () {
                              _showHintDialog(context, docId: hintId, initialData: hint);
                            },
                            tooltip: 'Editar Dica',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                               FirebaseFirestore.instance.collection('hints_pool').doc(hintId).delete();
                            },
                            tooltip: 'Excluir Dica',
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

  void _showHintDialog(BuildContext context, {String? docId, Map<String, dynamic>? initialData}) {
    final titleCtrl = TextEditingController(text: initialData?['title'] ?? '');
    final contentCtrl = TextEditingController(text: initialData?['content'] ?? '');
    String type = initialData?['type'] ?? 'text';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: cardColor,
              title: Text(docId == null ? 'Nova Dica Global' : 'Editar Dica', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Título de Referência (Admin)', labelStyle: TextStyle(color: secondaryTextColor)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Tipo da Dica:', style: TextStyle(color: secondaryTextColor)),
                    DropdownButton<String>(
                      value: type,
                      dropdownColor: darkBackground,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('Texto (Charada)')),
                        DropdownMenuItem(value: 'image_url', child: Text('Imagem (URL)')),
                        DropdownMenuItem(value: 'audio_url', child: Text('Áudio (URL)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => type = val);
                        }
                      },
                    ),
                    TextField(
                      controller: contentCtrl,
                      style: const TextStyle(color: Colors.white),
                      maxLines: type == 'text' ? 3 : 1,
                      decoration: InputDecoration(
                        labelText: type == 'text' ? 'Texto da Charada' : 'URL do Arquivo',
                        labelStyle: const TextStyle(color: secondaryTextColor)
                      ),
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
                      'type': type,
                      'content': contentCtrl.text,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (docId == null) {
                      data['createdAt'] = FieldValue.serverTimestamp();
                      await FirebaseFirestore.instance.collection('hints_pool').add(data);
                    } else {
                      await FirebaseFirestore.instance.collection('hints_pool').doc(docId).update(data);
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
      },
    );
  }
}
