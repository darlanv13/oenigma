import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oenigma/features/admin/screens/main_admin_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: darkBackground,
            body: Center(child: CircularProgressIndicator(color: primaryAmber)),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return _buildAccessDenied(context);
        }

        return FutureBuilder<IdTokenResult>(
          future: user.getIdTokenResult(true),
          builder: (context, tokenSnapshot) {
            if (tokenSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: darkBackground,
                body: Center(child: CircularProgressIndicator(color: primaryAmber)),
              );
            }

            final claims = tokenSnapshot.data?.claims ?? {};
            final isAdmin = claims['super_admin'] == true || claims['editor'] == true;

            if (isAdmin) {
              return const MainAdminScreen();
            } else {
              return _buildAccessDenied(context);
            }
          },
        );
      },
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              'Acesso Restrito',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Você não tem permissão para acessar o Painel Admin.',
              style: TextStyle(color: secondaryTextColor),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar para o Aplicativo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAmber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
