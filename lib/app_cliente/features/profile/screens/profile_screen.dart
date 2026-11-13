import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? playerData;
  final UserWalletModel? walletData;

  const ProfileScreen({
    super.key,
    this.playerData,
    this.walletData,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  String _formatMaskedCpf(String? cpf) {
    if (cpf == null || cpf.trim().isEmpty) return 'Não cadastrado';
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
    }
    return cpf;
  }

  String _formatPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return 'Não informado';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return phone;
  }

  Future<void> _updateProfilePhoto(ParseUser user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (pickedFile != null) {
      setState(() => _isUploadingPhoto = true);
      SoundService.playClick();
      try {
        final bytes = await pickedFile.readAsBytes();
        ParseFileBase parseFile;

        if (kIsWeb) {
          parseFile = ParseWebFile(bytes, name: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
        } else {
          parseFile = ParseFile(File(pickedFile.path));
        }

        final response = await parseFile.save();

        if (response.success && parseFile.url != null) {
          user.set('photoURL', parseFile.url);
          await user.save();
          SoundService.playSuccess();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.circleCheck, color: Colors.white, size: 16),
                    SizedBox(width: 10),
                    Text('Foto de perfil atualizada com sucesso!'),
                  ],
                ),
                backgroundColor: AppColors.verdeVale,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          }
        } else {
          throw Exception(response.error?.message ?? 'Falha ao salvar imagem no servidor');
        }
      } catch (e) {
        SoundService.playError();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar foto: $e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploadingPhoto = false);
        }
      }
    }
  }

  void _showEditProfileModal(ParseUser user) {
    SoundService.playOpen();
    final nameController = TextEditingController(text: user.get<String>('name') ?? '');
    final phoneController = TextEditingController(text: user.get<String>('phone') ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF101B22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(color: Color(0xFF1E3A45), width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Puxador central
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Cabeçalho do modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.verdeVale.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const FaIcon(FontAwesomeIcons.userPen, color: AppColors.verdeVale, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'EDITAR PERFIL',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (!isSaving)
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.cinzaMedio, size: 22),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Campo: Nome Completo
                  Text(
                    'NOME COMPLETO',
                    style: GoogleFonts.inter(
                      color: AppColors.cinzaMedio,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: nameController,
                    hint: 'Seu nome completo',
                    icon: FontAwesomeIcons.user,
                    enabled: !isSaving,
                  ),
                  const SizedBox(height: 16),

                  // Campo: Telefone
                  Text(
                    'TELEFONE / WHATSAPP',
                    style: GoogleFonts.inter(
                      color: AppColors.cinzaMedio,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField(
                    controller: phoneController,
                    hint: '(00) 00000-0000',
                    icon: FontAwesomeIcons.phone,
                    enabled: !isSaving,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // Botão: Salvar Dados
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: AppColors.gradienteVerdeVale,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.verdeVale.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              SoundService.playClick();

                              user.set('name', nameController.text.trim());
                              user.set('phone', phoneController.text.trim());

                              final response = await user.save();
                              setModalState(() => isSaving = false);

                              if (response.success) {
                                SoundService.playSuccess();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.circleCheck, color: Colors.white, size: 16),
                                          SizedBox(width: 10),
                                          Text('Perfil atualizado com sucesso!'),
                                        ],
                                      ),
                                      backgroundColor: AppColors.verdeVale,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  );
                                  setState(() {});
                                }
                              } else {
                                SoundService.playError();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro: ${response.error?.message}'),
                                      backgroundColor: AppColors.danger,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : Text(
                              'SALVAR ALTERAÇÕES',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required FaIconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(13.0),
          child: FaIcon(icon, color: AppColors.verdeVale, size: 15),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.verdeVale, width: 1.5),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    SoundService.playClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131D24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF1E3A45), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.arrowRightFromBracket,
                color: AppColors.danger,
                size: 15,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sair da Conta',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Deseja realmente desconectar? Suas conquistas, saldos e progresso em enigmas ficam salvos com segurança na sua conta.',
          style: GoogleFonts.inter(
            color: const Color(0xFF91A3AE),
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              SoundService.playClick();
              await ref.read(authRepositoryProvider).signOut();
            },
            child: Text(
              'CONFIRMAR SAÍDA',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar elegante e integrada
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF131D24),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
                            ),
                            child: const Center(
                              child: FaIcon(FontAwesomeIcons.chevronLeft, color: Colors.white, size: 14),
                            ),
                          ),
                        )
                      : const SizedBox(width: 42),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(FontAwesomeIcons.idBadge, color: AppColors.verdeVale, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'PERFIL DO CAÇADOR',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),

            Expanded(
              child: authState.when(
                data: (user) {
                  if (user == null) {
                    return Center(
                      child: Text(
                        'Sessão expirada. Faça login novamente.',
                        style: GoogleFonts.inter(color: AppColors.cinzaMedio),
                      ),
                    );
                  }

                  final name = user.get<String>('name') ?? (user.get<String>('username') ?? 'Explorador');
                  final email = user.get<String>('email') ?? 'Não cadastrado';
                  final phone = user.get<String>('phone') ?? '';
                  final cpf = user.get<String>('cpf') ?? '';
                  final xp = user.get<num>('xp')?.toInt() ?? 0;
                  final league = (user.get<String>('league') ?? 'Bronze').toUpperCase();
                  final photoUrl = user.get<String>('photoURL');

                  final double balance = (user.get<num>('balance'))?.toDouble() ??
                      (widget.walletData?.balance ?? 0.0);

                  final int eventosJogados = user.get<Map<String, dynamic>>('events')?.keys.length ??
                      (widget.playerData?['events'] is Map ? (widget.playerData!['events'] as Map).keys.length : 0);

                  final int eventosVencidos = user.get<List<dynamic>>('winnerEvents')?.length ??
                      (widget.playerData?['winnerEvents'] is List ? (widget.playerData!['winnerEvents'] as List).length : 0);

                  return RefreshIndicator(
                    color: AppColors.verdeVale,
                    backgroundColor: const Color(0xFF131D24),
                    onRefresh: () async {
                      await user.fetch();
                      if (mounted) setState(() {});
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                      child: Column(
                        children: [
                          // 1. Hero Card do Caçador com Foto, Nível e Barra de XP
                          _buildHunterHeroCard(user, name, league, xp, photoUrl),
                          const SizedBox(height: 18),

                          // 2. HUD Grid de Estatísticas (Saldo, Caçadas, Vitórias, Patente)
                          _buildHunterMetricsGrid(balance, eventosJogados, eventosVencidos, xp),
                          const SizedBox(height: 18),

                          // 3. Card de Dados Cadastrais & Segurança (Zero Trust)
                          _buildAccountSecurityCard(cpf, email, phone),
                          const SizedBox(height: 18),

                          // 4. Configurações de Imersão e Áudio
                          _buildAudioSettingsCard(),
                          const SizedBox(height: 22),

                          // 5. Botões de Ação
                          _buildActionButtons(context, ref, user),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.verdeVale),
                ),
                error: (err, stack) => Center(
                  child: Text('Erro: $err', style: const TextStyle(color: AppColors.danger)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 1. HERO CARD DO CAÇADOR (Crachá do Aventureiro com Anel de Nível & XP)
  // =========================================================================
  Widget _buildHunterHeroCard(
    ParseUser user,
    String name,
    String league,
    int xp,
    String? photoUrl,
  ) {
    final int level = (xp / 500).floor() + 1;
    final int currentLevelProgressXp = xp % 500;
    final double levelProgressFraction = (currentLevelProgressXp / 500.0).clamp(0.05, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Efeito de iluminação sutil no canto superior
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.verdeVale.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              children: [
                // Avatar com Anel Metálico + Botão de Câmera Sobreposto
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Anel gradiente esmeralda / ouro
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.amareloVale, AppColors.verdeVale],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.verdeVale.withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3.5),
                          child: ClipOval(
                            child: Container(
                              color: const Color(0xFF0C171F),
                              child: _isUploadingPhoto
                                  ? const Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          color: AppColors.verdeVale,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                  : (photoUrl != null && photoUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: photoUrl,
                                          fit: BoxFit.cover,
                                          width: 96,
                                          height: 96,
                                          placeholder: (context, url) => const Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(color: AppColors.verdeVale, strokeWidth: 2),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => const Center(
                                            child: FaIcon(FontAwesomeIcons.solidUser, size: 38, color: AppColors.verdeVale),
                                          ),
                                        )
                                      : const Center(
                                          child: FaIcon(FontAwesomeIcons.solidUser, size: 40, color: AppColors.verdeVale),
                                        )),
                            ),
                          ),
                        ),
                      ),

                      // Botão Flutuante de Câmera para troca imediata de foto
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingPhoto ? null : () => _updateProfilePhoto(user),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.amareloVale,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF131D24), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: FaIcon(FontAwesomeIcons.camera, color: Color(0xFF131D24), size: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Nome do Caçador
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Badge da Liga & Patente
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C242C),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00A4B4).withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.crown, color: Color(0xFF00A4B4), size: 11),
                          const SizedBox(width: 6),
                          Text(
                            'LIGA $league',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF00A4B4),
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF261D0C),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.amareloVale.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.bolt, color: AppColors.amareloVale, size: 11),
                          const SizedBox(width: 6),
                          Text(
                            'NÍVEL $level',
                            style: GoogleFonts.poppins(
                              color: AppColors.amareloVale,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Barra de Progresso de XP
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PROGRESSO DO NÍVEL',
                          style: GoogleFonts.inter(
                            color: AppColors.cinzaMedio,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '$currentLevelProgressXp / 500 XP',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFCFD8DC),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C171F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF1E3A45),
                          width: 1,
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: levelProgressFraction,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00A4B4), AppColors.amareloVale],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00A4B4).withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. GRID DE ESTATÍSTICAS (HUD DE EXPLORADOR)
  // =========================================================================
  Widget _buildHunterMetricsGrid(double balance, int jogados, int vencidos, int xp) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'SALDO ATUAL',
                value: 'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
                icon: FontAwesomeIcons.coins,
                accentColor: const Color(0xFFF3A522),
                bgTint: const Color(0xFFF3A522).withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'EXPEDIÇÕES',
                value: jogados.toString(),
                icon: FontAwesomeIcons.mapLocationDot,
                accentColor: const Color(0xFF00A4B4),
                bgTint: const Color(0xFF00A4B4).withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'VITÓRIAS',
                value: vencidos.toString(),
                icon: FontAwesomeIcons.trophy,
                accentColor: const Color(0xFFFFB300),
                bgTint: const Color(0xFFFFB300).withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'EXPERIÊNCIA',
                value: '$xp XP',
                icon: FontAwesomeIcons.medal,
                accentColor: const Color(0xFF4CAF50),
                bgTint: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required FaIconData icon,
    required Color accentColor,
    required Color bgTint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7.5),
                decoration: BoxDecoration(
                  color: bgTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
                ),
                child: FaIcon(icon, color: accentColor, size: 14),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: const Color(0xFF91A3AE),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. CARTÃO DE DADOS CADASTRAIS & SEGURANÇA (ZERO TRUST)
  // =========================================================================
  Widget _buildAccountSecurityCard(String cpf, String email, String phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7.5),
                    decoration: BoxDecoration(
                      color: AppColors.verdeVale.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const FaIcon(FontAwesomeIcons.shieldHalved, color: AppColors.verdeVale, size: 13),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'DADOS & SEGURANÇA',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3123),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.6), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF4CAF50), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'ATIVO',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4CAF50),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // CPF Mascarado
          _buildInfoRow(
            icon: FontAwesomeIcons.fingerprint,
            label: 'CPF DE ACESSO',
            value: _formatMaskedCpf(cpf),
            trailingBadge: 'PROTEGIDO',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: const Color(0xFF1E3A45).withValues(alpha: 0.6), height: 1),
          ),

          // E-mail
          _buildInfoRow(
            icon: FontAwesomeIcons.envelope,
            label: 'E-MAIL',
            value: email,
            canCopy: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: const Color(0xFF1E3A45).withValues(alpha: 0.6), height: 1),
          ),

          // Telefone
          _buildInfoRow(
            icon: FontAwesomeIcons.phone,
            label: 'TELEFONE',
            value: _formatPhone(phone),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required FaIconData icon,
    required String label,
    required String value,
    String? trailingBadge,
    bool canCopy = false,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0C171F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E3A45), width: 1),
          ),
          child: Center(
            child: FaIcon(icon, color: const Color(0xFF00A4B4), size: 13.5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: const Color(0xFF91A3AE),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (trailingBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trailingBadge,
              style: GoogleFonts.inter(
                color: const Color(0xFF91A3AE),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (canCopy && value.isNotEmpty && value != 'Não cadastrado')
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              SoundService.playClick();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Copiado para a área de transferência!'),
                  backgroundColor: AppColors.verdeVale,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const FaIcon(FontAwesomeIcons.copy, color: AppColors.cinzaMedio, size: 12),
            ),
          ),
      ],
    );
  }

  // =========================================================================
  // 4. CONFIGURAÇÕES DE ÁUDIO & IMERSÃO
  // =========================================================================
  Widget _buildAudioSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.35), width: 1),
                ),
                child: Center(
                  child: FaIcon(
                    SoundService.isAmbientMuted ? FontAwesomeIcons.volumeXmark : FontAwesomeIcons.music,
                    color: AppColors.verdeVale,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Som Ambiente de Mistério',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    SoundService.isAmbientMuted
                        ? 'Trilha de suspense silenciada'
                        : 'Música de suspense e mistério ativada',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF91A3AE),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: !SoundService.isAmbientMuted,
            activeTrackColor: AppColors.verdeVale.withValues(alpha: 0.6),
            activeThumbColor: AppColors.verdeVale,
            onChanged: (enabled) {
              setState(() {
                SoundService.toggleAmbientMute();
              });
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. BOTÕES DE AÇÃO (EDITAR PERFIL E SAIR DA CONTA)
  // =========================================================================
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, ParseUser user) {
    return Column(
      children: [
        // Botão Primário: Editar Perfil
        GestureDetector(
          onTap: () => _showEditProfileModal(user),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.gradienteVerdeVale,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.verdeVale.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.penToSquare, size: 14, color: Colors.white),
                const SizedBox(width: 9),
                Text(
                  'EDITAR DADOS PESSOAIS',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Botão Secundário: Sair da Conta
        GestureDetector(
          onTap: () => _confirmSignOut(context, ref),
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.arrowRightFromBracket, size: 13, color: AppColors.danger),
                const SizedBox(width: 8),
                Text(
                  'SAIR DA CONTA',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                    fontSize: 12.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
