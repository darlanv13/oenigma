import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/painel_mestre/features/admin/screens/main_admin_screen.dart';
import 'package:oenigma/creator_studio/features/creator/screens/main_creator_screen.dart';
import 'package:oenigma/painel_mestre/features/auth/providers/auth_provider.dart';
import 'package:oenigma/painel_mestre/features/auth/screens/login_screen.dart';

/// Guardião Central de Autenticação do Painel Administrativo Web
///
/// Monitora o estado de autenticação via [authStateProvider] persistido no Parse (localStorage no Web).
/// - Se o usuário for Criador/Influenciador (`role == 'creator'`), renderiza [MainCreatorScreen].
/// - Se for Super Admin (`isAdmin` ou `role == 'admin'`), renderiza [MainAdminScreen].
/// - Se não houver sessão ativa ou se for encerrada (logout), exibe [LoginScreen].
class AdminAuthWrapper extends ConsumerWidget {
  const AdminAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final isAdmin = user.get<bool>('isAdmin') ?? false;
          final role = user.get<String>('role') ?? 'player';

          // 1. Influenciador vai direto para o Creator Studio
          if (role == 'creator' && !isAdmin) {
            return const MainCreatorScreen();
          }

          // 2. Super Admin vai para a Plataforma Master
          if (isAdmin || role == 'admin') {
            return const MainAdminScreen();
          }

          return const LoginScreen(
            initialErrorMessage:
                'Acesso Restrito: Esta conta não possui privilégios de administrador.',
          );
        }
        return const LoginScreen();
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OEnigmaAdminLogo(size: LogoSize.hero, isVertical: true),
              const SizedBox(height: 28),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.verdeVale,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sincronizando credenciais administrativas...',
                style: GoogleFonts.poppins(
                  color: AppColors.cinzaMedio,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => const LoginScreen(),
    );
  }
}
