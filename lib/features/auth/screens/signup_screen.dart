import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import necessário para os formatadores
import 'package:oenigma/core/services/auth_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

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
      // Remove a formatação antes de enviar para o backend (opcional, dependendo de como você quer salvar)
      // Aqui estou enviando formatado mesmo, conforme seu código original sugeria,
      // mas você pode usar .replaceAll(RegExp(r'\D'), '') se quiser apenas números.

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

  // --- VALIDAÇÃO DE CPF ---
  String? _validateCpf(String? value) {
    if (value == null || value.isEmpty) return 'Campo obrigatório';

    // Remove caracteres não numéricos para validação
    final cleanCpf = value.replaceAll(RegExp(r'\D'), '');

    if (cleanCpf.length != 11) return 'CPF incompleto';
    if (!_isValidCpf(cleanCpf)) return 'CPF inválido';

    return null;
  }

  bool _isValidCpf(String cpf) {
    // Rejeita CPFs com todos os números iguais (ex: 111.111.111-11)
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    // Algoritmo de validação dos dígitos verificadores
    List<int> digits = cpf.split('').map(int.parse).toList();

    // Primeiro dígito
    int sum1 = 0;
    for (int i = 0; i < 9; i++) {
      sum1 += digits[i] * (10 - i);
    }
    int remainder1 = sum1 % 11;
    int digit1 = remainder1 < 2 ? 0 : 11 - remainder1;

    // Segundo dígito
    int sum2 = 0;
    for (int i = 0; i < 9; i++) {
      sum2 += digits[i] * (11 - i);
    }
    sum2 += digit1 * 2;
    int remainder2 = sum2 % 11;
    int digit2 = remainder2 < 2 ? 0 : 11 - remainder2;

    return digits[9] == digit1 && digits[10] == digit2;
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
              keyboardType: TextInputType.emailAddress,
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
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _cpfController,
              hintText: 'CPF',
              icon: Icons.badge_outlined,
              validator: _validateCpf, // Validador customizado
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CpfInputFormatter(),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _birthDateController,
              hintText: 'Data de Nascimento',
              icon: Icons.calendar_today_outlined,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _phoneController,
              hintText: 'Telefone',
              icon: Icons.phone_outlined,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _PhoneInputFormatter(),
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
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
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

// --- CLASSES AUXILIARES DE FORMATAÇÃO ---

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length > 11) return oldValue; // Limita a 11 dígitos

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

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length > 11) return oldValue; // Limita a 11 dígitos

    var newText = '';

    // (00) 00000-0000
    for (var i = 0; i < text.length; i++) {
      if (i == 0) newText += '(';

      newText += text[i];

      if (i == 1) newText += ') ';
      if (i == 6) newText += '-';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
