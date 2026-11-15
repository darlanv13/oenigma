import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/painel_mestre/features/auth/providers/auth_provider.dart';
import 'package:oenigma/painel_mestre/features/auth/screens/login_screen.dart';
import 'package:oenigma/painel_mestre/features/master/screens/main_master_screen.dart';

class MasterAuthWrapper extends ConsumerWidget {
  const MasterAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(masterAuthStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final isAdmin = user.get<bool>('isAdmin') ?? false;
          final role = user.get<String>('role') ?? 'player';

          if (isAdmin || role == 'admin') {
            return const MainMasterScreen();
          } else {
            return const MasterLoginScreen(
              initialErrorMessage:
                  'Acesso Negado: Apenas Administradores do Painel Mestre possuem acesso.',
            );
          }
        }
        return const MasterLoginScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OEnigmaAdminLogo(size: LogoSize.hero, isVertical: true),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppColors.amareloVale),
              SizedBox(height: 12),
              Text(
                'Inicializando Painel Mestre...',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
      error: (_, _) => const MasterLoginScreen(),
    );
  }
}
