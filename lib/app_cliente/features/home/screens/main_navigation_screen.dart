import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
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
      backgroundColor: Colors.transparent,
      body: homeDataAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.verdeVale),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.circleExclamation,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar dados.',
                style: TextStyle(
                  color: AppColors.cinzaEscuro,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  '$error',
                  style: const TextStyle(color: AppColors.cinzaMedio),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(homeEventsProvider.future),
                icon: const FaIcon(
                  FontAwesomeIcons.rotateRight,
                  color: Colors.white,
                  size: 16,
                ),
                label: const Text(
                  "TENTAR NOVAMENTE",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeVale,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
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
          color: AppColors.darkCardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: AppColors.verdeVale.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.verdeVale,
              unselectedItemColor: AppColors.cinzaMedio,
              elevation: 0,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: FaIcon(
                      FontAwesomeIcons.compass,
                      size: 20,
                    ),
                  ),
                  activeIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.compass,
                        size: 20,
                        color: AppColors.verdeVale,
                      ),
                    ),
                  ),
                  label: 'EXPLORAR',
                ),
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: FaIcon(
                      FontAwesomeIcons.gem,
                      size: 20,
                    ),
                  ),
                  activeIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.gem,
                        size: 20,
                        color: AppColors.verdeVale,
                      ),
                    ),
                  ),
                  label: 'TESOURO',
                ),
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: FaIcon(
                      FontAwesomeIcons.trophy,
                      size: 20,
                    ),
                  ),
                  activeIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.trophy,
                        size: 20,
                        color: AppColors.verdeVale,
                      ),
                    ),
                  ),
                  label: 'RANKING',
                ),
                BottomNavigationBarItem(
                  icon: const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: FaIcon(
                      FontAwesomeIcons.solidUser,
                      size: 20,
                    ),
                  ),
                  activeIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.verdeVale.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.solidUser,
                        size: 20,
                        color: AppColors.verdeVale,
                      ),
                    ),
                  ),
                  label: 'PERFIL',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
