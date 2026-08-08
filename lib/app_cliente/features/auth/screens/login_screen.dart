import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/app_cliente/features/auth/screens/signup_screen.dart';
import 'package:oenigma/app_cliente/features/auth/screens/forgot_password_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:pinput/pinput.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authRepository = ref.read(authRepositoryProvider);

      // Clean CPF to match what is saved in parse server (as digits)
      final cleanCpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');

      final error = await authRepository.signInWithCpfAndPassword(
        cleanCpf,
        _passwordController.text.trim(),
      );
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Acessar',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 48),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const FaIcon(FontAwesomeIcons.magnifyingGlass, color: primaryAmber, size: 40),
        const SizedBox(height: 16),
        Text(
          'ENIGMA CITY',
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: primaryAmberLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'CAÇA AO TESOURO URBANO',
          style: GoogleFonts.inter(
            fontSize: 12,
            letterSpacing: 3,
            color: primaryAmber.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: const TextStyle(
          fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: darkBackground,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(FontAwesomeIcons.idBadge, size: 14, color: primaryAmber),
                const SizedBox(width: 8),
                Text(
                  'CPF',
                  style: GoogleFonts.inter(
                    color: primaryAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _cpfController,
              hintText: "000.000.000-00",
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CpfInputFormatter(),
              ],
              validator: (val) {
                if (val == null || val.isEmpty) return 'Por favor, insira um CPF';
                final cleanCpf = val.replaceAll(RegExp(r'\D'), '');
                if (cleanCpf.length != 11) return 'CPF incompleto';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.key, size: 14, color: primaryAmber),
                const SizedBox(width: 8),
                Text(
                  'SENHA (6 DÍGITOS)',
                  style: GoogleFonts.inter(
                    color: primaryAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Pinput(
              controller: _passwordController,
              length: 6,
              obscureText: true,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: primaryAmber),
                ),
              ),
              validator: (s) {
                return s!.length == 6 ? null : 'Insira 6 dígitos';
              },
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Esqueceu a senha?",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  foregroundColor: darkBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: darkBackground),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(FontAwesomeIcons.rightToBracket, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            "ENTRAR",
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Não tem uma conta? ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                  child: const Text(
                    "Cadastre-se",
                    style: TextStyle(
                      color: primaryAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        filled: true,
        fillColor: darkBackground,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
          borderSide: const BorderSide(color: primaryAmber, width: 1.5),
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
