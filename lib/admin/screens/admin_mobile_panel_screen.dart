import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/admin/utils/admin_upload_util.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';

class AdminMobilePanelScreen extends ConsumerStatefulWidget {
  const AdminMobilePanelScreen({super.key});

  @override
  ConsumerState<AdminMobilePanelScreen> createState() =>
      _AdminMobilePanelScreenState();
}

class _AdminMobilePanelScreenState
    extends ConsumerState<AdminMobilePanelScreen> {
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
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text('Painel Operador Mobile'),
        backgroundColor: cardColor,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
            tooltip: 'Sair do Painel',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showMobileEventDialog(context);
        },
        backgroundColor: primaryAmber,
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.black),
      ),
      body: FutureBuilder<ParseResponse>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
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

          return ListView.builder(
            itemCount: events.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final event = events[index];
              final eventId = event.objectId!;
              final title = event.get<String>('title') ?? 'Sem Título';
              final status = event.get<String>('status') ?? 'draft';
              final eventType = event.get<String>('eventType') ?? 'classic';
              final isPublished = status == 'open';

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    eventType,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: FaIcon(
                          isPublished
                              ? FontAwesomeIcons.eye
                              : FontAwesomeIcons.eyeSlash,
                          color: isPublished ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => _toggleEventStatus(eventId, status),
                      ),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.penToSquare,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _showMobileEventDialog(
                          context,
                          docId: eventId,
                          data: _parseObjectToMap(event),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (eventType == 'classic') {
                      _showMobilePhasesDialog(context, eventId, eventType);
                    } else {
                      _showMobileEnigmasDialog(context, eventId, eventType);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, dynamic> _parseObjectToMap(ParseObject obj) {
    final map = <String, dynamic>{};
    obj.toJson().forEach((key, value) {
      map[key] = value;
    });
    return map;
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

  void _showMobileEventDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) {
    final titleCtrl = TextEditingController(text: data?['title']);
    final descCtrl = TextEditingController(text: data?['description']);
    String selectedEventType = data?['eventType'] ?? 'classic';
    final locationCtrl = TextEditingController(text: data?['location']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      docId == null ? 'Novo Evento' : 'Editar Evento',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Local (Cidade) *',
                      ),
                    ),
                    const SizedBox(height: 12),
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
                          child: Text('Classic'),
                        ),
                        DropdownMenuItem(
                          value: 'find_and_win',
                          child: Text('Find & Win'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedEventType = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        if (locationCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('O local é obrigatório.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final newData = {
                          'title': titleCtrl.text,
                          'description': descCtrl.text,
                          'location': locationCtrl.text.trim(),
                          'eventType': selectedEventType,
                          'status': data?['status'] ?? 'draft',
                          'prizePool': data?['prizePool'] ?? 0,
                          'order': data?['order'] ?? 1,
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
                              parameters: {'eventId': docId, 'data': newData},
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
                      child: const Text(
                        'Salvar Evento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMobilePhasesDialog(
    BuildContext context,
    String eventId,
    String eventType,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _MobilePhaseListScreen(eventId: eventId, eventType: eventType),
      ),
    );
  }

  void _showMobileEnigmasDialog(
    BuildContext context,
    String eventId,
    String eventType,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _MobileEnigmaListScreen(eventId: eventId, eventType: eventType),
      ),
    );
  }
}

class _MobilePhaseListScreen extends StatefulWidget {
  final String eventId;
  final String eventType;

  const _MobilePhaseListScreen({
    required this.eventId,
    required this.eventType,
  });

  @override
  State<_MobilePhaseListScreen> createState() => _MobilePhaseListScreenState();
}

class _MobilePhaseListScreenState extends State<_MobilePhaseListScreen> {
  late Future<ParseResponse> _phasesFuture;

  @override
  void initState() {
    super.initState();
    _loadPhases();
  }

  void _loadPhases() {
    setState(() {
      final query = QueryBuilder<ParseObject>(ParseObject('Phase'))
        ..whereEqualTo(
          'event',
          (ParseObject('Event')..objectId = widget.eventId).toPointer(),
        )
        ..orderByAscending('order');
      _phasesFuture = query.query();
    });
  }

  Map<String, dynamic> _parseObjectToMap(ParseObject obj) {
    final map = <String, dynamic>{};
    obj.toJson().forEach((key, value) {
      map[key] = value;
    });
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text('Fases do Evento'),
        backgroundColor: cardColor,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showMobilePhaseEditDialog(context, null, null);
        },
        backgroundColor: primaryAmber,
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.black),
      ),
      body: FutureBuilder<ParseResponse>(
        future: _phasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.success ||
              snapshot.data!.results == null) {
            return const Center(
              child: Text(
                'Nenhuma fase encontrada.',
                style: TextStyle(color: secondaryTextColor),
              ),
            );
          }

          final phases = snapshot.data!.results as List<ParseObject>;

          return ListView.builder(
            itemCount: phases.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final phase = phases[index];
              final phaseId = phase.objectId!;
              final order = phase.get<num>('order') ?? 0;
              final isBlocked = phase.get<bool>('isBlocked') ?? false;

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryAmber,
                    child: Text(
                      order.toString(),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  title: Text(
                    'Fase $order',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isBlocked ? 'Bloqueada' : 'Desbloqueada',
                    style: TextStyle(
                      color: isBlocked ? Colors.redAccent : Colors.green,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.penToSquare,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _showMobilePhaseEditDialog(
                          context,
                          phaseId,
                          _parseObjectToMap(phase),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _MobileEnigmaListScreen(
                          eventId: widget.eventId,
                          eventType: widget.eventType,
                          phaseId: phaseId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMobilePhaseEditDialog(
    BuildContext context,
    String? docId,
    Map<String, dynamic>? data,
  ) {
    final orderCtrl = TextEditingController(
      text: data?['order']?.toString() ?? '1',
    );
    bool isBlocked = data?['isBlocked'] ?? false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
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
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: orderCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Ordem'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text(
                        'Fase Bloqueada?',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Os jogadores não poderão ver os enigmas desta fase até que ela seja desbloqueada.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      value: isBlocked,
                      onChanged: (val) => setState(() => isBlocked = val),
                      activeColor: primaryAmber,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setState(() => isSaving = true);
                              try {
                                final newData = {
                                  'order': int.tryParse(orderCtrl.text) ?? 1,
                                  'isBlocked': isBlocked,
                                };

                                ParseResponse response;
                                if (docId == null) {
                                  response =
                                      await ParseCloudFunction(
                                        'createOrUpdatePhase',
                                      ).execute(
                                        parameters: {
                                          'eventId': widget.eventId,
                                          'data': newData,
                                        },
                                      );
                                } else {
                                  response =
                                      await ParseCloudFunction(
                                        'createOrUpdatePhase',
                                      ).execute(
                                        parameters: {
                                          'eventId': widget.eventId,
                                          'phaseId': docId,
                                          'data': newData,
                                        },
                                      );
                                }

                                if (response.success) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _loadPhases();
                                  }
                                } else {
                                  throw Exception(response.error?.message);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro: $e')),
                                );
                              } finally {
                                setState(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Salvar Fase',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
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

class _MobileEnigmaListScreen extends StatefulWidget {
  final String eventId;
  final String eventType;
  final String? phaseId;

  const _MobileEnigmaListScreen({
    required this.eventId,
    required this.eventType,
    this.phaseId,
  });

  @override
  State<_MobileEnigmaListScreen> createState() =>
      _MobileEnigmaListScreenState();
}

class _MobileEnigmaListScreenState extends State<_MobileEnigmaListScreen> {
  late Future<ParseResponse> _enigmasFuture;

  @override
  void initState() {
    super.initState();
    _loadEnigmas();
  }

  void _loadEnigmas() {
    setState(() {
      final query = QueryBuilder<ParseObject>(ParseObject('Enigma'));
      if (widget.phaseId != null) {
        query.whereEqualTo(
          'phase',
          (ParseObject('Phase')..objectId = widget.phaseId).toPointer(),
        );
      } else {
        query.whereEqualTo(
          'event',
          (ParseObject('Event')..objectId = widget.eventId).toPointer(),
        );
      }
      query.orderByAscending('order');
      _enigmasFuture = query.query();
    });
  }

  Map<String, dynamic> _parseObjectToMap(ParseObject obj) {
    final map = <String, dynamic>{};
    obj.toJson().forEach((key, value) {
      map[key] = value;
    });
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text('Enigmas do Evento'),
        backgroundColor: cardColor,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          int nextOrder = 1;
          final currentSnapshot = await _enigmasFuture;
          if (currentSnapshot.success && currentSnapshot.results != null) {
            nextOrder = currentSnapshot.results!.length + 1;
          }
          _showMobileEnigmaEditDialog(
            context,
            null,
            null,
            nextOrder: nextOrder,
          );
        },
        backgroundColor: primaryAmber,
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.black),
      ),
      body: FutureBuilder<ParseResponse>(
        future: _enigmasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.success ||
              snapshot.data!.results == null) {
            return const Center(
              child: Text(
                'Nenhum enigma encontrado.',
                style: TextStyle(color: secondaryTextColor),
              ),
            );
          }

          final enigmas = snapshot.data!.results as List<ParseObject>;

          return ListView.builder(
            itemCount: enigmas.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final enigma = enigmas[index];
              final type = enigma.get<String>('type') ?? 'text';
              final order = enigma.get<num>('order') ?? 0;

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryAmber,
                    child: Text(
                      order.toString(),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  title: Text(
                    'Tipo: $type',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.penToSquare,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _showMobileEnigmaEditDialog(
                          context,
                          enigma.objectId,
                          _parseObjectToMap(enigma),
                        ),
                      ),
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.trash,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () async {
                          final response =
                              await ParseCloudFunction('deleteEnigma').execute(
                                parameters: {
                                  'eventId': widget.eventId,
                                  'enigmaId': enigma.objectId!,
                                },
                              );
                          if (response.success) _loadEnigmas();
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
    );
  }

  String _generateRandomName() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  void _showMobileEnigmaEditDialog(
    BuildContext context,
    String? docId,
    Map<String, dynamic>? data, {
    int? nextOrder,
  }) {
    final instructionCtrl = TextEditingController(
      text:
          data?['instruction'] ?? (docId == null ? _generateRandomName() : ''),
    );
    final codeCtrl = TextEditingController(text: data?['code']);
    final photoUrlCtrl = TextEditingController(text: data?['photoUrl']);
    final compassCoordsCtrl = TextEditingController(
      text: data?['compassCoords'],
    );
    final orderCtrl = TextEditingController(
      text:
          data?['order']?.toString() ??
          (docId == null && nextOrder != null ? nextOrder.toString() : '1'),
    );
    final prizeCtrl = TextEditingController(
      text: data?['prize']?.toString() ?? '0',
    );

    String selectedType = data?['type'] ?? 'foto';
    bool hasCompass = data?['hasCompass'] ?? false;
    bool isSaving = false;

    List<dynamic> linkedHints = List.from(data?['linkedHints'] ?? []);
    final Future<ParseResponse> hintsFuture = QueryBuilder<ParseObject>(
      ParseObject('Hint'),
    ).query();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
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
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedType,
                            dropdownColor: cardColor,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'text',
                                child: Text('Texto'),
                              ),
                              DropdownMenuItem(
                                value: 'gps',
                                child: Text('GPS'),
                              ),
                              DropdownMenuItem(
                                value: 'qrcode',
                                child: Text('QR Code'),
                              ),
                              DropdownMenuItem(
                                value: 'foto',
                                child: Text('Foto'),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => selectedType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instructionCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Instruções',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: selectedType == 'gps'
                            ? 'Coordenadas Alvo (Lat, Lng)'
                            : 'Código/Senha',
                      ),
                    ),
                    if (selectedType == 'gps') ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            bool serviceEnabled =
                                await Geolocator.isLocationServiceEnabled();
                            if (!serviceEnabled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ative a localização do dispositivo.',
                                  ),
                                ),
                              );
                              return;
                            }
                            LocationPermission permission =
                                await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                              if (permission == LocationPermission.denied)
                                return;
                            }
                            if (permission == LocationPermission.deniedForever)
                              return;

                            setState(() => isSaving = true);
                            Position position =
                                await Geolocator.getCurrentPosition();
                            setState(() {
                              codeCtrl.text =
                                  '${position.latitude}, ${position.longitude}';
                              isSaving = false;
                            });
                          } catch (e) {
                            setState(() => isSaving = false);
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Erro: $e')));
                          }
                        },
                        icon: const FaIcon(
                          FontAwesomeIcons.locationCrosshairs,
                          size: 16,
                        ),
                        label: const Text('Capturar Localização Atual'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                        ),
                      ),
                    ],
                    if (selectedType == 'foto') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: photoUrlCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'URL da Foto',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final url = await AdminUploadUtil.takeAndUploadPhoto(
                            context,
                          );
                          if (url != null) {
                            setState(() => photoUrlCtrl.text = url);
                          }
                        },
                        icon: const FaIcon(FontAwesomeIcons.camera, size: 16),
                        label: const Text('Tirar Foto do Local'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text(
                        'Habilitar Bússola?',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: hasCompass,
                      onChanged: (val) => setState(() => hasCompass = val),
                      activeColor: primaryAmber,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (hasCompass) ...[
                      TextField(
                        controller: compassCoordsCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Coordenadas da Bússola',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            bool serviceEnabled =
                                await Geolocator.isLocationServiceEnabled();
                            if (!serviceEnabled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ative a localização.'),
                                ),
                              );
                              return;
                            }
                            LocationPermission permission =
                                await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                              if (permission == LocationPermission.denied)
                                return;
                            }
                            Position position =
                                await Geolocator.getCurrentPosition();
                            setState(() {
                              compassCoordsCtrl.text =
                                  '${position.latitude}, ${position.longitude}';
                            });
                          } catch (e) {}
                        },
                        icon: const FaIcon(
                          FontAwesomeIcons.locationCrosshairs,
                          size: 16,
                        ),
                        label: const Text(
                          'Capturar Localização Atual (Bússola)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
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
                    FutureBuilder<ParseResponse>(
                      future: hintsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        if (!snapshot.hasData || snapshot.data!.results == null)
                          return const Text(
                            'Nenhuma dica.',
                            style: TextStyle(color: Colors.white),
                          );

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

                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (hasCompass &&
                                  compassCoordsCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Coordenadas da bússola obrigatórias se habilitada.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(() => isSaving = true);
                              try {
                                final newData = {
                                  'order': int.tryParse(orderCtrl.text) ?? 1,
                                  'code': codeCtrl.text,
                                  'instruction': instructionCtrl.text,
                                  'type': selectedType,
                                  'prize': num.tryParse(prizeCtrl.text) ?? 0,
                                  'hasCompass': hasCompass,
                                  'compassCoords': hasCompass
                                      ? compassCoordsCtrl.text.trim()
                                      : '',
                                  'linkedHints': linkedHints,
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
                                          'eventId': widget.eventId,
                                          'phaseId': widget.phaseId ?? '',
                                          'data': newData,
                                        },
                                      );
                                } else {
                                  response =
                                      await ParseCloudFunction(
                                        'createOrUpdateEnigma',
                                      ).execute(
                                        parameters: {
                                          'eventId': widget.eventId,
                                          'enigmaId': docId,
                                          'data': newData,
                                        },
                                      );
                                }

                                if (response.success) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _loadEnigmas();
                                  }
                                } else {
                                  throw Exception(response.error?.message);
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erro: $e')),
                                );
                              } finally {
                                setState(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Salvar Enigma',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
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
