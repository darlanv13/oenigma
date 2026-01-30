// lib/admin/screens/enigma_form_screen.dart

import 'package:flutter/material.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnigmaFormScreen extends StatefulWidget {
  final String eventId;
  final String? phaseId;
  final String eventType;
  final EnigmaModel? enigma;

  const EnigmaFormScreen({
    super.key,
    required this.eventId,
    required this.eventType,
    this.phaseId,
    this.enigma,
  });

  @override
  _EnigmaFormScreenState createState() => _EnigmaFormScreenState();
}

class _EnigmaFormScreenState extends State<EnigmaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  // Controladores
  late TextEditingController _instructionController;
  late TextEditingController _codeController;
  late TextEditingController _imageUrlController;
  late TextEditingController _hintDataController;
  late TextEditingController _prizeController;
  late TextEditingController _orderController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  String _selectedEnigmaType = 'text';
  String? _selectedHintType;

  @override
  void initState() {
    super.initState();
    final enigma = widget.enigma;

    _instructionController = TextEditingController(text: enigma?.instruction);
    _codeController = TextEditingController(text: enigma?.code);
    _imageUrlController = TextEditingController(text: enigma?.imageUrl);
    _hintDataController = TextEditingController(text: enigma?.hintData);
    _prizeController = TextEditingController(
      text: enigma?.prize.toString() ?? '0.0',
    );
    _orderController = TextEditingController(
      text: enigma?.order.toString() ?? '1',
    );

    _latitudeController = TextEditingController(
      text: enigma?.location?.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: enigma?.location?.longitude.toString(),
    );

    if (enigma != null) {
      _selectedEnigmaType = enigma.type;
      _selectedHintType = enigma.hintType;
    }
  }

  @override
  void dispose() {
    // Limpeza de todos os controladores
    _instructionController.dispose();
    _codeController.dispose();
    _imageUrlController.dispose();
    _hintDataController.dispose();
    _prizeController.dispose();
    _orderController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _saveEnigma() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // --- CORREÇÃO APLICADA AQUI ---
      // Em vez de um objeto GeoPoint, criamos um Mapa simples que pode ser enviado.
      Map<String, double>? locationData;
      if (_selectedEnigmaType == 'qr_code_gps') {
        final lat = double.tryParse(_latitudeController.text);
        final lon = double.tryParse(_longitudeController.text);
        if (lat != null && lon != null) {
          // Criamos um mapa com chaves que o backend irá reconhecer.
          locationData = {'_latitude': lat, '_longitude': lon};
        }
      }
      // -----------------------------

      final data = {
        'instruction': _instructionController.text,
        'code': _codeController.text,
        'type': _selectedEnigmaType,
        'order': int.tryParse(_orderController.text) ?? 1,
        'prize': double.tryParse(_prizeController.text) ?? 0.0,
        'imageUrl': _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text
            : null,
        'hintType': _selectedHintType,
        'hintData': _hintDataController.text.isNotEmpty
            ? _hintDataController.text
            : null,
        'location': locationData, // Enviamos o mapa ou nulo
      };

      try {
        await _firebaseService.createOrUpdateEnigma(
          eventId: widget.eventId,
          phaseId: widget.phaseId,
          enigmaId: widget.enigma?.id,
          data: data,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enigma salvo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar enigma: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.enigma == null ? 'Criar Enigma' : 'Editar Enigma'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle("Informações do Enigma"),
                  _buildTextField(
                    controller: _instructionController,
                    label: 'Instrução / Pergunta',
                    maxLines: 5,
                  ),
                  _buildTextField(
                    controller: _codeController,
                    label: 'Código / Resposta Correta',
                  ),
                  _buildTextField(
                    controller: _orderController,
                    label: 'Ordem',
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    controller: _imageUrlController,
                    label: 'URL da Imagem (Opcional)',
                  ),
                  if (widget.eventType == 'find_and_win')
                    _buildTextField(
                      controller: _prizeController,
                      label: 'Prêmio deste Enigma',
                      keyboardType: TextInputType.number,
                    ),
                  _buildDropdown(
                    label: 'Tipo de Enigma',
                    value: _selectedEnigmaType,
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('Texto')),
                      DropdownMenuItem(
                        value: 'photo_location',
                        child: Text('Localização por Foto'),
                      ),
                      DropdownMenuItem(
                        value: 'qr_code_gps',
                        child: Text('QR Code com GPS'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedEnigmaType = value!),
                  ),
                  if (_selectedEnigmaType == 'qr_code_gps') ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle("Coordenadas GPS"),
                    _buildTextField(
                      controller: _latitudeController,
                      label: 'Latitude',
                      keyboardType: TextInputType.number,
                    ),
                    _buildTextField(
                      controller: _longitudeController,
                      label: 'Longitude',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionTitle("Dica (Opcional)"),
                  _buildDropdown(
                    label: 'Tipo de Dica',
                    value: _selectedHintType,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Nenhuma')),
                      DropdownMenuItem(value: 'text', child: Text('Texto')),
                      DropdownMenuItem(
                        value: 'photo',
                        child: Text('Foto (URL)'),
                      ),
                      DropdownMenuItem(
                        value: 'gps',
                        child: Text('Coordenadas GPS'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedHintType = value),
                  ),
                  if (_selectedHintType != null)
                    _buildTextField(
                      controller: _hintDataController,
                      label: 'Conteúdo da Dica',
                      maxLines: 3,
                    ),

                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _saveEnigma,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar Enigma'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          alignLabelWithHint: true,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (v) {
          // A instrução e o código são sempre obrigatórios
          if (label.contains('Instrução') || label.contains('Código')) {
            if (v == null || v.isEmpty) return 'Este campo é obrigatório';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String?>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
