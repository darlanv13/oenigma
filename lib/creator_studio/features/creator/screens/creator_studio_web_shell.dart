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
import 'creator_events_screen.dart';
import 'creator_phases_screen.dart';
import 'creator_enigmas_screen.dart';
import 'creator_tools_screen.dart';
import 'creator_hints_screen.dart';
import 'creator_pricing_screen.dart';

/// Shell da Versão Web / Desktop do Creator Studio (Telas >= 900px)
class CreatorStudioWebShell extends ConsumerStatefulWidget {
  const CreatorStudioWebShell({super.key});

  @override
  ConsumerState<CreatorStudioWebShell> createState() => _CreatorStudioWebShellState();
}

class _CreatorStudioWebShellState extends ConsumerState<CreatorStudioWebShell> {
  int _selectedIndex = 0;
  ParseUser? _currentUser;

  final List<String> _titles = [
    'Dashboard do Criador',
    'Criação de Eventos',
    'Trilha de Fases',
    'Enigmas & Charadas',
    'Ferramentas & Arsenal',
    'Dicas Estratégicas',
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
          if (index >= 0 && index < _titles.length) {
            setState(() => _selectedIndex = index);
          }
        },
      ),
      const AdminEventsScreen(),
      const CreatorPhasesScreen(),
      const AdminEnigmasScreen(),
      const AdminToolsScreen(),
      const CreatorHintsScreen(),
      const CreatorPricingScreen(),
    ];
  }

  Future<void> _loadUser() async {
    final user = await CreatorTenantUtil.getCurrentUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  void _onSelectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: _screens[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final tenantId = CreatorTenantUtil.getDisplayTenantId(_currentUser);
    final creatorName = _currentUser?.get<String>('name') ??
        (_currentUser?.get<String>('username') ?? 'Criador');

    return Container(
      width: 250,
      color: AppColors.sidebarBackground,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const SizedBox(height: 12),

          // Badge Multi-Tenant do Criador
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF131D24),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.buildingUser, size: 11, color: AppColors.verdeVale),
                    const SizedBox(width: 6),
                    Text(
                      tenantId,
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.verdeVale,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  creatorName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Tenant Isolado • Eventos Globais',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildNavHeader('CRIAÇÃO & CONTEÚDO'),
          const SizedBox(height: 6),
          _buildNavItem(0, FontAwesomeIcons.chartPie, 'Dashboard'),
          _buildNavItem(1, FontAwesomeIcons.calendarCheck, 'Meus Eventos'),
          _buildNavItem(2, FontAwesomeIcons.layerGroup, 'Fases'),
          _buildNavItem(3, FontAwesomeIcons.puzzlePiece, 'Enigmas'),
          const SizedBox(height: 14),
          _buildNavHeader('ARSENAL & REGRAS'),
          const SizedBox(height: 6),
          _buildNavItem(4, FontAwesomeIcons.compass, 'Ferramentas'),
          _buildNavItem(5, FontAwesomeIcons.lightbulb, 'Dicas (Hints)'),
          _buildNavItem(6, FontAwesomeIcons.coins, 'Preços & Economia'),
          const Spacer(),
          _buildUserFooter(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OEnigmaAdminLogo(
          size: LogoSize.compact,
          isVertical: false,
          showBadge: false,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.amareloVale.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.5)),
          ),
          child: const Text(
            'CREATOR STUDIO • WEB',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.amareloVale,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, dynamic icon, String label) {
    final isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => _onSelectTab(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.verdeVale.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.verdeVale.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              size: 14,
              color: isActive ? AppColors.amareloVale : Colors.white60,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : Colors.white70,
                ),
              ),
            ),
            if (isActive)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.verdeVale,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFooter() {
    final creatorName = _currentUser?.get<String>('name') ??
        (_currentUser?.get<String>('username') ?? 'Criador');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.verdeVale,
            child: FaIcon(FontAwesomeIcons.userNinja, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              creatorName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 14, color: Colors.white54),
            tooltip: 'Sair',
            onPressed: () async {
              await ref.read(creatorAuthRepositoryProvider).signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _titles[_selectedIndex],
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.shieldHalved, size: 10, color: AppColors.verdeVale),
                    SizedBox(width: 6),
                    Text(
                      'Tenant Isolado',
                      style: TextStyle(fontSize: 11, color: AppColors.verdeVale, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
