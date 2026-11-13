import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/core/services/sound_service.dart';
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
          SoundService.playError();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error, style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          SoundService.playSuccess();
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
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    List<int> digits = cpf.split('').map(int.parse).toList();

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += digits[i] * (10 - i);
    }
    int firstVerifier = (sum * 10) % 11;
    if (firstVerifier == 10) firstVerifier = 0;
    if (firstVerifier != digits[9]) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += digits[i] * (11 - i);
    }
    int secondVerifier = (sum * 10) % 11;
    if (secondVerifier == 10) secondVerifier = 0;
    if (secondVerifier != digits[10]) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1115),
      body: Stack(
        children: [
          // Luzes ambientais suaves (Padrão Enigma)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.verdeVale.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amareloVale.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar customizada
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Navigator.canPop(context)
                          ? GestureDetector(
                              onTap: () {
                                SoundService.playClick();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131D24),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Center(
                                  child: FaIcon(FontAwesomeIcons.chevronLeft, color: Colors.white, size: 13),
                                ),
                              ),
                            )
                          : const SizedBox(width: 38),
                      Text(
                        'CRIAR CONTA',
                        style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildSignUpForm(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF131D24),
            border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
          ),
          child: const FaIcon(FontAwesomeIcons.userPlus, color: AppColors.verdeVale, size: 28),
        ),
        const SizedBox(height: 14),
        Text(
          'NOVO EXPLORADOR',
          style: GoogleFonts.cinzel(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PREPARE-SE PARA A CAÇADA',
          style: GoogleFonts.cinzel(
            fontSize: 10,
            letterSpacing: 2,
            color: AppColors.amareloVale,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    final defaultPinTheme = PinTheme(
      width: 46,
      height: 54,
      textStyle: GoogleFonts.orbitron(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C171F),
        border: Border.all(color: const Color(0xFF1E3A45)),
        borderRadius: BorderRadius.circular(14),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('DADOS PESSOAIS'),
            const SizedBox(height: 14),
            _buildFieldLabel('NOME COMPLETO', FontAwesomeIcons.solidUser),
            const SizedBox(height: 6),
            _buildTextFormField(
              controller: _fullNameController,
              hintText: "Seu nome",
              icon: FontAwesomeIcons.idCard,
              textCapitalization: TextCapitalization.words,
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 18),
            
            _buildFieldLabel('CPF', FontAwesomeIcons.fingerprint),
            const SizedBox(height: 6),
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
            const SizedBox(height: 18),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('DATA NASC.', FontAwesomeIcons.calendarDay),
                      const SizedBox(height: 6),
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('TELEFONE', FontAwesomeIcons.phone),
                      const SizedBox(height: 6),
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
            
            const SizedBox(height: 28),
            _buildSectionTitle('SEGURANÇA'),
            const SizedBox(height: 14),

            _buildFieldLabel('CRIAR SENHA (6 DÍGITOS)', FontAwesomeIcons.key),
            const SizedBox(height: 8),
            Center(
              child: Pinput(
                controller: _passwordController,
                length: 6,
                obscureText: true,
                obscuringWidget: const FaIcon(FontAwesomeIcons.asterisk, size: 12, color: AppColors.amareloVale),
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.verdeVale, width: 1.5),
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(color: AppColors.verdeVale.withValues(alpha: 0.25), blurRadius: 8),
                    ],
                  ),
                ),
                validator: (s) => s!.length == 6 ? null : 'Mín. 6 dígitos',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildFieldLabel('CONFIRMAR SENHA', FontAwesomeIcons.lock),
            const SizedBox(height: 8),
            Center(
              child: Pinput(
                controller: _confirmPasswordController,
                length: 6,
                obscureText: true,
                obscuringWidget: const FaIcon(FontAwesomeIcons.asterisk, size: 12, color: AppColors.amareloVale),
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.verdeVale, width: 1.5),
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(color: AppColors.verdeVale.withValues(alpha: 0.25), blurRadius: 8),
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
            
            const SizedBox(height: 32),
            
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: AppColors.gradienteVerdeVale,
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.verdeVale.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "FINALIZAR CADASTRO",
                            style: GoogleFonts.cinzel(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const FaIcon(FontAwesomeIcons.check, size: 14),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Já tem uma conta? ",
                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
                ),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          SoundService.playClick();
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    "Fazer Login",
                    style: GoogleFonts.inter(
                      color: AppColors.verdeVale,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.cinzaMedio,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 1,
          width: double.infinity,
          color: const Color(0xFF1E3A45),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, FaIconData icon) {
    return Row(
      children: [
        FaIcon(icon, size: 12, color: AppColors.verdeVale),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.cinzel(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
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
        fillColor: const Color(0xFF0C171F),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: AppColors.cinzaMedio,
          fontSize: 13,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: FaIcon(icon, color: AppColors.cinzaMedio, size: 14),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.verdeVale, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
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
