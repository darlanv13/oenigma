import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/painel_mestre/features/auth/providers/auth_provider.dart';

import 'master_dashboard_screen.dart';
import 'master_tenancy_screen.dart';
import 'master_users_screen.dart';
import 'master_finance_screen.dart';
import 'master_gateways_screen.dart';
import 'master_security_screen.dart';
import 'master_banners_screen.dart';

class MainMasterScreen extends ConsumerStatefulWidget {
  const MainMasterScreen({super.key});

  @override
  ConsumerState<MainMasterScreen> createState() => _MainMasterScreenState();
}

class _MainMasterScreenState extends ConsumerState<MainMasterScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard Global',
    'Controle de Tenancy (Multi-Tenant)',
    'Caçadores & Usuários',
    'Saques & Depósitos',
    'Gateways de Pagamento',
    'Segurança & Anti-Fraude',
    'Banners Globais',
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MasterDashboardScreen(
        onNavigateTab: (index) {
          if (index >= 0 && index < _titles.length) {
            setState(() => _selectedIndex = index);
          }
        },
      ),
      const MasterTenancyScreen(),
      const AdminUsersScreen(),
      const AdminFinanceScreen(),
      const AdminGatewaysScreen(),
      const AdminSecurityScreen(),
      const AdminBannersScreen(),
    ];
  }

  void _onSelectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

    // Layout Mobile / Tablet para Super Admin
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBackground,
        elevation: 0,
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 16),
            tooltip: 'Sair do Painel Mestre',
            onPressed: () async {
              await ref.read(masterAuthRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.sidebarBackground,
        child: SafeArea(
          child: Column(
            children: [
              _buildLogo(),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  children: [
                    _buildNavItem(0, FontAwesomeIcons.chartPie, 'Dashboard'),
                    _buildNavItem(1, FontAwesomeIcons.buildingUser, 'Tenancy (Multi-Tenant)'),
                    _buildNavItem(2, FontAwesomeIcons.users, 'Usuários & Caçadores'),
                    _buildNavItem(3, FontAwesomeIcons.moneyBillTransfer, 'Saques & Depósitos'),
                    _buildNavItem(4, FontAwesomeIcons.creditCard, 'Gateways'),
                    _buildNavItem(5, FontAwesomeIcons.shieldHalved, 'Segurança & Fraudes'),
                    _buildNavItem(6, FontAwesomeIcons.image, 'Banners Globais'),
                  ],
                ),
              ),
              _buildUserFooter(),
            ],
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(12),
        child: _screens[_selectedIndex],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 245,
      color: AppColors.sidebarBackground,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const SizedBox(height: 20),
          _buildNavSectionHeader('GOVERNANÇA & REDE'),
          const SizedBox(height: 4),
          _buildNavItem(0, FontAwesomeIcons.chartPie, 'Dashboard Mestre'),
          _buildNavItem(1, FontAwesomeIcons.buildingUser, 'Gestão de Tenancy'),
          const SizedBox(height: 12),
          _buildNavSectionHeader('USUÁRIOS & CONTAS'),
          const SizedBox(height: 4),
          _buildNavItem(2, FontAwesomeIcons.users, 'Caçadores & Usuários'),
          const SizedBox(height: 12),
          _buildNavSectionHeader('FINANCEIRO & INFRA'),
          const SizedBox(height: 4),
          _buildNavItem(3, FontAwesomeIcons.moneyBillTransfer, 'Saques & Depósitos'),
          _buildNavItem(4, FontAwesomeIcons.creditCard, 'Gateways Pagamento'),
          _buildNavItem(5, FontAwesomeIcons.shieldHalved, 'Segurança & Anti-Fraude'),
          _buildNavItem(6, FontAwesomeIcons.image, 'Banners Globais'),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.shade900.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.6)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(FontAwesomeIcons.crown, size: 9, color: AppColors.amareloVale),
              SizedBox(width: 5),
              Text(
                'PAINEL MESTRE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amareloVale,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9.5,
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
      onTap: () {
        _onSelectTab(index);
        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
        }
      },
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
            icon is IconData
                ? Icon(icon, size: 14, color: isActive ? AppColors.amareloVale : Colors.white60)
                : FaIcon(
                    icon,
                    size: 14,
                    color: isActive ? AppColors.amareloVale : Colors.white60,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
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
            backgroundColor: AppColors.amareloVale,
            child: FaIcon(FontAwesomeIcons.userTie, size: 12, color: Colors.black),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Super Admin',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 14, color: Colors.white54),
            tooltip: 'Sair do Painel Mestre',
            onPressed: () async {
              await ref.read(masterAuthRepositoryProvider).signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  color: AppColors.amareloVale.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.lock, size: 9, color: AppColors.amareloVale),
                    SizedBox(width: 6),
                    Text(
                      'Modo Mestre / Multi-Tenant',
                      style: TextStyle(fontSize: 11, color: AppColors.amareloVale, fontWeight: FontWeight.bold),
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
