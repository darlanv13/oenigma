import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_dashboard_screen.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_events_screen.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_enigmas_screen.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/admin_banners_screen.dart';
import 'package:oenigma/painel_admin_web/features/auth/providers/auth_provider.dart';

class MainAdminScreen extends StatefulWidget {
  const MainAdminScreen({super.key});

  @override
  State<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends State<MainAdminScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminEventsScreen(),
    AdminEnigmasScreen(),
    AdminBannersScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Eventos',
    'Enigmas',
    'Banners',
  ];

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
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 30),
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
      width: 220,
      color: sidebarBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 30),
          _buildMenuItem(0, FontAwesomeIcons.chartPie, 'Dashboard'),
          const SizedBox(height: 4),
          _buildMenuItem(1, FontAwesomeIcons.calendar, 'Eventos'),
          const SizedBox(height: 4),
          _buildMenuItem(2, FontAwesomeIcons.puzzlePiece, 'Enigmas'),
          const SizedBox(height: 4),
          _buildMenuItem(3, FontAwesomeIcons.image, 'Banners'),
          const Spacer(),
          _buildLogoutButton(),
          const SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FaIcon(FontAwesomeIcons.mapPin, color: primaryAmber, size: 18),
        const SizedBox(width: 8),
        Text(
          'ADM',
          style: GoogleFonts.orbitron(
            color: primaryAmber,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primaryAmber.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: FaIcon(
                icon,
                color: isActive ? primaryAmber : secondaryTextColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? primaryAmber : secondaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: FaIcon(
                    FontAwesomeIcons.rightFromBracket,
                    color: secondaryTextColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sair',
                  style: GoogleFonts.inter(
                    color: secondaryTextColor,
                    fontSize: 14,
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
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: primaryAmber.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Text(
        'v2.0 • Ache & Ganhe',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: mutedTextColor,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: primaryAmber.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _titles[_selectedIndex],
            style: GoogleFonts.orbitron(
              color: primaryAmberLight,
              fontSize: 26,
              fontWeight: FontWeight.w700,
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
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Online',
                  style: GoogleFonts.orbitron(
                    color: primaryAmber,
                    fontSize: 11,
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
