import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_dashboard_screen.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_events_screen.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_banners_screen.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_gateways_screen.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_finance_screen.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_users_screen.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_security_screen.dart';
import 'package:oenigma/painel_admin_web/features/auth/providers/auth_provider.dart';

class MainAdminScreen extends StatefulWidget {
  const MainAdminScreen({super.key});

  @override
  State<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends State<MainAdminScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  final List<String> _titles = [
    'Dashboard',
    'Eventos',
    'Banners',
    'Gateways de Pagamento',
    'Saques & Depósitos',
    'Caçadores & Usuários',
    'Segurança & Anti-Fraude',
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboardScreen(
        onNavigateTab: (index) {
          if (index >= 0 && index < _titles.length) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
      const AdminEventsScreen(),
      const AdminBannersScreen(),
      const AdminGatewaysScreen(),
      const AdminFinanceScreen(),
      const AdminUsersScreen(),
      const AdminSecurityScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
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
    return Container(
      width: 215,
      color: sidebarBackground,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 14),
          _buildMenuItem(0, FontAwesomeIcons.chartPie, 'Dashboard'),
          const SizedBox(height: 3),
          _buildMenuItem(1, FontAwesomeIcons.calendarCheck, 'Eventos'),
          const SizedBox(height: 3),
          _buildMenuItem(2, FontAwesomeIcons.image, 'Banners'),
          const SizedBox(height: 3),
          _buildMenuItem(3, FontAwesomeIcons.creditCard, 'Gateways'),
          const SizedBox(height: 3),
          _buildMenuItem(
            4,
            FontAwesomeIcons.moneyBillTransfer,
            'Saques & Depósitos',
          ),
          const SizedBox(height: 3),
          _buildMenuItem(5, FontAwesomeIcons.users, 'Caçadores'),
          const SizedBox(height: 3),
          _buildMenuItem(
            6,
            FontAwesomeIcons.shieldHalved,
            'Segurança & Fraudes',
          ),
          const Spacer(),
          _buildLogoutButton(),
          const SizedBox(height: 8),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: OEnigmaAdminLogo(
        size: LogoSize.compact,
        isVertical: false,
        showBadge: false,
      ),
    );
  }

  Widget _buildMenuItem(int index, dynamic icon, String label) {
    final isActive = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.verdeVale.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.verdeVale.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: FaIcon(
                icon,
                color: isActive ? AppColors.amareloVale : AppColors.cinzaMedio,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: isActive ? Colors.white : AppColors.cinzaMedio,
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.verdeVale,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Consumer(
      builder: (context, ref, child) {
        return InkWell(
          onTap: () async {
            await ref.read(authRepositoryProvider).signOut();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: FaIcon(
                    FontAwesomeIcons.rightFromBracket,
                    color: AppColors.cinzaMedio,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sair',
                  style: GoogleFonts.poppins(
                    color: AppColors.cinzaMedio,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.verdeVale.withValues(alpha: 0.1)),
        ),
      ),
      child: Text(
        'v2.0 • Enigma City',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: AppColors.cinzaMedio.withValues(alpha: 0.6),
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.verdeVale.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _titles[_selectedIndex],
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.verdeVale.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Painel Conectado',
                  style: GoogleFonts.poppins(
                    color: AppColors.verdeVale,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
