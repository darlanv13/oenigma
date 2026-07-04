import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/features/admin/screens/admin_banners_screen.dart';
import 'package:oenigma/features/admin/screens/admin_dashboard_screen.dart';
import 'package:oenigma/features/admin/screens/admin_events_screen.dart';
import 'package:oenigma/features/admin/screens/admin_finance_screen.dart';
import 'package:oenigma/features/admin/screens/admin_fraud_screen.dart';
import 'package:oenigma/features/admin/screens/admin_tools_screen.dart';
import 'package:oenigma/features/admin/screens/admin_users_screen.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:oenigma/features/auth/screens/login_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class MainAdminScreen extends ConsumerStatefulWidget {
  const MainAdminScreen({super.key});

  @override
  ConsumerState<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends ConsumerState<MainAdminScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminUsersScreen(),
    const AdminEventsScreen(),
    const AdminFinanceScreen(),
    const AdminFraudScreen(),
    const AdminBannersScreen(),
    const AdminToolsScreen(),
  ];

  final List<NavigationRailDestination> _destinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: Text('Usuários'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event),
      label: Text('Eventos'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: Text('Financeiro'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.security_outlined),
      selectedIcon: Icon(Icons.security),
      label: Text('Fraudes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.view_carousel_outlined),
      selectedIcon: Icon(Icons.view_carousel),
      label: Text('Banners'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.build_circle_outlined),
      selectedIcon: Icon(Icons.build_circle),
      label: Text('Ferramentas'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: cardColor,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: primaryAmber),
            unselectedIconTheme: const IconThemeData(color: secondaryTextColor),
            selectedLabelTextStyle: const TextStyle(color: primaryAmber, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: secondaryTextColor),
            destinations: _destinations,
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: 'Sair',
                    onPressed: () async {
                      ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: secondaryTextColor),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
