import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:oenigma/firebase_options.dart';
import 'package:oenigma/utils/app_colors.dart';

// Telas
import 'package:oenigma/admin/screens/admin_auth_wrapper.dart';
import 'package:oenigma/admin/screens/dashboard_screen.dart';
import 'package:oenigma/admin/screens/events_manager_screen.dart';
import 'package:oenigma/admin/screens/users_manager_screen.dart';
import 'package:oenigma/admin/screens/financial_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Painel Admin - OEnigma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryAmber,
        scaffoldBackgroundColor: darkBackground,
        fontFamily: 'Poppins',
        cardColor: cardColor,
        // Configurações globais de inputs e botões
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAmber,
            foregroundColor: darkBackground,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      // Rota inicial é o Wrapper (decide entre Login ou Dashboard)
      home: const AdminAuthWrapper(),

      // AQUI ESTÃO AS ROTAS NECESSÁRIAS PARA O SCAFFOLD FUNCIONAR:
      routes: {
        '/admin/dashboard': (context) => const DashboardScreen(),
        '/admin/events': (context) => const EventsManagerScreen(),
        '/admin/users': (context) => const UsersManagerScreen(),
        '/admin/financial': (context) => const FinancialScreen(),
      },
    );
  }
}
