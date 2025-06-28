import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/screens/wallet_screen.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../widgets/event_card.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _firebaseService.getHomeScreenData(); // <-- CHAMADA OTIMIZADA
  }

  // Função de recarregar
  Future<void> _reloadData() async {
    setState(() {
      _dataFuture = _firebaseService.getHomeScreenData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryAmber),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text('Erro ao carregar dados: ${snapshot.error}'),
              );
            }

            // Desempacota os dados da resposta única
            final allData = snapshot.data!;
            final List<EventModel> events = (allData['events'] as List)
                .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e)))
                .toList();
            final UserWalletModel walletData = UserWalletModel.fromMap(
              Map<String, dynamic>.from(allData['walletData']),
            );
            final List<dynamic> allPlayersRaw = allData['allPlayers'];

            return RefreshIndicator(
              onRefresh: _reloadData,
              color: primaryAmber,
              backgroundColor: cardColor,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildFinalProfileCard(
                        context,
                        walletData,
                        events,
                        allPlayersRaw,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                      child: _buildEventsSectionHeader(),
                    ),
                  ),
                  _buildEventsGrid(events),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Card de Perfil agora recebe os dados necessários para passar para a tela de Ranking
  Widget _buildFinalProfileCard(
    BuildContext context,
    UserWalletModel wallet,
    List<EventModel> events,
    List<dynamic> allPlayers, // Recebe a lista de todos os jogadores
  ) {
    final String firstName = wallet.name.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: darkBackground,
                backgroundImage:
                    (wallet.photoURL != null && wallet.photoURL!.isNotEmpty)
                    ? NetworkImage(wallet.photoURL!)
                    : null,
                child: (wallet.photoURL == null || wallet.photoURL!.isEmpty)
                    ? const Icon(
                        Icons.person_outline,
                        color: secondaryTextColor,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $firstName!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ranking: #${wallet.lastEventRank ?? '-'}',
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Saldo',
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${wallet.balance.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      color: primaryAmber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32, thickness: 0.5, color: secondaryTextColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context: context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Carteira',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WalletScreen(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context: context,
                icon: Icons.leaderboard_outlined,
                label: 'Ranking',
                onTap: () {
                  // Navega para o Ranking passando a lista de eventos e jogadores
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RankingScreen(
                        availableEvents: events
                            .where((e) => e.status != 'closed')
                            .toList(),
                        allPlayers: allPlayers,
                      ),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context: context,
                icon: Icons.settings_outlined,
                label: 'Perfil',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER PARA OS BOTÕES DE AÇÃO
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Demais widgets da tela (sem alteração)
  Widget _buildEventsSectionHeader() {
    return const Text(
      "EVENTOS DISPONÍVEIS",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: secondaryTextColor,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildEventsGrid(List<EventModel> events) {
    if (events.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Text(
              'Nenhum evento encontrado no momento.',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => EventCard(event: events[index]),
          childCount: events.length,
        ),
      ),
    );
  }
}
