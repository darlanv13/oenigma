import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/oenigma_admin_logo.dart';
import 'package:oenigma/painel_admin_web/features/auth/providers/auth_provider.dart';
import 'package:oenigma/painel_admin_web/features/auth/screens/signup_screen.dart';
import 'package:oenigma/painel_admin_web/features/auth/screens/forgot_password_screen.dart';
import 'package:oenigma/painel_admin_web/features/admin/screens/main_admin_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberEmail = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_admin_email');
      final remember = prefs.getBool('remember_admin_email') ?? true;
      if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberEmail = remember;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar e-mail salvo: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _errorMessage = null);

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Persistência da preferência "Lembrar meu e-mail"
      try {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberEmail) {
          await prefs.setString('saved_admin_email', _emailController.text.trim());
          await prefs.setBool('remember_admin_email', true);
        } else {
          await prefs.remove('saved_admin_email');
          await prefs.setBool('remember_admin_email', false);
        }
      } catch (e) {
        debugPrint('Erro ao salvar preferência de e-mail: $e');
      }

      final authRepository = ref.read(authRepositoryProvider);
      final error = await authRepository.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        if (error != null) {
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          final user = authRepository.currentUser;
          final isAdmin = user?.get<bool>('isAdmin') ?? false;
          final role = user?.get<String>('role') ?? 'player';

          if (!isAdmin && role != 'admin') {
            setState(() {
              _errorMessage = 'Acesso Restrito: Apenas administradores autorizados.';
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.gpp_bad_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Acesso Restrito: Esta conta não possui privilégios de administrador.'),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFD32F2F),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            await authRepository.signOut();
            return;
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainAdminScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Background com atmosfera tática & luz ambiente
          _buildAmbientBackground(),

          // Conteúdo Responsivo Desktop / Tablet / Mobile
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 960;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : 20.0,
                      vertical: 24.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 1160 : 480,
                      ),
                      child: isDesktop
                          ? _buildDesktopLayout()
                          : _buildMobileLayout(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Luz ambiente e gradiente do tema dark
  Widget _buildAmbientBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF091012),
              Color(0xFF0D1416),
              Color(0xFF070B0C),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Brilho verde sutil no canto superior esquerdo
            Positioned(
              top: -120,
              left: -120,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.verdeVale.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Brilho dourado suave no canto inferior direito
            Positioned(
              bottom: -150,
              right: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.amareloVale.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Layout em Split-Screen para Desktop / Wide Screens
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Lado Esquerdo: Vitrine da Plataforma & Nova Logo Hero
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.only(right: 48.0),
            child: _buildBrandingShowcase(),
          ),
        ),

        // Lado Direito: Card de Autenticação Tático
        Expanded(
          flex: 5,
          child: Center(
            child: _buildLoginCard(isDesktop: true),
          ),
        ),
      ],
    );
  }

  /// Layout em Coluna Centralizada para Mobile / Telas Pequenas
  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        const OEnigmaAdminLogo(
          size: LogoSize.large,
          isVertical: true,
          showBadge: false,
        ),
        const SizedBox(height: 32),
        _buildLoginCard(isDesktop: false),
        const SizedBox(height: 24),
        _buildFooterCredits(),
      ],
    );
  }

  /// Vitrine de Funcionalidades e Apresentação da Plataforma (Lado Esquerdo Desktop)
  Widget _buildBrandingShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const OEnigmaAdminLogo(
          size: LogoSize.hero,
          isVertical: false,
          showBadge: true,
        ),
        const SizedBox(height: 36),
        Text(
          'Central Integrada de Comando & Gestão Tática',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Ambiente exclusivo para administradores controlarem a hierarquia completa '
          'de eventos, fases sequenciais, enigmas de campo e transações econômicas.',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14.5,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 36),

        // 3 Cards de Recursos
        _buildFeatureItem(
          icon: FontAwesomeIcons.layerGroup,
          title: 'Gestão Centralizada de Eventos',
          description:
              'Controle unificado de Classic e FindWin. Crie eventos, fases e enigmas em uma única tela fluida.',
        ),
        const SizedBox(height: 18),
        _buildFeatureItem(
          icon: FontAwesomeIcons.shieldHalved,
          title: 'Segurança & Validação Anti-Fraude',
          description:
              'Validação instantânea por código e QR Code físico com controle tático de cooldown.',
        ),
        const SizedBox(height: 18),
        _buildFeatureItem(
          icon: FontAwesomeIcons.chartLine,
          title: 'Economia & Operações em Tempo Real',
          description:
              'Acompanhe gateways, arrecadações, saques e depósitos de forma transparente e segura.',
        ),

        const SizedBox(height: 36),
        // Badge de Status do Terminal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF142023),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.verdeVale.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E599),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00E599),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'TERMINAL ATIVO • CONEXÃO CRIPTOGRAFADA SSL • V2.0',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required dynamic icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.verdeVale.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.verdeVale.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: FaIcon(
            icon,
            color: AppColors.amareloVale,
            size: 18,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Card de Autenticação Elegante e de Fácil Acesso
  Widget _buildLoginCard({required bool isDesktop}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: EdgeInsets.all(isDesktop ? 36.0 : 24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF142023),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.verdeVale.withValues(alpha: 0.08),
            blurRadius: 36,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header do Card
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amareloVale.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.amareloVale.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'PORTAL DE ACESSO',
                    style: GoogleFonts.poppins(
                      color: AppColors.amareloVale,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Acesse sua Conta',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Insira seu e-mail e senha cadastrados para entrar na central administrativa.',
              style: GoogleFonts.inter(
                color: AppColors.cinzaMedio,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              _buildErrorBanner(_errorMessage!),
            ],

            const SizedBox(height: 24),

            // Campo: E-mail
            _buildFieldLabel('E-MAIL DE ACESSO'),
            const SizedBox(height: 6),
            _buildTextFormField(
              controller: _emailController,
              hintText: "admin@oenigma.com.br",
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
              prefixIcon: Container(
                alignment: Alignment.center,
                width: 46,
                child: const FaIcon(
                  FontAwesomeIcons.envelope,
                  color: AppColors.amareloVale,
                  size: 16,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Informe seu e-mail institucional';
                }
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Insira um e-mail válido';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // Campo: Senha
            _buildFieldLabel('SENHA MESTRE'),
            const SizedBox(height: 6),
            _buildTextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              hintText: "••••••••••••",
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              prefixIcon: Container(
                alignment: Alignment.center,
                width: 46,
                child: const FaIcon(
                  FontAwesomeIcons.lock,
                  color: AppColors.amareloVale,
                  size: 16,
                ),
              ),
              suffixIcon: IconButton(
                icon: FaIcon(
                  _isPasswordVisible
                      ? FontAwesomeIcons.solidEyeSlash
                      : FontAwesomeIcons.solidEye,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 16,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Informe sua senha de acesso';
                }
                if (val.length < 6) {
                  return 'A senha deve conter no mínimo 6 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Linha: Lembrar meu e-mail + Esqueceu a senha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    setState(() => _rememberEmail = !_rememberEmail);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _rememberEmail,
                            activeColor: AppColors.verdeVale,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() => _rememberEmail = val ?? true);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lembrar e-mail',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Esqueceu a senha?',
                    style: GoogleFonts.inter(
                      color: AppColors.amareloVale,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Botão Principal de Login com Enter / Click
            _buildSubmitButton(),

            const SizedBox(height: 22),

            // Rodapé do Card: Solicitar Acesso
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Novo administrador? ',
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Solicitar Acesso',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.amareloVale,
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

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3B1214),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE53935).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF5252),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: const Color(0xFFFFCDD2),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF007D8A),
            Color(0xFF009AA8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.verdeVale.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading ? null : _handleLogin,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ACESSAR O PAINEL',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const FaIcon(
                        FontAwesomeIcons.arrowRight,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required Widget prefixIcon,
    FocusNode? focusNode,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0A0F11),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 13.5,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.verdeVale,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE53935),
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE53935),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterCredits() {
    return Text(
      'O Enigma • Sistema Tático de Operações © 2026',
      style: GoogleFonts.inter(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    );
  }
}
