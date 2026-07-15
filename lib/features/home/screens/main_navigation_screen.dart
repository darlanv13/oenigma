import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/features/home/providers/home_events_provider.dart';
import 'package:oenigma/features/home/screens/home_screen.dart';
import 'package:oenigma/features/home/widgets/svg_icon.dart';
import 'package:oenigma/features/profile/screens/profile_screen.dart';
import 'package:oenigma/features/ranking/screens/ranking_screen.dart';
import 'package:oenigma/features/wallet/screens/wallet_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
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
      backgroundColor: Colors.transparent,
      body: homeDataAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.circleExclamation,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar dados.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                icon: const FaIcon(
                  FontAwesomeIcons.rotateRight,
                  color: Colors.black,
                ),
                label: const Text(
                  "TENTAR NOVAMENTE",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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
              availableEvents: events
                  .where((e) => e.status != 'closed')
                  .toList(),
              allPlayers: allPlayers,
            ),
            ProfileScreen(playerData: playerData, walletData: walletData),
          ];

          return screens[_selectedIndex];
        },
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: const Color(0xFF1E1E1E), // Fundo escuro premium
          border: Border(
            top: BorderSide(
              color: const Color(
                0xFFFFD54F,
              ).withValues(alpha: 0.2), // Borda dourada sutil
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFFD54F), // Dourado
          unselectedItemColor: Colors.grey,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Opacity(
                  opacity: 0.5,
                  child: SvgNavIcon(assetPath: 'assets/icon/maps.svg'),
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: SvgNavIcon(assetPath: 'assets/icon/maps.svg'),
              ),
              label: 'Explorar',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Opacity(
                  opacity: 0.5,
                  child: SvgNavIcon(assetPath: 'assets/icon/chest.svg'),
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: SvgNavIcon(assetPath: 'assets/icon/chest.svg'),
              ),
              label: 'Tesouro',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Opacity(
                  opacity: 0.5,
                  child: SvgNavIcon(assetPath: 'assets/icon/ship.svg'),
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: SvgNavIcon(assetPath: 'assets/icon/ship.svg'),
              ),
              label: 'Ranking',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Opacity(
                  opacity: 0.5,
                  child: SvgNavIcon(assetPath: 'assets/icon/pirate.svg'),
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: SvgNavIcon(assetPath: 'assets/icon/pirate.svg'),
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
