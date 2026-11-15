import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/admin_modal.dart';
import 'package:oenigma/creator_studio/features/creator/utils/creator_tenant_util.dart';

class CreatorHintsScreen extends StatefulWidget {
  const CreatorHintsScreen({super.key});

  @override
  State<CreatorHintsScreen> createState() => _CreatorHintsScreenState();
}

class _CreatorHintsScreenState extends State<CreatorHintsScreen> {
  List<ParseObject> _events = [];
  String? _selectedEventId;
  List<ParseObject> _enigmas = [];
  String? _selectedEnigmaId;
  List<ParseObject> _hints = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final query = QueryBuilder<ParseObject>(ParseObject('Event'))
      ..orderByDescending('createdAt');
    final scopedQuery = await CreatorTenantUtil.scopeEventQuery(query);
    final response = await scopedQuery.query();
    if (mounted) {
      if (response.success && response.results != null) {
        _events = List<ParseObject>.from(response.results!);
        if (_events.isNotEmpty) {
          _selectedEventId = _events.first.objectId;
          await _loadEnigmas(_selectedEventId!);
        } else {
          _selectedEventId = null;
          _enigmas = [];
          _hints = [];
        }
      } else {
        _events = [];
        _selectedEventId = null;
        _enigmas = [];
        _hints = [];
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEnigmas(String eventId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
      ..whereEqualTo('eventId', eventId)
      ..orderByAscending('order');
    final response = await query.query();
    if (mounted) {
      if (response.success && response.results != null) {
        _enigmas = List<ParseObject>.from(response.results!);
        _selectedEnigmaId = _enigmas.isNotEmpty ? _enigmas.first.objectId : null;
        if (_selectedEnigmaId != null) {
          await _loadHints(_selectedEnigmaId!);
        } else {
          setState(() => _hints = []);
        }
      } else {
        setState(() {
          _enigmas = [];
          _selectedEnigmaId = null;
          _hints = [];
        });
      }
    }
  }

  Future<void> _loadHints(String enigmaId) async {
    setState(() => _isLoading = true);
    final query = QueryBuilder<ParseObject>(ParseObject('Hint'))
      ..whereEqualTo('enigmaId', enigmaId)
      ..orderByAscending('order');
    final response = await query.query();
    if (mounted) {
      if (response.success && response.results != null) {
        _hints = List<ParseObject>.from(response.results!);
      } else {
        _hints = [];
      }
      setState(() => _isLoading = false);
    }
  }

  void _showAddHintDialog({ParseObject? hintToEdit}) {
    if (_selectedEnigmaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um enigma primeiro.')),
      );
      return;
    }

    final isEditing = hintToEdit != null;
    final titleController = TextEditingController(
      text: hintToEdit?.get<String>('title') ?? 'Dica ${_hints.length + 1}',
    );
    final descController = TextEditingController(
      text: hintToEdit?.get<String>('text') ?? hintToEdit?.get<String>('description') ?? '',
    );
    final priceController = TextEditingController(
      text: (hintToEdit?.get<num>('price') ?? 0.0).toString(),
    );
    final orderController = TextEditingController(
      text: (hintToEdit?.get<num>('order') ?? (_hints.length + 1)).toString(),
    );
    String hintType = hintToEdit?.get<String>('type') ?? 'text'; // text, audio, image, coordinate

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AdminModal(
          title: isEditing ? 'Editar Dica' : 'Criar Nova Dica',
          icon: FontAwesomeIcons.lightbulb,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título da Dica (Ex: Primeira Pista)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: hintType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Dica',
                  border: OutlineInputBorder(),
                ),
                dropdownColor: AppColors.darkCardColor,
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Texto / Charada')),
                  DropdownMenuItem(value: 'coordinate', child: Text('Aproximação no Mapa')),
                  DropdownMenuItem(value: 'audio', child: Text('Mensagem de Áudio')),
                  DropdownMenuItem(value: 'image', child: Text('Imagem / Pista Visual')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => hintType = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo da Dica / Pista Secreta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Preço (R\$ ou 0 para Grátis)',
                        border: OutlineInputBorder(),
                        prefixText: 'R\$ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nível / Ordem (1, 2, 3)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdeVale,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final text = descController.text.trim();
                      final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
                      final order = int.tryParse(orderController.text.trim()) ?? 1;

                      if (title.isEmpty || text.isEmpty) return;

                      Navigator.pop(ctx);
                      final hintObj = hintToEdit ?? ParseObject('Hint');
                      hintObj.set('title', title);
                      hintObj.set('text', text);
                      hintObj.set('description', text);
                      hintObj.set('type', hintType);
                      hintObj.set('price', price);
                      hintObj.set('order', order);
                      hintObj.set('enigmaId', _selectedEnigmaId);
                      hintObj.set('eventId', _selectedEventId);

                      await hintObj.save();
                      if (_selectedEnigmaId != null) {
                        await _loadHints(_selectedEnigmaId!);
                      }
                    },
                    child: Text(isEditing ? 'Salvar' : 'Criar Dica'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteHint(ParseObject hint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        title: const Text('Excluir Dica?'),
        content: Text('Deseja excluir a dica "${hint.get<String>('title')}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await hint.delete();
      if (_selectedEnigmaId != null) {
        await _loadHints(_selectedEnigmaId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildSelectors(),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hints.isEmpty
                  ? _buildEmptyState()
                  : _buildHintsList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dicas Estratégicas (Hints)',
              style: GoogleFonts.cinzel(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Configure pistas progressivas e defina os valores de desbloqueio.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.cinzaMedio,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _selectedEnigmaId == null ? null : () => _showAddHintDialog(),
          icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
          label: const Text('Nova Dica'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amareloVale,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectors() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: AppColors.darkCardColor,
              value: _selectedEventId,
              hint: const Text('1. Selecione o Evento'),
              items: _events.map((e) {
                return DropdownMenuItem<String>(
                  value: e.objectId,
                  child: Text('🎯 Evento: ${e.get<String>('title') ?? 'Sem título'}'),
                );
              }).toList(),
              onChanged: (newId) {
                if (newId != null) {
                  setState(() => _selectedEventId = newId);
                  _loadEnigmas(newId);
                }
              },
            ),
          ),
          if (_enigmas.isNotEmpty) ...[
            const Divider(color: Colors.white10),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: AppColors.darkCardColor,
                value: _selectedEnigmaId,
                hint: const Text('2. Selecione o Enigma'),
                items: _enigmas.map((en) {
                  final order = en.get<num>('order') ?? 1;
                  final title = en.get<String>('title') ?? 'Sem título';
                  return DropdownMenuItem<String>(
                    value: en.objectId,
                    child: Text('🧩 Enigma #$order: $title'),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null) {
                    setState(() => _selectedEnigmaId = newId);
                    _loadHints(newId);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.lightbulb, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            _selectedEnigmaId == null
                ? 'Selecione um evento e um enigma para visualizar as dicas'
                : 'Nenhuma dica cadastrada para este enigma',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dicas auxiliam jogadores travados e aumentam o engajamento e monetização.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHintsList() {
    return ListView.separated(
      itemCount: _hints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final hint = _hints[index];
        final title = hint.get<String>('title') ?? 'Dica ${index + 1}';
        final text = hint.get<String>('text') ?? hint.get<String>('description') ?? '';
        final price = (hint.get<num>('price') ?? 0.0).toDouble();
        final type = hint.get<String>('type') ?? 'text';
        final order = hint.get<num>('order') ?? (index + 1);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.amareloVale.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
                ),
                child: const Center(
                  child: FaIcon(FontAwesomeIcons.lightbulb, color: AppColors.amareloVale, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Nível $order: $title',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: price > 0 ? AppColors.verdeVale.withValues(alpha: 0.2) : Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            price > 0 ? 'R\$ ${price.toStringAsFixed(2)}' : 'GRÁTIS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: price > 0 ? AppColors.verdeVale : Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 15, color: Colors.white70),
                onPressed: () => _showAddHintDialog(hintToEdit: hint),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.trashCan, size: 15, color: AppColors.danger),
                onPressed: () => _deleteHint(hint),
              ),
            ],
          ),
        );
      },
    );
  }
}
