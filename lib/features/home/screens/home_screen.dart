import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/event/widgets/event_card.dart';
import 'package:oenigma/features/home/providers/home_events_provider.dart';
import 'package:oenigma/features/profile/screens/profile_screen.dart';
import 'package:oenigma/features/ranking/screens/ranking_screen.dart';
import 'package:oenigma/features/wallet/screens/wallet_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _reloadData() async {
    return await ref.refresh(homeEventsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homeEventsProvider);

    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: homeDataAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryAmber),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Erro ao carregar dados.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    '$error',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _reloadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Tentar Novamente"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          data: (data) {
            final List<EventModel> events = (data['events'] as List)
                .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e)))
                .toList();
            final UserWalletModel walletData = UserWalletModel.fromMap(
              Map<String, dynamic>.from(data['walletData']),
            );
            final Map<String, dynamic> playerData =
                data['playerData'] != null
                ? Map<String, dynamic>.from(data['playerData'])
                : {};
            final List<dynamic> allPlayers = data['allPlayers'] ?? [];

            _fadeController.forward();

            return RefreshIndicator(
              onRefresh: _reloadData,
              color: primaryAmber,
              backgroundColor: cardColor,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
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
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20.0,
                          16.0,
                          20.0,
                          8.0,
                        ),
                        child: _buildEventsSectionHeader(),
                      ),
                    ),
                  ),
                  _buildEventsGrid(events, playerData),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryAmber, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAmber.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: CircleAvatar(
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
                          size: 30,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $firstName!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.emoji_events, size: 14, color: primaryAmber),
                        const SizedBox(width: 4),
                        Text(
                          'Ranking: #${wallet.lastEventRank ?? '-'}',
                          style: const TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context: context,
                icon: Icons.account_balance_wallet_rounded,
                label: 'Carteira',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalletScreen(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context: context,
                icon: Icons.leaderboard_rounded,
                label: 'Ranking',
                onTap: () {
                  Navigator.push(
                    context,
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
                icon: Icons.person_rounded,
                label: 'Perfil',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: textColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: primaryAmber,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          "EVENTOS DISPONÍVEIS",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: secondaryTextColor,
            letterSpacing: 1.2,
          ),
        ),
      ],
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
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 40, color: secondaryTextColor),
                SizedBox(height: 16),
                Text(
                  'Nenhum evento ativo no momento.',
                  style: TextStyle(color: secondaryTextColor),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75, // Ajustado para melhor proporção
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          // Adiciona uma animação escalonada simples
          return FadeTransition(
            opacity: _fadeAnimation,
            child: EventCard(
              event: events[index],
              playerData: playerData,
              onReturn: _reloadData,
            ),
          );
        }, childCount: events.length),
      ),
    );
  }
}
