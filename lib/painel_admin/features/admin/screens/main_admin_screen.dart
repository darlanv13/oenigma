import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/painel_admin/features/admin/screens/admin_banners_screen.dart';
import 'package:oenigma/painel_admin/features/admin/screens/admin_dashboard_screen.dart';
import 'package:oenigma/painel_admin/features/admin/screens/admin_events_screen.dart';
import 'package:oenigma/painel_admin/features/admin/screens/admin_finance_screen.dart';
import 'package:oenigma/painel_admin/features/admin/screens/admin_fraud_screen.dart';
import 'package:oenigma/painel_admin/features/admin/screens/admin_mobile_panel_screen.dart';
import 'package:oenigma/painel_admin/features/admin/screens/admin_tools_screen.dart';
import 'package:oenigma/painel_admin/features/admin/screens/admin_users_screen.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:oenigma/painel_admin/core/utils/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/painel_admin/features/auth/providers/auth_provider.dart';

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

  final List<String> _screenTitles = const [
    'Dashboard',
    'Eventos',
    'Usuários & Carteira',
    'Financeiro',
    'Monitor de Fraude',
    'Enigmas',
    'Banners',
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
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        margin: const EdgeInsets.only(bottom: 28.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: primaryAmber.withValues(alpha: 0.08),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _screenTitles[_controller.selectedIndex],
                              style: GoogleFonts.orbitron(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: highlightTextColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryAmber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: primaryAmber.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    color: Colors.green,
                                    size: 8,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Online',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 11,
                                      color: primaryAmber,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            key: ValueKey<int>(_controller.selectedIndex),
                            child: _screens[_controller.selectedIndex],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends ConsumerWidget {
  const _AdminSidebar({super.key, required SidebarXController controller})
    : _controller = controller;

  final SidebarXController _controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            right: BorderSide(
              color: primaryAmber.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
        ),
        hoverColor: primaryAmber.withValues(alpha: 0.06),
        textStyle: GoogleFonts.inter(
          color: secondaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        selectedTextStyle: GoogleFonts.inter(
          color: primaryAmber,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hoverTextStyle: GoogleFonts.inter(
          color: primaryAmber.withValues(alpha: 0.8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        itemTextPadding: const EdgeInsets.only(left: 10),
        selectedItemTextPadding: const EdgeInsets.only(left: 10),
        itemPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        selectedItemPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemMargin: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
        selectedItemMargin: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: primaryAmber.withValues(alpha: 0.10),
        ),
        iconTheme: IconThemeData(color: secondaryTextColor, size: 20),
        selectedIconTheme: const IconThemeData(color: primaryAmber, size: 20),
        hoverIconTheme: IconThemeData(color: primaryAmber.withValues(alpha: 0.8), size: 20),
      ),
      extendedTheme: SidebarXTheme(
        width: 220,
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            right: BorderSide(
              color: primaryAmber.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
        ),
      ),
      footerDivider: const Divider(color: Color(0x0FC0A060), height: 1), // rgba(192, 160, 96, 0.06)
      headerBuilder: (context, extended) {
        return SafeArea(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(top: 24.0, bottom: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.mapPin,
                  color: primaryAmber,
                  size: 20,
                ),
                if (extended) const SizedBox(width: 8),
                if (extended)
                  Text(
                    'ADM',
                    style: GoogleFonts.orbitron(
                      color: primaryAmber,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      footerBuilder: (context, extended) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.rightFromBracket,
                  color: secondaryTextColor,
                  size: 16,
                ),
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                tooltip: 'Sair do Painel',
              ),
            ),
            if (extended)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'v2.0 • Ache & Ganhe',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
              ),
          ],
        );
      },
      items: [
        SidebarXItem(
          iconBuilder: (selected, hovered) =>
              FaIcon(FontAwesomeIcons.chartPie, size: 20, color: selected ? primaryAmber : (hovered ? primaryAmber.withValues(alpha: 0.8) : secondaryTextColor)),
          label: 'Dashboard',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) =>
              FaIcon(FontAwesomeIcons.calendar, size: 20, color: selected ? primaryAmber : (hovered ? primaryAmber.withValues(alpha: 0.8) : secondaryTextColor)),
          label: 'Eventos',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) =>
              FaIcon(FontAwesomeIcons.users, size: 20, color: selected ? primaryAmber : (hovered ? primaryAmber.withValues(alpha: 0.8) : secondaryTextColor)),
          label: 'Usuários',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) =>
              FaIcon(FontAwesomeIcons.moneyBillWave, size: 20, color: selected ? primaryAmber : (hovered ? primaryAmber.withValues(alpha: 0.8) : secondaryTextColor)),
          label: 'Financeiro',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) =>
              FaIcon(FontAwesomeIcons.shieldHalved, size: 20, color: selected ? primaryAmber : (hovered ? primaryAmber.withValues(alpha: 0.8) : secondaryTextColor)),
          label: 'Fraude',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) =>
              FaIcon(FontAwesomeIcons.puzzlePiece, size: 20, color: selected ? primaryAmber : (hovered ? primaryAmber.withValues(alpha: 0.8) : secondaryTextColor)),
          label: 'Enigmas',
          onTap: () => _handleItemTap(context),
        ),
        SidebarXItem(
          iconBuilder: (selected, hovered) =>
              FaIcon(FontAwesomeIcons.image, size: 20, color: selected ? primaryAmber : (hovered ? primaryAmber.withValues(alpha: 0.8) : secondaryTextColor)),
          label: 'Banners',
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
