import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/models/phase_model.dart';
import 'package:oenigma/services/storage_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

// TELA PRINCIPAL E COMPLETA DO EDITOR DE EVENTOS
class EventEditorScreen extends StatefulWidget {
  final EventModel? event;
  const EventEditorScreen({super.key, this.event});

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  String? _eventId;

  Future<EventModel?>? _fullEventFuture;

  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'prize': TextEditingController(),
    'price': TextEditingController(),
    'startDate': TextEditingController(),
    'location': TextEditingController(),
    'fullDescription': TextEditingController(),
  };
  late TextEditingController _eventIconUrlController;

  String _eventType = 'classic';
  String _status = 'dev';
  List<PhaseModel> _phases = [];
  List<EnigmaModel> _findAndWinEnigmas = [];
  int? _selectedPhaseIndex;

  Uint8List? _eventIconBytes;
  String? _eventIconName;

  final Map<String, Uint8List?> _enigmaFileBytes = {};
  final Map<String, String?> _enigmaFileNames = {};

  @override
  void initState() {
    super.initState();
    _eventIconUrlController = TextEditingController();

    if (widget.event != null && widget.event!.id.isNotEmpty) {
      _eventId = widget.event!.id;
      _fullEventFuture = _firebaseService.getFullEventDetails(_eventId!);
    }
  }

  void _loadEventData(EventModel? event) {
    if (mounted) {
      setState(() {
        _eventId = event?.id;
        _eventType = event?.eventType ?? 'classic';
        _controllers['name']!.text = event?.name ?? '';
        _controllers['prize']!.text = event?.prize ?? '';
        _controllers['price']!.text = event?.price.toString() ?? '0.0';
        _controllers['startDate']!.text = event?.startDate ?? '';
        _controllers['location']!.text = event?.location ?? '';
        _controllers['fullDescription']!.text = event?.fullDescription ?? '';
        _status = event?.status ?? 'dev';
        _phases = List.from(event?.phases ?? []);
        _findAndWinEnigmas = List.from(event?.enigmas ?? []);
        _eventIconUrlController.text = event?.icon ?? '';
      });
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _eventIconUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickEventIcon() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _eventIconBytes = result.files.single.bytes;
        _eventIconName = result.files.single.name;
        _eventIconUrlController.text = "Novo arquivo: $_eventIconName";
      });
    }
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? iconUrl = _eventIconUrlController.text.startsWith("https://")
          ? _eventIconUrlController.text
          : widget.event?.icon;
      if (_eventIconBytes != null) {
        final path =
            'events/${_eventId ?? DateTime.now().millisecondsSinceEpoch}/icon/$_eventIconName';
        iconUrl = await _storageService.uploadFile(path, _eventIconBytes!);
      }

      final eventData = {
        'name': _controllers['name']!.text,
        'prize': _controllers['prize']!.text,
        'price': double.tryParse(_controllers['price']!.text) ?? 0.0,
        'icon': iconUrl,
        'startDate': _controllers['startDate']!.text,
        'location': _controllers['location']!.text,
        'fullDescription': _controllers['fullDescription']!.text,
        'status': _status,
        'eventType': _eventType,
      };

      final eventResult = await _firebaseService.createOrUpdateEvent(
        eventId: _eventId,
        data: eventData,
      );
      final currentEventId =
          (_eventId ?? (eventResult.data as Map)['eventId']) as String;
      if (_eventId == null) setState(() => _eventId = currentEventId);

      if (_eventType == 'classic') {
        for (int i = 0; i < _phases.length; i++)
          await _savePhaseWithEnigmas(currentEventId, _phases[i], i);
      } else {
        for (int i = 0; i < _findAndWinEnigmas.length; i++)
          await _saveFindAndWinEnigma(currentEventId, _findAndWinEnigmas[i], i);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Evento salvo com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: $e"),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePhaseWithEnigmas(
    String eventId,
    PhaseModel phase,
    int phaseIndex,
  ) async {
    final phaseResult = await _firebaseService.createOrUpdatePhase(
      eventId: eventId,
      phaseId: phase.id.isNotEmpty ? phase.id : null,
      data: {'order': phase.order},
    );
    final phaseId = (phaseResult.data as Map)['phaseId'];

    var updatedEnigmas = <EnigmaModel>[];
    for (int i = 0; i < phase.enigmas.length; i++) {
      final enigmaData = await _uploadAndPrepareEnigmaData(
        eventId,
        enigma: phase.enigmas[i],
        phaseId: phaseId,
        phaseIndex: phaseIndex,
        enigmaIndex: i,
      );
      final enigmaResult = await _firebaseService.createOrUpdateEnigma(
        eventId: eventId,
        phaseId: phaseId,
        enigmaId: phase.enigmas[i].id.isNotEmpty ? phase.enigmas[i].id : null,
        data: enigmaData,
      );
      updatedEnigmas.add(
        EnigmaModel.fromMap({
          'id': (enigmaResult.data as Map)['enigmaId'],
          ...enigmaData,
        }),
      );
    }
    setState(
      () => _phases[phaseIndex] = PhaseModel(
        id: phaseId,
        order: phase.order,
        enigmas: updatedEnigmas,
      ),
    );
  }

  Future<void> _saveFindAndWinEnigma(
    String eventId,
    EnigmaModel enigma,
    int index,
  ) async {
    final enigmaData = await _uploadAndPrepareEnigmaData(
      eventId,
      enigma: enigma,
      phaseIndex: -1,
      enigmaIndex: index,
    );
    final enigmaResult = await _firebaseService.createOrUpdateEnigma(
      eventId: eventId,
      enigmaId: enigma.id.isNotEmpty ? enigma.id : null,
      data: enigmaData,
    );
    final newEnigmaId = (enigmaResult.data as Map)['enigmaId'];
    setState(
      () => _findAndWinEnigmas[index] = EnigmaModel.fromMap({
        'id': newEnigmaId,
        ...enigmaData,
      }),
    );
  }

  Future<Map<String, dynamic>> _uploadAndPrepareEnigmaData(
    String eventId, {
    required EnigmaModel enigma,
    String? phaseId,
    required int phaseIndex,
    required int enigmaIndex,
  }) async {
    String? enigmaImageUrl = enigma.imageUrl;
    String? hintDataUrl = enigma.hintData;
    final phasePath = phaseId ?? 'no_phase';

    final enigmaImageKey = 'phase_${phaseIndex}_enigma_${enigmaIndex}_image';
    if (_enigmaFileBytes[enigmaImageKey] != null) {
      final fileName = _enigmaFileNames[enigmaImageKey] ?? 'enigma_image.jpg';
      final path =
          'events/$eventId/phases/$phasePath/enigma_${enigmaIndex}_$fileName';
      enigmaImageUrl = await _storageService.uploadFile(
        path,
        _enigmaFileBytes[enigmaImageKey]!,
      );
    }

    final hintFileKey = 'phase_${phaseIndex}_enigma_${enigmaIndex}_hint';
    if (_enigmaFileBytes[hintFileKey] != null) {
      final fileName = _enigmaFileNames[hintFileKey] ?? 'hint_file';
      final path =
          'events/$eventId/phases/$phasePath/enigma_${enigmaIndex}_hint_$fileName';
      hintDataUrl = await _storageService.uploadFile(
        path,
        _enigmaFileBytes[hintFileKey]!,
      );
    }

    return {
      'type': enigma.type,
      'instruction': enigma.instruction,
      'code': enigma.code,
      'imageUrl': enigmaImageUrl,
      'hintType': enigma.hintType,
      'hintData': enigma.hintType == 'gps' ? enigma.hintData : hintDataUrl,
      'prize': enigma.prize,
      'order': enigma.order,
      'status': 'open',
    };
  }

  void _addNewPhase() {
    setState(() {
      _phases.add(PhaseModel(id: '', order: _phases.length + 1, enigmas: []));
      _selectedPhaseIndex = _phases.length - 1;
    });
  }

  void _addNewFindAndWinEnigma() {
    setState(() {
      _findAndWinEnigmas.add(
        EnigmaModel(
          id: '',
          type: 'photo_location',
          instruction: '',
          code: '',
          order: _findAndWinEnigmas.length + 1,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.event == null ? "Criar Novo Evento" : "Editor de Evento",
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveAll,
              tooltip: "Salvar Todas as Alterações",
            ),
        ],
      ),
      body: FutureBuilder<EventModel?>(
        future: _fullEventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text("Erro: ${snapshot.error}"));
          if (snapshot.hasData && _controllers['name']!.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _loadEventData(snapshot.data),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 350, child: _buildLeftColumn()),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: _eventType == 'classic'
                    ? _buildClassicEditor()
                    : _buildFindAndWinEditor(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftColumn() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Detalhes do Evento",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _eventType,
              decoration: const InputDecoration(
                labelText: "Modalidade do Evento",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'classic',
                  child: Text("Clássico (por Fases)"),
                ),
                DropdownMenuItem(
                  value: 'find_and_win',
                  child: Text("Find & Win"),
                ),
              ],
              onChanged: (value) => setState(() => _eventType = value!),
            ),
            const SizedBox(height: 16),
            ..._controllers.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextFormField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Campo Obrigatório' : null,
                ),
              ),
            ),
            _FileUploadWidget(
              label: "Ícone do Evento",
              urlController: _eventIconUrlController,
              pickedFileBytes: _eventIconBytes,
              onPickFile: _pickEventIcon,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: "Status do Evento",
                border: OutlineInputBorder(),
              ),
              items: ['dev', 'open', 'closed']
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            if (_eventType == 'classic') ...[
              const Divider(height: 40),
              Text("Fases", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              if (_phases.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Nenhuma fase criada."),
                  ),
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _phases.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text("Fase ${_phases[index].order}"),
                  selected: _selectedPhaseIndex == index,
                  selectedTileColor: primaryAmber.withOpacity(0.2),
                  onTap: () => setState(() => _selectedPhaseIndex = index),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => setState(() {
                      _phases.removeAt(index);
                      if (_selectedPhaseIndex == index)
                        _selectedPhaseIndex = null;
                      else if (_selectedPhaseIndex != null &&
                          _selectedPhaseIndex! > index)
                        _selectedPhaseIndex = _selectedPhaseIndex! - 1;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addNewPhase,
                  icon: const Icon(Icons.add),
                  label: const Text("Adicionar Fase"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassicEditor() {
    if (_selectedPhaseIndex == null || _selectedPhaseIndex! >= _phases.length) {
      return const Center(
        child: Text("Selecione ou crie uma fase para editar."),
      );
    }
    return PhaseEditorView(
      key: ValueKey("${_phases[_selectedPhaseIndex!].id}_$_selectedPhaseIndex"),
      initialPhase: _phases[_selectedPhaseIndex!],
      phaseIndex: _selectedPhaseIndex!,
      onPhaseUpdated: (updatedPhase, files, names) => setState(() {
        _phases[_selectedPhaseIndex!] = updatedPhase;
        _enigmaFileBytes.addAll(files);
        _enigmaFileNames.addAll(names);
      }),
    );
  }

  Widget _buildFindAndWinEditor() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          "Enigmas (Ache e Ganhe)",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        ..._findAndWinEnigmas.asMap().entries.map((entry) {
          int index = entry.key;
          return EnigmaEditorCard(
            key: ValueKey("fw_${entry.value.id}_$index"),
            enigma: entry.value,
            enigmaIndex: index,
            isFindAndWin: true,
            onEnigmaChanged: (idx, updatedEnigma, files, names) => setState(() {
              _findAndWinEnigmas[idx] = updatedEnigma;
              final imageKey = 'fw_enigma_${idx}_image';
              _enigmaFileBytes[imageKey] = files['enigmaImageBytes'];
              _enigmaFileNames[imageKey] = files['enigmaImageName'];
              // Adicione lógica para hint files se necessário
            }),
            onEnigmaDeleted: () =>
                setState(() => _findAndWinEnigmas.removeAt(index)),
          );
        }).toList(),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _addNewFindAndWinEnigma,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Adicionar Enigma"),
          ),
        ),
      ],
    );
  }
}

