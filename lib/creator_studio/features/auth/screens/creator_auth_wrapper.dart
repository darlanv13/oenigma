import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/creator_studio/features/auth/providers/auth_provider.dart';
import 'package:oenigma/creator_studio/features/auth/screens/login_screen.dart';
import 'package:oenigma/creator_studio/features/creator/screens/creator_studio_shell.dart';

class CreatorAuthWrapper extends ConsumerWidget {
  const CreatorAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(creatorAuthStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final isAdmin = user.get<bool>('isAdmin') ?? false;
          final role = user.get<String>('role') ?? 'player';

          if (isAdmin || role == 'admin' || role == 'creator') {
            return const CreatorStudioShell();
          } else {
            return const CreatorLoginScreen(
              initialErrorMessage:
                  'Acesso Restrito: Sua conta não possui permissão de Criador.',
            );
          }
        }
        return const CreatorLoginScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OEnigmaAdminLogo(size: LogoSize.hero, isVertical: true),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppColors.verdeVale),
              SizedBox(height: 12),
              Text(
                'Inicializando Creator Studio...',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => const CreatorLoginScreen(),
    );
  }
}
