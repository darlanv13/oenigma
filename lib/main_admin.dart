import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/admin_dashboard_screen.dart';
import 'package:oenigma/admin/screens/withdrawal_requests_screen.dart';
import 'package:oenigma/admin/screens/user_list_screen.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class MainAdminScreen extends StatefulWidget {
  const MainAdminScreen({super.key});

  @override
  State<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends State<MainAdminScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final role = await AuthService().getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        _isLoading = false;

        // Auditor defaults to Withdrawals screen if Dashboard is too event-heavy,
        // but we will make Dashboard adaptive.
        // For now, let's keep Dashboard as home for everyone.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryAmber)),
      );
    }

    // Determine available screens based on role
    Widget content;

    if (_selectedIndex == 0) {
      content = AdminDashboardScreen(userRole: _userRole);
    } else if (_selectedIndex == 1) {
       // Withdrawals
       if (['auditor', 'super_admin', 'admin'].contains(_userRole)) {
         content = const WithdrawalRequestsScreen();
       } else {
         content = const Center(child: Text("Acesso Negado", style: TextStyle(color: Colors.red)));
       }
    } else if (_selectedIndex == 2) {
      // Users
       if (['super_admin', 'admin'].contains(_userRole)) {
         content = const UserListScreen();
       } else {
         content = const Center(child: Text("Acesso Negado", style: TextStyle(color: Colors.red)));
       }
    } else {
      content = Container();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Administrativo OEnigma"),
        backgroundColor: cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: darkBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: primaryAmber),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 64,
                    color: darkBackground,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "OEnigma Admin",
                    style: TextStyle(
                      color: darkBackground,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Dashboard: Everyone
            _buildDrawerItem(0, "Dashboard & Visão Geral", Icons.dashboard),

            // Withdrawals: Auditor & Super Admin
            if (['auditor', 'super_admin', 'admin'].contains(_userRole))
              _buildDrawerItem(1, "Solicitações de Saque", Icons.attach_money),

            // Users: Editor & Super Admin - REMOVED editor
            if (['super_admin', 'admin'].contains(_userRole))
              _buildDrawerItem(2, "Gerenciar Usuários", Icons.people),
          ],
        ),
      ),
      body: content,
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? primaryAmber : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? primaryAmber : Colors.white,
          fontWeight: _selectedIndex == index
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      tileColor: _selectedIndex == index ? cardColor : null,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context); // Fecha o Drawer
      },
    );
  }
}
