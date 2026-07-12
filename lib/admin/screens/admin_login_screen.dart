import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../auth/providers/admin_auth_provider.dart';
import '../../core/utils/admin_colors.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
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
      final error = await authRepository.signInAdminWithEmailAndPassword(
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
        const FaIcon(
          FontAwesomeIcons.userShield,
          size: 64,
          color: primaryAmber,
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
            children: <TextSpan>[
              TextSpan(
                text: 'ADMIN\n',
                style: TextStyle(color: textColor),
              ),
              TextSpan(
                text: 'PANEL',
                style: TextStyle(
                  color: primaryAmber,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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
              hintText: "Email Admin",
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
            const SizedBox(height: 32),
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
                        "Entrar no Painel",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required Widget prefixIcon,
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
        fillColor: darkBackground,
        hintText: hintText,
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
