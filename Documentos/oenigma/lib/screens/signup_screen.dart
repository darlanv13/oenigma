import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _authService = AuthService();
  int _currentStep = 0;

  // Controladores para os campos de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_formKeyStep1.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else {
      _handleSignUp();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleSignUp() async {
    if (_formKeyStep2.currentState!.validate()) {
      setState(() => _isLoading = true);
      final error = await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        cpf: _cpfController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          // Se o cadastro for bem-sucedido, volta para a tela de login
          Navigator.of(context).pop();
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  ElevatedButton.icon(
                    onPressed: details.onStepCancel,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      foregroundColor: textColor,
                    ),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : details.onStepContinue,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: darkBackground,
                          ),
                        )
                      : Icon(
                          _currentStep == 0 ? Icons.arrow_forward : Icons.check,
                        ),
                  label: Text(_currentStep == 0 ? 'Avançar' : 'Concluir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmber,
                    foregroundColor: darkBackground,
                  ),
                ),
              ],
            ),
          );
        },
        steps: [_buildStep1(), _buildStep2()],
      ),
    );
  }

  Step _buildStep1() {
    return Step(
      title: const Text('Conta'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _formKeyStep1,
        child: Column(
          children: [
            _buildTextFormField(
              controller: _emailController,
              hintText: 'E-mail',
              icon: Icons.email_outlined,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _passwordController,
              hintText: 'Senha',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (v) => v!.length < 6 ? 'Mínimo de 6 caracteres' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _confirmPasswordController,
              hintText: 'Confirmar Senha',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (v) => v != _passwordController.text
                  ? 'As senhas não coincidem'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('Informações Pessoais'),
      isActive: _currentStep >= 1,
      content: Form(
        key: _formKeyStep2,
        child: Column(
          children: [
            _buildTextFormField(
              controller: _fullNameController,
              hintText: 'Nome Completo',
              icon: Icons.person_outline,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _cpfController,
              hintText: 'CPF',
              icon: Icons.badge_outlined,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _birthDateController,
              hintText: 'Data de Nascimento',
              icon: Icons.calendar_today_outlined,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _phoneController,
              hintText: 'Telefone',
              icon: Icons.phone_outlined,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: textColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: textColor.withOpacity(0.7)),
        hintText: hintText,
        hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: primaryAmber),
      ),
    );
  }
}
