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

  @override
  Widget build(BuildContext context) {
    // Usaremos um IndexedStack para manter o estado das páginas
    final List<Widget> screens = [
      AdminDashboardScreen(),
      const WithdrawalRequestsScreen(),
      const UserListScreen(),
    ];

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
            _buildDrawerItem(0, "Dashboard & Eventos", Icons.dashboard),
            _buildDrawerItem(1, "Solicitações de Saque", Icons.attach_money),
            _buildDrawerItem(2, "Gerenciar Usuários", Icons.people),
          ],
        ),
      ),
      body: screens[_selectedIndex],
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
