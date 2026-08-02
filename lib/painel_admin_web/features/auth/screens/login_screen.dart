import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oenigma/painel_admin/features/auth/providers/auth_provider.dart';
import 'package:oenigma/painel_admin/features/auth/screens/signup_screen.dart';
import 'package:oenigma/painel_admin/features/auth/screens/forgot_password_screen.dart';
import 'package:oenigma/painel_admin/features/admin/screens/main_admin_screen.dart';
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
        } else {
          final user = authRepository.currentUser;
          final isAdmin = user?.get<bool>('isAdmin') ?? false;
          final role = user?.get<String>('role') ?? 'player';
          if (!isAdmin && role != 'admin') {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Acesso Restrito: Apenas administradores.'), backgroundColor: Colors.red),
             );
             await authRepository.signOut();
             setState(() => _isLoading = false);
             return;
          }
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainAdminScreen()));
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

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextFormField(
              controller: _emailController,
              hintText: "Email",
              prefixIcon: Container(
                alignment: Alignment.center,
                width: 48,
                child: const FaIcon(
                  FontAwesomeIcons.envelope,
                  color: Colors.grey,
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
                child: const FaIcon(
                  FontAwesomeIcons.lock,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: FaIcon(
                  _isPasswordVisible
                      ? FontAwesomeIcons.solidEyeSlash
                      : FontAwesomeIcons.solidEye,
                  color: Colors.grey,
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
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.black),
                      )
                    : const Text(
                        "ENTRAR",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
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
                  style: TextStyle(color: Colors.grey),
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
                      color: Color(0xFFD6B570),
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
    required Widget prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF121212),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
        ),
      ),
    );
  }
}
