import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/features/admin/utils/admin_upload_util.dart';

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
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
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
                  final eventType = event.get<String>('eventType') ?? 'classic';
                  final isPublished = status == 'open';
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
                              if (eventType == 'find_and_win')
                                TextButton.icon(
                                  onPressed: () {
                                    _showFindAndWinEnigmasDialog(context, eventId);
                                  },
                                  icon: const FaIcon(
                                    FontAwesomeIcons.puzzlePiece,
                                    size: 16,
                                  ),
                                  label: const Text('Enigmas'),
                                )
                              else
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
    String selectedEventType = data?['eventType'] ?? 'classic';
    final prizeCtrl = TextEditingController(
      text: data?['prizePool']?.toString(),
    );
    final orderCtrl = TextEditingController(
      text: data?['order']?.toString() ?? '1',
    );
    final locationCtrl = TextEditingController(text: data?['location']);
    final iconCtrl = TextEditingController(text: data?['icon']);

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
                      docId == null ? 'Novo Evento' : 'Editar Evento',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextField(
                              controller: titleCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Título',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: descCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Descrição',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: prizeCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Prêmio (R\$)',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: orderCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Ordem',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: locationCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Local do Evento (Cidade) *',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: iconCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'URL do Ícone (Lottie/Image)',
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
                                        iconCtrl.text = url;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: selectedEventType,
                              dropdownColor: cardColor,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Evento',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'classic',
                                  child: Text(
                                    'Classic (A Jornada Estratégica)',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'find_and_win',
                                  child: Text(
                                    'Find & Win (Recompensa Instantânea)',
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedEventType = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedEventType == 'classic'
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedEventType == 'classic'
                                      ? Colors.blue
                                      : Colors.orange,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.circleInfo,
                                        color: selectedEventType == 'classic'
                                            ? Colors.blue
                                            : Colors.orange,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedEventType == 'classic'
                                            ? 'Modo Clássico'
                                            : 'Modo Find & Win',
                                        style: TextStyle(
                                          color: selectedEventType == 'classic'
                                              ? Colors.blue
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    selectedEventType == 'classic'
                                        ? 'O jogador precisa concluir todas as fases e enigmas (jornada estruturada). O prêmio configurado neste formulário será entregue apenas no final de toda a jornada.'
                                        : 'Fases são ignoradas pelo jogador (recompensa instantânea). O prêmio é entregue na hora ao resolver cada enigma. O valor do "Prêmio (R\$)" acima funciona apenas como informativo do total estimado da campanha.',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () async {
                            if (locationCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'O local do evento é obrigatório.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            final newData = {
                              'title': titleCtrl.text,
                              'description': descCtrl.text,
                              'prizePool': num.tryParse(prizeCtrl.text) ?? 0,
                              'order': int.tryParse(orderCtrl.text) ?? 1,
                              'icon': iconCtrl.text,
                              'location': locationCtrl.text.trim(),
                              'eventType': selectedEventType,
                              'status': data?['status'] ?? 'draft',
                            };
                            try {
                              if (docId == null) {
                                final response = await ParseCloudFunction(
                                  'createOrUpdateEvent',
                                ).execute(parameters: {'data': newData});
                                if (!response.success)
                                  throw response.error ?? ParseError();
                              } else {
                                await ParseCloudFunction(
                                  'createOrUpdateEvent',
                                ).execute(
                                  parameters: {
                                    'eventId': docId,
                                    'data': newData,
                                  },
                                );
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

  void _toggleEventStatus(String eventId, String currentStatus) async {
    final newStatus = currentStatus == 'open' ? 'draft' : 'open';
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
    String? phaseId,
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
            future: () {
              var query = QueryBuilder<ParseObject>(ParseObject('Enigma'));
              if (phaseId != null) {
                query.whereEqualTo(
                  'phase',
                  (ParseObject('Phase')..objectId = phaseId).toPointer(),
                );
              } else {
                query.whereEqualTo('eventId', eventId);
              }
              query.orderByAscending('order');
              return query.query();
            }(),
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
            return Dialog(
              backgroundColor: darkBackground,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      docId == null ? 'Nova Fase' : 'Editar Fase',
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
                              controller: orderCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Ordem',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text(
                                'Fase Bloqueada',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: const Text(
                                'Os jogadores não poderão ver os enigmas desta fase até que ela seja desbloqueada.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              value: isBlocked,
                              onChanged: (val) {
                                setState(() => isBlocked = val);
                              },
                              activeColor: primaryAmber,
                              contentPadding: EdgeInsets.zero,
                            ),
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
                                      parameters: {
                                        'eventId': eventId,
                                        'data': newData,
                                      },
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
                                      content: Text(
                                        'Fase guardada com sucesso!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
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
                              debugPrint('Erro ao salvar fase: $e');
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

  void _showFindAndWinEnigmasDialog(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 800,
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setStateEnigmas) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enigmas do Evento',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showEnigmaEditDialog(
                          context,
                          eventId,
                          null,
                          onSaved: () {
                            setStateEnigmas(() {});
                          },
                        );
                      },
                      icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                      label: const Text('Novo Enigma'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildEnigmasList(eventId, null, () {
                        setStateEnigmas(() {});
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showEnigmaEditDialog(
    BuildContext context,
    String eventId,
    String? phaseId, {
    String? docId,
    Map<String, dynamic>? data,
    VoidCallback? onSaved,
  }) {
    final orderCtrl = TextEditingController(
      text: data?['order']?.toString() ?? '1',
    );
    final codeCtrl = TextEditingController(text: data?['code']);
    final instructionCtrl = TextEditingController(text: data?['instruction']);
    final prizeCtrl = TextEditingController(
      text: data?['prize']?.toString() ?? '0',
    );
    final photoUrlCtrl = TextEditingController(text: data?['photoUrl']);

    // NOVOS CONTROLADORES: Bússola e Coordenadas Obrigatórias
    bool hasCompass = data?['hasCompass'] ?? false;
    final compassCoordsCtrl = TextEditingController(
      text: data?['compassCoords'],
    );

    String selectedType = data?['type'] ?? 'text';
    if (!['text', 'gps', 'qrcode', 'foto'].contains(selectedType)) {
      selectedType = 'text';
    }

    List<dynamic> linkedHints = List.from(data?['linkedHints'] ?? []);
    final Future<ParseResponse> hintsFuture = QueryBuilder<ParseObject>(
      ParseObject('Hint'),
    ).query();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
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
                      docId == null ? 'Novo Enigma' : 'Editar Enigma',
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: orderCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Ordem',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedType,
                              dropdownColor: darkBackground,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Enigma',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'text',
                                  child: Text('Texto (Senha/Palavra)'),
                                ),
                                DropdownMenuItem(
                                  value: 'gps',
                                  child: Text('GPS (Coordenada Oculta)'),
                                ),
                                DropdownMenuItem(
                                  value: 'qrcode',
                                  child: Text('QR Code Simples'),
                                ),
                                DropdownMenuItem(
                                  value: 'foto',
                                  child: Text(
                                    'Foto (Achar Local + Ler QR Code)',
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedType = val!;
                                });
                              },
                            ),

                            if (selectedType == 'foto') ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: photoUrlCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'URL da Foto do Local',
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
                                          photoUrlCtrl.text = url;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            TextField(
                              controller: codeCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: selectedType == 'gps'
                                    ? 'Coordenadas Alvo (Lat, Lng)'
                                    : 'Código (Senha/Resposta)',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: instructionCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Instrução para o jogador',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: prizeCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Prêmio (R\$)',
                              ),
                              keyboardType: TextInputType.number,
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 8),

                            // 👇 NOVO: CONFIGURAÇÃO DA BÚSSOLA 👇
                            SwitchListTile(
                              title: const Text(
                                'Habilitar Bússola neste enigma?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                'Permite ao usuário usar o item facilitador.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              value: hasCompass,
                              activeColor: primaryAmber,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                setState(() {
                                  hasCompass = val;
                                });
                              },
                            ),

                            // Campo de Coordenadas condicional: Só aparece se a bússola estiver ligada
                            if (hasCompass) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: compassCoordsCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText:
                                      'Coordenadas da Bússola (Lat, Lng) *Obrigatório',
                                  labelStyle: TextStyle(color: primaryAmber),
                                  hintText: 'Ex: -23.5505, -46.6333',
                                  hintStyle: TextStyle(color: Colors.white38),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 12),
                            const Text(
                              'Dicas Vinculadas (Hints Pool)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            FutureBuilder<ParseResponse>(
                              future: hintsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (!snapshot.hasData ||
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
                                    final isSelected = linkedHints.contains(
                                      hintId,
                                    );
                                    return CheckboxListTile(
                                      title: Text(
                                        doc.get<String>('title') ?? 'Dica',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      value: isSelected,
                                      activeColor: primaryAmber,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true)
                                            linkedHints.add(hintId);
                                          else
                                            linkedHints.remove(hintId);
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
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryAmber,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  // 🔴 REGRA DE VALIDAÇÃO OBRIGATÓRIA DA BÚSSOLA 🔴
                                  if (hasCompass &&
                                      compassCoordsCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Erro: Ao habilitar a Bússola, insira as coordenadas correspondentes!',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                    return; // Cancela a execução para impedir o salvamento incorreto
                                  }

                                  setState(() => isSaving = true);

                                  try {
                                    final newData = {
                                      'order':
                                          int.tryParse(orderCtrl.text) ?? 1,
                                      'code': codeCtrl.text,
                                      'instruction': instructionCtrl.text,
                                      'type': selectedType,
                                      'prize':
                                          num.tryParse(prizeCtrl.text) ?? 0,
                                      'linkedHints': linkedHints,

                                      // Salvando as novas chaves no Back4App
                                      'hasCompass': hasCompass,
                                      'compassCoords': hasCompass
                                          ? compassCoordsCtrl.text.trim()
                                          : '',
                                    };

                                    if (selectedType == 'foto') {
                                      newData['photoUrl'] = photoUrlCtrl.text;
                                    }

                                    ParseResponse response;
                                    if (docId == null) {
                                      response =
                                          await ParseCloudFunction(
                                            'createOrUpdateEnigma',
                                          ).execute(
                                            parameters: {
                                              'eventId': eventId,
                                              'phaseId': phaseId ?? '',
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
                                      }
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
                                  } finally {
                                    setState(() => isSaving = false);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Salvar'),
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
