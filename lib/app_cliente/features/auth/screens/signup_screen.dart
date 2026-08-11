import 'dart:ui';
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
            SnackBar(
              content: Text(error, style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: dangerColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
          'Alistamento',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryAmber, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSignUpForm(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryAmber.withOpacity(0.1),
            border: Border.all(color: primaryAmber.withOpacity(0.3)),
          ),
          child: const FaIcon(FontAwesomeIcons.userSecret, color: primaryAmber, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'NOVO EXPLORADOR',
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: primaryAmberLight,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PREPARE-SE PARA A CAÇADA',
          style: GoogleFonts.inter(
            fontSize: 10,
            letterSpacing: 3,
            color: primaryAmber.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    final defaultPinTheme = PinTheme(
      width: 45,
      height: 55,
      textStyle: GoogleFonts.orbitron(
        fontSize: 20,
        color: primaryAmberLight,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('DADOS PESSOAIS'),
                const SizedBox(height: 16),
                _buildFieldLabel('NOME COMPLETO', FontAwesomeIcons.solidUser),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _fullNameController,
                  hintText: "Seu nome",
                  icon: FontAwesomeIcons.idCard,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 20),
                
                _buildFieldLabel('CPF', FontAwesomeIcons.fingerprint),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _cpfController,
                  hintText: "000.000.000-00",
                  icon: FontAwesomeIcons.barcode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CpfInputFormatter(),
                  ],
                  validator: _validateCpf,
                ),
                const SizedBox(height: 20),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('DATA NASC.', FontAwesomeIcons.calendarDay),
                          const SizedBox(height: 8),
                          _buildTextFormField(
                            controller: _birthDateController,
                            hintText: "DD/MM/AAAA",
                            icon: FontAwesomeIcons.cakeCandles,
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
                            hintText: "(11) 99999-9999",
                            icon: FontAwesomeIcons.mobileScreen,
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
                
                const SizedBox(height: 32),
                _buildSectionTitle('SEGURANÇA'),
                const SizedBox(height: 16),

                _buildFieldLabel('CRIAR SENHA (6 DÍGITOS)', FontAwesomeIcons.key),
                const SizedBox(height: 12),
                Center(
                  child: Pinput(
                    controller: _passwordController,
                    length: 6,
                    obscureText: true,
                    obscuringWidget: const FaIcon(FontAwesomeIcons.asterisk, size: 14, color: primaryAmber),
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: primaryAmber, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: primaryAmber.withOpacity(0.2), blurRadius: 8),
                        ],
                      ),
                    ),
                    validator: (s) => s!.length == 6 ? null : 'Mín. 6 dígitos',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildFieldLabel('CONFIRMAR SENHA', FontAwesomeIcons.lock),
                const SizedBox(height: 12),
                Center(
                  child: Pinput(
                    controller: _confirmPasswordController,
                    length: 6,
                    obscureText: true,
                    obscuringWidget: const FaIcon(FontAwesomeIcons.asterisk, size: 14, color: primaryAmber),
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: primaryAmber, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: primaryAmber.withOpacity(0.2), blurRadius: 8),
                        ],
                      ),
                    ),
                    validator: (s) {
                      if (s != _passwordController.text) return 'Senhas não coincidem';
                      return s!.length == 6 ? null : 'Mín. 6 dígitos';
                    },
                    keyboardType: TextInputType.number,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: primaryAmber.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      foregroundColor: Colors.black,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "FINALIZAR CADASTRO",
                                style: GoogleFonts.orbitron(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const FaIcon(FontAwesomeIcons.check, size: 16),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Já é um explorador? ",
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop(); // Volta para o login
                            },
                      child: Text(
                        "Fazer Login",
                        style: GoogleFonts.inter(
                          color: primaryAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryAmber.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFieldLabel(String label, FaIconData icon) {
    return Row(
      children: [
        FaIcon(icon, size: 12, color: primaryAmber),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: primaryAmber,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required FaIconData icon,
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
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: Colors.white.withOpacity(0.2),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: FaIcon(icon, color: Colors.white54, size: 14),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAmber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerColor, width: 1.5),
        ),
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