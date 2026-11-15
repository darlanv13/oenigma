import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Cartão de dados de segurança e identificação da conta
class ProfileSecurityCard extends StatelessWidget {
  final String cpf;
  final String email;
  final String phone;

  const ProfileSecurityCard({
    super.key,
    required this.cpf,
    required this.email,
    required this.phone,
  });

  static String formatMaskedCpf(String? cpf) {
    if (cpf == null || cpf.trim().isEmpty) return 'Não cadastrado';
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
    }
    return cpf;
  }

  static String formatPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return 'Não informado';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7.5),
                    decoration: BoxDecoration(
                      color: AppColors.verdeVale.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const FaIcon(FontAwesomeIcons.shieldHalved, color: AppColors.verdeVale, size: 13),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'DADOS & SEGURANÇA',
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3123),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.6), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF4CAF50), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'ATIVO',
                      style: GoogleFonts.cinzel(
                        color: const Color(0xFF4CAF50),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // CPF Mascarado
          ProfileInfoRow(
            icon: FontAwesomeIcons.fingerprint,
            label: 'CPF DE ACESSO',
            value: formatMaskedCpf(cpf),
            trailingBadge: 'PROTEGIDO',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: const Color(0xFF1E3A45).withValues(alpha: 0.6), height: 1),
          ),

          // E-mail
          ProfileInfoRow(
            icon: FontAwesomeIcons.envelope,
            label: 'E-MAIL',
            value: email,
            canCopy: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: const Color(0xFF1E3A45).withValues(alpha: 0.6), height: 1),
          ),

          // Telefone
          ProfileInfoRow(
            icon: FontAwesomeIcons.phone,
            label: 'TELEFONE',
            value: formatPhone(phone),
          ),
        ],
      ),
    );
  }
}

/// Linha de informação de segurança com opção de cópia
class ProfileInfoRow extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String value;
  final String? trailingBadge;
  final bool canCopy;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailingBadge,
    this.canCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0C171F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E3A45), width: 1),
          ),
          child: Center(
            child: FaIcon(icon, color: const Color(0xFF00A4B4), size: 13.5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cinzel(
                  color: const Color(0xFF91A3AE),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (trailingBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trailingBadge!,
              style: GoogleFonts.cinzel(
                color: const Color(0xFF91A3AE),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        if (canCopy && value.isNotEmpty && value != 'Não cadastrado')
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: value));
              SoundService.playClick();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Copiado para a área de transferência!'),
                  backgroundColor: AppColors.verdeVale,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const FaIcon(FontAwesomeIcons.copy, color: AppColors.cinzaMedio, size: 12),
            ),
          ),
      ],
    );
  }
}
