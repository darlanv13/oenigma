import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../widgets/custom_text_form_field.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../stores/login_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginStore _store = LoginStore();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      _store.setEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      _store.setPassword(_passwordController.text);
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await _store.login();
      if (!success && mounted && _store.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_store.errorMessage!), backgroundColor: Colors.red),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
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
                text: 'ENIGMA\n',
                style: TextStyle(color: textColor),
              ),
              TextSpan(
                text: 'CITY',
                style: TextStyle(
                  color: primaryAmber,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "",
          style: TextStyle(
            color: textColor,
            fontSize: 32,
            fontWeight: FontWeight.w300,
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Observer(
          builder: (_) => Column(
            children: [
              CustomTextFormField(
                controller: _emailController,
                hintText: "Email",
                icon: FontAwesomeIcons.envelope,
                validator: (val) =>
                    val!.isEmpty ? 'Por favor, insira um email' : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
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
                  onPressed: _store.isLoading ? null : _handleLogin,
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
                    onPressed: _store.isLoading
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
      ),
    );
  }
}
