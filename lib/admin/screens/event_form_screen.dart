import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'package:oenigma/widgets/lottie_dialog.dart';

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
    _descriptionController = TextEditingController(
      text: event?.fullDescription,
    );
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
          await LottieDialog.show(
            context,
            assetPath: 'assets/animations/check.json',
            message: 'Evento Salvo!',
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar evento: $e'),
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryAmber,
              onPrimary: darkBackground,
              onSurface: textColor,
            ),
            dialogBackgroundColor: cardColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
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
            _buildTextField(
              controller: _nameController,
              label: 'Nome do Evento',
              prefixIcon: Icons.event,
            ),
            _buildTextField(
              controller: _prizeController,
              label: 'Prêmio Total',
              prefixIcon: Icons.emoji_events,
            ),
            _buildTextField(
              controller: _priceController,
              label: 'Preço da Inscrição',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Campo obrigatório';
                final n = double.tryParse(val);
                if (n == null || n < 0) return 'Digite um valor válido >= 0';
                return null;
              },
            ),
          ],
        ),
      ),
      Step(
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 1,
        title: const Text("Detalhes"),
        content: Column(
          children: [
            _buildTextField(
              controller: _descriptionController,
              label: 'Descrição Completa',
              prefixIcon: Icons.description,
              maxLines: 5,
            ),
            _buildTextField(
              controller: _iconController,
              label: 'URL da Animação Lottie',
              prefixIcon: Icons.animation,
              helperText: 'Insira a URL do arquivo JSON do Lottie',
            ),
          ],
        ),
      ),
      Step(
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 2,
        title: const Text("Configurações"),
        content: Column(
          children: [
            _buildTextField(
              controller: _locationController,
              label: 'Localização (Cidade, Estado)',
              prefixIcon: Icons.location_on,
            ),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: _buildTextField(
                  controller: _startDateController,
                  label: 'Data de Início (dd/MM/yyyy)',
                  prefixIcon: Icons.calendar_today,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Tipo de Evento',
              value: _selectedEventType,
              items: const [
                DropdownMenuItem(
                  value: 'classic',
                  child: Text('Clássico (com fases)'),
                ),
                DropdownMenuItem(
                  value: 'find_and_win',
                  child: Text('Find and Win (enigmas diretos)'),
                ),
              ],
              onChanged: (value) => setState(() => _selectedEventType = value!),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Status do Evento',
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(
                  value: 'dev',
                  child: Text('Em Desenvolvimento'),
                ),
                DropdownMenuItem(
                  value: 'open',
                  child: Text('Aberto para Inscrições'),
                ),
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
      appBar: AppBar(
        title: Text(
          widget.event == null ? 'Criar Novo Evento' : 'Editar Evento',
        ),
      ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      foregroundColor: darkBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading && _currentStep == 2
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: darkBackground,
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? 'Salvar Evento' : 'Continuar',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _isLoading ? null : details.onStepCancel,
                      child: const Text(
                        'Voltar',
                        style: TextStyle(color: secondaryTextColor),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: secondaryTextColor),
          helperText: helperText,
          helperStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
          filled: true,
          fillColor: cardColor,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: primaryAmber)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryAmber),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator:
            validator ?? (v) => v!.isEmpty ? 'Este campo é obrigatório' : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryAmber),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
