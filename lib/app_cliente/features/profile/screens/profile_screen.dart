import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required Map<String, dynamic> playerData, required UserWalletModel walletData});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  
  void _showEditProfileModal(ParseUser user) {
    final nameController = TextEditingController(text: user.get<String>('name') ?? '');
    final phoneController = TextEditingController(text: user.get<String>('phone') ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkCardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.userPen, color: AppColors.verdeVale, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'EDITAR PERFIL',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        if (!isSaving)
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Campo: Nome
                    _buildInputField(
                      controller: nameController,
                      hint: 'Seu Nome',
                      icon: FontAwesomeIcons.user,
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 14),
                    
                    // Campo: Telefone
                    _buildInputField(
                      controller: phoneController,
                      hint: 'Telefone',
                      icon: FontAwesomeIcons.phone,
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 20),

                    // Botão: Alterar Foto de Perfil
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSaving 
                            ? null 
                            : () => _updateProfilePhoto(user, (savingState) {
                                setModalState(() => isSaving = savingState);
                              }),
                        icon: const FaIcon(FontAwesomeIcons.camera, size: 14, color: AppColors.verdeVale),
                        label: Text(
                          'ALTERAR FOTO',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.verdeVale),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdeVale.withValues(alpha: 0.12),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppColors.verdeVale.withValues(alpha: 0.4), width: 1.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botão: Salvar Dados
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppColors.gradienteVerdeVale,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.verdeVale.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                
                                user.set('name', nameController.text.trim());
                                user.set('phone', phoneController.text.trim());
                                
                                final response = await user.save();
                                
                                setModalState(() => isSaving = false);

                                if (response.success) {
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Perfil atualizado com sucesso!'),
                                        backgroundColor: AppColors.verdeVale,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                    setState(() {});
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erro: ${response.error?.message}'),
                                        backgroundColor: AppColors.danger,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                'SALVAR ALTERAÇÕES',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateProfilePhoto(ParseUser user, Function(bool) setSavingState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setSavingState(true);
      try {
        final bytes = await pickedFile.readAsBytes();
        ParseFileBase parseFile;
        
        if (kIsWeb) {
          parseFile = ParseWebFile(bytes, name: 'avatar.jpg');
        } else {
          parseFile = ParseFile(File(pickedFile.path));
        }

        final response = await parseFile.save();
        
        if (response.success && parseFile.url != null) {
          user.set('photoURL', parseFile.url);
          await user.save();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Foto atualizada com sucesso!'),
                backgroundColor: AppColors.verdeVale,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            setState(() {});
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao enviar foto: $e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        setSavingState(false);
      }
    }
  }

  Widget _buildInputField({required TextEditingController controller, required String hint, required FaIconData icon, required bool enabled}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.cinzaMedio),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14.0),
          child: FaIcon(icon, color: AppColors.verdeVale, size: 16),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.verdeVale, width: 1.5),
        ),
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
            // AppBar Customizada
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Navigator.canPop(context)
                      ? GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: const Center(
                              child: FaIcon(FontAwesomeIcons.chevronLeft, color: Colors.white, size: 14),
                            ),
                          ),
                        )
                      : const SizedBox(width: 40),
                  Text(
                    'MEU PERFIL',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 40),
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

                  final name = user.get<String>('name') ?? 'Explorador';
                  final email = user.get<String>('email') ?? 'Sem email';
                  final phone = user.get<String>('phone') ?? 'Não informado';
                  final xp = user.get<num>('xp')?.toInt() ?? 0;
                  final league = user.get<String>('league') ?? 'Bronze';
                  final photoUrl = user.get<String>('photoURL');

                  final eventosJogados = user.get<Map<String, dynamic>>('events')?.keys.length ?? 0;
                  final eventosVencidos = user.get<List<dynamic>>('winnerEvents')?.length ?? 0;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      children: [
                        _buildAvatarSection(name, league, xp, photoUrl),
                        const SizedBox(height: 24),
                        _buildGamerStats(eventosJogados, eventosVencidos),
                        const SizedBox(height: 20),
                        _buildInfoCard(email, phone),
                        const SizedBox(height: 28),
                        _buildActionButtons(context, ref, user),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
                error: (err, stack) => Center(child: Text('Erro: $err', style: const TextStyle(color: AppColors.danger))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(String name, String league, int xp, String? photoUrl) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.amareloVale, AppColors.verdeVale],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.verdeVale.withValues(alpha: 0.3),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.darkCardColor,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const FaIcon(FontAwesomeIcons.solidUser, size: 36, color: AppColors.verdeVale)
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.amareloVale.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.medal, color: AppColors.amareloVale, size: 12),
              const SizedBox(width: 6),
              Text(
                'LIGA ${league.toUpperCase()}  •  $xp XP',
                style: GoogleFonts.inter(
                  color: AppColors.amareloVale,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamerStats(int jogados, int vencidos) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
                  ),
                  child: const FaIcon(FontAwesomeIcons.mapLocationDot, color: AppColors.verdeVale, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  jogados.toString(),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                Text(
                  'EXPLORADOS',
                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.amareloVale.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.3)),
                  ),
                  child: const FaIcon(FontAwesomeIcons.trophy, color: AppColors.amareloVale, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  vencidos.toString(),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                Text(
                  'VITÓRIAS',
                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String email, String phone) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.idCard, color: AppColors.cinzaMedio, size: 14),
              const SizedBox(width: 10),
              Text(
                'DADOS DA CONTA',
                style: GoogleFonts.inter(
                  color: AppColors.cinzaMedio,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInfoRow(FontAwesomeIcons.envelope, 'E-mail', email),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          ),
          _buildInfoRow(FontAwesomeIcons.phone, 'Telefone', phone),
        ],
      ),
    );
  }

  Widget _buildInfoRow(dynamic icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(icon, color: AppColors.verdeVale, size: 14),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, ParseUser user) {
    return Column(
      children: [
        _buildProfileButton(
          icon: FontAwesomeIcons.penToSquare,
          label: 'EDITAR PERFIL',
          isPrimary: true,
          color: AppColors.verdeVale,
          useGradient: true,
          onTap: () => _showEditProfileModal(user),
        ),
        const SizedBox(height: 12),
        _buildProfileButton(
          icon: FontAwesomeIcons.arrowRightFromBracket,
          label: 'SAIR DA CONTA',
          isPrimary: false,
          color: AppColors.danger,
          onTap: () async {
            await ref.read(authRepositoryProvider).signOut();
          },
        ),
      ],
    );
  }

  Widget _buildProfileButton({
    required dynamic icon,
    required String label,
    required bool isPrimary,
    required Color color,
    bool useGradient = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? (useGradient ? null : color) : Colors.white.withValues(alpha: 0.06),
          gradient: isPrimary && useGradient ? AppColors.gradienteVerdeVale : null,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary ? null : Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 13, color: isPrimary ? Colors.white : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : color,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
