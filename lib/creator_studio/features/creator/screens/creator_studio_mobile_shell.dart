import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/creator_studio/features/auth/providers/auth_provider.dart';
import 'package:oenigma/creator_studio/features/creator/utils/creator_tenant_util.dart';

import 'creator_dashboard_screen.dart';
import 'creator_mobile_quick_screen.dart';
import 'creator_phases_screen.dart';
import 'creator_enigmas_screen.dart';
import 'creator_pricing_screen.dart';

/// Shell da Versão Mobile do Creator Studio (Smartphones & Tablets < 900px)
class CreatorStudioMobileShell extends ConsumerStatefulWidget {
  const CreatorStudioMobileShell({super.key});

  @override
  ConsumerState<CreatorStudioMobileShell> createState() => _CreatorStudioMobileShellState();
}

class _CreatorStudioMobileShellState extends ConsumerState<CreatorStudioMobileShell> {
  int _selectedIndex = 1; // Inicia em Meus Eventos no mobile
  ParseUser? _currentUser;

  final List<String> _titles = [
    'Dashboard',
    'Meus Eventos',
    'Trilha de Fases',
    'Enigmas & IA',
    'Preços & Economia',
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _screens = [
      CreatorDashboardScreen(
        onNavigateTab: (index) {
          if (index == 1) setState(() => _selectedIndex = 1);
          if (index == 2) setState(() => _selectedIndex = 2);
          if (index == 3) setState(() => _selectedIndex = 3);
          if (index == 6) setState(() => _selectedIndex = 4);
        },
      ),
      const AdminMobilePanelScreen(),
      const CreatorPhasesScreen(),
      const AdminEnigmasScreen(),
      const CreatorPricingScreen(),
    ];
  }

  Future<void> _loadUser() async {
    final user = await CreatorTenantUtil.getCurrentUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantId = CreatorTenantUtil.getDisplayTenantId(_currentUser);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBackground,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            const OEnigmaAdminLogo(size: LogoSize.compact, isVertical: false, showBadge: false),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.amareloVale.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
              ),
              child: Text(
                tenantId,
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.amareloVale,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _titles[_selectedIndex],
                style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 16),
            tooltip: 'Sair da Conta',
            onPressed: () async {
              await ref.read(creatorAuthRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        backgroundColor: AppColors.sidebarBackground,
        indicatorColor: AppColors.verdeVale.withValues(alpha: 0.3),
        height: 64,
        destinations: const [
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.chartPie, size: 15),
            label: 'Início',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.calendarDay, size: 15),
            label: 'Eventos',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.layerGroup, size: 15),
            label: 'Fases',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.puzzlePiece, size: 15),
            label: 'Enigmas',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.coins, size: 15),
            label: 'Economia',
          ),
        ],
      ),
    );
  }
}
