// lib/admin/screens/admin_auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oenigma/admin/screens/admin_login_screen.dart';
import 'package:oenigma/main_admin.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: primaryAmber)),
          );
        }

        if (snapshot.hasData) {
          // Se houver um usuário, vá para o dashboard
          return const MainAdminScreen();
        } else {
          // Senão, mostre a tela de login do admin
          return const AdminLoginScreen();
        }
      },
    );
  }
}
