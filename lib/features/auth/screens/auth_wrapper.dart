import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:oenigma/features/home/screens/home_screen.dart';
import 'package:oenigma/features/auth/screens/login_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // Se o usuário está logado, mostra a tela principal
          return const HomeScreen();
        } else {
          // Se não, mostra a tela de login
          return const LoginScreen();
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
}
