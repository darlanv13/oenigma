import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/creator_studio/features/creator/utils/creator_tenant_util.dart';

class CreatorPricingScreen extends StatefulWidget {
  const CreatorPricingScreen({super.key});

  @override
  State<CreatorPricingScreen> createState() => _CreatorPricingScreenState();
}

class _CreatorPricingScreenState extends State<CreatorPricingScreen> {
  List<ParseObject> _events = [];
  String? _selectedEventId;
  ParseObject? _selectedEvent;
  bool _isLoading = false;

  final TextEditingController _ticketPriceController = TextEditingController();
  final TextEditingController _prizeController = TextEditingController();
  final TextEditingController _compassPriceController = TextEditingController(text: '15.00');
  final TextEditingController _mapPriceController = TextEditingController(text: '4.99');
  final TextEditingController _radarPriceController = TextEditingController(text: '2.99');
  final TextEditingController _hintDefaultPriceController = TextEditingController(text: '1.99');

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _ticketPriceController.dispose();
    _prizeController.dispose();
    _compassPriceController.dispose();
    _mapPriceController.dispose();
    _radarPriceController.dispose();
    _hintDefaultPriceController.dispose();
    super.dispose();
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
          _selectEvent(_events.first);
        } else {
          _selectedEvent = null;
          _selectedEventId = null;
        }
      } else {
        _events = [];
        _selectedEvent = null;
        _selectedEventId = null;
      }
      setState(() => _isLoading = false);
    }
  }

  void _selectEvent(ParseObject event) {
    setState(() {
      _selectedEvent = event;
      _selectedEventId = event.objectId;
      _ticketPriceController.text = (event.get<num>('price') ?? 0.0).toStringAsFixed(2);
      _prizeController.text = event.get<String>('prize') ?? (event.get<num>('prizePool') ?? 0.0).toString();
      _compassPriceController.text = (event.get<num>('compassPrice') ?? 15.0).toStringAsFixed(2);
      _mapPriceController.text = (event.get<num>('mapPrice') ?? 4.99).toStringAsFixed(2);
      _radarPriceController.text = (event.get<num>('radarPrice') ?? 2.99).toStringAsFixed(2);
      _hintDefaultPriceController.text = (event.get<num>('hintPrice') ?? 1.99).toStringAsFixed(2);
    });
  }

  Future<void> _savePricing() async {
    if (_selectedEvent == null) return;

    final price = double.tryParse(_ticketPriceController.text.replaceAll(',', '.')) ?? 0.0;
    final compassPrice = double.tryParse(_compassPriceController.text.replaceAll(',', '.')) ?? 15.0;
    final mapPrice = double.tryParse(_mapPriceController.text.replaceAll(',', '.')) ?? 4.99;
    final radarPrice = double.tryParse(_radarPriceController.text.replaceAll(',', '.')) ?? 2.99;
    final hintPrice = double.tryParse(_hintDefaultPriceController.text.replaceAll(',', '.')) ?? 1.99;

    _selectedEvent!.set('price', price);
    _selectedEvent!.set('prize', _prizeController.text.trim());
    _selectedEvent!.set('compassPrice', compassPrice);
    _selectedEvent!.set('mapPrice', mapPrice);
    _selectedEvent!.set('radarPrice', radarPrice);
    _selectedEvent!.set('hintPrice', hintPrice);

    final res = await _selectedEvent!.save();
    if (mounted) {
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tabela de preços e economia atualizada com sucesso!'),
            backgroundColor: AppColors.verdeVale,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar preços: ${res.error?.message}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildEventPicker(),
          const SizedBox(height: 20),
          if (_selectedEvent != null) ...[
            _buildEconomyCards(),
            const SizedBox(height: 24),
            _buildPricingForm(),
          ] else if (!_isLoading)
            const Center(
              child: Text(
                'Nenhum evento selecionado para precificação.',
                style: TextStyle(color: Colors.white60),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precificação & Economia do Jogo',
          style: GoogleFonts.cinzel(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Defina os valores de ingressos, premiações e itens do arsenal tático.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.cinzaMedio,
          ),
        ),
      ],
    );
  }

  Widget _buildEventPicker() {
    if (_events.isEmpty) {
      return const SizedBox.shrink();
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
          hint: const Text('Selecione o Evento'),
          items: _events.map((e) {
            return DropdownMenuItem<String>(
              value: e.objectId,
              child: Text('🎯 ${e.get<String>('title') ?? 'Sem título'}'),
            );
          }).toList(),
          onChanged: (newId) {
            if (newId != null) {
              final ev = _events.firstWhere((e) => e.objectId == newId);
              _selectEvent(ev);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEconomyCards() {
    final players = _selectedEvent?.get<num>('playerCount')?.toInt() ?? 0;
    final price = double.tryParse(_ticketPriceController.text.replaceAll(',', '.')) ?? 0.0;
    final revenue = players * price;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Caçadores Inscritos',
            value: '$players',
            icon: FontAwesomeIcons.users,
            color: AppColors.amareloVale,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Receita de Inscrições',
            value: 'R\$ ${revenue.toStringAsFixed(2)}',
            icon: FontAwesomeIcons.sackDollar,
            color: AppColors.verdeVale,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Premiação Atual',
            value: _prizeController.text.isEmpty ? 'A definir' : _prizeController.text,
            icon: FontAwesomeIcons.trophy,
            color: Colors.amberAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required dynamic icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              icon is IconData
                  ? Icon(icon, size: 16, color: color)
                  : FaIcon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurações de Valores e Taxas',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ticketPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço do Ingresso / Inscrição (R\$)',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _prizeController,
                  decoration: const InputDecoration(
                    labelText: 'Valor / Descrição do Prêmio',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Text(
            'Preços dos Itens do Arsenal (Ferramentas de Jogo)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.amareloVale,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _compassPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço Bússola Tática (R\$)',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _mapPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço Mapa de Raio (R\$)',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _radarPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço Radar (R\$)',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hintDefaultPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço Padrão de Dicas (R\$)',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _savePricing,
              icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 15),
              label: const Text('Salvar Tabela de Preços'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeVale,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
