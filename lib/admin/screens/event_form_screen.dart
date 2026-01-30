import 'package:flutter/material.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class EventFormScreen extends StatefulWidget {
  final EventModel? event;

  const EventFormScreen({super.key, this.event});

  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  int _currentStep = 0;

  late TextEditingController _nameController;
  late TextEditingController _prizeController;
  late TextEditingController _priceController;
  late TextEditingController _iconController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _startDateController;
  String _selectedEventType = 'classic';
  String _selectedStatus = 'dev';

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _nameController = TextEditingController(text: event?.name);
    _prizeController = TextEditingController(text: event?.prize);
    _priceController = TextEditingController(text: event?.price.toString());
    _iconController = TextEditingController(text: event?.icon);
    _descriptionController = TextEditingController(text: event?.fullDescription);
    _locationController = TextEditingController(text: event?.location);
    _startDateController = TextEditingController(text: event?.startDate);
    if (event != null) {
      _selectedEventType = event.eventType;
      _selectedStatus = event.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prizeController.dispose();
    _priceController.dispose();
    _iconController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final data = {
        'name': _nameController.text,
        'prize': _prizeController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'icon': _iconController.text,
        'fullDescription': _descriptionController.text,
        'location': _locationController.text,
        'startDate': _startDateController.text,
        'eventType': _selectedEventType,
        'status': _selectedStatus,
        'playerCount': widget.event?.playerCount ?? 0,
      };

      try {
        await _firebaseService.createOrUpdateEvent(
          eventId: widget.event?.id,
          data: data,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento salvo com sucesso!'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar evento: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  List<Step> _getSteps() {
    return [
      Step(
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 0,
        title: const Text("Informações Básicas"),
        content: Column(
          children: [
            _buildTextField(controller: _nameController, label: 'Nome do Evento'),
            _buildTextField(controller: _prizeController, label: 'Prêmio Total'),
            _buildTextField(controller: _priceController, label: 'Preço da Inscrição', keyboardType: TextInputType.number),
          ],
        ),
      ),
      Step(
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 1,
        title: const Text("Detalhes"),
        content: Column(
          children: [
            _buildTextField(controller: _descriptionController, label: 'Descrição Completa', maxLines: 5),
            _buildTextField(controller: _iconController, label: 'URL da Animação Lottie'),
          ],
        ),
      ),
      Step(
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 2,
        title: const Text("Configurações"),
        content: Column(
          children: [
            _buildTextField(controller: _locationController, label: 'Localização (Cidade, Estado)'),
            _buildTextField(controller: _startDateController, label: 'Data de Início (dd/MM/yyyy)'),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Tipo de Evento',
              value: _selectedEventType,
              items: const [
                DropdownMenuItem(value: 'classic', child: Text('Clássico (com fases)')),
                DropdownMenuItem(value: 'find_and_win', child: Text('Find and Win (enigmas diretos)')),
              ],
              onChanged: (value) => setState(() => _selectedEventType = value!),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Status do Evento',
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: 'dev', child: Text('Em Desenvolvimento')),
                DropdownMenuItem(value: 'open', child: Text('Aberto para Inscrições')),
                DropdownMenuItem(value: 'closed', child: Text('Fechado')),
              ],
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event == null ? 'Criar Novo Evento' : 'Editar Evento')),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < _getSteps().length - 1) {
              setState(() => _currentStep += 1);
            } else {
              _saveEvent();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          controlsBuilder: (context, details) {
             return Padding(
               padding: const EdgeInsets.only(top: 20.0),
               child: Row(
                 children: [
                   ElevatedButton(
                     onPressed: _isLoading ? null : details.onStepContinue,
                     child: _isLoading && _currentStep == 2
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_currentStep == 2 ? 'Salvar Evento' : 'Continuar'),
                   ),
                   const SizedBox(width: 12),
                   if (_currentStep > 0)
                     TextButton(
                       onPressed: _isLoading ? null : details.onStepCancel,
                       child: const Text('Voltar', style: TextStyle(color: Colors.white)),
                     ),
                 ],
               ),
             );
          },
          steps: _getSteps(),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: secondaryTextColor),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey))
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (v) => v!.isEmpty ? 'Este campo é obrigatório' : null,
      ),
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: cardColor,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: secondaryTextColor),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey))
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
