import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/admin/screens/admin_dashboard_screen.dart';
import 'package:oenigma/features/admin/screens/admin_events_screen.dart';
import 'package:oenigma/features/admin/screens/admin_users_screen.dart';
import 'package:oenigma/features/admin/screens/admin_finance_screen.dart';
import 'package:oenigma/features/admin/screens/admin_fraud_screen.dart';
import 'package:oenigma/features/admin/screens/admin_tools_screen.dart';
import 'package:oenigma/features/admin/screens/admin_banners_screen.dart';
import 'package:oenigma/features/admin/screens/admin_mobile_panel_screen.dart'; // NEW
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/features/auth/screens/login_screen.dart';

class MainAdminScreen extends StatefulWidget {
  const MainAdminScreen({super.key});

  @override
  State<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends State<MainAdminScreen> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminEventsScreen(),
    AdminUsersScreen(),
    AdminFinanceScreen(),
    AdminFraudScreen(),
    AdminToolsScreen(),
    AdminBannersScreen(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    // NEW: Retorna a tela mobile específica se for dispositivo pequeno
    if (!isDesktop) {
      return const AdminMobilePanelScreen();
    }

    return Scaffold(
      key: _key,
      backgroundColor: darkBackground,
      appBar: null,
      body: Row(
        children: [
          if (isDesktop) _AdminSidebar(controller: _controller),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey<int>(_controller.selectedIndex),
                      padding: const EdgeInsets.all(24.0),
                      child: _screens[_controller.selectedIndex],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    super.key,
    required SidebarXController controller,
  })  : _controller = controller;

  final SidebarXController _controller;

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        hoverColor: primaryAmber.withOpacity(0.1),
        textStyle: TextStyle(color: secondaryTextColor),
        selectedTextStyle: const TextStyle(color: darkBackground, fontWeight: FontWeight.bold),
        hoverTextStyle: const TextStyle(
          color: primaryAmber,
          fontWeight: FontWeight.w500,
        ),
        itemTextPadding: const EdgeInsets.only(left: 30),
        selectedItemTextPadding: const EdgeInsets.only(left: 30),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardColor),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primaryAmber.withOpacity(0.37),
          ),
          gradient: const LinearGradient(
            colors: [primaryAmber, primaryAmber],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 30,
            )
          ],
        ),
        iconTheme: IconThemeData(
          color: secondaryTextColor,
          size: 20,
        ),
        selectedIconTheme: const IconThemeData(
          color: darkBackground,
          size: 20,
        ),
      ),
      extendedTheme: const SidebarXTheme(
        width: 250,
        decoration: BoxDecoration(
          color: cardColor,
        ),
      ),
      footerDivider: divider,
      headerBuilder: (context, extended) {
        return SafeArea(
          child: SizedBox(
            height: 100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: extended
                  ? const Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: primaryAmber,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.shieldHalved,
                      color: primaryAmber,
                      size: 40,
                    ),
            ),
          ),
        );
      },
      footerBuilder: (context, extended) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: IconButton(
            icon: FaIcon(
              FontAwesomeIcons.rightFromBracket,
              color: secondaryTextColor,
            ),
            onPressed: () async {
              final user = await ParseUser.currentUser() as ParseUser?;
              if (user != null) await user.logout();
              if (context.mounted) {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (context) => const LoginScreen()),
                 );
              }
            },
            tooltip: 'Sair do Painel',
          ),
        );
      },
      items: [
        SidebarXItem(
          iconBuilder: (selected, hovered) => const FaIcon(FontAwesomeIcons.chartPie, size: 20),
          label: 'Dashboard',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) => const FaIcon(FontAwesomeIcons.calendarCheck, size: 20),
          label: 'Gestão de Eventos',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) => const FaIcon(FontAwesomeIcons.users, size: 20),
          label: 'Usuários & Carteira',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) => const FaIcon(FontAwesomeIcons.moneyBillWave, size: 20),
          label: 'Financeiro',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) => const FaIcon(FontAwesomeIcons.shieldHalved, size: 20),
          label: 'Monitor de Fraude',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) => const FaIcon(FontAwesomeIcons.toolbox, size: 20),
          label: 'Dicas & Ferramentas',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) => const FaIcon(FontAwesomeIcons.images, size: 20),
          label: 'Gestão de Banners',
          onTap: () => _handleItemTap(context),
        ),
      ],
    );
  }

  void _handleItemTap(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;
    if (!isDesktop) {
      Navigator.of(context).pop();
    }
  }
}

const divider = Divider(color: Colors.white24, height: 1);
