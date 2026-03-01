import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ProfileEditableInfoCard extends StatelessWidget {
  final Map<String, dynamic> playerData;
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final bool isLoading;
  final VoidCallback onSave;

  const ProfileEditableInfoCard({
    super.key,
    required this.playerData,
    required this.formKey,
    required this.phoneController,
    required this.isLoading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _InfoRow(
              label: 'Nome Completo',
              value: playerData['name'] ?? '',
              icon: Icons.badge_outlined,
            ),
            const Divider(height: 32, color: Colors.white10),
            _InfoRow(
              label: 'CPF',
              value: playerData['cpf'] ?? '',
              icon: Icons.credit_card,
            ),
            const Divider(height: 32, color: Colors.white10),
            _InfoRow(
              label: 'Data de Nascimento',
              value: playerData['birthDate'] ?? '',
              icon: Icons.calendar_month,
            ),
            const Divider(height: 32, color: Colors.white10),
            _TextFormField(
              controller: phoneController,
              label: 'Telefone',
              icon: Icons.phone_android,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  foregroundColor: darkBackground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: darkBackground,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SALVAR ALTERAÇÕES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: secondaryTextColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: textColor, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}

class _TextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _TextFormField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: textColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: secondaryTextColor, size: 20),
        labelText: label,
        labelStyle: const TextStyle(color: secondaryTextColor),
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryAmber),
        ),
      ),
    );
  }
}
