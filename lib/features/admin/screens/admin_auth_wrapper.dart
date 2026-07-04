import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/features/admin/screens/main_admin_screen.dart';
import 'package:oenigma/features/auth/screens/login_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';

class AdminAuthWrapper extends ConsumerWidget {
  const AdminAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final isSuperAdmin = user.get<bool>('super_admin') ?? false;
          final isEditor = user.get<bool>('editor') ?? false;

          if (isSuperAdmin || isEditor) {
            return const MainAdminScreen();
          }
        }
        return const LoginScreen();
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
