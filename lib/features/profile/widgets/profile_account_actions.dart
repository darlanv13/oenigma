import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';

class ProfileAccountActions extends ConsumerWidget {
  final String email;
  final Function(String) onResetPassword;

  const ProfileAccountActions({
    super.key,
    required this.email,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_reset, color: textColor, size: 20),
            ),
            title: const Text(
              'Redefinir Senha',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: secondaryTextColor,
            ),
            onTap: () => onResetPassword(email),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            title: const Text(
              'Sair da Conta',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              final authRepository = ref.read(authRepositoryProvider);
              await authRepository.signOut();
            },
          ),
        ],
      ),
    );
  }
}
