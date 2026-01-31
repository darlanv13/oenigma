import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'package:oenigma/admin/screens/admin_dashboard_screen.dart';
import 'package:oenigma/admin/screens/user_list_screen.dart';
import 'package:oenigma/admin/screens/withdrawal_requests_screen.dart';
import 'package:oenigma/app_gamer/screens/login_screen.dart';

// Definição das rotas para identificar a tela ativa
enum AdminRoute { dashboard, users, events, finance, enigmas }

class AdminLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final AdminRoute currentRoute;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const AdminLayout({
    super.key,
    required this.body,
    required this.title,
    required this.currentRoute,
    this.floatingActionButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title.toUpperCase(),
          style: GoogleFonts.orbitron(
            color: primaryAmber,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: actions,
      ),
      drawer: _AdminDrawer(currentRoute: currentRoute),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final AdminRoute currentRoute;
  final AuthService _authService = AuthService();

  _AdminDrawer({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(
        0xFF1E1E1E,
      ), // Um pouco mais claro que o darkBackground
      child: Column(
        children: [
          // --- HEADER DO DRAWER ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryAmber.withOpacity(0.15), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: const Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryAmber, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAmber.withOpacity(0.2),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.shieldHalved,
                    color: primaryAmber,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "ADMINISTRAÇÃO",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Acesso Restrito",
                  style: TextStyle(color: secondaryTextColor, fontSize: 10),
                ),
              ],
            ),
          ),

          // --- ITENS DE NAVEGAÇÃO ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDrawerItem(
                  context,
                  icon: FontAwesomeIcons.chartLine,
                  label: "Dashboard",
                  route: AdminRoute.dashboard,
                  onTap: () => _navigate(context, const AdminDashboardScreen()),
                ),
                _buildDrawerItem(
                  context,
                  icon: FontAwesomeIcons.users,
                  label: "Usuários",
                  route: AdminRoute.users,
                  // Nota: UserListScreen precisa ser envolvida num Scaffold ou AdminLayout na sua implementação
                  onTap: () => _navigate(
                    context,
                    const _ScaffoldWrapper(
                      title: "Usuários",
                      route: AdminRoute.users,
                      child: UserListScreen(),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: FontAwesomeIcons.moneyBillTransfer,
                  label: "Financeiro",
                  route: AdminRoute.finance,
                  // Nota: Mesmo caso, envolvendo a tela de saques
                  onTap: () => _navigate(
                    context,
                    const _ScaffoldWrapper(
                      title: "Solicitações de Saque",
                      route: AdminRoute.finance,
                      child: WithdrawalRequestsScreen(),
                    ),
                  ),
                ),
                // Adicione mais itens conforme necessário (Eventos, Enigmas, etc)
              ],
            ),
          ),

          // --- BOTÃO DE LOGOUT ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required AdminRoute route,
    required VoidCallback onTap,
  }) {
    final bool isActive = currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? primaryAmber.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: primaryAmber.withOpacity(0.3))
            : Border.all(color: Colors.transparent),
      ),
      child: ListTile(
        leading: FaIcon(
          icon,
          color: isActive ? primaryAmber : secondaryTextColor,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: isActive ? () => Navigator.pop(context) : onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: const Text(
          "Sair",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () async {
          await _authService.signOut();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context); // Fecha o drawer
    // PushReplacement para evitar pilha infinita no Admin
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

// Wrapper auxiliar para telas que não têm Scaffold próprio ou para padronizar
class _ScaffoldWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final AdminRoute route;

  const _ScaffoldWrapper({
    required this.title,
    required this.child,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return AdminLayout(title: title, currentRoute: route, body: child);
  }
}
