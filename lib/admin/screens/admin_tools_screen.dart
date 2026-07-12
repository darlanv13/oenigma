import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/admin_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../utils/admin_upload_util.dart';

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
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
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
                  final linkedEnigmaId = hint.get<String>('linkedEnigmaId');
                  final linkedEventName = hint.get<String>('linkedEventName');
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
                          if (linkedEnigmaId != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Vinculada: ${linkedEventName ?? 'Desconhecido'}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (linkedEnigmaId == null)
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.link,
                                color: Colors.green,
                              ),
                              tooltip: 'Atribuir a um Enigma',
                              onPressed: () {
                                _showAssignHintDialog(context, hintId);
                              },
                            )
                          else
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.linkSlash,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Desvincular do Enigma',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: darkBackground,
                                    title: const Text(
                                      'Desvincular Dica',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: const Text(
                                      'Deseja desvincular esta dica do enigma atual?',
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Desvincular'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    final response =
                                        await ParseCloudFunction(
                                          'assignHintToEnigma',
                                        ).execute(
                                          parameters: {
                                            'hintId': hintId,
                                            'enigmaId': null,
                                          },
                                        );
                                    if (response.success && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Dica desvinculada!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _loadHints();
                                    } else {
                                      throw Exception(
                                        response.error?.message ??
                                            'Erro desconhecido',
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro: $e'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
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
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: darkBackground,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      docId == null ? 'Nova Dica' : 'Editar Dica',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: titleCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Título',
                              ),
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
                                DropdownMenuItem(
                                  value: 'text',
                                  child: Text('Texto'),
                                ),
                                DropdownMenuItem(
                                  value: 'image',
                                  child: Text('Imagem (Foto)'),
                                ),
                                DropdownMenuItem(
                                  value: 'audio',
                                  child: Text('Áudio'),
                                ),
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
                                decoration: const InputDecoration(
                                  labelText: 'Descrição / Texto da Dica',
                                ),
                                maxLines: 5,
                              )
                            else
                              TextField(
                                controller: descCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Descrição (Opcional)',
                                ),
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
                                    icon: const FaIcon(
                                      FontAwesomeIcons.upload,
                                      size: 18,
                                    ),
                                    onPressed: () async {
                                      final url =
                                          await AdminUploadUtil.pickAndUploadImage(
                                            context,
                                          );
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
                                decoration: InputDecoration(
                                  labelText: 'URL do Áudio (Obrigatório)',
                                  suffixIcon: IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.upload,
                                      size: 18,
                                    ),
                                    onPressed: () async {
                                      final url =
                                          await AdminUploadUtil.pickAndUploadAudio(
                                            context,
                                          );
                                      if (url != null) {
                                        setState(() {
                                          contentUrlCtrl.text = url;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryAmber,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            if (selectedType == 'image' &&
                                contentUrlCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'A URL da Foto é obrigatória para o tipo Imagem.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            if (selectedType == 'audio' &&
                                contentUrlCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'A URL do Áudio é obrigatória para o tipo Áudio.',
                                  ),
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
                              ParseResponse
                              response; // Variável para capturar a resposta

                              if (docId == null) {
                                response = await ParseCloudFunction(
                                  'createOrUpdateHint',
                                ).execute(parameters: {'data': newData});
                              } else {
                                response =
                                    await ParseCloudFunction(
                                      'createOrUpdateHint',
                                    ).execute(
                                      parameters: {
                                        'hintId': docId,
                                        'data': newData,
                                      },
                                    );
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
                                      content: Text(
                                        'Erro: ${response.error?.message}',
                                      ),
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
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignHintDialog(BuildContext context, String hintId) {
    String? selectedEventId;
    String? selectedEnigmaId;
    String? selectedEventName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: darkBackground,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Atribuir a um Enigma',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<ParseResponse>(
                      future: QueryBuilder<ParseObject>(
                        ParseObject('Event'),
                      ).query(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        final events =
                            snapshot.data?.results as List<ParseObject>? ?? [];
                        return DropdownButtonFormField<String>(
                          value: selectedEventId,
                          dropdownColor: darkBackground,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Selecione o Evento',
                          ),
                          items: events.map((e) {
                            return DropdownMenuItem<String>(
                              value: e.objectId,
                              child: Text(
                                e.get<String>('title') ?? 'Sem Título',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedEventId = val;
                              selectedEnigmaId = null;
                              selectedEventName = events
                                  .firstWhere((e) => e.objectId == val)
                                  .get<String>('title');
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (selectedEventId != null)
                      FutureBuilder<ParseResponse>(
                        future: (QueryBuilder<ParseObject>(
                          ParseObject('Enigma'),
                        )..whereEqualTo('eventId', selectedEventId)).query(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          final enigmas =
                              snapshot.data?.results as List<ParseObject>? ??
                              [];
                          if (enigmas.isEmpty) {
                            return const Text(
                              'Nenhum enigma encontrado.',
                              style: TextStyle(color: Colors.white),
                            );
                          }
                          return DropdownButtonFormField<String>(
                            value: selectedEnigmaId,
                            dropdownColor: darkBackground,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Selecione o Enigma',
                            ),
                            items: enigmas.map((e) {
                              final instr = e.get<String>('instruction') ?? '';
                              final code = e.get<String>('code') ?? '';
                              final text = instr.isNotEmpty
                                  ? instr
                                  : 'Cód: $code';
                              return DropdownMenuItem<String>(
                                value: e.objectId,
                                child: Text(
                                  text.length > 30
                                      ? '${text.substring(0, 30)}...'
                                      : text,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedEnigmaId = val;
                              });
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: (selectedEnigmaId == null)
                              ? null
                              : () async {
                                  try {
                                    final response =
                                        await ParseCloudFunction(
                                          'assignHintToEnigma',
                                        ).execute(
                                          parameters: {
                                            'hintId': hintId,
                                            'enigmaId': selectedEnigmaId,
                                            'eventId': selectedEventId,
                                            'eventName': selectedEventName,
                                          },
                                        );
                                    if (response.success && context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Dica vinculada com sucesso!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _loadHints();
                                    } else {
                                      throw Exception(
                                        response.error?.message ?? 'Erro',
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro: $e'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                  }
                                },
                          child: const Text('Vincular'),
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
    );
  }
}
