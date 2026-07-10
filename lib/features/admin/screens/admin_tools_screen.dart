import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/features/admin/utils/admin_upload_util.dart';

class AdminToolsScreen extends StatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  State<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends State<AdminToolsScreen> {
  late Future<ParseResponse> _hintsFuture;

  @override
  void initState() {
    super.initState();
    _loadHints();
  }

  void _loadHints() {
    setState(() {
      _hintsFuture = (QueryBuilder<ParseObject>(
        ParseObject('Hint'),
      )..orderByDescending('createdAt')).query();
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
              'Gestão de Dicas (Caixa Global)',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showHintDialog(context);
              },
              icon: const FaIcon(FontAwesomeIcons.plus),
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
          child: FutureBuilder<ParseResponse>(
            future: _hintsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              if (!snapshot.hasData ||
                  !snapshot.data!.success ||
                  snapshot.data!.results == null ||
                  snapshot.data!.results!.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma dica global cadastrada.',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                );
              }

              final hints = snapshot.data!.results as List<ParseObject>;

              return ListView.builder(
                itemCount: hints.length,
                itemBuilder: (context, index) {
                  final hint = hints[index];
                  final hintId = hint.objectId!;
                  final title = hint.get<String>('title') ?? 'Sem Título';
                  final description = hint.get<String>('description') ?? '';
                  final type = hint.get<String>('type') ?? 'text';
                  // ignore: unused_local_variable
                  var contentUrl = hint.get<String>('contentUrl') ?? '';

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryAmber.withValues(alpha: 0.2),
                        child: FaIcon(
                          type == 'text'
                              ? FontAwesomeIcons.fileLines
                              : (type == 'image'
                                    ? FontAwesomeIcons.image
                                    : FontAwesomeIcons.microphoneLines),
                          color: primaryAmber,
                        ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(color: secondaryTextColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tipo: $type',
                            style: const TextStyle(
                              color: primaryAmber,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.penToSquare,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              _showHintDialog(
                                context,
                                docId: hintId,
                                data: _parseObjectToMap(hint),
                              );
                            },
                          ),
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.trash,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: darkBackground,
                                  title: const Text(
                                    'Confirmar exclusão',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'Deseja mesmo excluir esta dica?',
                                    style: TextStyle(color: secondaryTextColor),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(
                                          context,
                                        ); // Fecha o dialog de confirmação
                                        try {
                                          final response =
                                              await ParseCloudFunction(
                                                'deleteHint',
                                              ).execute(
                                                parameters: {'hintId': hintId},
                                              );

                                          // VERIFICAÇÃO ADICIONADA:
                                          if (response.success) {
                                            _loadHints();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Dica excluída com sucesso!',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Erro: ${response.error?.message}',
                                                  ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                              );
                                            }
                                          }
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

  void _showHintDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) {
    final titleCtrl = TextEditingController(text: data?['title']);
    final descCtrl = TextEditingController(text: data?['description']);
    String selectedType = data?['type'] ?? 'text';
    if (!['text', 'image', 'audio'].contains(selectedType)) {
      selectedType = 'text';
    }
    final contentUrlCtrl = TextEditingController(text: data?['contentUrl']);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: darkBackground,
          title: Text(
            docId == null ? 'Nova Dica' : 'Editar Dica',
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: darkBackground,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Dica',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('Texto')),
                    DropdownMenuItem(value: 'image', child: Text('Imagem (Foto)')),
                    DropdownMenuItem(value: 'audio', child: Text('Áudio')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedType = val!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (selectedType == 'text')
                  TextField(
                    controller: descCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Descrição / Texto da Dica'),
                    maxLines: 5,
                  )
                else
                  TextField(
                    controller: descCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Descrição (Opcional)'),
                    maxLines: 2,
                  ),
                if (selectedType == 'image') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentUrlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'URL da Foto (Obrigatório)',
                      suffixIcon: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.upload, size: 18),
                        onPressed: () async {
                          final url = await AdminUploadUtil.pickAndUploadImage(context);
                          if (url != null) {
                            setState(() {
                              contentUrlCtrl.text = url;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ] else if (selectedType == 'audio') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentUrlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'URL do Áudio (Obrigatório)',
                    ),
                  ),
                ],
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
                if (selectedType == 'image' && contentUrlCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('A URL da Foto é obrigatória para o tipo Imagem.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                if (selectedType == 'audio' && contentUrlCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('A URL do Áudio é obrigatória para o tipo Áudio.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final newData = {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'type': selectedType,
                  'contentUrl': contentUrlCtrl.text,
                };

                try {
                  ParseResponse response; // Variável para capturar a resposta

                  if (docId == null) {
                    response = await ParseCloudFunction(
                      'createOrUpdateHint',
                    ).execute(parameters: {'data': newData});
                  } else {
                    response = await ParseCloudFunction(
                      'createOrUpdateHint',
                    ).execute(parameters: {'hintId': docId, 'data': newData});
                  }

                  // VERIFICAÇÃO ADICIONADA:
                  if (response.success) {
                    if (context.mounted) {
                      Navigator.pop(
                        context,
                      ); // Só fecha o modal se der sucesso!
                      _loadHints();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dica salva com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    // Mostra o erro e NÃO fecha o modal
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro: ${response.error?.message}'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Erro ao salvar dica: $e');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
          );
        });
      },
    );
  }
}
