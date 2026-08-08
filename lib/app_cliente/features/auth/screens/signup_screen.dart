import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authRepository = ref.read(authRepositoryProvider);

      final cleanCpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');

      final error = await authRepository.signUpWithCpfAndPassword(
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        cpf: cleanCpf,
        birthDate: _birthDateController.text.trim(),
        phone: _phoneController.text.trim(),
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

  String? _validateCpf(String? value) {
    if (value == null || value.isEmpty) return 'Campo obrigatório';

    final cleanCpf = value.replaceAll(RegExp(r'\D'), '');

    if (cleanCpf.length != 11) return 'CPF incompleto';
    if (!_isValidCpf(cleanCpf)) return 'CPF inválido';

    return null;
  }

  bool _isValidCpf(String cpf) {
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    List<int> digits = cpf.split('').map(int.parse).toList();

    int sum1 = 0;
    for (int i = 0; i < 9; i++) {
      sum1 += digits[i] * (10 - i);
    }
    int remainder1 = sum1 % 11;
    int digit1 = remainder1 < 2 ? 0 : 11 - remainder1;

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Criar Conta',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryAmber),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSignUpForm(),
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
          'JUNTE-SE À CAÇADA',
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

  Widget _buildSignUpForm() {
    final defaultPinTheme = PinTheme(
      width: 40,
      height: 50,
      textStyle: const TextStyle(
          fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: darkBackground,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
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
            _buildFieldLabel('NOME COMPLETO', FontAwesomeIcons.solidUser),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _fullNameController,
              hintText: "Seu nome completo",
              textCapitalization: TextCapitalization.words,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
            ),

            const SizedBox(height: 20),

            _buildFieldLabel('CPF', FontAwesomeIcons.idBadge),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _cpfController,
              hintText: "000.000.000-00",
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CpfInputFormatter(),
              ],
              validator: _validateCpf,
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('DATA NASC.', FontAwesomeIcons.calendarDay),
                      const SizedBox(height: 8),
                      _buildTextFormField(
                        controller: _birthDateController,
                        hintText: "11/11/1111",
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _DateInputFormatter(),
                        ],
                        validator: (v) => v!.length < 10 ? 'Data inválida' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('TELEFONE', FontAwesomeIcons.phone),
                      const SizedBox(height: 8),
                      _buildTextFormField(
                        controller: _phoneController,
                        hintText: "(11) 11111-1111",
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _PhoneInputFormatter(),
                        ],
                        validator: (v) => v!.length < 14 ? 'Telefone inválido' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildFieldLabel('SENHA (6 DÍGITOS)', FontAwesomeIcons.key),
            const SizedBox(height: 8),
            Center(
              child: Pinput(
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
                  return s!.length == 6 ? null : 'Mín. 6 dígitos';
                },
                keyboardType: TextInputType.number,
              ),
            ),

            const SizedBox(height: 20),

            _buildFieldLabel('CONFIRMAR SENHA', FontAwesomeIcons.solidCircleCheck),
            const SizedBox(height: 8),
            Center(
              child: Pinput(
                controller: _confirmPasswordController,
                length: 6,
                obscureText: true,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: primaryAmber),
                  ),
                ),
                validator: (s) {
                  if (s != _passwordController.text) return 'Senhas não coincidem';
                  return s!.length == 6 ? null : 'Mín. 6 dígitos';
                },
                keyboardType: TextInputType.number,
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
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
                          const FaIcon(FontAwesomeIcons.userPlus, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            "CRIAR CONTA",
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
                  "Já tem uma conta? ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop(); // Volta para o login
                        },
                  child: const Text(
                    "Faça login",
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

  Widget _buildFieldLabel(String label, dynamic icon) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: primaryAmber),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: primaryAmber,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        filled: true,
        fillColor: darkBackground,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length > 8) return oldValue;

    var newText = '';
    for (var i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) newText += '/';
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
    if (text.length > 11) return oldValue;

    var newText = '';
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
