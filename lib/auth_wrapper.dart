import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar se é Web
import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/dashboard_screen.dart'; // Tela inicial do Admin
import 'package:oenigma/screens/home_screen.dart';
import 'package:oenigma/screens/login_screen.dart';
import 'package:oenigma/screens/splash_screen.dart';
import 'package:oenigma/utils/app_colors.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Verificando estado da conexão
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // 2. Se não tem usuário logado, manda pro Login
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        User user = snapshot.data!;

        // 3. SE FOR WEB, VERIFICA SE É ADMIN PARA REDIRECIONAR
        if (kIsWeb) {
          return FutureBuilder<IdTokenResult>(
            future: user.getIdTokenResult(
              false,
            ), // false = usa cache para ser rápido
            builder: (context, tokenSnapshot) {
              if (tokenSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: darkBackground,
                  body: Center(
                    child: CircularProgressIndicator(color: primaryAmber),
                  ),
                );
              }

              // Verifica a claim 'role'
              final bool isAdmin =
                  tokenSnapshot.data?.claims?['role'] == 'admin';

              if (isAdmin) {
                // REDIRECIONAMENTO MÁGICO: Admin na Web vai direto pro Dashboard
                return const DashboardScreen();
              } else {
                // Usuário comum na Web continua vendo a Home normal
                // (Ou você pode bloquear se seu app web for SÓ para admin)
                return const HomeScreen();
              }
            },
          );
        }

        // 4. Se for Mobile (Android/iOS), segue fluxo normal de jogador
        return const HomeScreen();
      },
    );
  }
}
