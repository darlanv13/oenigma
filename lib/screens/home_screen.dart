import 'package:flutter/material.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/screens/profile_screen.dart';
import 'package:oenigma/screens/ranking_screen.dart';
import 'package:oenigma/screens/wallet_screen.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../widgets/event_card.dart';

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
    _dataFuture = _firebaseService.getHomeScreenData();
  }

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Erro ao carregar dados.',
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _reloadData,
                      child: const Text("Tentar Novamente"),
                    ),
                  ],
                ),
              );
            }

            final allData = snapshot.data!;
            final List<EventModel> events = (allData['events'] as List)
                .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e)))
                .toList();
            final UserWalletModel walletData = UserWalletModel.fromMap(
              Map<String, dynamic>.from(allData['walletData']),
            );
            final Map<String, dynamic> playerData =
                allData['playerData'] != null
                ? Map<String, dynamic>.from(allData['playerData'])
                : {};
            final List<dynamic> allPlayers = allData['allPlayers'] ?? [];

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
                        playerData,
                        walletData,
                        events,
                        allPlayers,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                      child: _buildEventsSectionHeader(),
                    ),
                  ),
                  // CORREÇÃO APLICADA AQUI: Passando playerData como argumento
                  _buildEventsGrid(events, playerData),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFinalProfileCard(
    BuildContext context,
    Map<String, dynamic> playerData,
    UserWalletModel wallet,
    List<EventModel> events,
    List<dynamic> allPlayers,
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
                radius: 25,
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
                        fontSize: 18,
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
                        fontSize: 10,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32, thickness: 0.4, color: secondaryTextColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                context: context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Carteira',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WalletScreen(wallet: wallet),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context: context,
                icon: Icons.leaderboard_outlined,
                label: 'Ranking',
                onTap: () {
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
                label: 'Perfil   ',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        playerData: playerData,
                        walletData: wallet,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

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

  Widget _buildEventsGrid(
    List<EventModel> events,
    Map<String, dynamic> playerData,
  ) {
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
          (context, index) => EventCard(
            event: events[index],
            playerData: playerData,
            onReturn: _reloadData, // <-- PASSA A FUNÇÃO DE RECARREGAR AQUI
          ),
          childCount: events.length,
        ),
      ),
    );
  }
}
