import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/widgets/dashed_rect.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:oenigma/features/profile/providers/profile_repository_provider.dart';
import 'package:oenigma/features/profile/screens/edit_profile_screen.dart';
import 'package:oenigma/features/profile/widgets/profile_account_actions.dart';
import 'package:oenigma/features/profile/widgets/profile_badges_section.dart';
import 'package:oenigma/features/profile/widgets/profile_stats_section.dart';
import 'package:oenigma/features/wallet/providers/wallet_provider.dart';
import 'package:oenigma/features/wallet/screens/wallet_screen.dart';
import 'package:oenigma/features/wallet/widgets/wallet_credit_options_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> playerData;
  final UserWalletModel walletData;

  const ProfileScreen({
    super.key,
    required this.playerData,
    required this.walletData,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _saveProfileImage();
      });
    }
  }

  Future<void> _saveProfileImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final currentUser = authRepository.currentUser;

      if (currentUser == null || currentUser.objectId == null) {
          throw Exception('Usuário não autenticado.');
      }

      final userId = currentUser.objectId!;
      String photoURL = await ref
          .read(profileRepositoryProvider)
          .uploadFile(
            'profile_pictures/$userId/profile_image.jpg',
            await _selectedImage!.readAsBytes(),
          );

      await ref
          .read(profileRepositoryProvider)
          .updateUserProfile(userId, {'photoURL': photoURL});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil atualizada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword(String email) async {
    if (email.isEmpty) return;

    final authRepository = ref.read(authRepositoryProvider);
    final error = await authRepository.sendPasswordResetEmail(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'E-mail de recuperação enviado para $email'),
          backgroundColor: error == null ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _refreshWalletData() async {
    return await ref.refresh(walletProvider.future);
  }

  void _showAddFundsDialog(UserWalletModel wallet) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CreditOptionsSheet(wallet: wallet);
      },
    ).then((_) {
      _refreshWalletData();
    });
  }

  void _showWithdrawDialog(UserWalletModel wallet) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: WithdrawSheet(wallet: wallet),
        );
      },
    ).then((_) {
      _refreshWalletData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String email = widget.playerData['email'] ?? widget.walletData.email;
    final walletAsync = ref.watch(walletProvider);
    final currentWallet = walletAsync.value ?? widget.walletData;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Fundo principal escuro
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.angleLeft,
              color: Color(0xFFD6B570), // Dourado
              size: 16,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        title: Text(
          'Perfil',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white.withValues(alpha: 0.05),
            height: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.pen,
              color: Color(0xFFB39D82),
              size: 16,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    playerData: widget.playerData,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            _buildHeader(currentWallet, widget.playerData),
            const SizedBox(height: 32),
            _buildBalanceCard(currentWallet),
            const SizedBox(height: 32),
            _buildStatsSection(),
            const SizedBox(height: 32),
            _buildBadgesSection(),
            const SizedBox(height: 32),
            _buildAccountActionsSection(email),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserWalletModel wallet, Map<String, dynamic> player) {
    String name = player['name'] ?? wallet.name;
    String email = player['email'] ?? wallet.email;
    String initials = "";

    if (name.isNotEmpty) {
      var parts = name.split(' ');
      if (parts.length > 1) {
        initials = parts[0][0] + parts[parts.length - 1][0];
      } else {
        initials = parts[0][0];
      }
      initials = initials.toUpperCase();
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFE2C993), Color(0xFFB1904C)],
                  radius: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC7A55C).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _selectedImage != null
                  ? ClipOval(
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : (player['photoURL'] != null && player['photoURL'].isNotEmpty)
                      ? ClipOval(
                          child: Image.network(player['photoURL'], fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
            ),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB1904C),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F0F0F),
                    width: 3,
                  ),
                ),
                child: _isLoading
                  ? const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.camera,
                      size: 10,
                      color: Colors.black,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(UserWalletModel wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'SALDO DISPONÍVEL',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'R\$ ${wallet.balance.toStringAsFixed(2).replaceAll('.', ',')}',
            style: GoogleFonts.orbitron(
              color: const Color(0xFFDCD6CC),
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDEC388), Color(0xFFB1904C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC7A55C).withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showAddFundsDialog(wallet),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'DEPOSITAR',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFFDCD6CC),
                      width: 1.0,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showWithdrawDialog(wallet),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'SACAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ESTATÍSTICAS GERAIS',
          style: TextStyle(
            color: Color(0xFFDCD6CC),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        DashedRect(
          color: Colors.white.withValues(alpha: 0.1),
          strokeWidth: 1.5,
          gap: 6.0,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131313),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ProfileStatsSection(wallet: widget.walletData),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEUS PRÊMIOS',
          style: TextStyle(
            color: Color(0xFFDCD6CC),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        DashedRect(
          color: Colors.white.withValues(alpha: 0.1),
          strokeWidth: 1.5,
          gap: 6.0,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131313),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ProfileBadgesSection(playerData: widget.playerData),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActionsSection(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTA & SEGURANÇA',
          style: TextStyle(
            color: Color(0xFFDCD6CC),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        DashedRect(
          color: Colors.white.withValues(alpha: 0.1),
          strokeWidth: 1.5,
          gap: 6.0,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
            decoration: BoxDecoration(
              color: const Color(0xFF131313),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ProfileAccountActions(
              email: email,
              onResetPassword: _resetPassword,
            ),
          ),
        ),
      ],
    );
  }
}
