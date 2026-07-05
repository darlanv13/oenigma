import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:oenigma/features/profile/providers/profile_repository_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/profile/widgets/profile_account_actions.dart';
import 'package:oenigma/features/profile/widgets/profile_editable_info_card.dart';
import 'package:oenigma/features/profile/widgets/profile_header.dart';
import 'package:oenigma/features/profile/widgets/profile_section_header.dart';
import 'package:oenigma/features/profile/widgets/profile_stats_section.dart';
import 'package:oenigma/features/profile/widgets/profile_badges_section.dart';

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
            ProfileHeader(
              walletData: widget.walletData,
              playerData: widget.playerData,
              selectedImage: _selectedImage,
              onPickImage: _pickImage,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  const ProfileSectionHeader(title: 'ESTATÍSTICAS GERAIS'),
                  ProfileStatsSection(wallet: widget.walletData),
                  const SizedBox(height: 32),
                  ProfileBadgesSection(playerData: widget.playerData),
                  const SizedBox(height: 32),
                  const ProfileSectionHeader(title: 'INFORMAÇÕES PESSOAIS'),
                  ProfileEditableInfoCard(
                    playerData: widget.playerData,
                    formKey: _formKey,
                    phoneController: _phoneController,
                    isLoading: _isLoading,
                    onSave: _saveProfile,
                  ),
                  const SizedBox(height: 32),
                  const ProfileSectionHeader(title: 'CONTA'),
                  ProfileAccountActions(
                    email: email,
                    onResetPassword: _resetPassword,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
