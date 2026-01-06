import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/utils/app_colors.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int selectedIndex;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: textColor)),
        backgroundColor: cardColor,
        iconTheme: const IconThemeData(color: primaryAmber),
        actions: [
          Center(
            child: Text(
              FirebaseAuth.instance.currentUser?.email ?? 'Admin',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Sair do Painel",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // O AuthWrapper no main_admin cuidará do redirecionamento para o login
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: cardColor,
            selectedIndex: selectedIndex,
            selectedIconTheme: const IconThemeData(color: primaryAmber),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            selectedLabelTextStyle: const TextStyle(color: primaryAmber),
            unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
            // Exibe o menu estendido se a tela for larga (Web Desktop)
            extended: MediaQuery.of(context).size.width > 900,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event),
                label: Text('Eventos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Jogadores'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.attach_money),
                label: Text('Financeiro'),
              ),
            ],
            onDestinationSelected: (int index) {
              // Evita recarregar a mesma tela se já estiver nela
              if (index == selectedIndex) return;

              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/admin/dashboard');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/admin/events');
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, '/admin/users');
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, '/admin/financial');
                  break;
              }
            },
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.grey),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(24.0), child: body),
          ),
        ],
      ),
    );
  }
}
