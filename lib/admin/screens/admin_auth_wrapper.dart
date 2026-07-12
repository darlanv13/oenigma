import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'admin_login_screen.dart';
import 'main_admin_screen.dart';

class AdminAuthWrapper extends ConsumerWidget {
  const AdminAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const AdminLoginScreen();
        }

        final isAdmin = user.get<bool>('isAdmin') ?? false;
        final role = user.get<String>('role') ?? 'player';

        if (!isAdmin && role != 'admin') {
          return _buildAccessDenied(context, ref);
        }

        return const MainAdminScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: primaryAmber)),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: Text('Erro: $e')),
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.shieldHalved,
              size: 80,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'Acesso Restrito',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
              icon: const FaIcon(FontAwesomeIcons.arrowLeft),
              label: const Text('Voltar para o Aplicativo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAmber,
                foregroundColor: Colors.black,
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
              child: const Text("Sair e Fazer Login"),
            ),
          ],
        ),
      ),
    );
  }
}
