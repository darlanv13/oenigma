import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';

/// Tela de Moderação e Auditoria de Eventos no Painel Mestre
///
/// Todas as funções de criação de desafios, fases e enigmas pertencem ao Creator Studio.
/// Esta tela fornece controle de plataforma: auditoria, moderação de status,
/// visualização de métricas de engajamento e combate a fraudes.
class AdminEventsScreen extends StatefulWidget {
  final Function(String eventId)? onInspectEvent;

  const AdminEventsScreen({super.key, this.onInspectEvent});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  bool _isLoading = true;
  List<ParseObject> _events = [];
  List<ParseObject> _filteredEvents = [];

  final _searchController = TextEditingController();
  String _statusFilter = 'todos'; // 'todos', 'open', 'em_breve', 'paused', 'encerrado'

  // KPIs da Plataforma
  int _totalEvents = 0;
  int _activeEvents = 0;
  int _pausedEvents = 0;
  int _closedEvents = 0;
  double _totalPrizePool = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Event'))
        ..orderByDescending('createdAt')
        ..setLimit(200);

      final response = await query.query();
      if (response.success && response.results != null) {
        _events = List<ParseObject>.from(response.results!);
      } else {
        _events = [];
      }

      _calculateKPIs();
      _applyFilter();
    } catch (e) {
      debugPrint('Erro ao carregar eventos para moderação: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateKPIs() {
    _totalEvents = _events.length;
    _activeEvents = 0;
    _pausedEvents = 0;
    _closedEvents = 0;
    _totalPrizePool = 0.0;

    for (var ev in _events) {
      final status = (ev.get<String>('status') ?? 'open').toLowerCase();
      if (status == 'open' || status == 'ativo') {
        _activeEvents++;
      } else if (status == 'paused' || status == 'pausado') {
        _pausedEvents++;
      } else if (status == 'encerrado' || status == 'finalizado' || status == 'closed') {
        _closedEvents++;
      }

      final prize = (ev.get<num>('prizeAmount') ?? ev.get<num>('premio') ?? 0.0).toDouble();
      _totalPrizePool += prize;
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredEvents = _events.where((ev) {
        final title = (ev.get<String>('title') ?? '').toLowerCase();
        final slug = (ev.get<String>('slug') ?? '').toLowerCase();
        final creatorName = (ev.get<String>('creatorName') ?? '').toLowerCase();
        final creatorId = (ev.get<String>('creatorId') ?? '').toLowerCase();
        final status = (ev.get<String>('status') ?? 'open').toLowerCase();

        final matchesQuery = query.isEmpty ||
            title.contains(query) ||
            slug.contains(query) ||
            creatorName.contains(query) ||
            creatorId.contains(query);

        final matchesStatus = _statusFilter == 'todos' ||
            (_statusFilter == 'open' && (status == 'open' || status == 'ativo')) ||
            (_statusFilter == 'paused' && (status == 'paused' || status == 'pausado')) ||
            (_statusFilter == 'encerrado' &&
                (status == 'encerrado' || status == 'finalizado' || status == 'closed')) ||
            (_statusFilter == 'em_breve' && status == 'em_breve');

        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  Future<void> _updateEventStatus(ParseObject event, String newStatus) async {
    event.set('status', newStatus);
    final response = await event.save();
    if (response.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status atualizado para: ${newStatus.toUpperCase()}'),
            backgroundColor: AppColors.verdeVale,
          ),
        );
      }
      _loadEvents();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: ${response.error?.message}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteEvent(ParseObject event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirmar Exclusão',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Deseja realmente remover o evento "${event.get<String>('title') ?? 'Sem Título'}" da plataforma?\nEsta ação não poderá ser desfeita.',
          style: GoogleFonts.poppins(color: AppColors.cinzaClaro, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: AppColors.cinzaMedio)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Excluir', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await event.delete();
      if (res.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evento removido com sucesso.'),
              backgroundColor: AppColors.verdeVale,
            ),
          );
        }
        _loadEvents();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha ao remover: ${res.error?.message}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _showEventAuditModal(ParseObject event) {
    final title = event.get<String>('title') ?? 'Sem Título';
    final slug = event.get<String>('slug') ?? event.objectId ?? '';
    final creatorName = event.get<String>('creatorName') ?? 'Criador Oficial';
    final creatorId = event.get<String>('creatorId') ?? 'Plataforma';
    final price = (event.get<num>('price') ?? event.get<num>('entryFee') ?? 0.0).toDouble();
    final prize = (event.get<num>('prizeAmount') ?? event.get<num>('premio') ?? 0.0).toDouble();
    final status = (event.get<String>('status') ?? 'open').toUpperCase();
    final description = event.get<String>('description') ?? 'Sem descrição detalhada.';
    final bannerUrl = event.get<String>('bannerUrl') ?? event.get<String>('imageUrl') ?? '';
    final createdAt = event.createdAt != null
        ? '${event.createdAt!.day.toString().padLeft(2, '0')}/${event.createdAt!.month.toString().padLeft(2, '0')}/${event.createdAt!.year}'
        : '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.darkCardBorder)),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.shieldHalved, color: AppColors.amareloVale, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Auditoria de Moderação: $title',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bannerUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          bannerUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 120,
                            color: AppColors.darkBackground,
                            child: const Center(
                              child: Icon(Icons.broken_image, color: AppColors.cinzaMedio),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildAuditField('ID do Evento', event.objectId ?? '-'),
                    _buildAuditField('Slug Público', slug),
                    _buildAuditField('Criador / Tenant', '$creatorName ($creatorId)'),
                    _buildAuditField('Status Atual', status),
                    _buildAuditField(
                      'Preço do Ingresso',
                      price == 0 ? 'Gratuito (Free)' : 'R\$ ${price.toStringAsFixed(2)}',
                    ),
                    _buildAuditField('Prêmio ao Vencedor', 'R\$ ${prize.toStringAsFixed(2)}'),
                    _buildAuditField('Data de Criação', createdAt),
                    const SizedBox(height: 12),
                    Text(
                      'Descrição / Lore do Desafio:',
                      style: GoogleFonts.poppins(
                        color: AppColors.cinzaMedio,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkCardBorder),
                      ),
                      child: Text(
                        description,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ações Rápidas de Moderação:',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateEventStatus(event, 'open');
                          },
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Ativar Desafio'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.verdeVale),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateEventStatus(event, 'paused');
                          },
                          icon: const Icon(Icons.pause, size: 16),
                          label: const Text('Pausar Temporariamente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.amareloVale,
                            foregroundColor: Colors.black,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateEventStatus(event, 'encerrado');
                          },
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('Encerrar Desafio'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteEvent(event);
                          },
                          icon: const Icon(Icons.delete_forever, size: 16),
                          label: const Text('Remover da Plataforma'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildKPIs(),
          const SizedBox(height: 16),
          _buildFilterBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildEventsList()),
        ],
      ),
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
              'Moderação de Eventos da Plataforma',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Audite todos os desafios dos criadores, pause conteúdos suspeitos ou encerre competições.',
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontSize: 12,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: _loadEvents,
          icon: const Icon(Icons.refresh, color: AppColors.amareloVale),
          tooltip: 'Atualizar Lista',
        ),
      ],
    );
  }

  Widget _buildKPIs() {
    return Row(
      children: [
        _buildKpiCard('Total de Eventos', '$_totalEvents', FontAwesomeIcons.trophy, AppColors.info),
        const SizedBox(width: 12),
        _buildKpiCard('Eventos Ativos', '$_activeEvents', FontAwesomeIcons.circlePlay, AppColors.verdeVale),
        const SizedBox(width: 12),
        _buildKpiCard('Pausados', '$_pausedEvents', FontAwesomeIcons.circlePause, AppColors.amareloVale),
        const SizedBox(width: 12),
        _buildKpiCard('Encerrados', '$_closedEvents', FontAwesomeIcons.flagCheckered, AppColors.cinzaMedio),
        const SizedBox(width: 12),
        _buildKpiCard(
          'Total em Prêmios',
          'R\$ ${_totalPrizePool.toStringAsFixed(0)}',
          FontAwesomeIcons.sackDollar,
          AppColors.amareloValeDark,
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, dynamic icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.darkCardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 10.5),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: AppColors.cinzaMedio, size: 18),
                hintText: 'Buscar por título, slug ou ID do criador...',
                hintStyle: TextStyle(color: AppColors.cinzaMedio, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.darkCardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              dropdownColor: AppColors.sidebarBackground,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos os Status')),
                DropdownMenuItem(value: 'open', child: Text('Apenas Ativos')),
                DropdownMenuItem(value: 'paused', child: Text('Pausados')),
                DropdownMenuItem(value: 'em_breve', child: Text('Em Breve')),
                DropdownMenuItem(value: 'encerrado', child: Text('Encerrados')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _statusFilter = val);
                  _applyFilter();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.verdeVale),
      );
    }

    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.folderOpen, color: AppColors.cinzaMedio, size: 40),
            const SizedBox(height: 12),
            Text(
              'Nenhum evento encontrado com os filtros atuais.',
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredEvents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final ev = _filteredEvents[index];
        return _buildEventModerationTile(ev);
      },
    );
  }

  Widget _buildEventModerationTile(ParseObject ev) {
    final title = ev.get<String>('title') ?? 'Sem Título';
    final slug = ev.get<String>('slug') ?? ev.objectId ?? '';
    final creatorName = ev.get<String>('creatorName') ?? 'Criador Oficial';
    final price = (ev.get<num>('price') ?? ev.get<num>('entryFee') ?? 0.0).toDouble();
    final prize = (ev.get<num>('prizeAmount') ?? ev.get<num>('premio') ?? 0.0).toDouble();
    final status = (ev.get<String>('status') ?? 'open').toLowerCase();

    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'open':
      case 'ativo':
        statusColor = AppColors.verdeVale;
        statusLabel = 'ATIVO';
        break;
      case 'paused':
      case 'pausado':
        statusColor = AppColors.amareloVale;
        statusLabel = 'PAUSADO';
        break;
      case 'encerrado':
      case 'finalizado':
      case 'closed':
        statusColor = AppColors.cinzaMedio;
        statusLabel = 'ENCERRADO';
        break;
      case 'em_breve':
        statusColor = AppColors.info;
        statusLabel = 'EM BREVE';
        break;
      default:
        statusColor = AppColors.cinzaMedio;
        statusLabel = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(FontAwesomeIcons.trophy, color: statusColor, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          color: statusColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Slug: /$slug',
                      style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '• Criador: $creatorName',
                      style: GoogleFonts.poppins(color: AppColors.cinzaClaro, fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      price == 0 ? '• Gratuito' : '• Ingresso: R\$ ${price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(color: AppColors.amareloVale, fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '• Prêmio: R\$ ${prize.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(color: AppColors.verdeVale, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Ações Rápidas de Moderação
          IconButton(
            onPressed: () => _showEventAuditModal(ev),
            icon: const Icon(Icons.info_outline, color: AppColors.info, size: 20),
            tooltip: 'Auditoria & Detalhes',
          ),
          if (status == 'open' || status == 'ativo')
            IconButton(
              onPressed: () => _updateEventStatus(ev, 'paused'),
              icon: const Icon(Icons.pause_circle_outline, color: AppColors.amareloVale, size: 20),
              tooltip: 'Pausar Desafio',
            )
          else
            IconButton(
              onPressed: () => _updateEventStatus(ev, 'open'),
              icon: const Icon(Icons.play_circle_outline, color: AppColors.verdeVale, size: 20),
              tooltip: 'Ativar Desafio',
            ),
          IconButton(
            onPressed: () => _deleteEvent(ev),
            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
            tooltip: 'Remover',
          ),
        ],
      ),
    );
  }
}
