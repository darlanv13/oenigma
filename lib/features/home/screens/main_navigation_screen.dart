import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/home/providers/home_events_provider.dart';
import 'package:oenigma/features/home/screens/home_screen.dart';
import 'package:oenigma/features/profile/screens/profile_screen.dart';
import 'package:oenigma/features/ranking/screens/ranking_screen.dart';
import 'package:oenigma/features/wallet/screens/wallet_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homeEventsProvider);

    return Scaffold(
      backgroundColor: darkBackground,
      body: homeDataAsync.when(
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
                onPressed: () => ref.refresh(homeEventsProvider.future),
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
          final Map<String, dynamic> playerData = data['playerData'] != null
              ? Map<String, dynamic>.from(data['playerData'])
              : {};
          final List<dynamic> allPlayers = data['allPlayers'] ?? [];

          final List<Widget> screens = [
            const HomeScreen(),
            const WalletScreen(),
            RankingScreen(
              availableEvents: events.where((e) => e.status != 'closed').toList(),
              allPlayers: allPlayers,
            ),
            ProfileScreen(
              playerData: playerData,
              walletData: walletData,
            ),
          ];

          return screens[_selectedIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: cardColor,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryAmber,
        unselectedItemColor: secondaryTextColor,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.wallet),
            label: 'Carteira',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.trophy),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.user),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
