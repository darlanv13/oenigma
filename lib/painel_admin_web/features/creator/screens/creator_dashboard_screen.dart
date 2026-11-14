import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';

class CreatorDashboardScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;
  final VoidCallback? onOpenWizard;

  const CreatorDashboardScreen({
    super.key,
    this.onNavigateTab,
    this.onOpenWizard,
  });

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  bool _isLoading = true;
  ParseUser? _currentUser;
  List<ParseObject> _myEvents = [];

  // KPIs do Influenciador
  int _totalParticipants = 0;
  int _activeEventsCount = 0;
  double _grossRevenue = 0.0;
  double _platformFees = 0.0;
  double _netBalance = 0.0;
  double _totalEarned = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCreatorData();
  }

  Future<void> _loadCreatorData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      _currentUser = user;

      if (user != null) {
        // 1. Busca os desafios do criador
        final query = QueryBuilder<ParseObject>(ParseObject('Event'))
          ..orderByDescending('createdAt');

        // Se o usuário não for super_admin com visão total, filtra pelos eventos dele
        final role = user.get<String>('role') ?? 'player';
        final isAdmin = user.get<bool>('isAdmin') ?? false;

        if (role == 'creator' || !isAdmin) {
          query.whereEqualTo('creatorId', user.objectId);
        }

        final response = await query.query();
        if (response.success && response.results != null) {
          _myEvents = List<ParseObject>.from(response.results!);
        } else {
          _myEvents = [];
        }

        // 2. Calcula métricas dos eventos
        int participants = 0;
        int active = 0;
        for (var ev in _myEvents) {
          final count = ev.get<dynamic>('playerCount');
          if (count is num) participants += count.toInt();
          final status = ev.get<String>('status') ?? 'open';
          if (status == 'open') active++;
        }
        _totalParticipants = participants;
        _activeEventsCount = active;

        // 3. Saldo atual do usuário no Parse
        _netBalance = (user.get<num>('balance') ?? 0.0).toDouble();
        _totalEarned = (user.get<num>('totalEarned') ?? 0.0).toDouble();

        // 4. Busca transações do criador para faturamento bruto
        final txQuery = QueryBuilder<ParseObject>(ParseObject('Transaction'))
          ..whereEqualTo('creatorId', user.objectId)
          ..whereEqualTo('status', 'approved');

        final txRes = await txQuery.query();
        double gross = 0.0;
        double fees = 0.0;
        if (txRes.success && txRes.results != null) {
          for (var tx in txRes.results!) {
            final g = (tx.get<num>('grossAmount') ?? tx.get<num>('amount') ?? 0.0).toDouble();
            final f = (tx.get<num>('feeAmount') ?? 0.0).toDouble();
            gross += g;
            fees += f;
          }
        }
        _grossRevenue = gross;
        _platformFees = fees;
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do criador: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyLink(String slug) {
    final domain = 'https://oenigma.com.br/e/$slug';
    Clipboard.setData(ClipboardData(text: domain));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copiado: $domain'),
        backgroundColor: AppColors.verdeVale,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.verdeVale),
      );
    }

    final creatorName = _currentUser?.get<String>('name') ??
        _currentUser?.get<String>('username') ??
        'Criador';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Superior de Boas-Vindas & Ação Rápida
          _buildHeroHeader(creatorName),
          const SizedBox(height: 20),

          // Cards de Métricas Principais (KPIs)
          _buildKpisGrid(),
          const SizedBox(height: 24),

          // Seção "Meus Desafios"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.bullhorn,
                    color: AppColors.amareloVale,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Seus Desafios Lançados',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.plus, size: 13),
                label: const Text('Novo Desafio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeVale,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: widget.onOpenWizard,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lista de Desafios ou Estado Vazio
          if (_myEvents.isEmpty)
            _buildEmptyState()
          else
            _buildEventsList(),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(String name) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        if (isMobile) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF13222A),
                  AppColors.verdeVale.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.wandMagicSparkles,
                        color: AppColors.amareloVale,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Olá, $name! 🚀',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Crie desafios misteriosos para sua audiência, insira vídeos e dicas, e monetize com inscrições e Super Dicas.',
                  style: GoogleFonts.poppins(
                    color: AppColors.cinzaMedio,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: widget.onOpenWizard,
                    icon: const FaIcon(FontAwesomeIcons.rocket, size: 14),
                    label: const Text('Lançar Novo Desafio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloVale,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF13222A),
                AppColors.verdeVale.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.wandMagicSparkles,
                  color: AppColors.amareloVale,
                  size: 26,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $name! 🚀',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crie desafios misteriosos para sua audiência, insira vídeos e dicas, e monetize com inscrições e Super Dicas.',
                      style: GoogleFonts.poppins(
                        color: AppColors.cinzaMedio,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: widget.onOpenWizard,
                icon: const FaIcon(FontAwesomeIcons.rocket, size: 14),
                label: const Text('Lançar Desafio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amareloVale,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpisGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
        final aspectRatio = constraints.maxWidth > 900
            ? 1.8
            : (constraints.maxWidth > 500 ? 1.55 : 1.38);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: aspectRatio,
          children: [
            _buildKpiCard(
              title: 'Participantes',
              value: '$_totalParticipants',
              subtitle: 'Seguidores que jogaram',
              icon: FontAwesomeIcons.users,
              iconColor: AppColors.info,
            ),
            _buildKpiCard(
              title: 'Faturamento Bruto',
              value: 'R\$ ${_grossRevenue.toStringAsFixed(2)}',
              subtitle: 'Inscrições + Super Dicas',
              icon: FontAwesomeIcons.sackDollar,
              iconColor: AppColors.amareloVale,
            ),
            _buildKpiCard(
              title: 'Taxa da Plataforma',
              value: 'R\$ ${_platformFees.toStringAsFixed(2)}',
              subtitle: '15% de serviço',
              icon: FontAwesomeIcons.shieldHalved,
              iconColor: AppColors.cinzaMedio,
            ),
            _buildKpiCard(
              title: 'Saldo Disponível',
              value: 'R\$ ${_netBalance.toStringAsFixed(2)}',
              subtitle: 'Pronto para saque Pix',
              icon: FontAwesomeIcons.bolt,
              iconColor: AppColors.verdeVale,
              highlight: true,
              actionLabel: 'Sacar Pix',
              onAction: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(3); // Aba Financeiro
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required dynamic icon,
    required Color iconColor,
    bool highlight = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.verdeVale.withValues(alpha: 0.5)
              : AppColors.darkCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: AppColors.cinzaMedio,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              FaIcon(icon, color: iconColor, size: 16),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: highlight ? AppColors.amareloVale : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (actionLabel != null && onAction != null)
                InkWell(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.verdeVale,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      actionLabel,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: AppColors.cinzaMedio.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(
              FontAwesomeIcons.compassDrafting,
              color: AppColors.verdeVale,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Você ainda não criou nenhum desafio',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Clique no botão abaixo para criar seu primeiro enigma com vídeo, pistas e link de divulgação.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.cinzaMedio,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: widget.onOpenWizard,
            icon: const FaIcon(FontAwesomeIcons.plus, size: 13),
            label: const Text('Criar Meu Primeiro Desafio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ev = _myEvents[index];
        final title = ev.get<String>('name') ?? 'Desafio sem título';
        final slug = ev.get<String>('slug') ?? ev.objectId ?? '';
        final price = (ev.get<num>('price') ?? 0.0).toDouble();
        final prize = ev.get<String>('prize') ?? 'R\$ 0,00';
        final playerCount = ev.get<num>('playerCount') ?? 0;
        final status = ev.get<String>('status') ?? 'open';
        final bannerUrl = ev.get<String>('prizeImageUrl') ?? ev.get<String>('icon') ?? '';
        final isFree = price <= 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkCardBorder),
          ),
          child: Row(
            children: [
              // Thumbnail / Ícone do Desafio
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  image: bannerUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(bannerUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: bannerUrl.isEmpty
                    ? const Center(
                        child: FaIcon(
                          FontAwesomeIcons.puzzlePiece,
                          color: AppColors.amareloVale,
                          size: 22,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Informações do Desafio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isFree
                                ? Colors.blueAccent.withValues(alpha: 0.15)
                                : AppColors.amareloVale.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFree ? 'GRÁTIS' : 'R\$ ${price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: isFree ? Colors.blueAccent : AppColors.amareloVale,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: status == 'open'
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status == 'open' ? 'ATIVO' : 'ENCERRADO',
                            style: GoogleFonts.poppins(
                              color: status == 'open' ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prêmio: $prize • $playerCount participantes inscritos',
                      style: GoogleFonts.poppins(
                        color: AppColors.cinzaMedio,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Botões de Ação
              OutlinedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.copy, size: 12),
                label: const Text('Copiar Link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.amareloVale,
                  side: const BorderSide(color: AppColors.amareloVale),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _copyLink(slug),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.qrcode, size: 12),
                label: const Text('Divulgar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeVale,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(2); // Aba de Divulgação
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
