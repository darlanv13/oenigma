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
  
  // Função para abrir o Modal de Edição salvando no Parse
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
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryAmber.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 10)),
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
                            const FaIcon(FontAwesomeIcons.userPen, color: primaryAmber, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'EDITAR PERFIL',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        if (!isSaving)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Campo: Nome
                    _buildInputField(
                      controller: nameController,
                      hint: 'Seu Nome',
                      icon: FontAwesomeIcons.user,
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo: Telefone
                    _buildInputField(
                      controller: phoneController,
                      hint: 'Telefone',
                      icon: FontAwesomeIcons.phone,
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 24),

                    // Botão: Alterar Foto de Perfil
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        // Correção: Passando um callback para alterar o estado do modal
                        onPressed: isSaving 
                            ? null 
                            : () => _updateProfilePhoto(user, (savingState) {
                                setModalState(() => isSaving = savingState);
                              }),
                        icon: const FaIcon(FontAwesomeIcons.camera, size: 14, color: Colors.white),
                        label: Text(
                          'ALTERAR FOTO',
                          style: GoogleFonts.orbitron(fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão: Salvar Dados
                    SizedBox(
                      width: double.infinity,
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
                                      const SnackBar(content: Text('Perfil atualizado!'), backgroundColor: successColor),
                                    );
                                    setState(() {}); // Força a tela a recarregar os novos dados
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro: ${response.error?.message}'), backgroundColor: dangerColor),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAmber,
                          foregroundColor: darkBackground,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: darkBackground, strokeWidth: 2))
                            : Text(
                                'SALVAR ALTERAÇÕES',
                                style: GoogleFonts.orbitron(fontWeight: FontWeight.w900, fontSize: 14),
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

  // Lógica de Upload da Foto do Parse (Corrigida a assinatura)
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
              const SnackBar(content: Text('Foto atualizada com sucesso!'), backgroundColor: successColor),
            );
            setState(() {}); // Recarrega a tela de perfil
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar foto: $e'), backgroundColor: dangerColor),
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
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        filled: true,
        fillColor: darkBackground,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14.0),
          child: FaIcon(icon, color: primaryAmber, size: 18),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryAmber.withOpacity(0.5), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Fundo base escuro
      body: Stack(
        children: [
          // Fundo imersivo do mapa
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),

          SafeArea(
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
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primaryAmber.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: FaIcon(FontAwesomeIcons.chevronLeft, color: primaryAmber, size: 14),
                                ),
                              ),
                            )
                          : const SizedBox(width: 36),
                      Text(
                        'MEU PERFIL',
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryAmber,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),

                Expanded(
                  child: authState.when(
                    data: (user) {
                      if (user == null) {
                        return const Center(
                          child: Text('Sessão expirada. Faça login novamente.', style: TextStyle(color: Colors.white)),
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
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildAvatarSection(name, league, xp, photoUrl),
                            const SizedBox(height: 32),
                            _buildGamerStats(eventosJogados, eventosVencidos),
                            const SizedBox(height: 24),
                            _buildInfoCard(email, phone),
                            const SizedBox(height: 32),
                            _buildActionButtons(context, ref, user),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: primaryAmber)),
                    error: (err, stack) => Center(child: Text('Erro: $err', style: const TextStyle(color: dangerColor))),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: primaryAmber.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: darkBackground,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const FaIcon(FontAwesomeIcons.userNinja, size: 40, color: secondaryTextColor)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name.toUpperCase(),
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.8), offset: const Offset(0, 2), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryAmber.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.medal, color: primaryAmber, size: 14),
              const SizedBox(width: 8),
              Text(
                'LIGA ${league.toUpperCase()}  •  $xp XP',
                style: GoogleFonts.inter(
                  color: primaryAmber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryAmber.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                const FaIcon(FontAwesomeIcons.mapLocationDot, color: Colors.blueAccent, size: 24),
                const SizedBox(height: 12),
                Text(
                  jogados.toString(),
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text('EXPLORADOS', style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryAmber.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                const FaIcon(FontAwesomeIcons.trophy, color: primaryAmber, size: 24),
                const SizedBox(height: 12),
                Text(
                  vencidos.toString(),
                  style: GoogleFonts.orbitron(color: primaryAmber, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text('VITÓRIAS', style: GoogleFonts.inter(color: primaryAmber, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String email, String phone) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryAmber.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.idCard, color: secondaryTextColor, size: 16),
              const SizedBox(width: 12),
              Text(
                'DADOS DA CONTA',
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(FontAwesomeIcons.envelope, 'E-mail', email),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: primaryAmber.withOpacity(0.1), height: 1),
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
            color: darkBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryAmber.withOpacity(0.1)),
          ),
          child: FaIcon(icon, color: primaryAmber, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 12),
              ),
              const SizedBox(height: 4),
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
          color: Colors.white70,
          onTap: () => _showEditProfileModal(user),
        ),
        const SizedBox(height: 16),
        _buildProfileButton(
          icon: FontAwesomeIcons.arrowRightFromBracket,
          label: 'SAIR DA CONTA',
          color: dangerColor,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}