import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
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
          child: FutureBuilder<ParseResponse>(
            future: (QueryBuilder<ParseObject>(ParseObject('banners'))..orderByAscending('order')).query(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.results == null || snapshot.data!.results!.isEmpty) {
                return const Center(
                  child: Text('Nenhum banner cadastrado.', style: TextStyle(color: secondaryTextColor)),
                );
              }

              final banners = snapshot.data!.results! as List<ParseObject>;

              return ListView.builder(
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  final bannerId = banner.objectId!;
                  final imageUrl = banner.get<String>('imageUrl') ?? '';
                  final actionUrl = banner.get<String>('actionUrl') ?? '';
                  final isActive = banner.get<bool>('isActive') ?? false;
                  final order = banner.get<int>('order') ?? 0;

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
                            onPressed: () async {
                               try {
                                 await ParseCloudFunction('deleteBanner').execute(parameters: {'bannerId': bannerId});
                               } catch (e) {
                                 // ignore
                               }
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

  void _showBannerDialog(BuildContext context, {String? docId, ParseObject? initialData}) {
    final imageUrlCtrl = TextEditingController(text: initialData?.get<String>('imageUrl') ?? '');
    final actionUrlCtrl = TextEditingController(text: initialData?.get<String>('actionUrl') ?? '');
    final orderCtrl = TextEditingController(text: initialData?.get<int>('order')?.toString() ?? '');
    bool isActive = initialData?.get<bool>('isActive') ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: darkBackground,
              title: Text(docId == null ? 'Novo Banner' : 'Editar Banner', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: imageUrlCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'URL da Imagem')),
                    TextField(controller: actionUrlCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Link de Ação (URL externa ou tela)')),
                    TextField(controller: orderCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Ordem de Exibição')),
                    SwitchListTile(
                      title: const Text('Banner Ativo?', style: TextStyle(color: Colors.white)),
                      value: isActive,
                      activeColor: primaryAmber,
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: secondaryTextColor))),
                ElevatedButton(
                  onPressed: () async {
                    final data = {
                      'imageUrl': imageUrlCtrl.text,
                      'actionUrl': actionUrlCtrl.text,
                      'order': int.tryParse(orderCtrl.text) ?? 1,
                      'isActive': isActive,
                    };
                    try {
                      if (docId == null) {
                        await ParseCloudFunction('createOrUpdateBanner').execute(parameters: {'data': data});
                      } else {
                        await ParseCloudFunction('createOrUpdateBanner').execute(parameters: {'bannerId': docId, 'data': data});
                      }
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Erro: \$e')));
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
