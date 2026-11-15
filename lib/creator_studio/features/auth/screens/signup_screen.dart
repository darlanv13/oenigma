import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/creator_studio/features/auth/providers/auth_provider.dart';

class CreatorSignupScreen extends ConsumerStatefulWidget {
  const CreatorSignupScreen({super.key});

  @override
  ConsumerState<CreatorSignupScreen> createState() => _CreatorSignupScreenState();
}

class _CreatorSignupScreenState extends ConsumerState<CreatorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authRepo = ref.read(creatorAuthRepositoryProvider);
      final error = await authRepo.signUpCreatorWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        cpf: _cpfController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        if (error != null) {
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta de Criador criada com sucesso! Faça login.'),
              backgroundColor: AppColors.verdeVale,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Cadastro de Criador'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.darkCardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_errorMessage != null) ...[
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                      validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cpfController,
                      decoration: const InputDecoration(labelText: 'CPF ou CNPJ', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'WhatsApp / Telefone', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha de Acesso', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.verdeVale),
                        onPressed: _isLoading ? null : _handleSignup,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Cadastrar e Começar a Criar'),
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
