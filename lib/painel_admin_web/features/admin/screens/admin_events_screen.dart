import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/admin_item_card.dart';
import 'package:oenigma/core/widgets/admin_modal.dart';
import 'package:oenigma/painel_admin_web/features/admin/utils/admin_upload_util.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  Future<List<ParseObject>>? _eventsFuture;
  ParseObject? _selectedEvent;

  // Filtros da Listagem de Eventos
  final TextEditingController _searchController = TextEditingController();
  String _modalityFilter = 'todos'; // 'todos', 'classic', 'find_and_win'
  String _statusFilter = 'todos'; // 'todos', 'open', 'em_breve', 'encerrado'

  // Estado Local do Cockpit (Carregamento Único Reativo — Evita travamentos por loops assíncronos)
  bool _isLoadingCockpit = false;
  List<ParseObject> _cockpitPhases = [];
  List<ParseObject> _cockpitEnigmas = [];
  List<ParseObject> _cockpitHints = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    setState(() {
      final query = QueryBuilder<ParseObject>(ParseObject('Event'))
        ..orderByDescending('createdAt');
      _eventsFuture = query.query().then((response) {
        if (response.success && response.results != null) {
          final list = List<ParseObject>.from(response.results!);
          if (_selectedEvent != null) {
            final idx = list.indexWhere((e) => e.objectId == _selectedEvent!.objectId);
            if (idx != -1) {
              _selectedEvent = list[idx];
            }
          }
          if (mounted) setState(() {});
          return list;
        }
        return [];
      });
    });
  }

  // =========================================================================
  //  MÉTODOS SEGUROS DE EXTRAÇÃO DE DADOS (EVITAM TYPEERROR EM DADOS DIVERGENTES)
  // =========================================================================
  String? _getEnigmaPhaseId(ParseObject enigma) {
    try {
      final direct = enigma.get<dynamic>('phaseId');
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }
      final phaseRaw = enigma.get<dynamic>('phase');
      if (phaseRaw is ParseObject) {
        return phaseRaw.objectId;
      } else if (phaseRaw is Map) {
        return phaseRaw['objectId']?.toString();
      }
    } catch (_) {}
    return null;
  }

  int _safeOrder(ParseObject obj, {int defaultVal = 1}) {
    try {
      final val = obj.get<dynamic>('order');
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultVal;
    } catch (_) {}
    return defaultVal;
  }

  bool _safeBool(ParseObject obj, String key, {bool defaultVal = false}) {
    try {
      final val = obj.get<dynamic>(key);
      if (val is bool) return val;
      if (val is num) return val != 0;
      if (val is String) {
        final s = val.trim().toLowerCase();
        return s == 'true' || s == '1' || s == 'yes' || s == 'sim';
      }
    } catch (_) {}
    return defaultVal;
  }

  double _safePrice(ParseObject obj, String key, {double defaultVal = 0.0}) {
    try {
      final val = obj.get<dynamic>(key);
      if (val is num) return val.toDouble();
      if (val is String) return _parseMoney(val);
    } catch (_) {}
    return defaultVal;
  }

  String _safeString(ParseObject obj, String key, {String defaultVal = ''}) {
    try {
      final val = obj.get<dynamic>(key);
      if (val == null) return defaultVal;
      final str = val.toString().trim();
      return str.isNotEmpty ? str : defaultVal;
    } catch (_) {
      return defaultVal;
    }
  }

  void _selectEvent(ParseObject event) {
    setState(() {
      _selectedEvent = event;
      _isLoadingCockpit = true;
      _cockpitPhases = [];
      _cockpitEnigmas = [];
      _cockpitHints = [];
    });
    _loadCockpitData(event.objectId ?? '');
  }

  Future<void> _loadCockpitData(String eventId) async {
    if (eventId.isEmpty) {
      if (mounted) setState(() => _isLoadingCockpit = false);
      return;
    }

    try {
      // 1. Carrega Fases (paralelo com timeout e fallback por ponteiro)
      final phasesFuture = () async {
        try {
          final q = QueryBuilder<ParseObject>(ParseObject('Phase'))
            ..whereEqualTo('eventId', eventId)
            ..orderByAscending('order');
          final res = await q.query().timeout(const Duration(seconds: 7));
          if (res.success && res.results != null && res.results!.isNotEmpty) {
            return List<ParseObject>.from(res.results!);
          }
          final qPtr = QueryBuilder<ParseObject>(ParseObject('Phase'))
            ..whereEqualTo('event', (ParseObject('Event')..objectId = eventId).toPointer())
            ..orderByAscending('order');
          final resPtr = await qPtr.query().timeout(const Duration(seconds: 7));
          if (resPtr.success && resPtr.results != null) {
            return List<ParseObject>.from(resPtr.results!);
          }
        } catch (e) {
          debugPrint('Aviso ao buscar fases: $e');
        }
        return <ParseObject>[];
      }();

      // 2. Carrega Enigmas (paralelo com timeout e fallback por ponteiro)
      final enigmasFuture = () async {
        try {
          final q = QueryBuilder<ParseObject>(ParseObject('Enigma'))
            ..whereEqualTo('eventId', eventId)
            ..orderByAscending('order');
          final res = await q.query().timeout(const Duration(seconds: 7));
          if (res.success && res.results != null && res.results!.isNotEmpty) {
            return List<ParseObject>.from(res.results!);
          }
          final qPtr = QueryBuilder<ParseObject>(ParseObject('Enigma'))
            ..whereEqualTo('event', (ParseObject('Event')..objectId = eventId).toPointer())
            ..orderByAscending('order');
          final resPtr = await qPtr.query().timeout(const Duration(seconds: 7));
          if (resPtr.success && resPtr.results != null) {
            return List<ParseObject>.from(resPtr.results!);
          }
        } catch (e) {
          debugPrint('Aviso ao buscar enigmas: $e');
        }
        return <ParseObject>[];
      }();

      final results = await Future.wait([phasesFuture, enigmasFuture])
          .timeout(const Duration(seconds: 10), onTimeout: () => [<ParseObject>[], <ParseObject>[]]);

      final phases = results[0];
      final enigmas = results[1];

      // 3. Carrega Dicas vinculadas aos enigmas deste evento
      List<ParseObject> hints = [];
      final enigmaIds = enigmas.map((e) => e.objectId).whereType<String>().toList();
      if (enigmaIds.isNotEmpty) {
        try {
          final hintsQuery = QueryBuilder<ParseObject>(ParseObject('Hint'))
            ..whereContainedIn('linkedEnigmaId', enigmaIds)
            ..orderByAscending('createdAt');
          final hintsRes = await hintsQuery.query().timeout(const Duration(seconds: 7));
          if (hintsRes.success && hintsRes.results != null) {
            hints = List<ParseObject>.from(hintsRes.results!);
          }
        } catch (e) {
          debugPrint('Aviso ao buscar dicas: $e');
        }
      }

      if (mounted) {
        setState(() {
          _cockpitPhases = phases;
          _cockpitEnigmas = enigmas;
          _cockpitHints = hints;
          _isLoadingCockpit = false;
        });
      }
    } catch (e) {
      debugPrint('Erro geral ao carregar dados do cockpit: $e');
      if (mounted) {
        setState(() => _isLoadingCockpit = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedEvent != null) {
      return _buildEventCockpit(_selectedEvent!);
    }
    return _buildEventsListView();
  }

  // =========================================================================
  //  1. IDENTIFICAÇÃO VISUAL DA MODALIDADE (CLASSIC vs FIND & WIN)
  // =========================================================================
  Widget _buildModalityTag(String eventType, {bool isLarge = false}) {
    final bool isClassic = eventType.toLowerCase() == 'classic';
    final Color tagColor = isClassic ? AppColors.verdeVale : AppColors.amareloVale;
    final icon = isClassic ? FontAwesomeIcons.trophy : FontAwesomeIcons.boxOpen;
    final String label = isClassic ? 'CLASSIC' : 'FIND & WIN';
    final String ruleDesc = isClassic
        ? 'Fases Sequenciais • Prêmio Único ao 1º Colocado'
        : 'Recompensas Individuais • Baú por Enigma';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 9,
        vertical: isLarge ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tagColor.withValues(alpha: 0.7),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: tagColor.withValues(alpha: 0.12),
            blurRadius: isLarge ? 8 : 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: isLarge ? 13 : 10.5,
            color: tagColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: tagColor,
              fontSize: isLarge ? 12 : 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          if (isLarge) ...[
            const SizedBox(width: 10),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              ruleDesc,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  //  2. LISTAGEM DE EVENTOS
  // =========================================================================
  Widget _buildEventsListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Eventos', FontAwesomeIcons.calendar, showLine: true),
        const SizedBox(height: 12),

        // Barra de Pesquisa e Filtros
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryAmber.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: primaryAmber, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        hintText: 'Buscar evento por nome, local ou descrição...',
                        hintStyle: TextStyle(color: secondaryTextColor.withValues(alpha: 0.6), fontSize: 13),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.3),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryAmber),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Modalidade: ',
                    style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip('Todos', _modalityFilter == 'todos', () => setState(() => _modalityFilter = 'todos')),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    'Classic',
                    _modalityFilter == 'classic',
                    () => setState(() => _modalityFilter = 'classic'),
                    color: AppColors.verdeVale,
                    icon: FontAwesomeIcons.trophy,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    'Find & Win',
                    _modalityFilter == 'find_and_win',
                    () => setState(() => _modalityFilter = 'find_and_win'),
                    color: AppColors.amareloVale,
                    icon: FontAwesomeIcons.boxOpen,
                  ),
                  const Spacer(),
                  Text(
                    'Status: ',
                    style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip('Todos', _statusFilter == 'todos', () => setState(() => _statusFilter = 'todos')),
                  const SizedBox(width: 6),
                  _buildFilterChip('Ativo', _statusFilter == 'open', () => setState(() => _statusFilter = 'open'), color: successColor),
                  const SizedBox(width: 6),
                  _buildFilterChip('Em breve', _statusFilter == 'em_breve', () => setState(() => _statusFilter = 'em_breve'), color: warningColor),
                  const SizedBox(width: 6),
                  _buildFilterChip('Encerrado', _statusFilter == 'encerrado', () => setState(() => _statusFilter = 'encerrado'), color: dangerColor),
                ],
              ),
            ],
          ),
        ),

        // Lista de Eventos
        Expanded(
          child: FutureBuilder<List<ParseObject>>(
            future: _eventsFuture ?? Future.value([]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryAmber),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              var events = snapshot.data ?? [];

              // Aplica busca por texto
              final search = _searchController.text.trim().toLowerCase();
              if (search.isNotEmpty) {
                events = events.where((e) {
                  final title = (e.get<String>('title') ?? e.get<String>('name') ?? '').toLowerCase();
                  final location = (e.get<String>('location') ?? '').toLowerCase();
                  final desc = (e.get<String>('description') ?? '').toLowerCase();
                  return title.contains(search) || location.contains(search) || desc.contains(search);
                }).toList();
              }

              // Aplica filtro por modalidade
              if (_modalityFilter == 'classic') {
                events = events.where((e) {
                  final t = (e.get<String>('eventType') ?? 'classic').toLowerCase();
                  return t == 'classic';
                }).toList();
              } else if (_modalityFilter == 'find_and_win') {
                events = events.where((e) {
                  final t = (e.get<String>('eventType') ?? 'classic').toLowerCase();
                  return t != 'classic';
                }).toList();
              }

              // Aplica filtro por status
              if (_statusFilter != 'todos') {
                events = events.where((e) {
                  final s = (e.get<String>('status') ?? '').toLowerCase();
                  if (_statusFilter == 'open') return s == 'open' || s == 'ativo';
                  if (_statusFilter == 'em_breve') return s == 'em_breve';
                  if (_statusFilter == 'encerrado') return s == 'encerrado' || s == 'closed';
                  return true;
                }).toList();
              }

              if (events.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventCard(event);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildAddButton('Novo Evento', () => _showAddEventModal(context)),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    Color? color,
    dynamic icon,
  }) {
    final effectiveColor = color ?? primaryAmber;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              FaIcon(icon, size: 10, color: isSelected ? effectiveColor : Colors.white70),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(ParseObject event) {
    final status = event.get<String>('status') ?? 'encerrado';
    Color statusColor;
    String statusLabel;

    if (status == 'open' || status == 'ativo') {
      statusColor = successColor;
      statusLabel = 'Ativo';
    } else if (status == 'em_breve') {
      statusColor = warningColor;
      statusLabel = 'Em breve';
    } else {
      statusColor = dangerColor;
      statusLabel = 'Encerrado';
    }

    final eventType = event.get<String>('eventType') ?? 'classic';
    final isClassic = eventType.toLowerCase() == 'classic';

    final prize =
        event.get<dynamic>('prize')?.toString() ??
        event.get<dynamic>('prizePool')?.toString() ??
        'R\$ 0,00';
    final location = event.get<String>('location') ?? 'Sem local definido';

    final subtitleText = isClassic
        ? 'Classic • Local: $location • Prêmio Total: $prize (Ao 1º colocado)'
        : 'Find & Win • Local: $location • Prêmio Estimado: $prize (Baú por Enigma)';

    return AdminItemCard(
      icon: isClassic ? FontAwesomeIcons.trophy : FontAwesomeIcons.boxOpen,
      title: event.get<String>('title') ?? event.get<String>('name') ?? 'Sem Nome',
      statusText: statusLabel,
      statusColor: statusColor,
      subtitle: subtitleText,
      tagWidget: _buildModalityTag(eventType),
      onTap: () => _selectEvent(event),
      actions: [
        _buildButton(
          'Gerenciar Evento',
          isPrimary: true,
          onTap: () => _selectEvent(event),
        ),
        const SizedBox(width: 8),
        _buildButton(
          'Editar Dados',
          isPrimary: false,
          onTap: () => _showEditEventModal(context, event),
        ),
        const SizedBox(width: 8),
        _buildButton(
          'Exportar QRs',
          isPrimary: false,
          onTap: () => _exportQRs(context, event),
        ),
        const SizedBox(width: 8),
        _buildButton(
          'Duplicar',
          isPrimary: false,
          onTap: () => _duplicateEvent(context, event),
        ),
        const SizedBox(width: 8),
        _buildButton(
          'Excluir',
          isDanger: true,
          onTap: () => _deleteEvent(event),
        ),
      ],
    );
  }

  // =========================================================================
  //  3. EVENT COCKPIT — GESTÃO CENTRALIZADA (EVENTOS > FASES > ENIGMAS > DICAS)
  // =========================================================================
  Widget _buildEventCockpit(ParseObject event) {
    final status = event.get<String>('status') ?? 'encerrado';
    Color statusColor;
    String statusLabel;

    if (status == 'open' || status == 'ativo') {
      statusColor = successColor;
      statusLabel = 'Ativo';
    } else if (status == 'em_breve') {
      statusColor = warningColor;
      statusLabel = 'Em breve';
    } else {
      statusColor = dangerColor;
      statusLabel = 'Encerrado';
    }

    final eventType = event.get<String>('eventType') ?? 'classic';
    final isClassic = eventType.toLowerCase() == 'classic';

    final prize =
        event.get<dynamic>('prize')?.toString() ??
        event.get<dynamic>('prizePool')?.toString() ??
        'R\$ 0,00';
    final location = event.get<String>('location') ?? 'Sem local definido';
    final description = event.get<String>('description') ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        InkWell(
          onTap: () => setState(() => _selectedEvent = null),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(FontAwesomeIcons.arrowLeft, size: 12, color: primaryAmber),
                const SizedBox(width: 8),
                Text(
                  'VOLTAR PARA TODOS OS EVENTOS',
                  style: GoogleFonts.inter(
                    color: primaryAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Event Cockpit Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isClassic
                  ? AppColors.verdeVale.withValues(alpha: 0.35)
                  : AppColors.amareloVale.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                              event.get<String>('title') ?? event.get<String>('name') ?? 'Sem Nome',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildModalityTag(eventType, isLarge: true),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.inter(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 18,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(FontAwesomeIcons.locationDot, size: 12, color: AppColors.cinzaMedio),
                                const SizedBox(width: 6),
                                Text(
                                  location,
                                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(FontAwesomeIcons.trophy, size: 12, color: primaryAmber),
                                const SizedBox(width: 6),
                                Text(
                                  isClassic ? 'Prêmio Total (1º Colocado): $prize' : 'Prêmio Estimado da Campanha: $prize',
                                  style: GoogleFonts.inter(
                                    color: primaryAmber,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (description.isNotEmpty)
                              Text(
                                '• $description',
                                style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildButton(
                        'Editar Evento',
                        isPrimary: false,
                        onTap: () => _showEditEventModal(context, event),
                      ),
                      _buildButton(
                        'Publicar Enigmas',
                        isPrimary: false,
                        onTap: () => _publishAllEnigmas(context, event),
                      ),
                      _buildButton(
                        'Exportar QRs',
                        isPrimary: false,
                        onTap: () => _exportQRs(context, event),
                      ),
                      _buildButton(
                        'Excluir Evento',
                        isDanger: true,
                        onTap: () => _deleteEvent(event),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Conteúdo do Cockpit
        if (_isLoadingCockpit)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: primaryAmber),
                    const SizedBox(height: 16),
                    Text(
                      'Carregando estrutura do evento...',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Builder(
              builder: (ctx) {
                try {
                  return isClassic
                      ? _buildClassicHierarchyView(event)
                      : _buildFindWinHierarchyView(event);
                } catch (e, stack) {
                  debugPrint('Erro de renderização do cockpit: $e\n$stack');
                  return _buildCockpitErrorState(event, e.toString());
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCockpitErrorState(ParseObject event, String errorMsg) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dangerColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation, color: dangerColor, size: 40),
            const SizedBox(height: 16),
            Text(
              'Não foi possível renderizar a estrutura completa deste evento',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMsg,
              style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                  'Tentar Recarregar',
                  isPrimary: true,
                  onTap: () => _loadCockpitData(event.objectId ?? ''),
                ),
                const SizedBox(width: 12),
                _buildButton(
                  'Voltar aos Eventos',
                  isPrimary: false,
                  onTap: () => setState(() => _selectedEvent = null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  //  4. HIERARQUIA CLASSIC (EVENTO > FASES > ENIGMAS > DICAS)
  // =========================================================================
  Widget _buildClassicHierarchyView(ParseObject event) {
    // Separa enigmas que possuem fase atribuída e enigmas avulsos de forma 100% segura
    final phaseIds = _cockpitPhases.map((p) => p.objectId).toSet();
    final unassignedEnigmas = _cockpitEnigmas.where((e) {
      final pid = _getEnigmaPhaseId(e);
      return pid == null || pid.isEmpty || !phaseIds.contains(pid);
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Banner Classic
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.verdeVale.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleInfo,
                  color: AppColors.verdeVale,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estrutura Classic: A caçada é dividida em Fases sequenciais. Para cada fase, os enigmas devem ser resolvidos na ordem estrita definida. O avanço para a etapa seguinte só ocorre após resolver todos os enigmas da fase atual. O prêmio total do evento é entregue exclusivamente ao 1º jogador a concluir a jornada.',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Fases & Etapas da Caçada', FontAwesomeIcons.layerGroup),
              _buildButton(
                '+ Adicionar Nova Fase',
                isPrimary: true,
                onTap: () => _showAddPhaseModal(context, event, () => _loadCockpitData(event.objectId ?? '')),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_cockpitPhases.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryAmber.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const FaIcon(FontAwesomeIcons.layerGroup, color: secondaryTextColor, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhuma fase criada ainda para este evento Classic.',
                    style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildButton(
                    'Criar Fase 1',
                    isPrimary: true,
                    onTap: () async {
                      await ParseCloudFunction('createOrUpdatePhase').execute(
                        parameters: {
                          'eventId': event.objectId,
                          'data': {
                            'title': 'Fase 1',
                            'order': 1,
                            'status': 'open',
                          },
                        },
                      );
                      _loadCockpitData(event.objectId ?? '');
                    },
                  ),
                ],
              ),
            )
          else ...[
            ..._cockpitPhases.map((phase) {
              final phaseEnigmas = _cockpitEnigmas.where((e) {
                final pid = _getEnigmaPhaseId(e);
                return pid == phase.objectId;
              }).toList();

              return _buildCockpitPhaseItem(event, phase, phaseEnigmas);
            }),
          ],

          // Enigmas Avulsos (Sem Fase atribuída no Classic)
          if (unassignedEnigmas.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionTitle('Enigmas Avulsos (Sem Fase)', FontAwesomeIcons.puzzlePiece, showLine: true),
            const SizedBox(height: 10),
            ...unassignedEnigmas.map((enigma) {
              final enigmaHints = _cockpitHints.where((h) => h.get<String>('linkedEnigmaId') == enigma.objectId).toList();
              return _buildCockpitEnigmaCard(
                event,
                enigma,
                enigmaHints,
                isClassic: true,
                currentPhase: null,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCockpitPhaseItem(
    ParseObject event,
    ParseObject phase,
    List<ParseObject> phaseEnigmas,
  ) {
    final phaseOrder = _safeOrder(phase);
    final phaseTitle = _safeString(phase, 'title', defaultVal: 'Fase $phaseOrder');
    final phaseStatus = _safeString(phase, 'status', defaultVal: 'bloqueado');
    final isOpen = phaseStatus == 'open' || phaseStatus == 'aberto';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOpen
              ? AppColors.verdeVale.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Fase
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '$phaseOrder',
                      style: GoogleFonts.inter(
                        color: AppColors.verdeVale,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phaseTitle,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOpen ? successColor : secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen
                                ? 'Fase Inicial (Aberta ao iniciar)'
                                : 'Fase Sequencial (Desbloqueada após concluir fase anterior)',
                            style: GoogleFonts.inter(
                              color: secondaryTextColor,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${phaseEnigmas.length} Enigmas',
                            style: GoogleFonts.inter(
                              color: primaryAmberLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildButton(
                      '+ Novo Enigma',
                      isPrimary: true,
                      onTap: () => _showEnigmaFormModal(
                        context,
                        event,
                        phase: phase,
                        isClassic: true,
                        onSaved: () => _loadCockpitData(event.objectId ?? ''),
                      ),
                    ),
                    _buildButton(
                      '+ Vincular Existente',
                      isPrimary: false,
                      onTap: () => _showLinkExistingEnigmaDialog(
                        context,
                        event,
                        phase,
                        () => _loadCockpitData(event.objectId ?? ''),
                      ),
                    ),
                    _buildButton(
                      'Editar Fase',
                      isPrimary: false,
                      onTap: () => _showEditPhaseModal(
                        context,
                        event,
                        phase,
                        () => _loadCockpitData(event.objectId ?? ''),
                      ),
                    ),
                    _buildButton(
                      'Excluir Fase',
                      isDanger: true,
                      onTap: () => _deletePhase(context, event, phase, () => _loadCockpitData(event.objectId ?? '')),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Enigmas e Dicas da Fase
          Padding(
            padding: const EdgeInsets.all(16),
            child: phaseEnigmas.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Nenhum enigma vinculado a esta etapa. Clique em "+ Novo Enigma" ou "+ Vincular Existente".',
                        style: GoogleFonts.inter(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: phaseEnigmas.map((enigma) {
                      final enigmaHints = _cockpitHints.where((h) => h.get<String>('linkedEnigmaId') == enigma.objectId).toList();
                      return _buildCockpitEnigmaCard(
                        event,
                        enigma,
                        enigmaHints,
                        isClassic: true,
                        currentPhase: phase,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  //  5. HIERARQUIA FIND & WIN (EVENTO > ENIGMAS & BAÚS > DICAS)
  // =========================================================================
  Widget _buildFindWinHierarchyView(ParseObject event) {
    final double totalBauSum = _cockpitEnigmas.fold<double>(
      0.0,
      (sum, e) => sum + _parseMoney(_safeString(e, 'prize', defaultVal: '0')),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Banner Find & Win
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.amareloVale.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.amareloVale.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleInfo,
                  color: AppColors.amareloVale,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estrutura Find & Win: Os enigmas possuem baús e prêmios individuais. Cada enigma decifrado credita a recompensa instantaneamente na carteira do jogador. Não existem fases sequenciais bloqueadas.',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildSectionTitle('Enigmas & Baús do Evento', FontAwesomeIcons.boxOpen),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amareloVale.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Soma Baús: R\$ ${totalBauSum.toStringAsFixed(2)} (${_cockpitEnigmas.length} Enigmas)',
                      style: GoogleFonts.inter(
                        color: AppColors.amareloVale,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              _buildButton(
                '+ Criar Novo Enigma',
                isPrimary: true,
                onTap: () => _showEnigmaFormModal(
                  context,
                  event,
                  isClassic: false,
                  onSaved: () => _loadCockpitData(event.objectId ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_cockpitEnigmas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryAmber.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const FaIcon(FontAwesomeIcons.boxOpen, color: secondaryTextColor, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhum enigma cadastrado para este evento Find & Win.',
                    style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildButton(
                    'Criar Primeiro Enigma',
                    isPrimary: true,
                    onTap: () => _showEnigmaFormModal(
                      context,
                      event,
                      isClassic: false,
                      onSaved: () => _loadCockpitData(event.objectId ?? ''),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ..._cockpitEnigmas.map((enigma) {
              final enigmaHints = _cockpitHints.where((h) => h.get<String>('linkedEnigmaId') == enigma.objectId).toList();
              return _buildCockpitEnigmaCard(
                event,
                enigma,
                enigmaHints,
                isClassic: false,
              );
            }),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  //  6. CARD DO ENIGMA COM SUB-CAMADA DE DICAS INTEGRADA
  // =========================================================================
  Widget _buildCockpitEnigmaCard(
    ParseObject event,
    ParseObject enigma,
    List<ParseObject> hints, {
    required bool isClassic,
    ParseObject? currentPhase,
  }) {
    final order = _safeOrder(enigma);
    final instruction = _safeString(enigma, 'instruction', defaultVal: _safeString(enigma, 'name', defaultVal: 'Sem instrução'));
    final type = _safeString(enigma, 'type', defaultVal: 'text');
    final difficulty = _safeString(enigma, 'difficulty', defaultVal: 'Médio');
    final code = _safeString(enigma, 'code', defaultVal: '---');
    final prize = _safeString(enigma, 'prize', defaultVal: '0,00');

    final hasCompass = _safeBool(enigma, 'hasCompass');
    final hasMap = _safeBool(enigma, 'hasMap');
    final hasRadar = _safeBool(enigma, 'hasRadar');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryAmber.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enigma Header Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isClassic
                        ? AppColors.verdeVale.withValues(alpha: 0.18)
                        : AppColors.amareloVale.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isClassic
                          ? AppColors.verdeVale.withValues(alpha: 0.3)
                          : AppColors.amareloVale.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '#$order',
                    style: GoogleFonts.inter(
                      color: isClassic ? AppColors.verdeVale : AppColors.amareloVale,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instruction,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: GoogleFonts.inter(color: primaryAmber, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Dif: $difficulty',
                              style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 10),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Código "$code" copiado!'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Cód: $code',
                                    style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 10),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy, size: 10, color: Colors.white54),
                                ],
                              ),
                            ),
                          ),
                          if (!isClassic) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.amareloVale.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FaIcon(FontAwesomeIcons.boxOpen, size: 10, color: AppColors.amareloVale),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Prêmio Baú: R\$ $prize',
                                    style: GoogleFonts.inter(
                                      color: AppColors.amareloVale,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.verdeVale.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'Jornada Classic (Prêmio no Final)',
                                style: GoogleFonts.inter(
                                  color: AppColors.verdeVale,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (hasCompass || hasMap || hasRadar) ...[
                            if (hasCompass)
                              const Padding(
                                padding: EdgeInsets.only(right: 2),
                                child: FaIcon(FontAwesomeIcons.compass, size: 11, color: primaryAmber),
                              ),
                            if (hasMap)
                              const Padding(
                                padding: EdgeInsets.only(right: 2),
                                child: FaIcon(FontAwesomeIcons.mapLocationDot, size: 11, color: Colors.blueAccent),
                              ),
                            if (hasRadar)
                              const Padding(
                                padding: EdgeInsets.only(right: 2),
                                child: FaIcon(FontAwesomeIcons.satelliteDish, size: 11, color: successColor),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildButton(
                      'Prévia',
                      isPrimary: false,
                      onTap: () => _showEnigmaPreviewDialog(context, enigma),
                    ),
                    _buildButton(
                      'Ver QR',
                      isPrimary: false,
                      onTap: () => _showEnigmaQrDialog(context, enigma),
                    ),
                    _buildButton(
                      'Editar',
                      isPrimary: false,
                      onTap: () => _showEnigmaFormModal(
                        context,
                        event,
                        enigma: enigma,
                        phase: currentPhase,
                        isClassic: isClassic,
                        onSaved: () => _loadCockpitData(event.objectId ?? ''),
                      ),
                    ),
                    if (isClassic && currentPhase != null)
                      _buildButton(
                        'Mover Fase',
                        isPrimary: false,
                        onTap: () => _showMoveEnigmaPhaseDialog(
                          context,
                          event,
                          currentPhase,
                          enigma,
                          () => _loadCockpitData(event.objectId ?? ''),
                        ),
                      ),
                    _buildButton(
                      'Duplicar',
                      isPrimary: false,
                      onTap: () => _duplicateEnigma(
                        context,
                        event,
                        enigma,
                        phase: currentPhase,
                        isClassic: isClassic,
                        onRefresh: () => _loadCockpitData(event.objectId ?? ''),
                      ),
                    ),
                    _buildButton(
                      'Excluir',
                      isDanger: true,
                      onTap: () => _deleteEnigmaWithCascade(context, enigma, () => _loadCockpitData(event.objectId ?? '')),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-camada: DICAS DO ENIGMA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.lightbulb, size: 11, color: primaryAmber),
                        const SizedBox(width: 6),
                        Text(
                          'Dicas deste Enigma (${hints.length}):',
                          style: GoogleFonts.inter(
                            color: secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showAddHintModal(context, enigma, () => _loadCockpitData(event.objectId ?? '')),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.plus, size: 10, color: primaryAmber),
                            const SizedBox(width: 4),
                            Text(
                              'Adicionar Dica',
                              style: GoogleFonts.inter(
                                color: primaryAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (hints.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...hints.map((hint) {
                    final desc = _safeString(hint, 'description', defaultVal: _safeString(hint, 'title', defaultVal: 'Dica'));
                    final priceHint = _safePrice(hint, 'price');

                    return Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '💡 $desc',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'R\$ ${priceHint.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                color: primaryAmberLight,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _showEditHintModal(context, hint, () => _loadCockpitData(event.objectId ?? '')),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: FaIcon(FontAwesomeIcons.penToSquare, size: 11, color: Colors.blueAccent),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _deleteHint(context, hint, () => _loadCockpitData(event.objectId ?? '')),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: FaIcon(FontAwesomeIcons.trash, size: 11, color: dangerColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  //  7. MODAIS DE DICAS (CRIAR, EDITAR, EXCLUIR)
  // =========================================================================
  void _showAddHintModal(BuildContext context, ParseObject enigma, VoidCallback onSaved) {
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0.50');

    showDialog(
      context: context,
      builder: (ctx) {
        return AdminModal(
          title: 'Adicionar Dica ao Enigma',
          maxWidth: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputForm(
                controller: descCtrl,
                hint: 'Texto explicativo da dica...',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildInputForm(
                controller: priceCtrl,
                hint: 'Preço em R\$ (Ex: 0.50)',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildButton('Cancelar', onTap: () => Navigator.pop(ctx)),
                  const SizedBox(width: 8),
                  _buildButton(
                    'Salvar Dica',
                    isPrimary: true,
                    onTap: () async {
                      if (descCtrl.text.trim().isEmpty) return;

                      final res = await ParseCloudFunction('createOrUpdateHint').execute(
                        parameters: {
                          'data': {
                            'description': descCtrl.text.trim(),
                            'price': _parseMoney(priceCtrl.text.trim()),
                            'linkedEnigmaId': enigma.objectId,
                          },
                        },
                      );

                      if (res.success) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        onSaved();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditHintModal(BuildContext context, ParseObject hint, VoidCallback onSaved) {
    final descCtrl = TextEditingController(text: hint.get<String>('description') ?? hint.get<String>('title') ?? '');
    final priceCtrl = TextEditingController(text: hint.get<num>('price')?.toString() ?? '0.50');

    showDialog(
      context: context,
      builder: (ctx) {
        return AdminModal(
          title: 'Editar Dica',
          maxWidth: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputForm(
                controller: descCtrl,
                hint: 'Texto explicativo da dica...',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildInputForm(
                controller: priceCtrl,
                hint: 'Preço em R\$ (Ex: 0.50)',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildButton('Cancelar', onTap: () => Navigator.pop(ctx)),
                  const SizedBox(width: 8),
                  _buildButton(
                    'Salvar Alterações',
                    isPrimary: true,
                    onTap: () async {
                      if (descCtrl.text.trim().isEmpty) return;

                      final res = await ParseCloudFunction('createOrUpdateHint').execute(
                        parameters: {
                          'hintId': hint.objectId,
                          'data': {
                            'description': descCtrl.text.trim(),
                            'price': _parseMoney(priceCtrl.text.trim()),
                          },
                        },
                      );

                      if (res.success) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        onSaved();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteHint(BuildContext context, ParseObject hint, VoidCallback onSaved) async {
    final res = await ParseCloudFunction('deleteHint').execute(
      parameters: {'hintId': hint.objectId},
    );
    if (res.success) {
      onSaved();
    }
  }

  // =========================================================================
  //  8. MODAL UNIVERSAL DE ENIGMA (CRIAR E EDITAR)
  // =========================================================================
  void _showEnigmaFormModal(
    BuildContext context,
    ParseObject event, {
    ParseObject? phase,
    ParseObject? enigma,
    required bool isClassic,
    required VoidCallback onSaved,
  }) {
    final isEdit = enigma != null;
    final instructionCtrl = TextEditingController(text: isEdit ? (enigma.get<String>('instruction') ?? '') : '');
    final codeCtrl = TextEditingController(text: isEdit ? _safeString(enigma, 'code') : '');
    final prizeCtrl = TextEditingController(text: isEdit ? (enigma.get<dynamic>('prize')?.toString() ?? '0') : '0');
    final orderCtrl = TextEditingController(text: isEdit ? (enigma.get<num>('order')?.toString() ?? '1') : '');
    final photoUrlCtrl = TextEditingController(text: isEdit ? (enigma.get<String>('imageUrl') ?? '') : '');
    final audioUrlCtrl = TextEditingController(text: isEdit ? (enigma.get<String>('audioUrl') ?? '') : '');
    final compassCoordsCtrl = TextEditingController(text: isEdit ? (enigma.get<String>('compassCoords') ?? '') : '');

    String tipo = isEdit ? (enigma.get<String>('type') ?? 'text') : 'text';
    String dificuldade = isEdit ? (enigma.get<String>('difficulty') ?? 'Médio') : 'Médio';

    bool hasCompass = isEdit ? (enigma.get<bool>('hasCompass') ?? false) : false;
    bool hasMap = isEdit ? (enigma.get<bool>('hasMap') ?? false) : false;
    bool hasRadar = isEdit ? (enigma.get<bool>('hasRadar') ?? false) : false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setFormState) {
            final modalTitle = isEdit
                ? 'Editar Enigma #${enigma.get<num>('order') ?? 1}'
                : (isClassic
                    ? 'Criar Enigma na ${phase?.get<String>('title') ?? "Fase"}'
                    : 'Criar Enigma (Find & Win)');

            return AdminModal(
              title: modalTitle,
              maxWidth: 620,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isClassic) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.circleInfo, color: AppColors.verdeVale, size: 13),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Modalidade Classic: Este enigma não possui premiação individual em dinheiro. O valor total configurado no evento é entregue exclusivamente ao 1º colocado ao finalizar todas as fases.',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  _buildInputForm(
                    controller: instructionCtrl,
                    hint: 'Instrução do enigma (Suporta Markdown)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectForm(
                          value: tipo,
                          items: const [
                            DropdownMenuItem(value: 'text', child: Text('Texto (Charada)')),
                            DropdownMenuItem(value: 'photo', child: Text('Foto (Imagem)')),
                            DropdownMenuItem(value: 'audio', child: Text('Áudio (Mídia)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setFormState(() => tipo = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectForm(
                          value: dificuldade,
                          items: const [
                            DropdownMenuItem(value: 'Fácil', child: Text('Fácil')),
                            DropdownMenuItem(value: 'Médio', child: Text('Médio')),
                            DropdownMenuItem(value: 'Difícil', child: Text('Difícil')),
                            DropdownMenuItem(value: 'Lendário', child: Text('Lendário')),
                          ],
                          onChanged: (val) {
                            if (val != null) setFormState(() => dificuldade = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: _buildInputForm(
                          controller: orderCtrl,
                          hint: 'Ordem',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputForm(
                          controller: codeCtrl,
                          hint: 'Código / Resposta (Vazio = auto-gerar)',
                        ),
                      ),
                      if (!isClassic) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputForm(
                            controller: prizeCtrl,
                            hint: 'Prêmio Baú (R\$)',
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (tipo == 'photo') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputForm(
                            controller: photoUrlCtrl,
                            hint: 'URL da Foto',
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.upload, color: primaryAmber, size: 18),
                          tooltip: 'Upload de Imagem',
                          onPressed: () async {
                            final url = await AdminUploadUtil.pickAndUploadImage(context);
                            if (url != null) {
                              setFormState(() => photoUrlCtrl.text = url);
                            }
                          },
                        ),
                      ],
                    ),
                  ] else if (tipo == 'audio') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputForm(
                            controller: audioUrlCtrl,
                            hint: 'URL do Áudio',
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.upload, color: primaryAmber, size: 18),
                          tooltip: 'Upload de Áudio',
                          onPressed: () async {
                            final url = await AdminUploadUtil.pickAndUploadAudio(context);
                            if (url != null) {
                              setFormState(() => audioUrlCtrl.text = url);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Ferramentas Disponíveis ao Jogador:',
                    style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Bússola'),
                        selected: hasCompass,
                        selectedColor: primaryAmber,
                        checkmarkColor: darkBackground,
                        labelStyle: TextStyle(color: hasCompass ? darkBackground : Colors.white, fontSize: 12),
                        backgroundColor: cardColor,
                        onSelected: (val) => setFormState(() => hasCompass = val),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Mapa'),
                        selected: hasMap,
                        selectedColor: primaryAmber,
                        checkmarkColor: darkBackground,
                        labelStyle: TextStyle(color: hasMap ? darkBackground : Colors.white, fontSize: 12),
                        backgroundColor: cardColor,
                        onSelected: (val) => setFormState(() => hasMap = val),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Radar'),
                        selected: hasRadar,
                        selectedColor: primaryAmber,
                        checkmarkColor: darkBackground,
                        labelStyle: TextStyle(color: hasRadar ? darkBackground : Colors.white, fontSize: 12),
                        backgroundColor: cardColor,
                        onSelected: (val) => setFormState(() => hasRadar = val),
                      ),
                    ],
                  ),
                  if (hasCompass || hasMap || hasRadar) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputForm(
                            controller: compassCoordsCtrl,
                            hint: 'Coordenadas Alvo (Ex: -19.5123, -42.5432)',
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.locationCrosshairs, color: primaryAmber, size: 18),
                          tooltip: 'Capturar Localização Atual via GPS',
                          onPressed: () async {
                            try {
                              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                              if (!serviceEnabled) throw 'Serviço de GPS desativado.';
                              LocationPermission perm = await Geolocator.checkPermission();
                              if (perm == LocationPermission.denied) {
                                perm = await Geolocator.requestPermission();
                                if (perm == LocationPermission.denied) throw 'Permissão negada.';
                              }
                              final pos = await Geolocator.getCurrentPosition(
                                locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
                              );
                              setFormState(() {
                                compassCoordsCtrl.text = '${pos.latitude}, ${pos.longitude}';
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro GPS: $e')));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton(
                        'Cancelar',
                        onTap: isSaving ? () {} : () => Navigator.pop(dialogCtx),
                      ),
                      const SizedBox(width: 10),
                      _buildButton(
                        isSaving
                            ? 'Salvando...'
                            : (isEdit ? 'Salvar Alterações' : 'Criar Enigma'),
                        isPrimary: true,
                        onTap: isSaving
                            ? () {}
                            : () async {
                                final instruction = instructionCtrl.text.trim();
                                if (instruction.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Por favor, informe a instrução do enigma.'),
                                      backgroundColor: dangerColor,
                                    ),
                                  );
                                  return;
                                }

                                setFormState(() => isSaving = true);

                                try {
                                  String code = codeCtrl.text.trim();
                                  if (code.isEmpty) {
                                    code = isEdit
                                        ? _safeString(enigma, 'code')
                                        : '${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}${DateTime.now().microsecond.toString().padLeft(3, '0')}';
                                  }

                                  int nextOrder = int.tryParse(orderCtrl.text.trim()) ?? (isEdit ? (enigma.get<num>('order')?.toInt() ?? 1) : 1);
                                  if (!isEdit && orderCtrl.text.trim().isEmpty) {
                                    final q = QueryBuilder<ParseObject>(ParseObject('Enigma'));
                                    if (isClassic && phase != null) {
                                      q.whereEqualTo('phase', (ParseObject('Phase')..objectId = phase.objectId).toPointer());
                                    } else {
                                      q.whereEqualTo('eventId', event.objectId);
                                    }
                                    q.orderByDescending('order');
                                    q.setLimit(1);
                                    final qRes = await q.query();
                                    if (qRes.success && qRes.results != null && qRes.results!.isNotEmpty) {
                                      nextOrder = ((qRes.results!.first as ParseObject).get<num>('order')?.toInt() ?? 0) + 1;
                                    }
                                  }

                                  final prizeStr = isClassic
                                      ? '0'
                                      : (prizeCtrl.text.trim().isEmpty ? '0' : prizeCtrl.text.trim());

                                  final res = await ParseCloudFunction('createOrUpdateEnigma').execute(
                                    parameters: {
                                      'eventId': event.objectId,
                                      if (isEdit) 'enigmaId': enigma.objectId,
                                      if (isClassic && phase != null) 'phaseId': phase.objectId,
                                      'data': {
                                        'instruction': instruction,
                                        'code': code,
                                        'order': nextOrder,
                                        'type': tipo,
                                        'difficulty': dificuldade,
                                        'prize': prizeStr,
                                        'imageUrl': photoUrlCtrl.text.trim(),
                                        'audioUrl': audioUrlCtrl.text.trim(),
                                        'hasCompass': hasCompass,
                                        'hasMap': hasMap,
                                        'hasRadar': hasRadar,
                                        'compassCoords': compassCoordsCtrl.text.trim(),
                                        if (!isEdit) 'status': 'open',
                                      },
                                    },
                                  );

                                  if (res.success) {
                                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEdit ? 'Enigma atualizado com sucesso!' : 'Enigma criado com sucesso!'),
                                          backgroundColor: successColor,
                                        ),
                                      );
                                    }
                                    onSaved();
                                  } else {
                                    setFormState(() => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro ao salvar enigma: ${res.error?.message ?? "Falha na operação"}'),
                                          backgroundColor: dangerColor,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  setFormState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erro ao salvar enigma: $e'),
                                        backgroundColor: dangerColor,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  //  8.1. PRÉVIA MOBILE DO ENIGMA
  // =========================================================================
  void _showEnigmaPreviewDialog(BuildContext context, ParseObject enigma) {
    final instruction = enigma.get<String>('instruction') ?? 'Instrução vazia';
    final type = enigma.get<String>('type') ?? 'text';
    final difficulty = enigma.get<String>('difficulty') ?? 'Médio';
    final hasMap = enigma.get<bool>('hasMap') ?? false;
    final hasCompass = enigma.get<bool>('hasCompass') ?? false;
    final hasRadar = enigma.get<bool>('hasRadar') ?? false;
    final imageUrl = enigma.get<String>('imageUrl') ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: 360,
            height: 680,
            decoration: BoxDecoration(
              color: const Color(0xFF161E22),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white24, width: 6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Scaffold(
                backgroundColor: AppColors.darkBackground,
                appBar: AppBar(
                  backgroundColor: AppColors.sidebarBackground,
                  title: Text(
                    'Prévia do Jogador',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryAmber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: GoogleFonts.inter(color: primaryAmber, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Dif: $difficulty',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (imageUrl.isNotEmpty && type == 'photo') ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 100,
                              color: Colors.white10,
                              child: const Center(child: Text('Erro ao carregar imagem')),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: MarkdownBody(
                          data: instruction,
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.5),
                            strong: GoogleFonts.inter(color: primaryAmber, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ferramentas Disponíveis na Caçada:',
                        style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      if (hasCompass)
                        _buildPreviewToolButton(FontAwesomeIcons.compass, 'Bússola Magnética'),
                      if (hasMap)
                        _buildPreviewToolButton(FontAwesomeIcons.mapLocationDot, 'Mapa e Raio de Busca'),
                      if (hasRadar)
                        _buildPreviewToolButton(FontAwesomeIcons.satelliteDish, 'Radar de Proximidade'),
                      if (!hasCompass && !hasMap && !hasRadar)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Nenhuma ferramenta ativa para este enigma.',
                            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewToolButton(dynamic icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryAmber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: primaryAmber, size: 14),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // =========================================================================
  //  8.2. MODAL DE QR CODE INDIVIDUAL DO ENIGMA
  // =========================================================================
  void _showEnigmaQrDialog(BuildContext context, ParseObject enigma) {
    final code = _safeString(enigma, 'code');
    final order = enigma.get<num>('order') ?? 1;

    showDialog(
      context: context,
      builder: (ctx) {
        return AdminModal(
          title: 'QR Code - Enigma #$order',
          maxWidth: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 180.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Código Hash / Resposta:',
                style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: SelectableText(
                  code,
                  style: GoogleFonts.orbitron(
                    color: primaryAmber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButton(
                    'Copiar Código',
                    isPrimary: true,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado para a área de transferência!')),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildButton('Fechar', onTap: () => Navigator.pop(ctx)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  //  8.3. DUPLICAR ENIGMA
  // =========================================================================
  Future<void> _duplicateEnigma(
    BuildContext context,
    ParseObject event,
    ParseObject enigma, {
    ParseObject? phase,
    required bool isClassic,
    required VoidCallback onRefresh,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: primaryAmber)),
    );

    try {
      final String generatedHash =
          '${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}${DateTime.now().microsecond.toString().padLeft(3, '0')}';

      final queryOrder = QueryBuilder<ParseObject>(ParseObject('Enigma'));
      if (isClassic && phase != null) {
        queryOrder.whereEqualTo('phase', phase.toPointer());
      } else {
        queryOrder.whereEqualTo('eventId', event.objectId);
      }
      queryOrder.orderByDescending('order');
      queryOrder.setLimit(1);
      final resOrder = await queryOrder.query();
      int nextOrder = 1;
      if (resOrder.success && resOrder.results != null && resOrder.results!.isNotEmpty) {
        nextOrder = ((resOrder.results!.first as ParseObject).get<num>('order')?.toInt() ?? 0) + 1;
      }

      final resNew = await ParseCloudFunction('createOrUpdateEnigma').execute(
        parameters: {
          'eventId': event.objectId,
          if (isClassic && phase != null) 'phaseId': phase.objectId,
          'data': {
            'instruction': '${enigma.get<String>("instruction") ?? "Enigma"} (Cópia)',
            'code': generatedHash,
            'order': nextOrder,
            'type': enigma.get<String>('type'),
            'difficulty': enigma.get<String>('difficulty'),
            'prize': isClassic ? '0' : (enigma.get<dynamic>('prize')?.toString() ?? '0'),
            'status': 'open',
            'hasCompass': enigma.get<bool>('hasCompass') ?? false,
            'compassCoords': enigma.get<String>('compassCoords') ?? '',
            'hasRadar': enigma.get<bool>('hasRadar') ?? false,
            'hasMap': enigma.get<bool>('hasMap') ?? false,
            'imageUrl': enigma.get<String>('imageUrl') ?? '',
            'audioUrl': enigma.get<String>('audioUrl') ?? '',
          },
        },
      );

      if (resNew.success && resNew.result != null) {
        String newEnigmaId = resNew.result is ParseObject
            ? (resNew.result as ParseObject).objectId!
            : (resNew.result is Map ? (resNew.result['enigmaId'] ?? resNew.result['objectId'] ?? '') : '');

        if (newEnigmaId.isNotEmpty) {
          final hintsQ = QueryBuilder<ParseObject>(ParseObject('Hint'))
            ..whereEqualTo('linkedEnigmaId', enigma.objectId);
          final hintsRes = await hintsQ.query();
          if (hintsRes.success && hintsRes.results != null) {
            for (var oldH in hintsRes.results!) {
              final h = oldH as ParseObject;
              await ParseCloudFunction('createOrUpdateHint').execute(
                parameters: {
                  'data': {
                    'description': h.get<String>('description'),
                    'price': h.get<num>('price')?.toDouble() ?? 0.0,
                    'linkedEnigmaId': newEnigmaId,
                  },
                },
              );
            }
          }
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enigma duplicado com sucesso!')),
        );
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao duplicar enigma: $e')));
      }
    }
  }

  Future<void> _deleteEnigmaWithCascade(
    BuildContext context,
    ParseObject enigma,
    VoidCallback onRefresh,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sidebarBackground,
        title: Text(
          'Excluir Enigma?',
          style: GoogleFonts.orbitron(color: primaryAmber),
        ),
        content: Text(
          'Deseja excluir permanentemente este enigma e todas as dicas associadas?',
          style: GoogleFonts.inter(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir', style: TextStyle(color: dangerColor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final hintsQ = QueryBuilder<ParseObject>(ParseObject('Hint'))
        ..whereEqualTo('linkedEnigmaId', enigma.objectId);
      final hintsRes = await hintsQ.query();
      if (hintsRes.success && hintsRes.results != null) {
        for (var h in hintsRes.results!) {
          await (h as ParseObject).delete();
        }
      }
      await ParseCloudFunction('deleteEnigma').execute(
        parameters: {'enigmaId': enigma.objectId},
      );
      onRefresh();
    }
  }

  // =========================================================================
  //  9. MODAIS DE FASE (CRIAR, EDITAR, EXCLUIR, VINCULAR, MOVER)
  // =========================================================================
  void _showAddPhaseModal(BuildContext context, ParseObject event, VoidCallback onRefresh) async {
    final nextOrder = _cockpitPhases.length + 1;
    final titleCtrl = TextEditingController(text: 'Fase $nextOrder');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AdminModal(
          title: 'Criar Nova Fase',
          maxWidth: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputForm(controller: titleCtrl, hint: 'Título da Fase (Ex: Fase 1)'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildButton('Cancelar', onTap: () => Navigator.pop(ctx)),
                  const SizedBox(width: 8),
                  _buildButton(
                    'Criar Fase',
                    isPrimary: true,
                    onTap: () async {
                      if (titleCtrl.text.trim().isEmpty) return;

                      final res = await ParseCloudFunction('createOrUpdatePhase').execute(
                        parameters: {
                          'eventId': event.objectId,
                          'data': {
                            'title': titleCtrl.text.trim(),
                            'order': nextOrder,
                            'status': nextOrder == 1 ? 'open' : 'bloqueado',
                          },
                        },
                      );

                      if (res.success) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        onRefresh();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditPhaseModal(
    BuildContext context,
    ParseObject event,
    ParseObject phase,
    VoidCallback onRefresh,
  ) {
    final phaseOrder = phase.get<num>('order') ?? 1;
    final titleCtrl = TextEditingController(text: phase.get<String>('title') ?? 'Fase $phaseOrder');
    final orderCtrl = TextEditingController(text: phaseOrder.toString());
    String status = phase.get<String>('status') ?? 'bloqueado';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AdminModal(
              title: 'Editar Fase $phaseOrder',
              maxWidth: 450,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputForm(controller: titleCtrl, hint: 'Título da Fase'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: _buildInputForm(controller: orderCtrl, hint: 'Ordem'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectForm(
                          value: status,
                          items: const [
                            DropdownMenuItem(value: 'open', child: Text('Aberta / Inicial')),
                            DropdownMenuItem(value: 'bloqueado', child: Text('Bloqueada (Sequencial)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => status = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton('Cancelar', onTap: () => Navigator.pop(dialogCtx)),
                      const SizedBox(width: 8),
                      _buildButton(
                        'Salvar Fase',
                        isPrimary: true,
                        onTap: () async {
                          if (titleCtrl.text.trim().isEmpty) return;

                          final res = await ParseCloudFunction('createOrUpdatePhase').execute(
                            parameters: {
                              'eventId': event.objectId,
                              'phaseId': phase.objectId,
                              'data': {
                                'title': titleCtrl.text.trim(),
                                'order': int.tryParse(orderCtrl.text.trim()) ?? phaseOrder,
                                'status': status,
                              },
                            },
                          );

                          if (res.success) {
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            onRefresh();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deletePhase(
    BuildContext context,
    ParseObject event,
    ParseObject phase,
    VoidCallback onRefresh,
  ) async {
    final title = phase.get<String>('title') ?? 'Fase';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sidebarBackground,
        title: Text('Excluir $title?', style: GoogleFonts.orbitron(color: primaryAmber)),
        content: Text(
          'A exclusão desta fase removerá também todos os enigmas e dicas vinculados a ela. Deseja prosseguir?',
          style: GoogleFonts.inter(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: dangerColor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ParseCloudFunction('deletePhase').execute(
        parameters: {
          'eventId': event.objectId,
          'phaseId': phase.objectId,
        },
      );
      if (res.success) {
        onRefresh();
      }
    }
  }

  void _showLinkExistingEnigmaDialog(
    BuildContext context,
    ParseObject event,
    ParseObject targetPhase,
    VoidCallback onRefresh,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        // Enigmas disponíveis que não estão na fase de destino
        final available = _cockpitEnigmas.where((e) {
          final currentPhaseId = _getEnigmaPhaseId(e);
          return currentPhaseId != targetPhase.objectId;
        }).toList();

        return AdminModal(
          title: 'Vincular Enigma Existente à ${targetPhase.get<String>('title') ?? "Fase"}',
          maxWidth: 650,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecione um enigma deste evento para vincular a esta fase:',
                style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13),
              ),
              const SizedBox(height: 14),
              if (available.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Todos os enigmas deste evento já estão vinculados a esta fase ou nenhum enigma foi cadastrado.',
                      style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final enigma = available[index];
                      final currentPhaseId = _getEnigmaPhaseId(enigma);
                      final hasPhase = currentPhaseId != null && currentPhaseId.isNotEmpty;
                      final currentPhaseObj = hasPhase
                          ? _cockpitPhases.cast<ParseObject?>().firstWhere((p) => p?.objectId == currentPhaseId, orElse: () => null)
                          : null;
                      final currentPhaseTitle = currentPhaseObj != null
                          ? _safeString(currentPhaseObj, 'title', defaultVal: 'Fase ${_safeOrder(currentPhaseObj)}')
                          : (hasPhase ? 'Outra Fase' : 'Sem Fase (Avulso)');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryAmber.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    enigma.get<String>('instruction') ?? 'Sem instrução',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: hasPhase ? primaryAmber.withValues(alpha: 0.15) : Colors.white10,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          currentPhaseTitle,
                                          style: GoogleFonts.inter(
                                            color: hasPhase ? primaryAmber : secondaryTextColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tipo: ${enigma.get<String>('type')} · Cód: ${enigma.get<String>('code') ?? "---"}',
                                        style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _buildButton(
                              'Vincular',
                              isPrimary: true,
                              onTap: () async {
                                final existingInPhase = _cockpitEnigmas.where((e) {
                                  final pid = _getEnigmaPhaseId(e);
                                  return pid == targetPhase.objectId;
                                }).length;
                                final int nextOrder = existingInPhase + 1;

                                final res = await ParseCloudFunction('createOrUpdateEnigma').execute(
                                  parameters: {
                                    'enigmaId': enigma.objectId,
                                    'eventId': event.objectId,
                                    'phaseId': targetPhase.objectId,
                                    'data': {
                                      'order': nextOrder,
                                      'prize': '0',
                                    },
                                  },
                                );

                                if (res.success) {
                                  if (context.mounted) Navigator.of(context).pop();
                                  onRefresh();
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildButton('Fechar', onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoveEnigmaPhaseDialog(
    BuildContext context,
    ParseObject event,
    ParseObject currentPhase,
    ParseObject enigma,
    VoidCallback onRefresh,
  ) {
    final otherPhases = _cockpitPhases.where((p) => p.objectId != currentPhase.objectId).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AdminModal(
          title: 'Mover Enigma para outra Fase',
          maxWidth: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enigma.get<String>('instruction') ?? 'Enigma',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Text(
                'Selecione a fase de destino:',
                style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (otherPhases.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Não há outras fases cadastradas neste evento.',
                    style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13),
                  ),
                )
              else
                ...otherPhases.map((targetP) {
                  final pOrder = targetP.get<num>('order') ?? 1;
                  final pTitle = targetP.get<String>('title') ?? 'Fase $pOrder';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: cardColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: primaryAmber.withValues(alpha: 0.1)),
                      ),
                      title: Text(pTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: _buildButton(
                        'Mover para cá',
                        isPrimary: true,
                        onTap: () async {
                          final existingInPhase = _cockpitEnigmas.where((e) {
                            final pid = _getEnigmaPhaseId(e);
                            return pid == targetP.objectId;
                          }).length;
                          final nextOrder = existingInPhase + 1;

                          final res = await ParseCloudFunction('createOrUpdateEnigma').execute(
                            parameters: {
                              'enigmaId': enigma.objectId,
                              'eventId': event.objectId,
                              'phaseId': targetP.objectId,
                              'data': {
                                'order': nextOrder,
                                'prize': '0',
                              },
                            },
                          );
                          if (res.success) {
                            if (context.mounted) Navigator.of(context).pop();
                            onRefresh();
                          }
                        },
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 10),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 10),
              ListTile(
                tileColor: dangerColor.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: dangerColor.withValues(alpha: 0.2)),
                ),
                title: const Text(
                  'Desvincular da Fase (Deixar Avulso)',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                subtitle: Text(
                  'O enigma continuará no evento, mas sem fase atribuída.',
                  style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 11),
                ),
                trailing: _buildButton(
                  'Desvincular',
                  isDanger: true,
                  onTap: () async {
                    final res = await ParseCloudFunction('createOrUpdateEnigma').execute(
                      parameters: {
                        'enigmaId': enigma.objectId,
                        'eventId': event.objectId,
                        'phaseId': '',
                        'data': {'prize': '0'},
                      },
                    );
                    if (res.success) {
                      if (context.mounted) Navigator.of(context).pop();
                      onRefresh();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildButton('Cancelar', onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  //  10. MODAIS DE EVENTO (CRIAR E EDITAR) COM PREVIEW DA TAG
  // =========================================================================
  void _showAddEventModal(BuildContext context) {
    final nomeController = TextEditingController();
    final premioController = TextEditingController();
    final descricaoController = TextEditingController();
    final localController = TextEditingController();
    String status = 'open';
    String eventType = 'classic';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AdminModal(
              title: 'Criar Novo Evento',
              maxWidth: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildInputForm(
                    controller: nomeController,
                    hint: 'Nome do evento (Ex: Caçada Vale do Aço)',
                  ),
                  const SizedBox(height: 12),
                  _buildInputForm(
                    controller: descricaoController,
                    hint: 'Descrição do evento',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildInputForm(
                    controller: localController,
                    hint: 'Local do evento (Cidade / Região)',
                  ),
                  const SizedBox(height: 12),
                  _buildInputForm(
                    controller: premioController,
                    hint: 'Prêmio Total Estimado (Ex: R\$ 5.000,00)',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectForm(
                          value: eventType,
                          items: const [
                            DropdownMenuItem(
                              value: 'classic',
                              child: Text('Classic (Fases Sequenciais)'),
                            ),
                            DropdownMenuItem(
                              value: 'find_and_win',
                              child: Text('Find & Win (Baús Instantâneos)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => eventType = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectForm(
                          value: status,
                          items: const [
                            DropdownMenuItem(value: 'open', child: Text('Ativo')),
                            DropdownMenuItem(value: 'em_breve', child: Text('Em breve')),
                            DropdownMenuItem(value: 'encerrado', child: Text('Encerrado')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => status = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildModalityTag(eventType, isLarge: true),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton(
                        'Cancelar',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      _buildButton(
                        'Criar Evento',
                        isPrimary: true,
                        onTap: () async {
                          if (nomeController.text.trim().isEmpty) return;

                          final resEvent = await ParseCloudFunction('createOrUpdateEvent').execute(
                            parameters: {
                              'data': {
                                'title': nomeController.text.trim(),
                                'description': descricaoController.text.trim(),
                                'location': localController.text.trim(),
                                'prizePool': _parseMoney(premioController.text.trim()).toString(),
                                'status': status,
                                'eventType': eventType,
                              },
                            },
                          );

                          if (!resEvent.success) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro: ${resEvent.error?.message}')),
                              );
                            }
                            return;
                          }

                          if (resEvent.success && resEvent.result != null && eventType == 'classic') {
                            String newEventId = resEvent.result is ParseObject
                                ? (resEvent.result as ParseObject).objectId!
                                : (resEvent.result is Map
                                    ? (resEvent.result['eventId'] ?? resEvent.result['objectId'] ?? '')
                                    : '');

                            if (newEventId.isNotEmpty) {
                              await ParseCloudFunction('createOrUpdatePhase').execute(
                                parameters: {
                                  'eventId': newEventId,
                                  'data': {
                                    'title': 'Fase 1',
                                    'order': 1,
                                    'status': 'open',
                                  },
                                },
                              );
                            }
                          }

                          if (context.mounted) Navigator.of(context).pop();
                          _loadEvents();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditEventModal(BuildContext context, ParseObject event) {
    final nomeController = TextEditingController(
      text: event.get<String>('title') ?? event.get<String>('name'),
    );
    final premioController = TextEditingController(
      text: event.get<dynamic>('prizePool')?.toString() ?? event.get<dynamic>('prize')?.toString(),
    );
    final descricaoController = TextEditingController(
      text: event.get<String>('description') ?? '',
    );
    final localController = TextEditingController(
      text: event.get<String>('location') ?? '',
    );
    String status = event.get<String>('status') ?? 'encerrado';
    String eventType = event.get<String>('eventType') ?? 'classic';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AdminModal(
              title: 'Editar Evento',
              maxWidth: 550,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildInputForm(
                          controller: nomeController,
                          hint: 'Nome do evento',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputForm(
                          controller: premioController,
                          hint: 'Prêmio Total',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectForm(
                          value: status,
                          items: const [
                            DropdownMenuItem(value: 'open', child: Text('Ativo')),
                            DropdownMenuItem(value: 'em_breve', child: Text('Em breve')),
                            DropdownMenuItem(value: 'encerrado', child: Text('Encerrado')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => status = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildInputForm(
                          controller: descricaoController,
                          hint: 'Descrição do evento',
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputForm(
                          controller: localController,
                          hint: 'Local do evento',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectForm(
                          value: eventType,
                          items: const [
                            DropdownMenuItem(value: 'classic', child: Text('Classic')),
                            DropdownMenuItem(value: 'find_and_win', child: Text('Find & Win')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => eventType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildModalityTag(eventType, isLarge: true),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildButton(
                        'Cancelar',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      _buildButton(
                        'Salvar Evento',
                        isPrimary: true,
                        onTap: () async {
                          final resEvent = await ParseCloudFunction('createOrUpdateEvent').execute(
                            parameters: {
                              'eventId': event.objectId,
                              'data': {
                                'title': nomeController.text.trim(),
                                'description': descricaoController.text.trim(),
                                'location': localController.text.trim(),
                                'prizePool': _parseMoney(premioController.text.trim()).toString(),
                                'status': status,
                                'eventType': eventType,
                              },
                            },
                          );

                          if (!resEvent.success) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro: ${resEvent.error?.message}')),
                              );
                            }
                            return;
                          }

                          if (context.mounted) Navigator.of(context).pop();
                          _loadEvents();
                          if (_selectedEvent?.objectId == event.objectId) {
                            _loadCockpitData(event.objectId ?? '');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportQRs(BuildContext context, ParseObject event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..whereEqualTo('eventId', event.objectId);
      final response = await query.query();

      if (!response.success || response.results == null || response.results!.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum enigma encontrado para exportar.')),
          );
        }
        return;
      }

      final doc = pw.Document();
      final enigmas = List<ParseObject>.from(response.results!);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('QR Codes - ${event.get<String>("title") ?? "Evento"}'),
              ),
              pw.Wrap(
                spacing: 20,
                runSpacing: 20,
                children: enigmas.map((enigma) {
                  final code = enigma.get<String>('code') ?? '';
                  final name = enigma.get<String>('instruction') ?? 'Sem Nome';
                  if (code.isEmpty) return pw.SizedBox();

                  return pw.Container(
                    width: 150,
                    child: pw.Column(
                      children: [
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: code,
                          width: 120,
                          height: 120,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(name, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(code, style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'QRCodes_${event.get<String>("title") ?? "Evento"}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exportação concluída!')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
      }
    }
  }

  Future<void> _publishAllEnigmas(BuildContext context, ParseObject event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..whereEqualTo('eventId', event.objectId);
      final response = await query.query();

      if (!response.success || response.results == null || response.results!.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum enigma encontrado.')),
          );
        }
        return;
      }

      final enigmas = List<ParseObject>.from(response.results!);
      final futures = <Future>[];

      for (var e in enigmas) {
        if (e.get<String>('status') != 'open') {
          futures.add(
            ParseCloudFunction('createOrUpdateEnigma').execute(
              parameters: {
                'enigmaId': e.objectId,
                'data': {'status': 'open'},
              },
            ),
          );
        }
      }

      await Future.wait(futures);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enigmas publicados com sucesso!')),
        );
        _loadCockpitData(event.objectId ?? '');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao publicar: $e')));
      }
    }
  }

  Future<void> _duplicateEvent(BuildContext context, ParseObject event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resEvent = await ParseCloudFunction('createOrUpdateEvent').execute(
        parameters: {
          'data': {
            'title': '${event.get<String>("title") ?? "Evento"} (Cópia)',
            'description': event.get<String>('description') ?? '',
            'location': event.get<String>('location') ?? '',
            'prizePool': _parseMoney(event.get<dynamic>('prizePool')?.toString() ?? '0').toString(),
            'status': 'em_breve',
            'eventType': event.get<String>('eventType') ?? 'classic',
          },
        },
      );

      if (!resEvent.success || resEvent.result == null) {
        throw 'Falha ao duplicar o evento principal.';
      }

      final newEventId = resEvent.result is ParseObject
          ? (resEvent.result as ParseObject).objectId!
          : (resEvent.result is Map ? (resEvent.result['eventId'] ?? resEvent.result['objectId'] ?? '') : '');

      if (newEventId.isEmpty) throw 'ID do novo evento inválido.';

      // Copia Fases
      final queryPhases = QueryBuilder<ParseObject>(ParseObject('Phase'))
        ..whereEqualTo('eventId', event.objectId);
      final phasesRes = await queryPhases.query();
      if (phasesRes.success && phasesRes.results != null) {
        final phaseFutures = <Future>[];
        for (var oldPhase in phasesRes.results!) {
          final p = oldPhase as ParseObject;
          phaseFutures.add(
            ParseCloudFunction('createOrUpdatePhase').execute(
              parameters: {
                'eventId': newEventId,
                'data': {
                  'title': p.get<String>('title') ?? 'Fase',
                  'order': p.get<num>('order')?.toInt() ?? 1,
                  'status': 'bloqueado',
                },
              },
            ),
          );
        }
        await Future.wait(phaseFutures);
      }

      // Copia Enigmas
      final queryEnigmas = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..whereEqualTo('eventId', event.objectId);
      final enigmasRes = await queryEnigmas.query();

      if (enigmasRes.success && enigmasRes.results != null) {
        for (var oldEnigma in enigmasRes.results!) {
          final enigmaObj = oldEnigma as ParseObject;
          final generatedHash =
              '${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}${DateTime.now().microsecond.toString().padLeft(3, '0')}';

          final resNewEnigma = await ParseCloudFunction('createOrUpdateEnigma').execute(
            parameters: {
              'eventId': newEventId,
              'data': {
                'instruction': enigmaObj.get<String>('instruction'),
                'code': generatedHash,
                'order': enigmaObj.get<num>('order'),
                'type': enigmaObj.get<String>('type'),
                'difficulty': enigmaObj.get<String>('difficulty'),
                'prize': enigmaObj.get<dynamic>('prize')?.toString() ?? '0',
                'status': 'bloqueado',
                'hasCompass': enigmaObj.get<bool>('hasCompass') ?? false,
                'compassCoords': enigmaObj.get<String>('compassCoords') ?? '',
                'compassPrice': enigmaObj.get<num>('compassPrice')?.toDouble() ?? 15.0,
                'compassDuration': enigmaObj.get<num>('compassDuration')?.toInt() ?? 0,
                'hasRadar': enigmaObj.get<bool>('hasRadar') ?? false,
                'hasMap': enigmaObj.get<bool>('hasMap') ?? false,
                'radarPrice': enigmaObj.get<num>('radarPrice')?.toDouble() ?? 2.99,
                'mapPrice': enigmaObj.get<num>('mapPrice')?.toDouble() ?? 4.99,
                'imageUrl': enigmaObj.get<String>('imageUrl') ?? '',
                'audioUrl': enigmaObj.get<String>('audioUrl') ?? '',
              },
            },
          );

          if (resNewEnigma.success && resNewEnigma.result != null) {
            String newEnigmaId = resNewEnigma.result is ParseObject
                ? (resNewEnigma.result as ParseObject).objectId!
                : (resNewEnigma.result is Map
                    ? (resNewEnigma.result['enigmaId'] ?? resNewEnigma.result['objectId'] ?? '')
                    : '');
            if (newEnigmaId.isNotEmpty) {
              final queryHints = QueryBuilder<ParseObject>(ParseObject('Hint'))
                ..whereEqualTo('linkedEnigmaId', enigmaObj.objectId);
              final hintsRes = await queryHints.query();
              if (hintsRes.success && hintsRes.results != null) {
                final hintFutures = <Future>[];
                for (var oldHint in hintsRes.results!) {
                  final hintObj = oldHint as ParseObject;
                  hintFutures.add(
                    ParseCloudFunction('createOrUpdateHint').execute(
                      parameters: {
                        'data': {
                          'description': hintObj.get<String>('description'),
                          'price': hintObj.get<num>('price')?.toDouble() ?? 0.0,
                          'linkedEnigmaId': newEnigmaId,
                        },
                      },
                    ),
                  );
                }
                await Future.wait(hintFutures);
              }
            }
          }
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento duplicado com sucesso!')));
        _loadEvents();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao duplicar evento: $e')));
      }
    }
  }

  Future<void> _deleteEvent(ParseObject event) async {
    final title = event.get<String>('title') ?? event.get<String>('name') ?? 'este evento';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sidebarBackground,
        title: Text('Excluir $title?', style: GoogleFonts.orbitron(color: primaryAmber)),
        content: Text(
          'Deseja excluir permanentemente este evento e todas as suas fases, enigmas e dicas vinculadas? Esta ação é irreversível.',
          style: GoogleFonts.inter(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir Tudo', style: TextStyle(color: dangerColor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ParseCloudFunction('deleteEvent').execute(
        parameters: {'eventId': event.objectId},
      );
      if (res.success) {
        if (_selectedEvent?.objectId == event.objectId) {
          setState(() => _selectedEvent = null);
        }
        _loadEvents();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: ${res.error?.message}')),
          );
        }
      }
    }
  }

  // =========================================================================
  //  11. WIDGETS E HELPERS AUXILIARES
  // =========================================================================
  double _parseMoney(String input) {
    String clean = input.replaceAll('R\$', '').trim();
    if (clean.contains(',') && clean.contains('.')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    } else if (clean.contains(',')) {
      clean = clean.replaceAll(',', '.');
    }
    return double.tryParse(clean) ?? 0.0;
  }

  Widget _buildSectionTitle(String title, dynamic icon, {bool showLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisSize: showLine ? MainAxisSize.max : MainAxisSize.min,
        children: [
          FaIcon(icon, color: primaryAmber, size: 14),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.orbitron(
              color: primaryAmber,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          if (showLine) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryAmber.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AdminItemCard(
      icon: FontAwesomeIcons.circleInfo,
      title: 'Nenhum evento encontrado',
      statusText: '',
      statusColor: Colors.transparent,
      subtitle: 'Nenhum evento corresponde aos filtros selecionados. Clique em "Novo Evento" para criar um.',
    );
  }

  Widget _buildAddButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: primaryAmber.withValues(alpha: 0.15),
            width: 1.5,
            style: BorderStyle.none,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.circlePlus,
                color: primaryAmber,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    String text, {
    bool isPrimary = false,
    bool isDanger = false,
    bool isWarning = false,
    required VoidCallback onTap,
  }) {
    Color bgColor = Colors.transparent;
    Color textColorStr = primaryAmberHover;
    Color borderColor = primaryAmber.withValues(alpha: 0.2);

    if (isPrimary) {
      bgColor = primaryAmber;
      textColorStr = Colors.white;
      borderColor = Colors.transparent;
    } else if (isDanger) {
      textColorStr = dangerColor;
      borderColor = dangerColor.withValues(alpha: 0.3);
    } else if (isWarning) {
      textColorStr = warningColor;
      borderColor = warningColor.withValues(alpha: 0.3);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.inter(
            color: textColorStr,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: secondaryTextColor.withValues(alpha: 0.5), fontSize: 13),
        filled: true,
        fillColor: cardColor.withValues(alpha: 0.8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryAmber.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAmber),
        ),
      ),
    );
  }

  Widget _buildSelectForm({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryAmber.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: sidebarBackground,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryAmber.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(startX - dashWidth, size.height),
        paint,
      );
      startX -= dashWidth + dashSpace;
    }
    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
