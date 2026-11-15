import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/admin_modal.dart';
import 'package:oenigma/creator_studio/features/creator/utils/creator_tenant_util.dart';

class CreatorPhasesScreen extends StatefulWidget {
  final String? initialEventId;

  const CreatorPhasesScreen({super.key, this.initialEventId});

  @override
  State<CreatorPhasesScreen> createState() => _CreatorPhasesScreenState();
}

class _CreatorPhasesScreenState extends State<CreatorPhasesScreen> {
  List<ParseObject> _events = [];
  String? _selectedEventId;
  bool _isLoadingEvents = true;

  List<ParseObject> _phases = [];
  bool _isLoadingPhases = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    final query = QueryBuilder<ParseObject>(ParseObject('Event'))
      ..orderByDescending('createdAt');
    final scopedQuery = await CreatorTenantUtil.scopeEventQuery(query);
    final response = await scopedQuery.query();
    if (mounted) {
      if (response.success && response.results != null) {
        _events = List<ParseObject>.from(response.results!);
        if (widget.initialEventId != null &&
            _events.any((e) => e.objectId == widget.initialEventId)) {
          _selectedEventId = widget.initialEventId;
        } else if (_events.isNotEmpty) {
          _selectedEventId = _events.first.objectId;
        } else {
          _selectedEventId = null;
          _phases = [];
        }
        if (_selectedEventId != null) {
          await _loadPhases(_selectedEventId!);
        }
      } else {
        _events = [];
        _selectedEventId = null;
        _phases = [];
      }
      setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _loadPhases(String eventId) async {
    setState(() => _isLoadingPhases = true);
    final query = QueryBuilder<ParseObject>(ParseObject('Phase'))
      ..whereEqualTo('eventId', eventId)
      ..orderByAscending('order');
    final response = await query.query();
    if (mounted) {
      if (response.success && response.results != null) {
        _phases = List<ParseObject>.from(response.results!);
      } else {
        _phases = [];
      }
      setState(() => _isLoadingPhases = false);
    }
  }

  void _showAddPhaseDialog({ParseObject? phaseToEdit}) {
    if (_selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um evento primeiro.')),
      );
      return;
    }

    final isEditing = phaseToEdit != null;
    final titleController = TextEditingController(
      text: phaseToEdit?.get<String>('title') ??
          'Fase ${_phases.length + 1}',
    );
    final descController = TextEditingController(
      text: phaseToEdit?.get<String>('description') ?? '',
    );
    final orderController = TextEditingController(
      text: (phaseToEdit?.get<num>('order') ?? (_phases.length + 1)).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AdminModal(
        title: isEditing ? 'Editar Fase' : 'Nova Fase da Trilha',
        icon: FontAwesomeIcons.layerGroup,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Título da Fase (Ex: O Início do Labirinto)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Instruções ou Tema da Fase',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ordem de Desbloqueio (1, 2, 3...)',
                border: OutlineInputBorder(),
              ),
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
                    final order = int.tryParse(orderController.text.trim()) ?? 1;
                    if (title.isEmpty) return;

                    Navigator.pop(ctx);
                    final phaseObj = phaseToEdit ?? ParseObject('Phase');
                    phaseObj.set('title', title);
                    phaseObj.set('description', descController.text.trim());
                    phaseObj.set('order', order);
                    phaseObj.set('eventId', _selectedEventId);

                    await phaseObj.save();
                    if (_selectedEventId != null) {
                      await _loadPhases(_selectedEventId!);
                    }
                  },
                  child: Text(isEditing ? 'Salvar' : 'Criar Fase'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhase(ParseObject phase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        title: const Text('Excluir Fase?'),
        content: Text(
          'Deseja excluir "${phase.get<String>('title')}"? Os enigmas vinculados deverão ser reatribuídos.',
        ),
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
      await phase.delete();
      if (_selectedEventId != null) {
        await _loadPhases(_selectedEventId!);
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
        _buildEventSelector(),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoadingPhases
              ? const Center(child: CircularProgressIndicator())
              : _phases.isEmpty
                  ? _buildEmptyState()
                  : _buildPhasesList(),
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
              'Trilha de Fases',
              style: GoogleFonts.cinzel(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Estruture a progressão dos caçadores ao longo do evento.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.cinzaMedio,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _selectedEventId == null ? null : () => _showAddPhaseDialog(),
          icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
          label: const Text('Nova Fase'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verdeVale,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildEventSelector() {
    if (_isLoadingEvents) {
      return const LinearProgressIndicator();
    }
    if (_events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Nenhum evento encontrado. Crie um evento primeiro na aba Eventos.',
          style: TextStyle(color: AppColors.amareloVale),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: AppColors.darkCardColor,
          value: _selectedEventId,
          hint: const Text('Selecione o Evento para gerenciar as Fases'),
          items: _events.map((e) {
            final title = e.get<String>('title') ?? 'Sem título';
            final status = e.get<String>('status') ?? 'draft';
            return DropdownMenuItem<String>(
              value: e.objectId,
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.calendarDay, size: 14, color: AppColors.amareloVale),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text('($status)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            );
          }).toList(),
          onChanged: (newId) {
            if (newId != null) {
              setState(() => _selectedEventId = newId);
              _loadPhases(newId);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.layerGroup, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'Nenhuma fase cadastrada para este evento',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clique no botão "+ Nova Fase" para adicionar a primeira etapa da aventura.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPhasesList() {
    return ListView.separated(
      itemCount: _phases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final phase = _phases[index];
        final title = phase.get<String>('title') ?? 'Fase ${index + 1}';
        final desc = phase.get<String>('description') ?? '';
        final order = phase.get<num>('order') ?? (index + 1);

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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.verdeVale),
                ),
                child: Center(
                  child: Text(
                    '$order',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.amareloVale,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 15, color: Colors.white70),
                onPressed: () => _showAddPhaseDialog(phaseToEdit: phase),
                tooltip: 'Editar Fase',
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.trashCan, size: 15, color: AppColors.danger),
                onPressed: () => _deletePhase(phase),
                tooltip: 'Excluir Fase',
              ),
            ],
          ),
        );
      },
    );
  }
}
