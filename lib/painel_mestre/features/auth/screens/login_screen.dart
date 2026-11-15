import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/painel_mestre/features/auth/providers/auth_provider.dart';
import 'package:oenigma/painel_mestre/features/auth/screens/forgot_password_screen.dart';
import 'package:oenigma/painel_mestre/features/master/screens/main_master_screen.dart';

class MasterLoginScreen extends ConsumerStatefulWidget {
  final String? initialErrorMessage;

  const MasterLoginScreen({super.key, this.initialErrorMessage});

  @override
  ConsumerState<MasterLoginScreen> createState() => _MasterLoginScreenState();
}

class _MasterLoginScreenState extends ConsumerState<MasterLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialErrorMessage;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authRepo = ref.read(masterAuthRepositoryProvider);
      final error = await authRepo.signInMasterWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        if (error != null) {
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainMasterScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.darkCardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.2)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OEnigmaAdminLogo(size: LogoSize.hero, isVertical: true),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amareloVale.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.crown, size: 10, color: AppColors.amareloVale),
                          SizedBox(width: 6),
                          Text(
                            'PAINEL MESTRE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.amareloVale,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.danger),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'E-mail do Administrador Mestre',
                        prefixIcon: FaIcon(FontAwesomeIcons.userTie, size: 14),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          (val == null || !val.contains('@')) ? 'Informe um e-mail válido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Senha de Acesso',
                        prefixIcon: const FaIcon(FontAwesomeIcons.lock, size: 14),
                        suffixIcon: IconButton(
                          icon: FaIcon(
                            _isPasswordVisible ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                            size: 14,
                          ),
                          onPressed: () =>
                              setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          (val == null || val.length < 6) ? 'Mínimo de 6 caracteres' : null,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MasterForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(color: AppColors.amareloVale, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amareloVale,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                                'Acessar Governança Master',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
