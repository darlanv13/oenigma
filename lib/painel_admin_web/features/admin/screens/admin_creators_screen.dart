import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';

class AdminCreatorsScreen extends StatefulWidget {
  final Function(String creatorId)? onViewCreatorEvents;

  const AdminCreatorsScreen({super.key, this.onViewCreatorEvents});

  @override
  State<AdminCreatorsScreen> createState() => _AdminCreatorsScreenState();
}

class _AdminCreatorsScreenState extends State<AdminCreatorsScreen> {
  bool _isLoading = true;
  List<ParseUser> _creators = [];
  List<ParseUser> _filteredCreators = [];
  final _searchController = TextEditingController();

  // KPIs dos Tenants
  int _totalCreators = 0;
  int _totalEventsByCreators = 0;
  double _totalGmv = 0.0;
  double _totalPlatformProfit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCreators();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCreators = List.from(_creators);
      } else {
        _filteredCreators = _creators.where((c) {
          final name = (c.get<String>('name') ?? '').toLowerCase();
          final username = (c.get<String>('username') ?? '').toLowerCase();
          final email = (c.get<String>('email') ?? '').toLowerCase();
          final pix = (c.get<String>('pixKey') ?? '').toLowerCase();
          return name.contains(query) ||
              username.contains(query) ||
              email.contains(query) ||
              pix.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadCreators() async {
    setState(() => _isLoading = true);
    try {
      // 1. Busca todos os usuários com papel de 'creator' ou que criaram eventos
      final query = QueryBuilder<ParseUser>(ParseUser(null, null, null))
        ..whereEqualTo('role', 'creator')
        ..orderByDescending('createdAt');

      final res = await query.query();
      if (res.success && res.results != null) {
        _creators = List<ParseUser>.from(res.results!);
      } else {
        _creators = [];
      }

      // 2. Busca todos os eventos para cruzar dados de tenancy
      final evQuery = QueryBuilder<ParseObject>(ParseObject('Event'));
      final evRes = await evQuery.query();
      final allEvents = evRes.success && evRes.results != null
          ? List<ParseObject>.from(evRes.results!)
          : <ParseObject>[];

      _totalEventsByCreators = allEvents.length;

      // 3. Busca transações para calcular GMV e lucro da plataforma
      final txQuery = QueryBuilder<ParseObject>(ParseObject('Transaction'))
        ..whereEqualTo('status', 'approved');
      final txRes = await txQuery.query();

      double gmv = 0.0;
      double fees = 0.0;
      if (txRes.success && txRes.results != null) {
        for (var tx in txRes.results!) {
          final gross = (tx.get<num>('grossAmount') ?? tx.get<num>('amount') ?? 0.0).toDouble();
          final fee = (tx.get<num>('feeAmount') ?? (gross * 0.15)).toDouble();
          gmv += gross;
          fees += fee;
        }
      }

      _totalCreators = _creators.length;
      _totalGmv = gmv;
      _totalPlatformProfit = fees;
      _filteredCreators = List.from(_creators);
    } catch (e) {
      debugPrint('Erro ao carregar criadores/tenants: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editPlatformFee(ParseUser creator) {
    final currentFee = creator.get<num>('platformFeePercent') ?? 15.0;
    final controller = TextEditingController(text: currentFee.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Taxa da Plataforma para este Criador',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Criador: ${creator.get<String>('name') ?? creator.get<String>('username')}',
              style: GoogleFonts.poppins(color: AppColors.amareloVale, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Porcentagem de Comissão (%)',
                labelStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio),
                suffixText: '%',
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verdeVale),
            onPressed: () async {
              final newFee = double.tryParse(controller.text.trim()) ?? 15.0;
              creator.set('platformFeePercent', newFee);
              await creator.save();
              if (mounted) {
                Navigator.pop(ctx);
                _loadCreators();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Comissão atualizada para $newFee%!'), backgroundColor: AppColors.verdeVale),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.verdeVale));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Superior
          _buildHeroKpis(),
          const SizedBox(height: 20),

          // Barra de Pesquisa e Filtro
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar criador por nome, @handle, e-mail ou chave Pix...',
                    hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: AppColors.cinzaMedio, size: 18),
                    filled: true,
                    fillColor: AppColors.darkCardColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.darkCardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeVale,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: _loadCreators,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tabela de Criadores / Tenants
          _buildCreatorsTable(),
        ],
      ),
    );
  }

  Widget _buildHeroKpis() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxis = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxis,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 2.0,
          children: [
            _buildKpiCard('CRIADORES ATIVOS', '$_totalCreators', 'Influenciadores parceiros', FontAwesomeIcons.usersViewfinder, AppColors.info),
            _buildKpiCard('DESAFIOS CRIADOS', '$_totalEventsByCreators', 'Eventos nos Studios', FontAwesomeIcons.puzzlePiece, AppColors.amareloVale),
            _buildKpiCard('VOLUME TOTAL (GMV)', 'R\$ ${_totalGmv.toStringAsFixed(2)}', 'Total movimentado no Pix', FontAwesomeIcons.sackDollar, Colors.greenAccent),
            _buildKpiCard('LUCRO DA PLATAFORMA', 'R\$ ${_totalPlatformProfit.toStringAsFixed(2)}', '15% taxa de serviço retida', FontAwesomeIcons.vault, AppColors.amareloVale, highlight: true),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, dynamic icon, Color color, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? AppColors.verdeVale.withValues(alpha: 0.5) : AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              FaIcon(icon, color: color, size: 16),
            ],
          ),
          Text(value, style: GoogleFonts.poppins(color: highlight ? AppColors.amareloVale : Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(subtitle, style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCreatorsTable() {
    if (_filteredCreators.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkCardBorder),
        ),
        child: Center(
          child: Text('Nenhum influenciador encontrado com os filtros atuais.', style: GoogleFonts.poppins(color: AppColors.cinzaMedio)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.darkBackground),
        columns: const [
          DataColumn(label: Text('INFLUENCIADOR / TENANT')),
          DataColumn(label: Text('E-MAIL')),
          DataColumn(label: Text('CHAVE PIX')),
          DataColumn(label: Text('SALDO DO CRIADOR')),
          DataColumn(label: Text('COMISSÃO PLATAFORMA')),
          DataColumn(label: Text('AÇÕES')),
        ],
        rows: _filteredCreators.map((c) {
          final name = c.get<String>('name') ?? c.get<String>('username') ?? 'Criador';
          final email = c.get<String>('email') ?? 'Sem e-mail';
          final pixKey = c.get<String>('pixKey') ?? 'Não cadastrada';
          final pixType = c.get<String>('pixKeyType') ?? 'PIX';
          final balance = (c.get<num>('balance') ?? 0.0).toDouble();
          final feePercent = (c.get<num>('platformFeePercent') ?? 15.0).toDouble();

          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.verdeVale.withValues(alpha: 0.2),
                      child: const FaIcon(FontAwesomeIcons.userAstronaut, size: 12, color: AppColors.amareloVale),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Role: Creator', style: GoogleFonts.poppins(color: AppColors.amareloVale, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(Text(email, style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12))),
              DataCell(
                Text(
                  '$pixKey ($pixType)',
                  style: GoogleFonts.poppins(color: pixKey.contains('Não') ? AppColors.cinzaMedio : Colors.white, fontSize: 12),
                ),
              ),
              DataCell(Text('R\$ ${balance.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$feePercent% retido', style: GoogleFonts.poppins(color: AppColors.verdeVale, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.sliders, color: AppColors.amareloVale, size: 14),
                      tooltip: 'Alterar Taxa da Plataforma',
                      onPressed: () => _editPlatformFee(c),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
