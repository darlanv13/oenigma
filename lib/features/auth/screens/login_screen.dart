import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/auth/screens/signup_screen.dart';
import 'package:oenigma/features/auth/screens/forgot_password_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authRepository = ref.read(authRepositoryProvider);
      final error = await authRepository.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //_buildHeaderBusula(),
              const SizedBox(height: 1),
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
        Image.asset('assets/images/logo_enigma_city.png', scale: 0.1), //
        const SizedBox(height: 1),
      ],
    );
  }

  Widget _buildHeaderBusula() {
    return Column(
      children: [
        Image.asset('assets/images/compass_icon.png', scale: 4.5), //
        const SizedBox(height: 1),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextFormField(
              controller: _emailController,
              hintText: "Email",
              // CORREÇÃO AQUI: Passando o Widget FaIcon centralizado
              prefixIcon: Container(
                alignment: Alignment.center,
                width: 48,
                child: FaIcon(
                  FontAwesomeIcons.envelope,
                  color: textColor.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              validator: (val) =>
                  val!.isEmpty ? 'Por favor, insira um email' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _passwordController,
              hintText: "Senha",
              // CORREÇÃO AQUI: Passando o Widget FaIcon centralizado
              prefixIcon: Container(
                alignment: Alignment.center,
                width: 48,
                child: FaIcon(
                  FontAwesomeIcons.lock,
                  color: textColor.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: FaIcon(
                  _isPasswordVisible
                      ? FontAwesomeIcons.solidEyeSlash
                      : FontAwesomeIcons.solidEye,
                  color: textColor.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              validator: (val) => val!.length < 6
                  ? 'A senha deve ter no mínimo 6 caracteres'
                  : null,
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
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  foregroundColor: darkBackground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: darkBackground),
                      )
                    : const Text(
                        "Entrar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Não tem uma conta? ",
                  style: TextStyle(color: textColor),
                ),
                TextButton(
                  onPressed: _isLoading
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

  // CORREÇÃO NA ASSINATURA DA FUNÇÃO: Recebendo "Widget prefixIcon"
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required Widget prefixIcon, // Alterado de IconData para Widget
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: cardColor,
        hintText: hintText,
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
        prefixIcon: prefixIcon, // Usando o Widget passado
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
