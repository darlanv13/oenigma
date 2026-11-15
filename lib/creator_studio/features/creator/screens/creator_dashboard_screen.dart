import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/creator_studio/features/creator/utils/creator_tenant_util.dart';

class CreatorDashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const CreatorDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  bool _isLoading = true;
  int _totalEvents = 0;
  int _activeEvents = 0;
  int _totalEnigmas = 0;
  int _totalPlayers = 0;
  double _estimatedRevenue = 0.0;
  List<ParseObject> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
      final user = await CreatorTenantUtil.getCurrentUser();
      final isMaster = CreatorTenantUtil.isMasterAdmin(user);

      final eventsQuery = QueryBuilder<ParseObject>(ParseObject('Event'))
        ..orderByDescending('createdAt');
      final scopedEventsQuery = await CreatorTenantUtil.scopeEventQuery(eventsQuery);
      final eventsRes = await scopedEventsQuery.query();

      final enigmasQuery = QueryBuilder<ParseObject>(ParseObject('Enigma'));

      if (eventsRes.success && eventsRes.results != null) {
        final list = List<ParseObject>.from(eventsRes.results!);
        _totalEvents = list.length;
        _activeEvents = list.where((e) => e.get<String>('status') == 'open').length;
        _recentEvents = list.take(5).toList();

        int players = 0;
        double rev = 0.0;
        for (var ev in list) {
          final p = ev.get<num>('playerCount')?.toInt() ?? 0;
          final pr = (ev.get<num>('price') ?? 0.0).toDouble();
          players += p;
          rev += (p * pr);
        }
        _totalPlayers = players;
        _estimatedRevenue = rev;

        if (!isMaster) {
          final myEventIds = list.map((e) => e.objectId).whereType<String>().toList();
          if (myEventIds.isEmpty) {
            _totalEnigmas = 0;
          } else {
            enigmasQuery.whereContainedIn('eventId', myEventIds);
            final enigmasCountRes = await enigmasQuery.count();
            if (enigmasCountRes.success) {
              _totalEnigmas = enigmasCountRes.count;
            }
          }
        } else {
          final enigmasCountRes = await enigmasQuery.count();
          if (enigmasCountRes.success) {
            _totalEnigmas = enigmasCountRes.count;
          }
        }
      } else {
        _totalEvents = 0;
        _activeEvents = 0;
        _recentEvents = [];
        _totalPlayers = 0;
        _estimatedRevenue = 0.0;
        _totalEnigmas = 0;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 20),
          _buildKPIsGrid(),
          const SizedBox(height: 24),
          _buildQuickActionCards(),
          const SizedBox(height: 24),
          _buildRecentEventsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.verdeVale.withValues(alpha: 0.25),
            AppColors.darkCardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creator Studio',
                  style: GoogleFonts.cinzel(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crie e gerencie seus eventos, trilhas de fases, enigmas, dicas táticas e economia.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => widget.onNavigateTab?.call(1), // Aba Eventos
            icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
            label: const Text('Novo Evento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 1.8 : 1.3,
          children: [
            _buildStatCard(
              title: 'Eventos Criados',
              value: '$_totalEvents',
              subtitle: '$_activeEvents abertos',
              icon: FontAwesomeIcons.calendarCheck,
              color: AppColors.verdeVale,
            ),
            _buildStatCard(
              title: 'Enigmas Ativos',
              value: '$_totalEnigmas',
              subtitle: 'Charadas & GPS',
              icon: FontAwesomeIcons.puzzlePiece,
              color: AppColors.amareloVale,
            ),
            _buildStatCard(
              title: 'Caçadores Totais',
              value: '$_totalPlayers',
              subtitle: 'Inscritos nas trilhas',
              icon: FontAwesomeIcons.users,
              color: Colors.cyanAccent,
            ),
            _buildStatCard(
              title: 'Receita Bruta Est.',
              value: 'R\$ ${_estimatedRevenue.toStringAsFixed(2)}',
              subtitle: 'Ingressos & Ferramentas',
              icon: FontAwesomeIcons.sackDollar,
              color: Colors.greenAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required dynamic icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
              icon is IconData
                  ? Icon(icon, size: 16, color: color)
                  : FaIcon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas de Criação',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                title: 'Eventos',
                desc: 'Criar / Editar Eventos',
                icon: FontAwesomeIcons.calendarDay,
                onTap: () => widget.onNavigateTab?.call(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionBtn(
                title: 'Trilha de Fases',
                desc: 'Estruturar Fases',
                icon: FontAwesomeIcons.layerGroup,
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionBtn(
                title: 'Enigmas',
                desc: 'Charadas & QR Code',
                icon: FontAwesomeIcons.puzzlePiece,
                onTap: () => widget.onNavigateTab?.call(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionBtn(
                title: 'Arsenal & Preços',
                desc: 'Configurar Economia',
                icon: FontAwesomeIcons.coins,
                onTap: () => widget.onNavigateTab?.call(6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required String title,
    required String desc,
    required dynamic icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon is IconData
                ? Icon(icon, color: AppColors.amareloVale, size: 18)
                : FaIcon(icon, color: AppColors.amareloVale, size: 18),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Meus Eventos Recentes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateTab?.call(1),
              child: const Text('Ver Todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentEvents.isEmpty)
          const Text('Nenhum evento criado ainda.', style: TextStyle(color: Colors.white54))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentEvents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ev = _recentEvents[index];
              final title = ev.get<String>('title') ?? 'Sem título';
              final status = ev.get<String>('status') ?? 'draft';
              final price = (ev.get<num>('price') ?? 0.0).toDouble();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.mapLocationDot, color: AppColors.verdeVale, size: 16),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                    Text(
                      price > 0 ? 'R\$ ${price.toStringAsFixed(2)}' : 'GRÁTIS',
                      style: const TextStyle(color: AppColors.amareloVale, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: status == 'open'
                            ? AppColors.verdeVale.withValues(alpha: 0.2)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status == 'open' ? AppColors.verdeVale : Colors.white60,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