// --- EDITOR DA LISTA DE ENIGMAS DE UMA FASE ---
class PhaseEditorView extends StatefulWidget {
  final PhaseModel initialPhase;
  final int phaseIndex;
  final Function(PhaseModel, Map<String, Uint8List?>, Map<String, String?>)
  onPhaseUpdated;

  const PhaseEditorView({
    super.key,
    required this.initialPhase,
    required this.phaseIndex,
    required this.onPhaseUpdated,
  });

  @override
  State<PhaseEditorView> createState() => _PhaseEditorViewState();
}

class _PhaseEditorViewState extends State<PhaseEditorView> {
  late PhaseModel _phase;
  final Map<String, Uint8List?> _fileBytesMap = {};
  final Map<String, String?> _fileNamesMap = {};

  @override
  void initState() {
    super.initState();
    _phase = widget.initialPhase;
  }

  @override
  void didUpdateWidget(covariant PhaseEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPhase.id != oldWidget.initialPhase.id ||
        widget.initialPhase.order != oldWidget.initialPhase.order) {
      setState(() {
        _phase = widget.initialPhase;
        _fileBytesMap.clear();
        _fileNamesMap.clear();
      });
    }
  }

  void _updateParent() {
    widget.onPhaseUpdated(_phase, _fileBytesMap, _fileNamesMap);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          "Editando Fase ${_phase.order}",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        ..._phase.enigmas.asMap().entries.map((entry) {
          int enigmaIndex = entry.key;
          return EnigmaEditorCard(
            key: ValueKey(
              entry.value.id.isNotEmpty ? entry.value.id : "new_${enigmaIndex}",
            ),
            enigma: entry.value,
            enigmaIndex: enigmaIndex,
            onEnigmaChanged: (index, updatedEnigma, files, names) {
              setState(() => _phase.enigmas[index] = updatedEnigma);
              final phaseKey = "phase_${widget.phaseIndex}";
              _fileBytesMap['${phaseKey}_enigma_${index}_image'] =
                  files['enigmaImageBytes'];
              _fileNamesMap['${phaseKey}_enigma_${index}_image'] =
                  files['enigmaImageName'];
              _fileBytesMap['${phaseKey}_enigma_${index}_hint'] =
                  files['hintFileBytes'];
              _fileNamesMap['${phaseKey}_enigma_${index}_hint'] =
                  files['hintFileName'];
              _updateParent();
            },
            onEnigmaDeleted: () => setState(() {
              _phase.enigmas.removeAt(enigmaIndex);
              _updateParent();
            }),
          );
        }).toList(),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(
                () => _phase.enigmas.add(
                  EnigmaModel(id: '', type: 'text', instruction: '', code: ''),
                ),
              );
              _updateParent();
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Adicionar Enigma à Fase"),
          ),
        ),
      ],
    );
  }
}

