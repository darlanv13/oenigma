import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/admin/screens/admin_dashboard_screen.dart';
import 'package:oenigma/features/admin/screens/admin_events_screen.dart';
import 'package:oenigma/features/admin/screens/admin_users_screen.dart';
import 'package:oenigma/features/admin/screens/admin_finance_screen.dart';
import 'package:oenigma/features/admin/screens/admin_fraud_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Placeholder for tools
class AdminToolsScreen extends StatelessWidget {
  const AdminToolsScreen({super.key});
  @override Widget build(BuildContext context) => const Center(child: Text('Gestão de Dicas e Ferramentas', style: TextStyle(color: Colors.white, fontSize: 24)));
}

// Placeholder for banners
class AdminBannersScreen extends StatelessWidget {
  const AdminBannersScreen({super.key});
  @override Widget build(BuildContext context) => const Center(child: Text('Gestão de Banners', style: TextStyle(color: Colors.white, fontSize: 24)));
}

class MainAdminScreen extends StatefulWidget {
  const MainAdminScreen({super.key});

  @override
  State<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends State<MainAdminScreen> {
  int _selectedIndex = 0;
  bool _isExpanded = true;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminEventsScreen(),
    AdminUsersScreen(),
    AdminFinanceScreen(),
    AdminFraudScreen(),
    AdminToolsScreen(),
    AdminBannersScreen(),
  ];

  final List<NavigationRailDestination> _destinations = const [
    NavigationRailDestination(
      icon: Icon(FontAwesomeIcons.chartPie),
      selectedIcon: Icon(FontAwesomeIcons.chartPie, color: primaryAmber),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(FontAwesomeIcons.calendarCheck),
      selectedIcon: Icon(FontAwesomeIcons.calendarCheck, color: primaryAmber),
      label: Text('Gestão de Eventos'),
    ),
    NavigationRailDestination(
      icon: Icon(FontAwesomeIcons.users),
      selectedIcon: Icon(FontAwesomeIcons.users, color: primaryAmber),
      label: Text('Usuários & Carteira'),
    ),
    NavigationRailDestination(
      icon: Icon(FontAwesomeIcons.moneyBillWave),
      selectedIcon: Icon(FontAwesomeIcons.moneyBillWave, color: primaryAmber),
      label: Text('Financeiro'),
    ),
    NavigationRailDestination(
      icon: Icon(FontAwesomeIcons.shieldHalved),
      selectedIcon: Icon(FontAwesomeIcons.shieldHalved, color: primaryAmber),
      label: Text('Monitor de Fraude'),
    ),
    NavigationRailDestination(
      icon: Icon(FontAwesomeIcons.toolbox),
      selectedIcon: Icon(FontAwesomeIcons.toolbox, color: primaryAmber),
      label: Text('Dicas & Ferramentas'),
    ),
    NavigationRailDestination(
      icon: Icon(FontAwesomeIcons.images),
      selectedIcon: Icon(FontAwesomeIcons.images, color: primaryAmber),
      label: Text('Gestão de Banners'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;
    if (!isDesktop && _isExpanded) {
      _isExpanded = false;
    }

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text('O Enigma - Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cardColor,
        elevation: 0,
        leading: isDesktop
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.rightFromBracket),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Sair do Painel',
          ),
        ],
      ),
      drawer: !isDesktop
          ? Drawer(
              backgroundColor: cardColor,
              child: ListView(
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: primaryAmber),
                    child: Center(
                      child: Text(
                        'Admin Menu',
                        style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  for (int i = 0; i < _destinations.length; i++)
                    ListTile(
                      leading: _destinations[i].icon,
                      title: _destinations[i].label,
                      selected: _selectedIndex == i,
                      selectedColor: primaryAmber,
                      onTap: () {
                        setState(() => _selectedIndex = i);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              backgroundColor: cardColor,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              extended: _isExpanded,
              selectedIconTheme: const IconThemeData(color: primaryAmber),
              selectedLabelTextStyle: const TextStyle(color: primaryAmber, fontWeight: FontWeight.bold),
              unselectedIconTheme: const IconThemeData(color: secondaryTextColor),
              unselectedLabelTextStyle: const TextStyle(color: secondaryTextColor),
              destinations: _destinations,
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1, color: Colors.white12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey<int>(_selectedIndex),
                padding: const EdgeInsets.all(24.0),
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
