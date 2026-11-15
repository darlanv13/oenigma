import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/painel_admin_web/features/auth/providers/auth_provider.dart';
import 'package:oenigma/painel_admin_web/features/creator/screens/creator_auth_screen.dart';
import 'package:oenigma/painel_admin_web/features/creator/screens/creator_dashboard_screen.dart';
import 'package:oenigma/painel_admin_web/features/creator/screens/creator_challenge_wizard_screen.dart';
import 'package:oenigma/painel_admin_web/features/creator/screens/creator_finance_screen.dart';
import 'package:oenigma/painel_admin_web/features/creator/screens/creator_links_screen.dart';
import 'package:oenigma/painel_admin_web/features/creator/screens/creator_credits_wallet_screen.dart';

/// Painel Dedicado e Exclusivo do Criador / Influenciador (Creator Studio)
class MainCreatorScreen extends StatefulWidget {
  const MainCreatorScreen({super.key});

  @override
  State<MainCreatorScreen> createState() => _MainCreatorScreenState();
}

class _MainCreatorScreenState extends State<MainCreatorScreen> {
  int _selectedIndex = 0;
  ParseUser? _currentUser;
  bool _isLoadingUser = true;

  late List<Widget> _screens;

  final List<String> _titles = [
    'Dashboard',
    'Criar Experiência',
    'Carteira de Créditos',
    'Divulgação & Links',
    'Vendas & Saques Pix',
  ];

  @override
  void initState() {
    super.initState();
    _initScreens();
    _loadUser();
  }

  void _initScreens() {
    _screens = [
      CreatorDashboardScreen(
        onNavigateTab: (index) {
          if (index >= 0 && index < _titles.length) {
            setState(() => _selectedIndex = index);
          }
        },
        onOpenWizard: () {
          setState(() => _selectedIndex = 1);
        },
      ),
      CreatorChallengeWizardScreen(
        onCancel: () => setState(() => _selectedIndex = 0),
        onChallengeCreated: (id) => setState(() => _selectedIndex = 0),
      ),
      const CreatorCreditsWalletScreen(),
      const CreatorLinksScreen(),
      const CreatorFinanceScreen(),
    ];
  }