// --- EDITOR DE UM ÚNICO ENIGMA ---
class EnigmaEditorCard extends StatefulWidget {
  final EnigmaModel enigma;
  final int enigmaIndex;
  final bool isFindAndWin;
  final Function(int, EnigmaModel, Map<String, dynamic>, Map<String, String?>)
  onEnigmaChanged;
  final VoidCallback onEnigmaDeleted;

  const EnigmaEditorCard({
    super.key,
    required this.enigma,
    required this.enigmaIndex,
    required this.onEnigmaChanged,
    required this.onEnigmaDeleted,
    this.isFindAndWin = false,
  });

  @override
  State<EnigmaEditorCard> createState() => _EnigmaEditorCardState();
}

class _EnigmaEditorCardState extends State<EnigmaEditorCard> {
  late final Map<String, TextEditingController> _controllers;
  Uint8List? _enigmaImageBytes;
  Uint8List? _hintFileBytes;
  String? _enigmaImageName;
  String? _hintFileName;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = {
      'instruction': TextEditingController(text: widget.enigma.instruction),
      'code': TextEditingController(text: widget.enigma.code),
      'imageUrl': TextEditingController(text: widget.enigma.imageUrl ?? ''),
      'hintData': TextEditingController(text: widget.enigma.hintData ?? ''),
      'prize': TextEditingController(text: widget.enigma.prize.toString()),
    };
    _controllers.forEach((_, controller) => controller.addListener(_onChanged));
  }

  @override
  void didUpdateWidget(covariant EnigmaEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enigma != oldWidget.enigma) {
      _controllers['instruction']!.text = widget.enigma.instruction;
      _controllers['code']!.text = widget.enigma.code;
      _controllers['imageUrl']!.text = widget.enigma.imageUrl ?? '';
      _controllers['hintData']!.text = widget.enigma.hintData ?? '';
      _controllers['prize']!.text = widget.enigma.prize.toString();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _onChanged() {
    final updatedEnigma = widget.enigma.copyWith(
      instruction: _controllers['instruction']!.text,
      code: _controllers['code']!.text,
      imageUrl: _controllers['imageUrl']!.text,
      hintData: _controllers['hintData']!.text,
      prize: double.tryParse(_controllers['prize']!.text) ?? 0.0,
    );
    widget.onEnigmaChanged(
      widget.enigmaIndex,
      updatedEnigma,
      {'enigmaImageBytes': _enigmaImageBytes, 'hintFileBytes': _hintFileBytes},
      {'enigmaImageName': _enigmaImageName, 'hintFileName': _hintFileName},
    );
  }

  Future<void> _pickFile(bool isEnigmaImage) async {
    FileType type = (widget.enigma.hintType == 'audio' && !isEnigmaImage)
        ? FileType.audio
        : FileType.image;
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: type);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        if (isEnigmaImage) {
          _enigmaImageBytes = result.files.single.bytes;
          _enigmaImageName = result.files.single.name;
          _controllers['imageUrl']!.text = "Novo: $_enigmaImageName";
        } else {
          _hintFileBytes = result.files.single.bytes;
          _hintFileName = result.files.single.name;
          _controllers['hintData']!.text = "Novo: $_hintFileName";
        }
      });
      _onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Enigma ${widget.enigmaIndex + 1}",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: widget.onEnigmaDeleted,
                ),
              ],
            ),
            const Divider(),
            DropdownButtonFormField<String>(
              value: widget.enigma.type,
              decoration: const InputDecoration(labelText: "Tipo de Enigma"),
              items: [
                'text',
                'photo_location',
                'qr_code_gps',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  widget.onEnigmaChanged(
                    widget.enigmaIndex,
                    widget.enigma.copyWith(type: newValue),
                    {},
                    {},
                  );
                }
              },
            ),
            TextFormField(
              controller: _controllers['instruction'],
              decoration: const InputDecoration(labelText: "Instrução"),
              maxLines: 3,
            ),
            TextFormField(
              controller: _controllers['code'],
              decoration: const InputDecoration(
                labelText: "Código de Resposta",
              ),
            ),
            if (widget.isFindAndWin)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  controller: _controllers['prize'],
                  decoration: const InputDecoration(
                    labelText: "Prêmio do Enigma (R\$)",
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            if (widget.enigma.type == 'photo_location' ||
                widget.enigma.type == 'qr_code_gps')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _FileUploadWidget(
                  label: "Imagem do Enigma",
                  pickedFileBytes: _enigmaImageBytes,
                  onPickFile: () => _pickFile(true),
                  urlController: _controllers['imageUrl']!,
                ),
              ),
            const Divider(height: 40),
            const Text(
              "Dica (Opcional)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButtonFormField<String?>(
              value: widget.enigma.hintType,
              decoration: const InputDecoration(labelText: "Tipo de Dica"),
              items: [
                const DropdownMenuItem(value: null, child: Text("Nenhuma")),
                ...[
                  'photo',
                  'gps',
                  'audio',
                ].map((v) => DropdownMenuItem(value: v, child: Text(v))),
              ],
              onChanged: (newValue) {
                widget.onEnigmaChanged(
                  widget.enigmaIndex,
                  widget.enigma.copyWith(hintType: () => newValue),
                  {},
                  {},
                );
              },
            ),
            if (widget.enigma.hintType == 'photo' ||
                widget.enigma.hintType == 'audio')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _FileUploadWidget(
                  label: "Arquivo da Dica (${widget.enigma.hintType})",
                  pickedFileBytes: _hintFileBytes,
                  onPickFile: () => _pickFile(false),
                  urlController: _controllers['hintData']!,
                ),
              ),
            if (widget.enigma.hintType == 'gps')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  controller: _controllers['hintData'],
                  decoration: const InputDecoration(
                    labelText: "Coordenadas GPS",
                    hintText: "-23.5714,-46.6669",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET AUXILIAR PARA O CAMPO DE UPLOAD ---
class _FileUploadWidget extends StatelessWidget {
  final String label;
  final Uint8List? pickedFileBytes;
  final VoidCallback onPickFile;
  final TextEditingController urlController;

  const _FileUploadWidget({
    required this.label,
    this.pickedFileBytes,
    required this.onPickFile,
    required this.urlController,
  });

  @override
  Widget build(BuildContext context) {
    bool hasValidUrl =
        urlController.text.isNotEmpty &&
        Uri.tryParse(urlController.text)?.isAbsolute == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10),
          ),
          child: (pickedFileBytes != null)
              ? Image.memory(pickedFileBytes!)
              : (hasValidUrl
                    ? Image.network(
                        urlController.text,
                        errorBuilder: (c, e, s) => const Icon(Icons.error),
                      )
                    : Center(
                        child: Text(
                          urlController.text.startsWith('Novo:')
                              ? urlController.text
                              : "Nenhum arquivo",
                          style: const TextStyle(color: secondaryTextColor),
                        ),
                      )),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: "Ou cole uma URL",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onPickFile,
          icon: const Icon(Icons.upload_file),
          label: const Text("Selecionar Arquivo..."),
        ),
      ],
    );
  }
}
