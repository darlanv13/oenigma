import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oenigma/app_gamer/screens/home_screen.dart';
import 'package:oenigma/app_gamer/screens/login_screen.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: darkBackground,
            body: Center(child: CircularProgressIndicator(color: primaryAmber)),
          );
        }

        if (snapshot.hasData) {
          // Se o usuário está logado, mostra a tela principal
          return const HomeScreen();
        } else {
          // Se não, mostra a tela de login
          return const LoginScreen();
        }
      },
    );
  }
}
