import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:oenigma/features/profile/providers/profile_repository_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.playerData['phone'] ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authRepository = ref.read(authRepositoryProvider);
      final userId = authRepository.currentUser!.uid;

      String? photoURL;
      if (_selectedImage != null) {
        photoURL = await ref.read(profileRepositoryProvider).uploadFile('profile_pictures/$userId/profile_image.jpg', await _selectedImage!.readAsBytes());
      }
      final dataToUpdate = {
        'phone': _phoneController.text,
        'birthDate': widget.playerData['birthDate'] ?? '',
      };
      if (photoURL != null) dataToUpdate['photoURL'] = photoURL;

      try {
        await ref.read(profileRepositoryProvider).updateUserProfile(userId, dataToUpdate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword(String email) async {
    if (email.isEmpty) return;

    final authRepository = ref.read(authRepositoryProvider);
    final error = await authRepository.sendPasswordResetEmail(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'E-mail de recuperação enviado para $email',
          ),
          backgroundColor: error == null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String email = widget.playerData['email'] ?? widget.walletData.email;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildSectionHeader('ESTATÍSTICAS GERAIS'),
                  _buildStatsSection(widget.walletData),
                  const SizedBox(height: 32),
                  _buildSectionHeader('INFORMAÇÕES PESSOAIS'),
                  _buildEditableInfoCard(widget.playerData),
                  const SizedBox(height: 32),
                  _buildSectionHeader('CONTA'),
                  _buildAccountActions(email),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryAmber, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAmber.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: darkBackground,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (widget.playerData['photoURL'] != null &&
                                widget.playerData['photoURL'].isNotEmpty
                            ? NetworkImage(widget.playerData['photoURL'])
                            : null) as ImageProvider?,
                    child: _selectedImage == null &&
                            (widget.playerData['photoURL'] == null ||
                                widget.playerData['photoURL'].isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: secondaryTextColor,
                          )
                        : null,
                  ),
                ),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: primaryAmber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: darkBackground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.walletData.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              widget.walletData.email,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatsSection(UserWalletModel wallet) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Saldo',
            'R\$ ${wallet.balance.toStringAsFixed(2)}',
            Icons.wallet,
            primaryAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Ranking',
            '#${wallet.lastEventRank ?? '-'}',
            Icons.bar_chart,
            Colors.lightBlueAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Vitórias',
            wallet.lastWonEventName != null ? "1" : "0",
            Icons.emoji_events,
            Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoCard(Map<String, dynamic> playerData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInfoRow(
              'Nome Completo',
              playerData['name'] ?? '',
              Icons.badge_outlined,
            ),
            const Divider(height: 32, color: Colors.white10),
            _buildInfoRow('CPF', playerData['cpf'] ?? '', Icons.credit_card),
            const Divider(height: 32, color: Colors.white10),
            _buildInfoRow(
              'Data de Nascimento',
              playerData['birthDate'] ?? '',
              Icons.calendar_month,
            ),
            const Divider(height: 32, color: Colors.white10),
            _buildTextFormField(
              controller: _phoneController,
              label: 'Telefone',
              icon: Icons.phone_android,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  foregroundColor: darkBackground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: darkBackground,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SALVAR ALTERAÇÕES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: secondaryTextColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: textColor, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: textColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: secondaryTextColor, size: 20),
        labelText: label,
        labelStyle: const TextStyle(color: secondaryTextColor),
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryAmber),
        ),
      ),
    );
  }

  Widget _buildAccountActions(String email) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_reset, color: textColor, size: 20),
            ),
            title: const Text(
              'Redefinir Senha',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: secondaryTextColor,
            ),
            onTap: () => _resetPassword(email),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            title: const Text(
              'Sair da Conta',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              final authRepository = ref.read(authRepositoryProvider);
              await authRepository.signOut();
            },
          ),
        ],
      ),
    );
  }
}