  Future<void> _loadUser() async {
    setState(() => _isLoadingUser = true);
    final user = await ParseUser.currentUser() as ParseUser?;
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
      _initScreens();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.amareloVale),
        ),
      );
    }

    if (_currentUser == null) {
      return CreatorAuthScreen(
        onAuthenticated: () async {
          await _loadUser();
        },
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: _buildMobileAppBar(context),
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: _screens[_selectedIndex],
          ),
        ),
        bottomNavigationBar: _buildMobileBottomBar(),
      );
    }

    // Versão Desktop
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

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    final name = _currentUser?.get<String>('name') ??
        _currentUser?.get<String>('username') ??
        'Criador';
    final balance = (_currentUser?.get<num>('balance') ?? 0.0).toDouble();

    return AppBar(
      backgroundColor: const Color(0xFF0C1013),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 10,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OEnigmaAdminLogo(size: LogoSize.compact, showBadge: false),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppColors.amareloVale.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.3)),
              ),
              child: Text(
                'STUDIO',
                style: GoogleFonts.poppins(
                  color: AppColors.amareloVale,
                  fontSize: 9.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Badge de Saldo Rápido Pix
        GestureDetector(
          onTap: () => setState(() => _selectedIndex = 3),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.verdeVale, size: 14),
                const SizedBox(width: 4),
                Text(
                  'R\$ ${balance.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Menu de Opções do Influencer
        Consumer(
          builder: (context, ref, _) {
            final isAdmin = _currentUser?.get<bool>('isAdmin') ?? false;
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
              color: AppColors.darkCardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.darkCardBorder),
              ),
              onSelected: (val) async {
                if (val == 'admin') {
                  Navigator.pushNamed(context, '/admin');
                } else if (val == 'logout') {
                  await ref.read(authRepositoryProvider).signOut();
                  if (mounted) setState(() => _currentUser = null);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(color: AppColors.amareloVale, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const PopupMenuDivider(),
                if (isAdmin)
                  PopupMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.shieldHalved, color: AppColors.info, size: 13),
                        const SizedBox(width: 8),
                        Text('Painel Super Admin', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.arrowRightFromBracket, color: Colors.redAccent, size: 13),
                      const SizedBox(width: 8),
                      Text('Sair do Studio', style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1013),
        border: Border(
          top: BorderSide(color: AppColors.verdeVale.withValues(alpha: 0.15)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(0, FontAwesomeIcons.chartPie, 'Início'),
              _buildBottomNavCreateButton(),
              _buildBottomNavItem(2, FontAwesomeIcons.coins, 'Créditos'),
              _buildBottomNavItem(3, FontAwesomeIcons.shareNodes, 'Links'),
              _buildBottomNavItem(4, FontAwesomeIcons.sackDollar, 'Vendas'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavCreateButton() {
    final isSelected = _selectedIndex == 1;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = 1),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amareloVale : AppColors.verdeVale,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AppColors.amareloVale : AppColors.verdeVale).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.plus,
              color: isSelected ? Colors.black : Colors.white,
              size: 12,
            ),
            const SizedBox(width: 5),
            Text(
              'Criar',
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, dynamic icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 15,
              color: isSelected ? AppColors.amareloVale : AppColors.cinzaMedio,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : AppColors.cinzaMedio,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final name = _currentUser?.get<String>('name') ??
        _currentUser?.get<String>('username') ??
        'Criador';
    final avatar = _currentUser?.get<String>('photoURL');

    return Container(
      width: 230,
      color: AppColors.sidebarBackground,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          // Logo com Badge Creator Studio
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: OEnigmaAdminLogo(
              size: LogoSize.compact,
              isVertical: false,
              showBadge: false,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amareloVale.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(FontAwesomeIcons.wandMagicSparkles, color: AppColors.amareloVale, size: 10),
                const SizedBox(width: 6),
                Text(
                  'CREATOR STUDIO',
                  style: GoogleFonts.poppins(
                    color: AppColors.amareloVale,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu de Navegação do Influencer (PRD v1.0)
          _buildMenuItem(0, FontAwesomeIcons.chartPie, 'Dashboard'),
          const SizedBox(height: 4),
          _buildMenuItem(1, FontAwesomeIcons.plus, 'Criar Experiência'),
          const SizedBox(height: 4),
          _buildMenuItem(2, FontAwesomeIcons.coins, 'Carteira de Créditos'),
          const SizedBox(height: 4),
          _buildMenuItem(3, FontAwesomeIcons.shareNodes, 'Divulgação & Links'),
          const SizedBox(height: 4),
          _buildMenuItem(4, FontAwesomeIcons.sackDollar, 'Vendas & Saques Pix'),

          const Spacer(),

          // Card de Perfil do Criador
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.verdeVale.withValues(alpha: 0.3),
                  backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar == null || avatar.isEmpty
                      ? const FaIcon(FontAwesomeIcons.user, color: Colors.white, size: 12)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Influenciador',
                        style: GoogleFonts.poppins(
                          color: AppColors.amareloVale,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, dynamic icon, String label) {
    final isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.verdeVale.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.verdeVale.withValues(alpha: 0.35)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
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
                style: GoogleFonts.poppins(
                  color: isActive ? Colors.white : AppColors.cinzaMedio,
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isActive)
              Container(
                width: 5,
                height: 5,
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
          Row(
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
            ],
          ),
          Row(
            children: [
              if (_selectedIndex != 1)
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 12),
                  label: const Text('Novo Desafio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeVale,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () => setState(() => _selectedIndex = 1),
                ),
              const SizedBox(width: 14),
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
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Studio Online',
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
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Consumer(
      builder: (context, ref, _) {
        return InkWell(
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.darkCardColor,
                title: Text(
                  'Encerrar Sessão',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'Deseja realmente sair do Creator Studio?',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sair'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await ref.read(authRepositoryProvider).signOut();
              if (mounted) setState(() => _currentUser = null);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.arrowRightFromBracket, color: AppColors.cinzaMedio, size: 13),
                const SizedBox(width: 8),
                Text(
                  'Sair do Studio',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
