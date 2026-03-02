import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminBannersScreen extends StatelessWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gestão de Banners',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showBannerDialog(context);
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Novo Banner'),
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
            stream: FirebaseFirestore.instance.collection('banners').orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Nenhum banner cadastrado.', style: TextStyle(color: secondaryTextColor)),
                );
              }

              final banners = snapshot.data!.docs;

              return ListView.builder(
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index].data() as Map<String, dynamic>;
                  final bannerId = banners[index].id;
                  final imageUrl = banner['imageUrl'] ?? '';
                  final actionUrl = banner['actionUrl'] ?? '';
                  final isActive = banner['isActive'] ?? false;
                  final order = banner['order'] ?? 0;

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: SizedBox(
                        width: 80,
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image))
                            : const Icon(Icons.image, color: Colors.grey),
                      ),
                      title: Text('Ordem: $order - ${isActive ? "Ativo" : "Inativo"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('Link: $actionUrl', style: const TextStyle(color: secondaryTextColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: primaryAmber),
                            onPressed: () {
                              _showBannerDialog(context, docId: bannerId, initialData: banner);
                            },
                            tooltip: 'Editar Banner',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                               FirebaseFirestore.instance.collection('banners').doc(bannerId).delete();
                            },
                            tooltip: 'Excluir Banner',
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

  void _showBannerDialog(BuildContext context, {String? docId, Map<String, dynamic>? initialData}) {
    final imageCtrl = TextEditingController(text: initialData?['imageUrl'] ?? '');
    final actionCtrl = TextEditingController(text: initialData?['actionUrl'] ?? '');
    final orderCtrl = TextEditingController(text: initialData?['order']?.toString() ?? '1');
    bool isActive = initialData?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: cardColor,
              title: Text(docId == null ? 'Novo Banner' : 'Editar Banner', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: imageCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'URL da Imagem', labelStyle: TextStyle(color: secondaryTextColor)),
                    ),
                    TextField(
                      controller: actionCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'URL de Ação (Abre ao clicar)', labelStyle: TextStyle(color: secondaryTextColor)),
                    ),
                    TextField(
                      controller: orderCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ordem de Exibição', labelStyle: TextStyle(color: secondaryTextColor)),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Banner Ativo', style: TextStyle(color: Colors.white)),
                      value: isActive,
                      activeTrackColor: primaryAmber.withValues(alpha: 0.5),
                      activeThumbColor: primaryAmber,
                      onChanged: (val) {
                        setState(() {
                          isActive = val;
                        });
                      },
                    )
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
                      'imageUrl': imageCtrl.text,
                      'actionUrl': actionCtrl.text,
                      'order': int.tryParse(orderCtrl.text) ?? 1,
                      'isActive': isActive,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (docId == null) {
                      data['createdAt'] = FieldValue.serverTimestamp();
                      await FirebaseFirestore.instance.collection('banners').add(data);
                    } else {
                      await FirebaseFirestore.instance.collection('banners').doc(docId).update(data);
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
