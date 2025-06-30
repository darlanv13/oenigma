import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/models/phase_model.dart';
import 'package:oenigma/services/storage_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

// --- TELA PRINCIPAL DO EDITOR DE EVENTOS ---
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

  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'prize': TextEditingController(),
    'price': TextEditingController(),
    'startDate': TextEditingController(),
    'location': TextEditingController(),
    'fullDescription': TextEditingController(),
  };
  String _status = 'dev';
  List<PhaseModel> _phases = [];
  int? _selectedPhaseIndex;

  Uint8List? _eventIconBytes;
  String? _eventIconName;
  String? _existingEventIconUrl;
  late TextEditingController _eventIconUrlController;

  final Map<String, Uint8List?> _enigmaFileBytes = {};

  @override
  void initState() {
    super.initState();
    _eventIconUrlController = TextEditingController();
    if (widget.event != null) {
      _loadEventData(widget.event!);
    }
  }

  void _loadEventData(EventModel event) {
    _eventId = event.id;
    _controllers['name']!.text = event.name;
    _controllers['prize']!.text = event.prize;
    _controllers['price']!.text = event.price.toString();
    _controllers['startDate']!.text = event.startDate;
    _controllers['location']!.text = event.location;
    _controllers['fullDescription']!.text = event.fullDescription;
    _status = event.status;
    _phases = List.from(event.phases);
    _existingEventIconUrl = event.icon;
    _eventIconUrlController.text = event.icon;
  }

  Future<void> _pickEventIcon() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _eventIconBytes = result.files.single.bytes;
        _eventIconName = result.files.single.name;
        _eventIconUrlController.text =
            "Novo arquivo selecionado: ${_eventIconName!}";
        _existingEventIconUrl = null;
      });
    }
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? iconUrl = _eventIconUrlController.text;
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
      };

      final eventResult = await _firebaseService.createOrUpdateEvent(
        eventId: _eventId,
        data: eventData,
      );
      final currentEventId =
          (_eventId ?? (eventResult.data as Map)['eventId']) as String;
      if (_eventId == null) setState(() => _eventId = currentEventId);

      for (int i = 0; i < _phases.length; i++) {
        await _savePhaseWithEnigmas(currentEventId, _phases[i], i);
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

    _phases[phaseIndex] = PhaseModel(
      id: phaseId,
      order: phase.order,
      enigmas: phase.enigmas,
    );

    for (int i = 0; i < phase.enigmas.length; i++) {
      EnigmaModel enigma = phase.enigmas[i];
      String? enigmaImageUrl = enigma.imageUrl;
      String? hintDataUrl = enigma.hintData;

      final enigmaImageKey = 'enigma_${phaseIndex}_${i}_image';
      if (_enigmaFileBytes.containsKey(enigmaImageKey)) {
        final path = 'events/$eventId/phases/$phaseId/enigma_${i}_image';
        enigmaImageUrl = await _storageService.uploadFile(
          path,
          _enigmaFileBytes[enigmaImageKey]!,
        );
      }

      final hintFileKey = 'enigma_${phaseIndex}_${i}_hint';
      if (_enigmaFileBytes.containsKey(hintFileKey)) {
        final path = 'events/$eventId/phases/$phaseId/enigma_${i}_hint';
        hintDataUrl = await _storageService.uploadFile(
          path,
          _enigmaFileBytes[hintFileKey]!,
        );
      }

      final enigmaData = {
        'type': enigma.type,
        'instruction': enigma.instruction,
        'code': enigma.code,
        'imageUrl': enigmaImageUrl,
        'hintType': enigma.hintType,
        'hintData': enigma.hintType == 'gps' ? enigma.hintData : hintDataUrl,
      };
      await _firebaseService.createOrUpdateEnigma(
        eventId: eventId,
        phaseId: phaseId,
        enigmaId: enigma.id.isNotEmpty ? enigma.id : null,
        data: enigmaData,
      );
    }
  }

  void _addNewPhase() {
    setState(() {
      _phases.add(PhaseModel(id: '', order: _phases.length + 1, enigmas: []));
      _selectedPhaseIndex = _phases.length - 1;
    });
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _eventIconUrlController.dispose();
    super.dispose();
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 350, color: cardColor, child: _buildLeftColumn()),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: _selectedPhaseIndex == null
                ? const Center(
                    child: Text("Selecione ou crie uma fase para editar."),
                  )
                : PhaseEditorView(
                    key: ValueKey(
                      _phases[_selectedPhaseIndex!].id.isNotEmpty
                          ? _phases[_selectedPhaseIndex!].id
                          : _selectedPhaseIndex,
                    ),
                    initialPhase: _phases[_selectedPhaseIndex!],
                    onPhaseUpdated: (updatedPhase, files) {
                      setState(() {
                        _phases[_selectedPhaseIndex!] = updatedPhase;
                        files.forEach((key, value) {
                          _enigmaFileBytes[key] = value;
                        });
                      });
                    },
                  ),
          ),
        ],
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
            ..._controllers.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextFormField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key.replaceAll('Controller', ''),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Campo Obrigatório' : null,
                ),
              ),
            ),
            _FileUploadWidget(
              label: "Ícone do Evento",
              pickedFileBytes: _eventIconBytes,
              onPickFile: _pickEventIcon,
              urlController: _eventIconUrlController,
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
            const Divider(height: 40),
            Text("Fases", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
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
                  onPressed: () {
                    setState(() {
                      _phases.removeAt(index);
                      if (_selectedPhaseIndex == index)
                        _selectedPhaseIndex = null;
                      else if (_selectedPhaseIndex != null &&
                          _selectedPhaseIndex! > index)
                        _selectedPhaseIndex = _selectedPhaseIndex! - 1;
                    });
                  },
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
        ),
      ),
    );
  }
}

