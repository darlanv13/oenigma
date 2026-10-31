import 'package:oenigma/core/utils/app_colors.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/admin_upload_util.dart';

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


  Widget _buildModalityTag(String eventType) {
    final bool isClassic = eventType == 'classic';
    final Color tagColor = isClassic ? AppColors.verdeVale : AppColors.amareloVale;
    final icon = isClassic ? FontAwesomeIcons.trophy : FontAwesomeIcons.boxOpen;
    final String label = isClassic ? 'CLASSIC' : 'FIND & WIN';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tagColor.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 10,
            color: tagColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: tagColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
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
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildModalityTag(eventType),
                                  ],
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
                                    _showFindAndWinEnigmasDialog(
                                      context,
                                      eventId,
                                    );
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
    final bool hasPrizeImage = data != null &&
        data['prizeImageUrl'] != null &&
        data['prizeImageUrl'].toString().trim().isNotEmpty;
    String prizeType = (data?['prizeType']?.toString().toLowerCase() == 'objeto' || hasPrizeImage)
        ? 'objeto'
        : 'dinheiro';
    String? prizeImageUrl = data?['prizeImageUrl']?.toString();
    String difficulty = data?['difficulty']?.toString() ?? 'Média';
    String selectedEventType = data?['eventType'] ?? 'classic';

    final titleCtrl = TextEditingController(
      text: prizeType == 'objeto'
          ? (selectedEventType == 'classic' ? 'Modo Clássico' : 'Ache & Ganhe')
          : (data?['title'] ?? ''),
    );
    final descCtrl = TextEditingController(text: data?['description']);
    final prizeCtrl = TextEditingController(
      text: data?['prizePool']?.toString() ?? data?['prize']?.toString() ?? '',
    );
    final orderCtrl = TextEditingController(
      text: data?['order']?.toString() ?? '1',
    );
    final locationCtrl = TextEditingController(text: data?['location']);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isObjeto = prizeType == 'objeto';

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          docId == null ? 'Novo Evento' : 'Editar Evento',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildModalityTag(selectedEventType),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seletor de Tipo de Prêmio
                            const Text(
                              'Tipo de Premiação *',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        prizeType = 'objeto';
                                        titleCtrl.text = selectedEventType == 'classic'
                                            ? 'Modo Clássico'
                                            : 'Ache & Ganhe';
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isObjeto
                                            ? AppColors.verdeVale.withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isObjeto ? AppColors.verdeVale : Colors.white24,
                                          width: isObjeto ? 1.8 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FaIcon(
                                            FontAwesomeIcons.mobileScreen,
                                            size: 14,
                                            color: isObjeto ? AppColors.verdeVale : Colors.white60,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Objeto / Produto',
                                            style: TextStyle(
                                              color: isObjeto ? Colors.white : Colors.white60,
                                              fontWeight: isObjeto ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        prizeType = 'dinheiro';
                                        if (titleCtrl.text == 'Modo Clássico' || titleCtrl.text == 'Ache & Ganhe') {
                                          titleCtrl.text = data?['title'] ?? '';
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: !isObjeto
                                            ? AppColors.amareloVale.withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: !isObjeto ? AppColors.amareloVale : Colors.white24,
                                          width: !isObjeto ? 1.8 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FaIcon(
                                            FontAwesomeIcons.sackDollar,
                                            size: 14,
                                            color: !isObjeto ? AppColors.amareloVale : Colors.white60,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Dinheiro (R\$)',
                                            style: TextStyle(
                                              color: !isObjeto ? Colors.white : Colors.white60,
                                              fontWeight: !isObjeto ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Campo de Valor / Nome do Prêmio
                            TextField(
                              controller: prizeCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: isObjeto
                                    ? 'Nome do Prêmio (Ex: iPhone 17 Pro) *'
                                    : 'Valor do Prêmio em Dinheiro (Ex: 5.000,00) *',
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Título (Desabilitado se for Objeto)
                            TextField(
                              controller: titleCtrl,
                              enabled: !isObjeto,
                              style: TextStyle(
                                color: isObjeto ? Colors.white54 : Colors.white,
                              ),
                              decoration: InputDecoration(
                                labelText: isObjeto
                                    ? 'Título (Automático pela modalidade)'
                                    : 'Título do Evento *',
                                filled: isObjeto,
                                fillColor: isObjeto ? Colors.white.withValues(alpha: 0.05) : null,
                              ),
                            ),
                            if (isObjeto) ...[
                              const SizedBox(height: 4),
                              const Text(
                                '💡 Quando o prêmio é Objeto, o título assume o modo do jogo.',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Seção Foto PNG ou Dinheiro Automático
                            if (isObjeto) ...[
                              const Text(
                                'Foto do Prêmio (.PNG com fundo transparente) *',
                                style: TextStyle(
                                  color: AppColors.amareloVale,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (prizeImageUrl == null || prizeImageUrl!.isEmpty)
                                InkWell(
                                  onTap: () async {
                                    final url = await AdminUploadUtil.pickAndUploadPng(context);
                                    if (url != null) {
                                      setState(() => prizeImageUrl = url);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.amareloVale.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Column(
                                      children: [
                                        FaIcon(
                                          FontAwesomeIcons.cloudArrowUp,
                                          color: AppColors.amareloVale,
                                          size: 24,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Subir Imagem PNG Transparente',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Obrigatório formato .PNG',
                                          style: TextStyle(color: Colors.white54, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.verdeVale),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Image.network(
                                          prizeImageUrl!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Foto PNG Carregada!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const FaIcon(FontAwesomeIcons.trashCan, size: 14, color: Colors.redAccent),
                                        onPressed: () => setState(() => prizeImageUrl = null),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.amareloVale.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    FaIcon(FontAwesomeIcons.sackDollar, color: AppColors.amareloVale, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Prêmio em Dinheiro: O ícone de saco de moedas será gerado automaticamente no App.',
                                        style: TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Descrição
                            TextField(
                              controller: descCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Descrição',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),

                            // Local e Dificuldade
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: locationCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Local do Evento (Cidade) *',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: difficulty,
                                    dropdownColor: cardColor,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(
                                      labelText: 'Dificuldade',
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Fácil', child: Text('Fácil')),
                                      DropdownMenuItem(value: 'Média', child: Text('Média')),
                                      DropdownMenuItem(value: 'Difícil', child: Text('Difícil')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => difficulty = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Modalidade
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
                                  child: Text('Classic (A Jornada Estratégica)'),
                                ),
                                DropdownMenuItem(
                                  value: 'find_and_win',
                                  child: Text('Find & Win (Recompensa Instantânea)'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedEventType = val;
                                    if (isObjeto) {
                                      titleCtrl.text = val == 'classic' ? 'Modo Clássico' : 'Ache & Ganhe';
                                    }
                                  });
                                }
                              },
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
                            if (isObjeto) {
                              if (prizeCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Por favor, informe o nome do prêmio.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (prizeImageUrl == null || prizeImageUrl!.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Para prêmios Objeto, é OBRIGATÓRIO subir a foto em formato PNG!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            } else {
                              if (titleCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('O título do evento é obrigatório.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }

                            if (locationCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('O local do evento é obrigatório.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final finalTitle = isObjeto
                                ? (selectedEventType == 'classic' ? 'Modo Clássico' : 'Ache & Ganhe')
                                : titleCtrl.text.trim();

                            final newData = {
                              'title': finalTitle,
                              'description': descCtrl.text.trim(),
                              'prizePool': prizeCtrl.text.trim(),
                              'prize': prizeCtrl.text.trim(),
                              'prizeType': prizeType,
                              'prizeImageUrl': isObjeto ? prizeImageUrl : null,
                              'difficulty': difficulty,
                              'order': int.tryParse(orderCtrl.text) ?? 1,
                              'location': locationCtrl.text.trim(),
                              'eventType': selectedEventType,
                              'status': data?['status'] ?? 'open',
                            };

                            try {
                              if (docId == null) {
                                final response = await ParseCloudFunction(
                                  'createOrUpdateEvent',
                                ).execute(parameters: {'data': newData});
                                if (!response.success) {
                                  throw response.error ?? ParseError(message: 'Erro desconhecido');
                                }
                              } else {
                                final response = await ParseCloudFunction(
                                  'createOrUpdateEvent',
                                ).execute(
                                  parameters: {
                                    'eventId': docId,
                                    'data': newData,
                                  },
                                );
                                if (!response.success) {
                                  throw response.error ?? ParseError(message: 'Erro desconhecido');
                                }
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                                _loadEvents();
                              }
                            } catch (e) {
                              debugPrint('Erro ao salvar evento: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erro ao salvar evento: ${e is ParseError ? e.message : e.toString()}',
                                    ),
                                  ),
                                );
                              }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enigmas:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              if (phaseId != null)
                TextButton.icon(
                  onPressed: () => _showLinkExistingEnigmaDialogMobile(
                    context,
                    eventId,
                    phaseId,
                    onRefresh,
                  ),
                  icon: const FaIcon(FontAwesomeIcons.link, size: 12),
                  label: const Text('Vincular Existente', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
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
              if (enigmas.isEmpty) {
                return const Text(
                  'Nenhum enigma nesta fase. Clique em Novo Enigma ou Vincular Existente.',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                );
              }

              return Column(
                children: enigmas.map((doc) {
                  final enigmaId = doc.objectId!;
                  final code = doc.get<String>('code') ?? '';
                  final type = doc.get<String>('type') ?? '';
                  final order = doc.get<num>('order') ?? 1;
                  final instruction = doc.get<String>('instruction') ?? doc.get<String>('title') ?? 'Código: $code';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 13,
                      backgroundColor: primaryAmber.withValues(alpha: 0.15),
                      child: Text(
                        '$order',
                        style: const TextStyle(
                          color: primaryAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    title: Text(
                      instruction,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Tipo: $type · Cód: $code',
                      style: const TextStyle(color: secondaryTextColor, fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.penToSquare,
                            size: 15,
                            color: Colors.blue,
                          ),
                          tooltip: 'Editar',
                          onPressed: () => _showEnigmaEditDialog(
                            context,
                            eventId,
                            phaseId,
                            docId: enigmaId,
                            data: _parseObjectToMap(doc),
                            onSaved: onRefresh,
                          ),
                        ),
                        if (phaseId != null)
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.arrowRightArrowLeft,
                              size: 13,
                              color: primaryAmber,
                            ),
                            tooltip: 'Mover Fase',
                            onPressed: () => _showMoveEnigmaPhaseDialogMobile(
                              context,
                              eventId,
                              phaseId,
                              doc,
                              onRefresh,
                            ),
                          ),
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.trash,
                            size: 15,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Excluir',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: darkBackground,
                                title: const Text('Excluir Enigma?', style: TextStyle(color: Colors.white)),
                                content: const Text('Tem certeza que deseja excluir este enigma?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final response = await ParseCloudFunction('deleteEnigma').execute(
                                parameters: {
                                  'eventId': eventId,
                                  'enigmaId': enigmaId,
                                },
                              );
                              if (response.success) {
                                onRefresh();
                              }
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

  void _showLinkExistingEnigmaDialogMobile(
    BuildContext context,
    String eventId,
    String phaseId,
    VoidCallback onRefresh,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
          ..whereEqualTo('eventId', eventId)
          ..includeObject(['phase'])
          ..orderByAscending('order');

        return Dialog(
          backgroundColor: darkBackground,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vincular Enigma à Fase',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white, size: 16),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<ParseResponse>(
                    future: query.query(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final all = (snapshot.data?.results as List<ParseObject>?) ?? [];
                      final available = all.where((e) {
                        final currentPid = e.get<String>('phaseId') ?? e.get<ParseObject>('phase')?.objectId;
                        return currentPid != phaseId;
                      }).toList();

                      if (available.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum outro enigma disponível para vincular.',
                            style: TextStyle(color: secondaryTextColor),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: available.length,
                        itemBuilder: (context, idx) {
                          final enigma = available[idx];
                          final instruction = enigma.get<String>('instruction') ?? enigma.get<String>('title') ?? 'Sem instrução';
                          final currentP = enigma.get<ParseObject>('phase');
                          final pName = currentP?.get<String>('title') ?? 'Sem Fase';

                          return Card(
                            color: cardColor,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                instruction,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Origem: $pName',
                                style: const TextStyle(color: secondaryTextColor, fontSize: 11),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryAmber,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                onPressed: () async {
                                  final countQ = QueryBuilder<ParseObject>(ParseObject('Enigma'))
                                    ..whereEqualTo('phase', (ParseObject('Phase')..objectId = phaseId).toPointer());
                                  final countRes = await countQ.count();
                                  final nextOrder = (countRes.success ? countRes.count : 0) + 1;

                                  final res = await ParseCloudFunction('createOrUpdateEnigma').execute(
                                    parameters: {
                                      'enigmaId': enigma.objectId,
                                      'eventId': eventId,
                                      'phaseId': phaseId,
                                      'data': {'order': nextOrder, 'prize': 0.0},
                                    },
                                  );

                                  if (res.success) {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    onRefresh();
                                  }
                                },
                                child: const Text('Vincular', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
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
      },
    );
  }

  void _showMoveEnigmaPhaseDialogMobile(
    BuildContext context,
    String eventId,
    String currentPhaseId,
    ParseObject enigma,
    VoidCallback onRefresh,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final query = QueryBuilder<ParseObject>(ParseObject('Phase'))
          ..whereEqualTo('event', (ParseObject('Event')..objectId = eventId).toPointer())
          ..orderByAscending('order');

        return Dialog(
          backgroundColor: darkBackground,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxHeight: 450, maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mover Enigma de Fase',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white, size: 16),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  enigma.get<String>('instruction') ?? enigma.get<String>('title') ?? 'Enigma',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<ParseResponse>(
                    future: query.query(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final phases = (snapshot.data?.results as List<ParseObject>?) ?? [];
                      final otherPhases = phases.where((p) => p.objectId != currentPhaseId).toList();

                      return ListView(
                        children: [
                          ...otherPhases.map((targetP) {
                            final pOrder = targetP.get<num>('order') ?? 1;
                            final pTitle = targetP.get<String>('title') ?? 'Fase $pOrder';

                            return Card(
                              color: cardColor,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(pTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryAmber,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  onPressed: () async {
                                    final countQ = QueryBuilder<ParseObject>(ParseObject('Enigma'))
                                      ..whereEqualTo('phase', targetP.toPointer());
                                    final countRes = await countQ.count();
                                    final nextOrder = (countRes.success ? countRes.count : 0) + 1;

                                    final res = await ParseCloudFunction('createOrUpdateEnigma').execute(
                                      parameters: {
                                        'enigmaId': enigma.objectId,
                                        'eventId': eventId,
                                        'phaseId': targetP.objectId,
                                        'data': {'order': nextOrder, 'prize': 0.0},
                                      },
                                    );

                                    if (res.success) {
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      onRefresh();
                                    }
                                  },
                                  child: const Text('Mover para cá', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            );
                          }),
                          const Divider(color: Colors.white24),
                          ListTile(
                            tileColor: Colors.red.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            title: const Text('Desvincular da Fase', style: TextStyle(color: Colors.white, fontSize: 13)),
                            subtitle: const Text('Deixa o enigma avulso no evento.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            trailing: TextButton(
                              onPressed: () async {
                                final res = await ParseCloudFunction('createOrUpdateEnigma').execute(
                                  parameters: {
                                    'enigmaId': enigma.objectId,
                                    'eventId': eventId,
                                    'phaseId': '',
                                    'data': {'prize': 0.0},
                                  },
                                );
                                if (res.success) {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  onRefresh();
                                }
                              },
                              child: const Text('Desvincular', style: TextStyle(color: Colors.redAccent)),
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
                          icon: const FaIcon(
                            FontAwesomeIcons.xmark,
                            color: Colors.white,
                          ),
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
    final titleCtrl = TextEditingController(text: data?['title']);
    final codeCtrl = TextEditingController(text: data?['code']);
    final instructionCtrl = TextEditingController(text: data?['instruction']);
    final prizeCtrl = TextEditingController(
      text: data?['prize']?.toString() ?? '0',
    );
    final photoUrlCtrl = TextEditingController(text: data?['imageUrl']);
    final audioUrlCtrl = TextEditingController(text: data?['audioUrl']);

    String selectedIcon = data?['icon'] ?? 'skull';
    String selectedDifficulty = data?['difficulty'] ?? 'MÉDIA';

    // NOVOS CONTROLADORES: Bússola e Coordenadas Obrigatórias
    bool hasCompass = data?['hasCompass'] ?? false;
    final compassCoordsCtrl = TextEditingController(
      text: data?['compassCoords'],
    );
    final compassPriceCtrl = TextEditingController(
      text: data?['compassPrice']?.toString() ?? '15.0',
    );
    final compassDurationCtrl = TextEditingController(
      text: data?['compassDuration']?.toString() ?? '0',
    );

    String selectedType = data?['type'] ?? 'text';
    if (!['text', 'photo', 'audio'].contains(selectedType)) {
      selectedType = 'text';
    }

    String selectedMediaType = 'none';
    if (data?['imageUrl'] != null &&
        data?['imageUrl'].toString().isNotEmpty == true) {
      selectedMediaType = 'image';
    } else if (data?['audioUrl'] != null &&
        data?['audioUrl'].toString().isNotEmpty == true) {
      selectedMediaType = 'audio';
    }

    List<String> selectedCharacteristics = List<String>.from(
      data?['characteristics'] ?? [],
    );
    final availableCharacteristics = [
      {'key': 'nado', 'label': 'Nado', 'icon': FontAwesomeIcons.personSwimming},
      {
        'key': 'corrida',
        'label': 'Corrida',
        'icon': FontAwesomeIcons.personRunning,
      },
      {'key': 'camera', 'label': 'Câmera', 'icon': FontAwesomeIcons.camera},
      {'key': 'noite', 'label': 'Noite', 'icon': FontAwesomeIcons.moon},
      {'key': 'dia', 'label': 'Dia', 'icon': FontAwesomeIcons.sun},
      {
        'key': 'exploracao',
        'label': 'Exploração',
        'icon': FontAwesomeIcons.compass,
      },
      {
        'key': 'escalada',
        'label': 'Escalada',
        'icon': FontAwesomeIcons.mountain,
      },
    ];

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
                                  child: Text('Charada (Texto)'),
                                ),
                                DropdownMenuItem(
                                  value: 'photo',
                                  child: Text('Foto (Imagem)'),
                                ),
                                DropdownMenuItem(
                                  value: 'audio',
                                  child: Text('Áudio (Mídia)'),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedType = val!;
                                });
                              },
                            ),

                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedMediaType,
                              dropdownColor: darkBackground,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Mídia',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'none',
                                  child: Text('Nenhuma'),
                                ),
                                DropdownMenuItem(
                                  value: 'image',
                                  child: Text('Imagem'),
                                ),
                                DropdownMenuItem(
                                  value: 'audio',
                                  child: Text('Áudio'),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedMediaType = val!;
                                  if (selectedMediaType == 'none') {
                                    photoUrlCtrl.clear();
                                    audioUrlCtrl.clear();
                                  } else if (selectedMediaType == 'image') {
                                    audioUrlCtrl.clear();
                                  } else if (selectedMediaType == 'audio') {
                                    photoUrlCtrl.clear();
                                  }
                                });
                              },
                            ),

                            if (selectedMediaType == 'image') ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: photoUrlCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'URL da Imagem',
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
                            ] else if (selectedMediaType == 'audio') ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: audioUrlCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'URL do Áudio',
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
                                          audioUrlCtrl.text = url;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedIcon,
                              dropdownColor: darkBackground,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Ícone',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'skull',
                                  child: Text('Caveira'),
                                ),
                                DropdownMenuItem(
                                  value: 'map',
                                  child: Text('Mapa'),
                                ),
                                DropdownMenuItem(
                                  value: 'robot',
                                  child: Text('Robô'),
                                ),
                                DropdownMenuItem(
                                  value: 'ghost',
                                  child: Text('Fantasma'),
                                ),
                                DropdownMenuItem(
                                  value: 'crown',
                                  child: Text('Coroa'),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedIcon = val!;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedDifficulty,
                              dropdownColor: darkBackground,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Dificuldade',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'FÁCIL',
                                  child: Text('FÁCIL'),
                                ),
                                DropdownMenuItem(
                                  value: 'MÉDIA',
                                  child: Text('MÉDIA'),
                                ),
                                DropdownMenuItem(
                                  value: 'ALTA',
                                  child: Text('ALTA'),
                                ),
                                DropdownMenuItem(
                                  value: 'ÉPICO',
                                  child: Text('ÉPICO'),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedDifficulty = val!;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: codeCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Código (Senha/Resposta)',
                              ),
                            ),
                            if (selectedType == 'gps') ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: compassCoordsCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText:
                                      'Coordenadas Alvo do GPS (Lat, Lng)',
                                  hintText: '-23.5505, -46.6333',
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextField(
                              controller: titleCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Título do Enigma',
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
                            if (phaseId != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryAmber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: primaryAmber.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    FaIcon(FontAwesomeIcons.circleInfo, color: primaryAmber, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Evento Classic: Enigmas de fases não possuem prêmio individual. A premiação total do evento é concedida ao 1º colocado que finalizar todas as etapas.',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              TextField(
                                controller: prizeCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Prêmio (R\$)',
                                ),
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
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: compassPriceCtrl,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Preço (R\$)',
                                        prefixIcon: const Icon(
                                          Icons.attach_money,
                                          color: Colors.greenAccent,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white10,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: compassDurationCtrl,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Tempo (Segundos)',
                                        prefixIcon: const Icon(
                                          Icons.timer,
                                          color: Colors.redAccent,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white10,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        helperText: '0 = Infinito',
                                        helperStyle: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 12),
                            const Text(
                              'Características do Enigma',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableCharacteristics.map((char) {
                                final isSelected = selectedCharacteristics
                                    .contains(char['key'] as String);
                                return FilterChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FaIcon(
                                        char['icon'] as dynamic,
                                        size: 14,
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(char['label'] as String),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: primaryAmber,
                                  checkmarkColor: Colors.black,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  backgroundColor: cardColor,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedCharacteristics.add(
                                          char['key'] as String,
                                        );
                                      } else {
                                        selectedCharacteristics.remove(
                                          char['key'] as String,
                                        );
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),

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
                                  if (hasCompass || selectedType == 'gps') {
                                    if (compassCoordsCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Erro: Coordenadas do GPS são obrigatórias!'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return;
                                    }
                                    final latLngRegEx = RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$');
                                    if (!latLngRegEx.hasMatch(compassCoordsCtrl.text.trim())) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Formato inválido. Use: Latitude, Longitude (ex: -23.5, -46.6)'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                  setState(() => isSaving = true);

                                  try {
                                    final newData = {
                                      'icon': selectedIcon,
                                      'difficulty': selectedDifficulty,
                                      'order':
                                          int.tryParse(orderCtrl.text) ?? 1,
                                      'title': titleCtrl.text,
                                      'code': docId == null && codeCtrl.text.trim().isEmpty
                                          ? '${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}${DateTime.now().microsecond.toString().padLeft(3, '0')}'
                                          : codeCtrl.text,
                                      'instruction': instructionCtrl.text,
                                      'type': selectedType,
                                      'prize': phaseId != null
                                          ? 0
                                          : (num.tryParse(prizeCtrl.text) ?? 0),
                                      'linkedHints': linkedHints,
                                      'characteristics':
                                          selectedCharacteristics,

                                      // Salvando as novas chaves no Back4App
                                      'hasCompass': hasCompass,
                                      'compassCoords':
                                          (hasCompass || selectedType == 'gps')
                                          ? compassCoordsCtrl.text.trim()
                                          : '',
                                      'compassPrice':
                                          double.tryParse(
                                            compassPriceCtrl.text.replaceAll(
                                              ',',
                                              '.',
                                            ),
                                          ) ??
                                          15.0,
                                      'compassDuration':
                                          int.tryParse(
                                            compassDurationCtrl.text,
                                          ) ??
                                          0,
                                      'hasRadar': data?['hasRadar'] ?? false,
                                      'hasMap': data?['hasMap'] ?? false,
                                      'radarPrice': data?['radarPrice'] ?? 2.99,
                                      'mapPrice': data?['mapPrice'] ?? 4.99,
                                      'imageUrl': photoUrlCtrl.text,
                                      'audioUrl': audioUrlCtrl.text,
                                    };

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
