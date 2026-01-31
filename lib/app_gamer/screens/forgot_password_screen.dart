import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../stores/forgot_password_store.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ForgotPasswordStore _store = ForgotPasswordStore();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => _store.setEmail(_emailController.text));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      await _store.resetPassword();
      if (mounted) {
        if (_store.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_store.errorMessage!), backgroundColor: Colors.red),
          );
        } else if (_store.success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: cardColor,
              title: const Text("Email Enviado", style: TextStyle(color: primaryAmber)),
              content: const Text(
                "Verifique sua caixa de entrada para redefinir sua senha.",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Back to login
                  },
                  child: const Text("OK", style: TextStyle(color: primaryAmber)),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Esqueceu a Senha?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Digite seu email abaixo para receber instruções de recuperação.",
                style: TextStyle(color: secondaryTextColor, fontSize: 16),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: textColor),
                validator: (val) => val!.isEmpty ? 'Digite seu email' : null,
                decoration: InputDecoration(
                  hintText: "Seu email cadastrado",
                  hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  prefixIcon: const Icon(FontAwesomeIcons.envelope, color: secondaryTextColor, size: 20),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Observer(
                builder: (_) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _store.isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _store.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: darkBackground),
                          )
                        : const Text(
                            "ENVIAR LINK",
                            style: TextStyle(
                              color: darkBackground,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
