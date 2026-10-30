import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authRepository = ref.read(authRepositoryProvider);
      final cleanCpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');

      try {
        final error = await authRepository.resetPassword(cleanCpf);

        if (mounted) {
          if (error != null) {
            _showSnackBar(error, isError: true);
          } else {
            _showSnackBar(
              'Instruções de recuperação enviadas. Verifique seu SMS/E-mail.',
              isError: false,
            );
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Ocorreu um erro ao tentar recuperar a senha.', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.verdeVale,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Recuperar Acesso',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.chevronLeft, color: Colors.white, size: 14),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildRecoveryForm(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.verdeVale.withValues(alpha: 0.15),
            boxShadow: [
              BoxShadow(
                color: AppColors.verdeVale.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.35), width: 1.5),
          ),
          child: const FaIcon(FontAwesomeIcons.userShield, color: AppColors.verdeVale, size: 40),
        ),
        const SizedBox(height: 18),
        Text(
          'CÓDIGO PERDIDO?',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Não se preocupe, explorador. Informe seu CPF de registro para recuperar sua credencial de acesso à Enigma City.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: AppColors.cinzaMedio,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryForm() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('CPF DE ACESSO', FontAwesomeIcons.idBadge),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _cpfController,
              hintText: "000.000.000-00",
              keyboardType: TextInputType.number,
              icon: FontAwesomeIcons.fingerprint,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CpfInputFormatter(),
              ],
              validator: (val) {
                if (val == null || val.isEmpty) return 'Por favor, insira seu CPF';
                final cleanCpf = val.replaceAll(RegExp(r'\D'), '');
                if (cleanCpf.length != 11) return 'CPF incompleto';
                return null;
              },
            ),
            
            const SizedBox(height: 28),
            
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: AppColors.gradienteVerdeVale,
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.verdeVale.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "ENVIAR INSTRUÇÕES",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const FaIcon(FontAwesomeIcons.paperPlane, size: 14),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  "Voltar para o Login",
                  style: GoogleFonts.inter(
                    color: AppColors.verdeVale,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, FaIconData icon) {
    return Row(
      children: [
        FaIcon(icon, size: 13, color: AppColors.verdeVale),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required FaIconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: AppColors.cinzaMedio,
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: FaIcon(icon, color: AppColors.cinzaMedio, size: 16),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.verdeVale, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
    );
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length > 11) return oldValue;
    var newText = '';
    for (var i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        newText += '.';
      } else if (i == 9) {
        newText += '-';
      }
      newText += text[i];
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
