import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'package:oenigma/admin/screens/admin_dashboard_screen.dart';
import 'package:oenigma/admin/screens/user_list_screen.dart';
import 'package:oenigma/admin/screens/withdrawal_requests_screen.dart';
import 'package:oenigma/app_gamer/screens/login_screen.dart';

enum AdminRoute { dashboard, users, events, finance, enigmas }

class AdminLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final AdminRoute currentRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AdminLayout({
    super.key,
    required this.body,
    required this.title,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    // Usa LayoutBuilder para detectar se é Desktop (> 800px) ou Mobile
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: darkBackground,
          appBar:
              !isDesktop // AppBar só aparece no Mobile
              ? AppBar(
                  backgroundColor: cardColor,
                  title: Text(
                    title,
                    style: GoogleFonts.orbitron(color: primaryAmber),
                  ),
                  actions: actions,
                )
              : null, // No Desktop não tem AppBar padrão
          drawer: !isDesktop ? _AdminDrawer(currentRoute: currentRoute) : null,
          body: Row(
            children: [
              // MENU LATERAL FIXO (Só Desktop)
              if (isDesktop)
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    border: Border(
                      right: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: _AdminDrawer(
                    currentRoute: currentRoute,
                    isDesktop: true,
                  ),
                ),

              // ÁREA DE CONTEÚDO
              Expanded(
                child: Column(
                  children: [
                    // Header Customizado para Desktop (Substitui AppBar)
                    if (isDesktop)
                      Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: darkBackground,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              title.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            if (actions != null) ...actions!,
                          ],
                        ),
                      ),

                    // O Conteúdo da Página
                    Expanded(child: ClipRect(child: body)),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final AdminRoute currentRoute;
  final bool isDesktop;
  final AuthService _authService = AuthService();

  _AdminDrawer({required this.currentRoute, this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      backgroundColor:
          Colors.transparent, // Transparente pois o Container pai já tem cor
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const FaIcon(
                  FontAwesomeIcons.shieldHalved,
                  color: primaryAmber,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  "OENIGMA",
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  "ADMIN CONSOLE",
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    color: primaryAmber,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              children: [
                _buildMenuItem(
                  context,
                  "Dashboard",
                  FontAwesomeIcons.chartLine,
                  AdminRoute.dashboard,
                  const AdminDashboardScreen(),
                ),
                _buildMenuItem(
                  context,
                  "Usuários",
                  FontAwesomeIcons.users,
                  AdminRoute.users,
                  const UserListScreenWrapper(),
                ),
                _buildMenuItem(
                  context,
                  "Financeiro",
                  FontAwesomeIcons.moneyBillTransfer,
                  AdminRoute.finance,
                  const WithdrawalRequestsWrapper(),
                ),
                // Adicione outras rotas aqui
              ],
            ),
          ),

          // Footer / Logout
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    AdminRoute route,
    Widget page,
  ) {
    final isActive = currentRoute == route;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? primaryAmber.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: primaryAmber.withOpacity(0.5))
            : null,
      ),
      child: ListTile(
        leading: FaIcon(
          icon,
          color: isActive ? primaryAmber : Colors.grey,
          size: 18,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (isDesktop) {
            // Em desktop, usamos pushReplacement sem animação de transição lateral para parecer web
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => page,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          }
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.logout, size: 18),
      label: const Text("SAIR DO SISTEMA"),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.redAccent,
        side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      onPressed: () async {
        await _authService.signOut();
        if (context.mounted)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (r) => false,
          );
      },
    );
  }
}

// Wrappers simples para manter a navegação funcionando
class UserListScreenWrapper extends StatelessWidget {
  const UserListScreenWrapper({super.key});
  @override
  Widget build(BuildContext context) => const AdminLayout(
    title: "Usuários",
    currentRoute: AdminRoute.users,
    body: UserListScreen(),
  );
}

class WithdrawalRequestsWrapper extends StatelessWidget {
  const WithdrawalRequestsWrapper({super.key});
  @override
  Widget build(BuildContext context) => const AdminLayout(
    title: "Financeiro",
    currentRoute: AdminRoute.finance,
    body: WithdrawalRequestsScreen(),
  );
}
