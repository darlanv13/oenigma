import 'dart:ui';
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

      // TODO: Verifique o nome correto do método no seu AuthRepository (ex: resetPassword, recoverPassword)
      // Substitua caso necessário. Estou assumindo um método genérico chamado `resetPassword`
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
        backgroundColor: isError ? dangerColor : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: primaryAmber, size: 20),
          onPressed: () => Navigator.of(context).pop(),
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
              const SizedBox(height: 48),
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
            color: primaryAmber.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: primaryAmber.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(color: primaryAmber.withOpacity(0.3), width: 1.5),
          ),
          child: const FaIcon(FontAwesomeIcons.userShield, color: primaryAmber, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          'CÓDIGO PERDIDO?',
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: primaryAmberLight,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Não se preocupe, explorador. Informe seu CPF de registro para recuperar sua credencial de acesso à Enigma City.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.5,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('CPF DE ACESSO', FontAwesomeIcons.idBadge),
                const SizedBox(height: 10),
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
                
                const SizedBox(height: 32),
                
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: primaryAmber.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      foregroundColor: Colors.black,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "ENVIAR INSTRUÇÕES",
                                style: GoogleFonts.orbitron(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const FaIcon(FontAwesomeIcons.paperPlane, size: 16),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      "Voltar para o Login",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, FaIconData icon) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: primaryAmber),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: primaryAmber,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
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
      style: GoogleFonts.orbitron(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        hintText: hintText,
        hintStyle: GoogleFonts.orbitron(
          color: Colors.white.withOpacity(0.2),
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FaIcon(icon, color: Colors.white54, size: 16),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryAmber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dangerColor, width: 1.5),
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