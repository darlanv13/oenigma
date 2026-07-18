import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:oenigma/features/home/screens/main_navigation_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final isAdmin = user.get<bool>('isAdmin') ?? false;

          if (isAdmin) {
            // Determine if device is conceptually a Desktop/Web screen
            final double screenWidth = MediaQuery.of(context).size.width;
            final bool isDesktop = kIsWeb || screenWidth > 800;

            if (isDesktop) {
              return const MainNavigationScreen();
            } else {
              return _buildAdminMobileBlockedScreen(context);
            }
          }

          // Regular users go to the game
          return const MainNavigationScreen();
        } else {
          return const MainNavigationScreen();
        }
      },
      loading: () => const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: primaryAmber)),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: Text('Erro: $error')),
      ),
    );
  }

  Widget _buildAdminMobileBlockedScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.desktop,
                size: 80,
                color: primaryAmber,
              ),
              const SizedBox(height: 24),
              const Text(
                'Acesso Restrito',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Você é um Administrador. Para gerenciar o O Enigma com eficiência, o Painel Admin deve ser acessado por um computador/Desktop.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final user = await ParseUser.currentUser() as ParseUser?;
                  if (user != null) await user.logout();
                },
                icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket),
                label: const Text('Sair e Trocar de Conta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