// --- EDITOR DA LISTA DE ENIGMAS (widget filho) ---
class PhaseEditorView extends StatefulWidget {
  final PhaseModel initialPhase;
  final Function(PhaseModel, Map<String, Uint8List?>) onPhaseUpdated;

  const PhaseEditorView({
    super.key,
    required this.initialPhase,
    required this.onPhaseUpdated,
  });

  @override
  State<PhaseEditorView> createState() => _PhaseEditorViewState();
}

class _PhaseEditorViewState extends State<PhaseEditorView> {
  late PhaseModel _phase;
  final Map<String, Uint8List?> _fileBytesMap = {};

  @override
  void initState() {
    super.initState();
    _phase = widget.initialPhase;
  }

  void _updateParent() {
    widget.onPhaseUpdated(_phase, _fileBytesMap);
  }

  void _addNewEnigma() {
    setState(
      () => _phase.enigmas.add(
        EnigmaModel(id: '', type: 'text', instruction: '', code: ''),
      ),
    );
    _updateParent();
  }

  void _deleteEnigma(int index) {
    setState(() => _phase.enigmas.removeAt(index));
    _updateParent();
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
          return EnigmaEditorCard(
            key: ValueKey(
              entry.value.id.isNotEmpty
                  ? "${entry.value.id}_${entry.key}"
                  : "new_${entry.key}",
            ),
            enigma: entry.value,
            enigmaIndex: entry.key,
            onEnigmaChanged: (index, updatedEnigma, imageBytes, hintBytes) {
              setState(() => _phase.enigmas[index] = updatedEnigma);
              final phaseOrder = _phase.order - 1;
              if (imageBytes != null)
                _fileBytesMap['enigma_${phaseOrder}_${index}_image'] =
                    imageBytes;
              if (hintBytes != null)
                _fileBytesMap['enigma_${phaseOrder}_${index}_hint'] = hintBytes;
              _updateParent();
            },
            onEnigmaDeleted: () => _deleteEnigma(entry.key),
          );
        }).toList(),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _addNewEnigma,
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
  final Function(int, EnigmaModel, Uint8List?, Uint8List?) onEnigmaChanged;
  final VoidCallback onEnigmaDeleted;

  const EnigmaEditorCard({
    super.key,
    required this.enigma,
    required this.enigmaIndex,
    required this.onEnigmaChanged,
    required this.onEnigmaDeleted,
  });

  @override
  State<EnigmaEditorCard> createState() => _EnigmaEditorCardState();
}

class _EnigmaEditorCardState extends State<EnigmaEditorCard> {
  late EnigmaModel _enigma;
  late final Map<String, TextEditingController> _controllers;

  Uint8List? _enigmaImageBytes;
  Uint8List? _hintFileBytes;

  @override
  void initState() {
    super.initState();
    _enigma = widget.enigma;
    _controllers = {
      'instruction': TextEditingController(text: _enigma.instruction),
      'code': TextEditingController(text: _enigma.code),
      'imageUrl': TextEditingController(text: _enigma.imageUrl ?? ''),
      'hintData': TextEditingController(text: _enigma.hintData ?? ''),
    };

    _controllers.forEach(
      (key, controller) => controller.addListener(_onChanged),
    );
  }

