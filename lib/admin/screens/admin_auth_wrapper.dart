import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/dashboard_screen.dart';
import 'package:oenigma/admin/screens/admin_login_screen.dart';
import 'package:oenigma/utils/app_colors.dart';

class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Verificando estado da conexão
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: darkBackground,
            body: Center(child: CircularProgressIndicator(color: primaryAmber)),
          );
        }

        // 2. Se não tem usuário logado
        if (!snapshot.hasData || snapshot.data == null) {
          return const AdminLoginScreen();
        }

        User user = snapshot.data!;

        // 3. SEGURANÇA EXTRA: Verifica se o usuário tem a claim 'admin'
        // Usamos FutureBuilder porque getIdTokenResult é assíncrono
        return FutureBuilder<IdTokenResult>(
          future: user.getIdTokenResult(false), // false = usa cache se válido
          builder: (context, tokenSnapshot) {
            if (tokenSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: darkBackground,
                body: Center(
                  child: CircularProgressIndicator(color: primaryAmber),
                ),
              );
            }

            final isAdmin = tokenSnapshot.data?.claims?['role'] == 'admin';

            if (isAdmin) {
              return const DashboardScreen();
            } else {
              // Se logou mas não é admin, faz logout forçado e avisa
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FirebaseAuth.instance.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Acesso negado: Apenas administradores."),
                    backgroundColor: Colors.red,
                  ),
                );
              });
              return const AdminLoginScreen();
            }
          },
        );
      },
    );
  }
}
