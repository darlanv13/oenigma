import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/painel_admin_web/features/auth/providers/auth_provider.dart';

/// Tela de Autenticação Rápida & Segura do Criador / Influenciador (Creator Studio)
class CreatorAuthScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAuthenticated;
  final bool initialShowSignUp;

  const CreatorAuthScreen({
    super.key,
    this.onAuthenticated,
    this.initialShowSignUp = false,
  });

  @override
  ConsumerState<CreatorAuthScreen> createState() => _CreatorAuthScreenState();
}

class _CreatorAuthScreenState extends ConsumerState<CreatorAuthScreen> {
  late bool _isSignUp;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Login Controllers
  final _loginIdController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginPasswordVisible = false;
  bool _rememberLogin = true;

  // Sign-Up Controllers
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialShowSignUp;
    _loadSavedLogin();
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _loginPasswordController.dispose();
    _nameController.dispose();
    _handleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('saved_creator_identifier');
      final remember = prefs.getBool('remember_creator_login') ?? true;
      if (savedId != null && savedId.isNotEmpty && mounted) {
        setState(() {
          _loginIdController.text = savedId;
          _rememberLogin = remember;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveLoginPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberLogin) {
        await prefs.setString('saved_creator_identifier', _loginIdController.text.trim());
        await prefs.setBool('remember_creator_login', true);
      } else {
        await prefs.remove('saved_creator_identifier');
        await prefs.setBool('remember_creator_login', false);
      }
    } catch (_) {}
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await _saveLoginPreference();

    final authRepo = ref.read(authRepositoryProvider);
    final error = await authRepo.signInCreator(
      identifier: _loginIdController.text.trim(),
      password: _loginPasswordController.text.trim(),
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!();
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_signUpFormKey.currentState!.validate()) return;

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() => _errorMessage = 'As senhas informadas não coincidem.');
      return;
    }

    setState(() => _isLoading = true);

    final authRepo = ref.read(authRepositoryProvider);
    final error = await authRepo.signUpCreatorWithEmailAndPassword(
      name: _nameController.text.trim(),
      handle: _handleController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _successMessage = 'Conta de criador criada com sucesso!';
      });
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!();
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _loginIdController.text.trim());
    bool isResetting = false;
    String? resetError;
    String? resetSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.darkCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.darkCardBorder),
            ),
            title: Row(
              children: [
                const FaIcon(FontAwesomeIcons.key, color: AppColors.amareloVale, size: 16),
                const SizedBox(width: 10),
                Text(
                  'Recuperar Senha',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digite seu e-mail cadastrado. Enviaremos um link seguro para você redefinir sua senha.',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.amareloVale, size: 18),
                    labelText: 'E-mail do Criador',
                    labelStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F1418),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.darkCardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.amareloVale),
                    ),
                  ),
                ),
                if (resetError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    resetError!,
                    style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11.5),
                  ),
                ],
                if (resetSuccess != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    resetSuccess!,
                    style: GoogleFonts.poppins(color: AppColors.verdeVale, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Fechar', style: GoogleFonts.poppins(color: AppColors.cinzaMedio)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amareloVale,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isResetting
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          setDialogState(() => resetError = 'Digite um e-mail válido.');
                          return;
                        }
                        setDialogState(() {
                          isResetting = true;
                          resetError = null;
                          resetSuccess = null;
                        });

                        final err = await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
                        setDialogState(() {
                          isResetting = false;
                          if (err != null) {
                            resetError = err;
                          } else {
                            resetSuccess = 'Link de recuperação enviado! Verifique sua caixa de entrada.';
                          }
                        });
                      },
                child: isResetting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        'Enviar Link',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 18 : 28,
              vertical: isMobile ? 18 : 36,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão Voltar ao Hub Central
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(context, '/portal');
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.arrowLeft, color: AppColors.cinzaMedio, size: 12),
                            const SizedBox(width: 8),
                            Text(
                              'Portal O Enigma',
                              style: GoogleFonts.poppins(
                                color: AppColors.cinzaMedio,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Header com Logo e Tag STUDIO
                  _buildHeader(),

                  const SizedBox(height: 22),

                  // Card de Autenticação
                  Container(
                    padding: EdgeInsets.all(isMobile ? 18 : 26),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.amareloVale.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amareloVale.withValues(alpha: 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Toggle Suave: Login vs Cadastro Rápido
                        _buildTabToggle(),

                        const SizedBox(height: 20),

                        // Mensagem de Erro
                        if (_errorMessage != null) ...[
                          _buildFeedbackBanner(
                            icon: Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            text: _errorMessage!,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Mensagem de Sucesso
                        if (_successMessage != null) ...[
                          _buildFeedbackBanner(
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.verdeVale,
                            text: _successMessage!,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Formulário Selecionado
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _isSignUp ? _buildSignUpForm() : _buildLoginForm(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Selo de Segurança e Criptografia
                  _buildSecurityFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OEnigmaAdminLogo(size: LogoSize.compact, showBadge: false),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amareloVale.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
              ),
              child: Text(
                'STUDIO',
                style: GoogleFonts.poppins(
                  color: AppColors.amareloVale,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _isSignUp ? 'Criar Conta de Criador' : 'Entrar no Creator Studio',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isSignUp
              ? 'Lançamento rápido em 1 minuto. Crie enigmas e monetize sua audiência.'
              : 'Gerencie seus desafios, acompanhe vendas e solicite saques Pix.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.cinzaMedio,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1418),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (_isSignUp) {
                  setState(() {
                    _isSignUp = false;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                }
              },
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !_isSignUp ? AppColors.amareloVale : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.bolt,
                      size: 12,
                      color: !_isSignUp ? Colors.black : AppColors.cinzaMedio,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Login Rápido',
                      style: GoogleFonts.poppins(
                        color: !_isSignUp ? Colors.black : AppColors.cinzaMedio,
                        fontWeight: !_isSignUp ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                if (!_isSignUp) {
                  setState(() {
                    _isSignUp = true;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                }
              },
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _isSignUp ? AppColors.amareloVale : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.rocket,
                      size: 12,
                      color: _isSignUp ? Colors.black : AppColors.cinzaMedio,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Criar Conta',
                      style: GoogleFonts.poppins(
                        color: _isSignUp ? Colors.black : AppColors.cinzaMedio,
                        fontWeight: _isSignUp ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === FORMULÁRIO DE LOGIN RÁPIDO ===
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo E-mail ou @canal
          _buildTextField(
            controller: _loginIdController,
            label: 'E-mail ou @canal',
            hint: 'seuemail@exemplo.com ou @seucanal',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Informe seu e-mail ou @canal.';
              }
              return null;
            },
          ),

          const SizedBox(height: 14),

          // Campo Senha
          _buildTextField(
            controller: _loginPasswordController,
            label: 'Senha de Acesso',
            hint: 'Sua senha secreta',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !_loginPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _loginPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.cinzaMedio,
                size: 18,
              ),
              onPressed: () => setState(() => _loginPasswordVisible = !_loginPasswordVisible),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Informe sua senha.';
              }
              return null;
            },
          ),

          const SizedBox(height: 10),

          // Lembrar & Esqueci minha senha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() => _rememberLogin = !_rememberLogin),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _rememberLogin,
                          activeColor: AppColors.amareloVale,
                          checkColor: Colors.black,
                          side: const BorderSide(color: AppColors.cinzaMedio),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _rememberLogin = val ?? true),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lembrar login',
                        style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                child: Text(
                  'Esqueci a senha',
                  style: GoogleFonts.poppins(
                    color: AppColors.amareloVale,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Botão Entrar
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amareloVale,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: AppColors.amareloVale.withValues(alpha: 0.4),
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.bolt, size: 14, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        'Entrar no Creator Studio',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // Alternar para Cadastro
          Center(
            child: InkWell(
              onTap: () => setState(() => _isSignUp = true),
              child: RichText(
                text: TextSpan(
                  text: 'Ainda não é um criador? ',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Cadastre-se grátis',
                      style: GoogleFonts.poppins(
                        color: AppColors.amareloVale,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === FORMULÁRIO DE CADASTRO RÁPIDO ===
  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nome / Canal
          _buildTextField(
            controller: _nameController,
            label: 'Nome ou Nome do Canal',
            hint: 'ex: Juca Games ou Lucas Silva',
            prefixIcon: Icons.badge_outlined,
            validator: (v) {
              if (v == null || v.trim().length < 3) {
                return 'Digite um nome válido (mínimo 3 letras).';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // @ do Canal / Rede Social
          _buildTextField(
            controller: _handleController,
            label: '@ do Canal (Instagram, TikTok, YouTube)',
            hint: '@seucanal',
            prefixIcon: Icons.alternate_email_rounded,
            validator: (v) {
              if (v == null || v.trim().length < 2) {
                return 'Informe o @ do seu canal ou perfil.';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // E-mail
          _buildTextField(
            controller: _emailController,
            label: 'E-mail Profissional',
            hint: 'seuemail@exemplo.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || !v.contains('@') || !v.contains('.')) {
                return 'Digite um e-mail válido.';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // WhatsApp (Opcional)
          _buildTextField(
            controller: _phoneController,
            label: 'WhatsApp para Notificações Pix (Opcional)',
            hint: '(11) 98765-4321',
            prefixIcon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 12),

          // Senha
          _buildTextField(
            controller: _passwordController,
            label: 'Senha de Acesso (Mínimo 6 dígitos)',
            hint: 'Crie uma senha segura',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !_passwordVisible,
            onChanged: (val) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.cinzaMedio,
                size: 18,
              ),
              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 6) {
                return 'A senha deve conter no mínimo 6 caracteres.';
              }
              return null;
            },
          ),

          // Indicador de força de senha
          _buildPasswordStrengthBar(_passwordController.text),

          const SizedBox(height: 12),

          // Confirmar Senha
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirmar Senha',
            hint: 'Repita a senha criada',
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: !_confirmPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.cinzaMedio,
                size: 18,
              ),
              onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
            ),
            validator: (v) {
              if (v != _passwordController.text) {
                return 'As senhas não coincidem.';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // Botão Criar Conta
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: AppColors.verdeVale.withValues(alpha: 0.4),
            ),
            onPressed: _isLoading ? null : _handleSignUp,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.rocket, size: 14, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Criar Minha Conta de Criador',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 14),

          // Alternar para Login
          Center(
            child: InkWell(
              onTap: () => setState(() => _isSignUp = false),
              child: RichText(
                text: TextSpan(
                  text: 'Já possui cadastro? ',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Entrar no Studio',
                      style: GoogleFonts.poppins(
                        color: AppColors.amareloVale,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, color: AppColors.amareloVale, size: 17),
        suffixIcon: suffixIcon,
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio.withValues(alpha: 0.5), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0F1418),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.amareloVale, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar(String password) {
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[0-9]').hasMatch(password) && RegExp(r'[a-zA-Z]').hasMatch(password)) strength++;

    Color barColor = Colors.redAccent;
    String label = 'Curta';
    if (strength == 2) {
      barColor = Colors.orangeAccent;
      label = 'Razoável';
    } else if (strength >= 3) {
      barColor = AppColors.verdeVale;
      label = 'Segura';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4, left: 4),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (strength / 3).clamp(0.1, 1.0),
                backgroundColor: Colors.white10,
                color: barColor,
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(color: barColor, fontSize: 10.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 11.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.cinzaMedio, size: 14),
            const SizedBox(width: 6),
            Text(
              'Criptografia de ponta a ponta • Sessão Segura',
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Suas chaves Pix e receitas ficam protegidas pela infraestrutura Back4App.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: AppColors.cinzaMedio.withValues(alpha: 0.7), fontSize: 10),
        ),
      ],
    );
  }
}
