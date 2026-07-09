import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  late Future<ParseResponse> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      final query = QueryBuilder<ParseObject>(ParseObject('Event'))
        ..orderByDescending('createdAt');
      _eventsFuture = query.query();
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
              'Gestão de Eventos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showEventDialog(context);
              },
              icon: const FaIcon(FontAwesomeIcons.plus),
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
          child: FutureBuilder<ParseResponse>(
            future: _eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                debugPrint("Erro no stream de eventos: ${snapshot.error}");
                return Center(
                  child: Text(
                    'Erro ao carregar eventos: \n${snapshot.error}',
                    textAlign: TextAlign.center,
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
                    'Nenhum evento encontrado.',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                );
              }

              final events = snapshot.data!.results as List<ParseObject>;

              return ListView.separated(
                itemCount: events.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final eventId = event.objectId!;
                  final title = event.get<String>('title') ?? 'Sem Título';
                  final status = event.get<String>('status') ?? 'draft';
                  final isPublished = status == 'published';
                  final prizePool = event.get<num>('prizePool') ?? 0;

                  return Card(
                    color: cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPublished
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isPublished ? 'Publicado' : 'Rascunho',
                                  style: TextStyle(
                                    color: isPublished
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Premiação: R\$ $prizePool',
                            style: const TextStyle(color: primaryAmber),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  _showEventDialog(
                                    context,
                                    docId: eventId,
                                    data: _parseObjectToMap(event),
                                  );
                                },
                                icon: const FaIcon(
                                  FontAwesomeIcons.penToSquare,
                                  size: 16,
                                ),
                                label: const Text('Editar'),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  _showPhasesDialog(context, eventId);
                                },
                                icon: const FaIcon(
                                  FontAwesomeIcons.listOl,
                                  size: 16,
                                ),
                                label: const Text('Fases'),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  _toggleEventStatus(eventId, status);
                                },
                                icon: FaIcon(
                                  isPublished
                                      ? FontAwesomeIcons.eyeSlash
                                      : FontAwesomeIcons.eye,
                                  size: 16,
                                ),
                                label: Text(
                                  isPublished ? 'Ocultar' : 'Publicar',
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  ParseCloudFunction('deleteEvent')
                                      .execute(parameters: {'eventId': eventId})
                                      .then((_) => _loadEvents());
                                },
                                icon: const FaIcon(
                                  FontAwesomeIcons.trash,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
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

  void _showEventDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) {
    final titleCtrl = TextEditingController(text: data?['title']);
    final descCtrl = TextEditingController(text: data?['description']);
    final prizeCtrl = TextEditingController(
      text: data?['prizePool']?.toString(),
    );
    final orderCtrl = TextEditingController(
      text: data?['order']?.toString() ?? '1',
    );
    final iconCtrl = TextEditingController(text: data?['icon']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: darkBackground,
          title: Text(
            docId == null ? 'Novo Evento' : 'Editar Evento',
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
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                ),
                TextField(
                  controller: prizeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Prêmio (R\$)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: orderCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Ordem'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: iconCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'URL do Ícone (Lottie/Image)',
                  ),
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
                final newData = {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'prizePool': num.tryParse(prizeCtrl.text) ?? 0,
                  'order': int.tryParse(orderCtrl.text) ?? 1,
                  'icon': iconCtrl.text,
                  'status': data?['status'] ?? 'draft',
                };
                try {
                  if (docId == null) {
                    final response = await ParseCloudFunction(
                      'createOrUpdateEvent',
                    ).execute(parameters: {'data': newData});
                    if (!response.success) throw response.error ?? ParseError();
                  } else {
                    await ParseCloudFunction(
                      'createOrUpdateEvent',
                    ).execute(parameters: {'eventId': docId, 'data': newData});
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadEvents();
                  }
                } catch (e) {
                  debugPrint('Erro ao salvar evento: $e');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _toggleEventStatus(String eventId, String currentStatus) async {
    final newStatus = currentStatus == 'published' ? 'draft' : 'published';
    try {
      await ParseCloudFunction('createOrUpdateEvent').execute(
        parameters: {
          'eventId': eventId,
          'data': {'status': newStatus},
        },
      );
      _loadEvents();
    } catch (e) {
      debugPrint("Erro ao alterar status: $e");
    }
  }

  void _showPhasesDialog(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: darkBackground,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fases do Evento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.xmark,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StatefulBuilder(
                    builder: (context, setStatePhases) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _showPhaseEditDialog(
                                context,
                                eventId,
                                onSaved: () {
                                  setStatePhases(() {});
                                },
                              );
                            },
                            icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                            label: const Text('Nova Fase'),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: FutureBuilder<ParseResponse>(
                              future:
                                  (QueryBuilder<ParseObject>(
                                          ParseObject('Phase'),
                                        )
                                        ..whereEqualTo(
                                          'event',
                                          (ParseObject(
                                            'Event',
                                          )..objectId = eventId).toPointer(),
                                        )
                                        ..orderByAscending('order'))
                                      .query(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.hasError ||
                                    !snapshot.hasData ||
                                    !snapshot.data!.success ||
                                    snapshot.data!.results == null) {
                                  return const Center(
                                    child: Text(
                                      'Nenhuma fase cadastrada.',
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  );
                                }

                                final phases =
                                    snapshot.data!.results as List<ParseObject>;

                                return ListView.builder(
                                  itemCount: phases.length,
                                  itemBuilder: (context, index) {
                                    final phase = phases[index];
                                    final phaseId = phase.objectId!;
                                    final order = phase.get<num>('order') ?? 0;
                                    final isBlocked =
                                        phase.get<bool>('isBlocked') ?? false;

                                    return Card(
                                      color: cardColor,
                                      child: ExpansionTile(
                                        title: Text(
                                          'Fase $order',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          isBlocked
                                              ? 'Bloqueada'
                                              : 'Desbloqueada',
                                          style: TextStyle(
                                            color: isBlocked
                                                ? Colors.redAccent
                                                : Colors.green,
                                          ),
                                        ),
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _showPhaseEditDialog(
                                                      context,
                                                      eventId,
                                                      docId: phaseId,
                                                      data: _parseObjectToMap(
                                                        phase,
                                                      ),
                                                      onSaved: () {
                                                        setStatePhases(() {});
                                                      },
                                                    ),
                                                icon: const FaIcon(
                                                  FontAwesomeIcons.penToSquare,
                                                  size: 14,
                                                ),
                                                label: const Text('Editar'),
                                              ),
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _showEnigmaEditDialog(
                                                      context,
                                                      eventId,
                                                      phaseId,
                                                      onSaved: () {
                                                        setStatePhases(() {});
                                                      },
                                                    ),
                                                icon: const FaIcon(
                                                  FontAwesomeIcons.plus,
                                                  size: 14,
                                                ),
                                                label: const Text(
                                                  'Novo Enigma',
                                                ),
                                              ),
                                              TextButton.icon(
                                                onPressed: () async {
                                                  bool confirm =
                                                      await showDialog(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          backgroundColor:
                                                              darkBackground,
                                                          title: const Text(
                                                            'Confirmar exclusão',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          content: const Text(
                                                            'Deseja excluir esta fase e seus enigmas?',
                                                            style: TextStyle(
                                                              color:
                                                                  secondaryTextColor,
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                'Cancelar',
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .redAccent,
                                                              ),
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                'Excluir',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ) ??
                                                      false;
                                                  if (confirm) {
                                                    try {
                                                      await ParseCloudFunction(
                                                        'deletePhase',
                                                      ).execute(
                                                        parameters: {
                                                          'eventId': eventId,
                                                          'phaseId': phaseId,
                                                        },
                                                      );
                                                      if (context.mounted) {
                                                        setStatePhases(() {});
                                                      }
                                                    } catch (e) {
                                                      debugPrint(
                                                        'Erro ao excluir fase: \$e',
                                                      );
                                                    }
                                                  }
                                                },
                                                icon: const FaIcon(
                                                  FontAwesomeIcons.trash,
                                                  color: Colors.redAccent,
                                                  size: 14,
                                                ),
                                                label: const Text(
                                                  'Excluir',
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          _buildEnigmasList(
                                            eventId,
                                            phaseId,
                                            () {
                                              setStatePhases(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnigmasList(
    String eventId,
    String phaseId,
    VoidCallback onRefresh,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enigmas:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<ParseResponse>(
            future:
                (QueryBuilder<ParseObject>(ParseObject('Enigma'))
                      ..whereEqualTo(
                        'phase',
                        (ParseObject('Phase')..objectId = phaseId).toPointer(),
                      )
                      ..orderByAscending('order'))
                    .query(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text(
                  'Carregando...',
                  style: TextStyle(color: Colors.white),
                );
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!.success ||
                  snapshot.data!.results == null) {
                return const Text(
                  'Nenhum enigma cadastrado nesta fase.',
                  style: TextStyle(color: secondaryTextColor),
                );
              }

              final enigmas = snapshot.data!.results as List<ParseObject>;

              return Column(
                children: enigmas.map((doc) {
                  final enigmaId = doc.objectId!;
                  final code = doc.get<String>('code') ?? '';
                  final type = doc.get<String>('type') ?? '';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Código: $code',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Tipo: $type',
                      style: const TextStyle(color: secondaryTextColor),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.penToSquare,
                            size: 16,
                            color: Colors.blue,
                          ),
                          onPressed: () => _showEnigmaEditDialog(
                            context,
                            eventId,
                            phaseId,
                            docId: enigmaId,
                            data: _parseObjectToMap(doc),
                            onSaved: onRefresh,
                          ),
                        ),
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.trash,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            final response =
                                await ParseCloudFunction(
                                  'deleteEnigma',
                                ).execute(
                                  parameters: {
                                    'eventId': eventId,
                                    'enigmaId': enigmaId,
                                  },
                                );
                            if (response.success) {
                              onRefresh();
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPhaseEditDialog(
    BuildContext context,
    String eventId, {
    String? docId,
    Map<String, dynamic>? data,
    VoidCallback? onSaved,
  }) {
    final orderCtrl = TextEditingController(
      text: data?['order']?.toString() ?? '1',
    );
    bool isBlocked = data?['isBlocked'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: darkBackground,
              title: Text(
                docId == null ? 'Nova Fase' : 'Editar Fase',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                // CORREÇÃO: Proteção contra o teclado
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: orderCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Ordem'),
                      keyboardType: TextInputType.number,
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Bloqueada',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: isBlocked,
                      onChanged: (val) {
                        setState(() => isBlocked = val);
                      },
                      activeColor: primaryAmber,
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
                    final newData = {
                      'order': int.tryParse(orderCtrl.text) ?? 1,
                      'isBlocked': isBlocked,
                    };
                    try {
                      ParseResponse response;
                      if (docId == null) {
                        response =
                            await ParseCloudFunction(
                              'createOrUpdatePhase',
                            ).execute(
                              parameters: {'eventId': eventId, 'data': newData},
                            );
                      } else {
                        response =
                            await ParseCloudFunction(
                              'createOrUpdatePhase',
                            ).execute(
                              parameters: {
                                'eventId': eventId,
                                'phaseId': docId,
                                'data': newData,
                              },
                            );
                      }

                      if (response.success) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (onSaved != null) onSaved();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fase guardada com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
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
                      debugPrint('Erro ao salvar fase: $e');
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

  void _showEnigmaEditDialog(
    BuildContext context,
    String eventId,
    String phaseId, {
    String? docId,
    Map<String, dynamic>? data,
    VoidCallback?
    onSaved, // Adicionado callback para atualizar a lista ao guardar
  }) {
    final orderCtrl = TextEditingController(
      text: data?['order']?.toString() ?? '1',
    );
    final codeCtrl = TextEditingController(text: data?['code']);
    final instructionCtrl = TextEditingController(text: data?['instruction']);
    final typeCtrl = TextEditingController(text: data?['type'] ?? 'text');
    final prizeCtrl = TextEditingController(
      text: data?['prize']?.toString() ?? '0',
    );
    List<dynamic> linkedHints = List.from(data?['linkedHints'] ?? []);

    // CORREÇÃO CRÍTICA: Instanciar o Future aqui evita que a requisição repita a cada clique de checkbox
    final Future<ParseResponse> hintsFuture = QueryBuilder<ParseObject>(
      ParseObject('Hint'),
    ).query();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: darkBackground,
              title: Text(
                docId == null ? 'Novo Enigma' : 'Editar Enigma',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: orderCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Ordem'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: codeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Código (Senha/Resposta)',
                      ),
                    ),
                    TextField(
                      controller: instructionCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Instrução'),
                      maxLines: 2,
                    ),
                    TextField(
                      controller: typeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tipo (text, gps, qrcode)',
                      ),
                    ),
                    TextField(
                      controller: prizeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Prémio (R\$)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Dicas Vinculadas (Hints Pool)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<ParseResponse>(
                      future:
                          hintsFuture, // Usa a referência fixa definida acima
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            !snapshot.data!.success ||
                            snapshot.data!.results == null) {
                          return const Text(
                            'Nenhuma dica no pool.',
                            style: TextStyle(color: Colors.white),
                          );
                        }

                        final allHints =
                            snapshot.data!.results as List<ParseObject>;

                        return Column(
                          children: allHints.map((doc) {
                            final hintId = doc.objectId!;
                            final isSelected = linkedHints.contains(hintId);
                            return CheckboxListTile(
                              title: Text(
                                doc.get<String>('title') ?? 'Dica',
                                style: const TextStyle(color: Colors.white),
                              ),
                              value: isSelected,
                              activeColor: primaryAmber,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    linkedHints.add(hintId);
                                  } else {
                                    linkedHints.remove(hintId);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
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
                    final newData = {
                      'order': int.tryParse(orderCtrl.text) ?? 1,
                      'code': codeCtrl.text,
                      'instruction': instructionCtrl.text,
                      'type': typeCtrl.text,
                      'prize': num.tryParse(prizeCtrl.text) ?? 0,
                      'linkedHints': linkedHints,
                    };
                    try {
                      ParseResponse response;
                      if (docId == null) {
                        response =
                            await ParseCloudFunction(
                              'createOrUpdateEnigma',
                            ).execute(
                              parameters: {
                                'eventId': eventId,
                                'phaseId': phaseId,
                                'data': newData,
                              },
                            );
                      } else {
                        response =
                            await ParseCloudFunction(
                              'createOrUpdateEnigma',
                            ).execute(
                              parameters: {
                                'eventId': eventId,
                                'enigmaId': docId,
                                'data': newData,
                              },
                            );
                      }

                      if (response.success) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (onSaved != null) onSaved();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enigma guardado com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
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
                      debugPrint('Erro ao salvar enigma: $e');
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
