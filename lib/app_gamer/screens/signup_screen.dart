import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../stores/signup_store.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final SignUpStore _store = SignUpStore();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => _store.setName(_nameController.text));
    _emailController.addListener(() => _store.setEmail(_emailController.text));
    _passwordController.addListener(() => _store.setPassword(_passwordController.text));
    _confirmPasswordController.addListener(() => _store.setConfirmPassword(_confirmPasswordController.text));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      await _store.signUp();
      if (mounted) {
        if (_store.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_store.errorMessage!), backgroundColor: Colors.red),
          );
        } else if (_store.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Conta criada com sucesso!"), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(); // Go back to login
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text("Criar Conta"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextFormField(
                    controller: _nameController,
                    hintText: "Nome Completo",
                    icon: FontAwesomeIcons.user,
                    validator: (val) => val!.isEmpty ? 'Insira seu nome' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _emailController,
                    hintText: "Email",
                    icon: FontAwesomeIcons.envelope,
                    validator: (val) => val!.isEmpty ? 'Insira um email' : null,
                  ),
                  const SizedBox(height: 16),
                  Observer(
                    builder: (_) => _buildTextFormField(
                      controller: _passwordController,
                      hintText: "Senha",
                      icon: FontAwesomeIcons.lock,
                      obscureText: !_store.isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: FaIcon(
                          _store.isPasswordVisible
                              ? FontAwesomeIcons.eyeSlash
                              : FontAwesomeIcons.eye,
                          color: textColor.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: _store.togglePasswordVisibility,
                      ),
                      validator: (val) => val!.length < 6
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Observer(
                    builder: (_) => _buildTextFormField(
                      controller: _confirmPasswordController,
                      hintText: "Confirmar Senha",
                      icon: FontAwesomeIcons.lock,
                      obscureText: !_store.isConfirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: FaIcon(
                          _store.isConfirmPasswordVisible
                              ? FontAwesomeIcons.eyeSlash
                              : FontAwesomeIcons.eye,
                          color: textColor.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: _store.toggleConfirmPasswordVisibility,
                      ),
                      validator: (val) {
                        if (val!.isEmpty) return 'Confirme a senha';
                        if (val != _passwordController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Observer(
                    builder: (_) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _store.isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAmber,
                          foregroundColor: darkBackground,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _store.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: darkBackground),
                              )
                            : const Text(
                                "Cadastrar",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
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
        hintText: hintText,
        hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FaIcon(icon, color: textColor.withOpacity(0.7), size: 18),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: primaryAmber),
      ),
    );
  }
}