  @override
  void didUpdateWidget(covariant EnigmaEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enigma != oldWidget.enigma) {
      setState(() {
        _enigma = widget.enigma;
        _controllers['instruction']!.text = _enigma.instruction;
        _controllers['code']!.text = _enigma.code;
        _controllers['imageUrl']!.text = _enigma.imageUrl ?? '';
        _controllers['hintData']!.text = _enigma.hintData ?? '';
      });
    }
  }

  void _onChanged() {
    final updatedEnigma = EnigmaModel(
      id: _enigma.id,
      type: _enigma.type,
      hintType: _enigma.hintType,
      instruction: _controllers['instruction']!.text,
      code: _controllers['code']!.text,
      imageUrl: _controllers['imageUrl']!.text,
      hintData: _controllers['hintData']!.text,
    );
    widget.onEnigmaChanged(
      widget.enigmaIndex,
      updatedEnigma,
      _enigmaImageBytes,
      _hintFileBytes,
    );
  }

  Future<void> _pickFile(bool isEnigmaImage) async {
    FileType type = (_enigma.hintType == 'audio' && !isEnigmaImage)
        ? FileType.audio
        : FileType.image;
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: type);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        if (isEnigmaImage) {
          _enigmaImageBytes = result.files.single.bytes;
          _controllers['imageUrl']!.text = "Novo: ${result.files.single.name}";
        } else {
          _hintFileBytes = result.files.single.bytes;
          _controllers['hintData']!.text = "Novo: ${result.files.single.name}";
        }
      });
      _onChanged();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              value: _enigma.type,
              decoration: const InputDecoration(
                labelText: "Tipo de Enigma",
                border: OutlineInputBorder(),
              ),
              items: [
                'text',
                'photo_location',
                'qr_code_gps',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (newValue) => setState(
                () => _enigma = EnigmaModel(
                  id: _enigma.id,
                  type: newValue!,
                  instruction: _enigma.instruction,
                  code: _enigma.code,
                  imageUrl: _enigma.imageUrl,
                  hintType: _enigma.hintType,
                  hintData: _enigma.hintData,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers['instruction'],
              decoration: const InputDecoration(
                labelText: "Instrução / Pergunta",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers['code'],
              decoration: const InputDecoration(
                labelText: "Código de Resposta",
                border: OutlineInputBorder(),
              ),
            ),

            if (_enigma.type == 'photo_location' ||
                _enigma.type == 'qr_code_gps')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _FileUploadWidget(
                  label: "Imagem do Enigma",
                  pickedFileBytes: _enigmaImageBytes,
                  onPickFile: () => _pickFile(true),
                  urlController: _controllers['imageUrl']!,
                ),
              ),

            const Divider(height: 40, thickness: 1),
            const Text(
              "Dica (Opcional)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String?>(
              value: _enigma.hintType,
              decoration: const InputDecoration(
                labelText: "Tipo de Dica",
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("Nenhuma")),
                ...[
                  'photo',
                  'gps',
                  'audio',
                ].map((v) => DropdownMenuItem(value: v, child: Text(v))),
              ],
              onChanged: (newValue) => setState(
                () => _enigma = EnigmaModel(
                  id: _enigma.id,
                  type: _enigma.type,
                  instruction: _enigma.instruction,
                  code: _enigma.code,
                  imageUrl: _enigma.imageUrl,
                  hintType: newValue,
                ),
              ),
            ),

            if (_enigma.hintType == 'photo' || _enigma.hintType == 'audio')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _FileUploadWidget(
                  label: "Arquivo da Dica (${_enigma.hintType})",
                  pickedFileBytes: _hintFileBytes,
                  onPickFile: () => _pickFile(false),
                  urlController: _controllers['hintData']!,
                ),
              ),

            if (_enigma.hintType == 'gps')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextFormField(
                  controller: _controllers['hintData'],
                  decoration: const InputDecoration(
                    labelText: "Coordenadas GPS da Dica",
                    hintText: "-23.5714,-46.6669",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET AUXILIAR PARA UPLOAD (AGORA GLOBAL NO ARQUIVO) ---
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
              ? Image.memory(
                  pickedFileBytes!,
                  fit: BoxFit.contain,
                ) // Correção de nulo
              : (hasValidUrl
                    ? Image.network(
                        urlController.text,
                        fit: BoxFit.contain,
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
            labelText: "Ou cole uma URL aqui",
            hintText: "https://...",
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
