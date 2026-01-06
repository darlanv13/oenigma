import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/event_structure_screen.dart'; // Certifique-se que este import existe
import 'package:oenigma/admin/services/admin_service.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/utils/app_colors.dart';

class EventEditorScreen extends StatefulWidget {
  final EventModel? event; // Se nulo, é criação. Se preenchido, é edição.

  const EventEditorScreen({super.key, this.event});

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();

  // Controllers para campos básicos
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _prizeController;
  String _eventType = 'classic';
  String _status = 'open';

  // Variável local para armazenar o ID do evento (seja novo ou existente)
  String? _currentEventId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa o ID com o evento recebido (se houver)
    _currentEventId = widget.event?.id;

    // Inicializa com dados existentes ou vazios
    _nameController = TextEditingController(text: widget.event?.name ?? '');
    _descController = TextEditingController(
      text: widget.event?.fullDescription ?? '',
    );
    _priceController = TextEditingController(
      text: widget.event?.price.toString() ?? '0.0',
    );
    _prizeController = TextEditingController(text: widget.event?.prize ?? '');
    _eventType = widget.event?.eventType ?? 'classic';
    _status = widget.event?.status ?? 'open';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 1. Criar objeto EventModel (As listas phases/enigmas vão vazias pois são geridas separadamente)
    final eventToSave = EventModel(
      id: _currentEventId ?? '', // Usa o ID local ou vazio se for novo
      name: _nameController.text,
      prize: _prizeController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      icon: widget.event?.icon ?? 'default_icon',
      startDate: widget.event?.startDate ?? DateTime.now().toIso8601String(),
      location: 'Online',
      fullDescription: _descController.text,
      status: _status,
      eventType: _eventType,
      phases: [],
      enigmas: [],
    );

    // 2. Chamar serviço conectado às Cloud Functions
    try {
      // O método saveEvent no AdminService deve retornar o ID do evento (String)
      final newId = await _adminService.saveEvent(eventToSave);

      setState(() {
        _currentEventId = newId; // Atualiza o ID localmente
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Evento Salvo! Agora você pode gerenciar a estrutura.",
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Não damos pop() aqui para permitir que o usuário clique em "Gerenciar Fases"
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: Text(widget.event == null ? "Novo Evento" : "Editar Evento"),
        backgroundColor: cardColor,
        iconTheme: const IconThemeData(color: primaryAmber),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: primaryAmber),
            onPressed: _isLoading ? null : _saveEvent,
            tooltip: "Salvar Evento",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryAmber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Detalhes Básicos"),
                    const SizedBox(height: 16),

                    // Linha 1: Nome e Tipo
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            "Nome do Evento",
                            _nameController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _eventType,
                            dropdownColor: cardColor,
                            style: const TextStyle(color: textColor),
                            decoration: _inputDecoration("Tipo de Jogo"),
                            items: const [
                              DropdownMenuItem(
                                value: 'classic',
                                child: Text("Clássico (Fases)"),
                              ),
                              DropdownMenuItem(
                                value: 'find_and_win',
                                child: Text("Find & Win"),
                              ),
                            ],
                            onChanged: (v) => setState(() => _eventType = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Linha 2: Preço, Prêmio e Status
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Preço Inscrição (R\$)",
                            _priceController,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            "Prêmio (Texto)",
                            _prizeController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            dropdownColor: cardColor,
                            style: const TextStyle(color: textColor),
                            decoration: _inputDecoration("Status"),
                            items: const [
                              DropdownMenuItem(
                                value: 'open',
                                child: Text("Aberto"),
                              ),
                              DropdownMenuItem(
                                value: 'closed',
                                child: Text("Fechado/Encerrado"),
                              ),
                              DropdownMenuItem(
                                value: 'soon',
                                child: Text("Em Breve"),
                              ),
                            ],
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Descrição Completa",
                      _descController,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 40),
                    _buildSectionTitle("Estrutura do Jogo"),
                    const Text(
                      "Para adicionar Fases e Enigmas, salve o evento primeiro.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.schema),
                        label: const Text("Gerenciar Fases e Enigmas"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentEventId != null
                              ? Colors.blueGrey
                              : Colors.grey.withOpacity(0.2),
                          minimumSize: const Size(200, 50),
                        ),
                        // Só habilita o botão se já tivermos um ID (evento salvo no Firestore)
                        onPressed: _currentEventId == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventStructureScreen(
                                      eventId: _currentEventId!,
                                      eventType: _eventType,
                                    ),
                                  ),
                                );
                              },
                      ),
                    ),
                    if (_currentEventId == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Salve as alterações acima para liberar o gerenciador.",
                            style: TextStyle(color: primaryAmber, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: textColor),
      decoration: _inputDecoration(label),
      validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryAmber,
          ),
        ),
        const Divider(color: Colors.grey),
      ],
    );
  }
}
