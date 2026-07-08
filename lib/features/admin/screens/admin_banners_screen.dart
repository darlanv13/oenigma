import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  late Future<ParseResponse> _bannersFuture;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  void _loadBanners() {
    setState(() {
      _bannersFuture = (QueryBuilder<ParseObject>(ParseObject('Banner'))
            ..orderByAscending('order'))
          .query();
    });
  }

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
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showBannerDialog(context);
              },
              icon: const FaIcon(FontAwesomeIcons.image),
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
            future: _bannersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.success || snapshot.data!.results == null || snapshot.data!.results!.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum banner cadastrado.',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                );
              }

              final banners = snapshot.data!.results as List<ParseObject>;

              return ListView.builder(
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  final bannerId = banner.objectId!;
                  final title = banner.get<String>('title') ?? 'Sem Título';
                  final imageUrl = banner.get<String>('imageUrl') ?? '';
                  final actionUrl = banner.get<String>('actionUrl') ?? '';
                  final order = banner.get<num>('order') ?? 0;
                  final isActive = banner.get<bool>('isActive') ?? false;

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 100,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 60,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.error,
                                            color: Colors.red),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 100,
                                    height: 60,
                                    color: Colors.grey[800],
                                    child: const FaIcon(FontAwesomeIcons.image,
                                        color: Colors.white54),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ordem: $order - Status: ${isActive ? "Ativo" : "Inativo"}',
                                  style: const TextStyle(
                                      color: secondaryTextColor, fontSize: 12),
                                ),
                                if (actionUrl.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Link: $actionUrl',
                                    style: const TextStyle(
                                        color: Colors.blueAccent, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.penToSquare,
                                    color: Colors.blue, size: 20),
                                onPressed: () {
                                  _showBannerDialog(
                                    context,
                                    docId: bannerId,
                                    data: _parseObjectToMap(banner),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.trash,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: darkBackground,
                                      title: const Text('Confirmar exclusão',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      content: const Text(
                                          'Deseja mesmo excluir este banner?',
                                          style: TextStyle(
                                              color: secondaryTextColor)),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            try {
                                              await ParseCloudFunction('deleteBanner').execute(parameters: {
                                                'bannerId': bannerId,
                                              });
                                              _loadBanners();
                                            } catch (e) {
                                              debugPrint('Erro ao excluir: $e');
                                            }
                                          },
                                          child: const Text('Excluir'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
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

  Map<String, dynamic> _parseObjectToMap(ParseObject obj) {
    final map = <String, dynamic>{};
    obj.toJson().forEach((key, value) {
      map[key] = value;
    });
    return map;
  }

  void _showBannerDialog(BuildContext context,
      {String? docId, Map<String, dynamic>? data}) {
    final titleCtrl = TextEditingController(text: data?['title']);
    final imageUrlCtrl = TextEditingController(text: data?['imageUrl']);
    final actionUrlCtrl = TextEditingController(text: data?['actionUrl']);
    final orderCtrl = TextEditingController(
        text: data?['order']?.toString() ?? '1');
    bool isActive = data?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: darkBackground,
              title: Text(
                docId == null ? 'Novo Banner' : 'Editar Banner',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    TextField(
                      controller: imageUrlCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'URL da Imagem (Obrigatório)'),
                    ),
                    TextField(
                      controller: actionUrlCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'URL de Ação (Opcional)'),
                    ),
                    TextField(
                      controller: orderCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Ordem'),
                      keyboardType: TextInputType.number,
                    ),
                    SwitchListTile(
                      title: const Text('Ativo',
                          style: TextStyle(color: Colors.white)),
                      value: isActive,
                      activeThumbColor: primaryAmber,
                      onChanged: (val) {
                        setState(() => isActive = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (imageUrlCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('URL da imagem é obrigatória')),
                      );
                      return;
                    }

                    final newData = {
                      'title': titleCtrl.text,
                      'imageUrl': imageUrlCtrl.text,
                      'actionUrl': actionUrlCtrl.text,
                      'order': int.tryParse(orderCtrl.text) ?? 1,
                      'isActive': isActive,
                    };

                    try {
                      if (docId == null) {
                        await ParseCloudFunction('createOrUpdateBanner').execute(parameters: {
                          'data': newData
                        });
                      } else {
                        await ParseCloudFunction('createOrUpdateBanner').execute(parameters: {
                          'bannerId': docId,
                          'data': newData
                        });
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadBanners();
                      }
                    } catch (e) {
                      debugPrint('Erro ao salvar banner: $e');
                    }
                  },
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
