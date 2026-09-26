import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/app_cliente/features/home/providers/home_events_provider.dart';
import 'package:oenigma/app_cliente/features/home/screens/home_screen.dart';
import 'package:oenigma/app_cliente/features/auth/screens/login_screen.dart';
import 'package:oenigma/app_cliente/features/profile/screens/profile_screen.dart';
import 'package:oenigma/app_cliente/features/ranking/screens/ranking_screen.dart';
import 'package:oenigma/app_cliente/features/wallet/screens/wallet_screen.dart';

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
      backgroundColor: Color(0xFFF0F4F8),
      body: homeDataAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.circleExclamation,
                size: 48,
                color: Color(0xFFF87171),
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar dados.',
                style: TextStyle(
                  color: const Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  '$error',
                  style: TextStyle(color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(homeEventsProvider.future),
                icon: const FaIcon(
                  FontAwesomeIcons.rotateRight,
                  color: Color(0xFF4C1D95),
                ),
                label: const Text(
                  "TENTAR NOVAMENTE",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFC4B5FD),
                  foregroundColor: Color(0xFF4C1D95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
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

          final bool isGuest = walletData.objectId == "visitante";

          final List<Widget> screens = [
            const HomeScreen(),
            isGuest ? const LoginScreen() : const WalletScreen(),
            RankingScreen(
              availableEvents: events
                  .where((e) => e.status != 'closed')
                  .toList(),
              allPlayers: allPlayers,
            ),
            isGuest
                ? const LoginScreen()
                : ProfileScreen(playerData: playerData, walletData: walletData),
          ];

          return screens[_selectedIndex];
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Color(0xFF8B5CF6),
            unselectedItemColor: Color(0xFF94A3B8),
            elevation: 0,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedLabelStyle: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: FaIcon(FontAwesomeIcons.compass, size: 22),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: FaIcon(
                    FontAwesomeIcons.compass,
                    size: 22,
                    shadows: [
                      Shadow(
                        color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                label: 'EXPLORAR',
              ),
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: FaIcon(FontAwesomeIcons.gem, size: 22),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: FaIcon(
                    FontAwesomeIcons.gem,
                    size: 22,
                    shadows: [
                      Shadow(
                        color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                label: 'TESOURO',
              ),
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: FaIcon(FontAwesomeIcons.trophy, size: 22),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: FaIcon(
                    FontAwesomeIcons.trophy,
                    size: 22,
                    shadows: [
                      Shadow(
                        color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                label: 'RANKING',
              ),
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: FaIcon(FontAwesomeIcons.solidUser, size: 22),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: FaIcon(
                    FontAwesomeIcons.solidUser,
                    size: 22,
                    shadows: [
                      Shadow(
                        color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                label: 'PERFIL',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
