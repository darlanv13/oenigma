import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oenigma/auth_wrapper.dart';
import 'package:oenigma/firebase_options.dart';
import 'package:oenigma/utils/app_colors.dart';

// Importações das telas do Usuário
import 'package:oenigma/screens/login_screen.dart';
import 'package:oenigma/screens/home_screen.dart';
import 'package:oenigma/screens/signup_screen.dart';
import 'package:oenigma/screens/forgot_password_screen.dart';

// Importações das telas do Admin (NECESSÁRIO PARA O REDIRECIONAMENTO WEB)
import 'package:oenigma/admin/screens/dashboard_screen.dart';
import 'package:oenigma/admin/screens/events_manager_screen.dart';
import 'package:oenigma/admin/screens/users_manager_screen.dart';
import 'package:oenigma/admin/screens/financial_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Forçar orientação retrato no mobile (opcional)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O Enigma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryAmber,
        scaffoldBackgroundColor: darkBackground,
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryAmber,
          brightness: Brightness.dark,
          surface: cardColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      // Rota Inicial controlada pelo Wrapper Inteligente
      home: const AuthWrapper(),

      // ROTAS (Misturando Rotas de User e Admin)
      routes: {
        // Rotas de Usuário
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),

        // Rotas de Admin (Essenciais para o menu lateral funcionar na Web)
        '/admin/dashboard': (context) => const DashboardScreen(),
        '/admin/events': (context) => const EventsManagerScreen(),
        '/admin/users': (context) => const UsersManagerScreen(),
        '/admin/financial': (context) => const FinancialScreen(),
      },
    );
  }
}
