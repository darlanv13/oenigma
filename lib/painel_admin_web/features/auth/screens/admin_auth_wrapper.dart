import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/main_admin_screen.dart';
import 'package:oenigma/painel_admin_web/features/auth/providers/auth_provider.dart';
import 'package:oenigma/painel_admin_web/features/auth/screens/login_screen.dart';

/// Guardião Central de Autenticação do Painel Administrativo Web
///
/// Monitora o estado de autenticação via [authStateProvider] persistido no Parse (localStorage no Web).
/// - Se o admin já estiver logado (ex.: ao recarregar a página com F5), renderiza diretamente [MainAdminScreen].
/// - Se não houver sessão ativa ou se for encerrada (logout), exibe [LoginScreen].
/// - Durante a verificação inicial da sessão, apresenta uma tela de carregamento tática sem piscar a tela de login.
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

          if (isAdmin || role == 'admin' || role == 'creator') {
            return const MainAdminScreen();
          } else {
            return const LoginScreen(
              initialErrorMessage:
                  'Acesso Restrito: Esta conta não possui privilégios de administrador.',
            );
          }
        }
        return const LoginScreen();
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OEnigmaAdminLogo(
                size: LogoSize.hero,
                isVertical: true,
              ),
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

