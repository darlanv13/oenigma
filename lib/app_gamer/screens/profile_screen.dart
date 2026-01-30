import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> playerData;
  final UserWalletModel walletData;

  const ProfileScreen({
    super.key,
    required this.playerData,
    required this.walletData,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
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
      final userId = _authService.currentUser!.uid;

      final error = await _authService.updateUserProfile(
        userId: userId,
        imageFile: _selectedImage,
        phone: _phoneController.text,
        birthDate: widget.playerData['birthDate'] ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error == null ? 'Perfil atualizado com sucesso!' : 'Erro: $error',
            ),
            backgroundColor: error == null ? Colors.green : Colors.red,
          ),
        );
        if (error == null) {
          Navigator.of(context).pop();
        }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword(String email) async {
    final error = await _authService.sendPasswordResetEmail(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Email de recuperação enviado!'),
          backgroundColor: error == null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader("ESTATÍSTICAS"),
                _buildStatsSection(widget.walletData),
                const SizedBox(height: 24),
                _buildSectionHeader("DADOS PESSOAIS"),
                _buildEditableInfoCard(widget.playerData),
                const SizedBox(height: 24),
                _buildSectionHeader("SEGURANÇA"),
                _buildAccountActions(widget.walletData.email),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            // Background decorativo
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryAmber.withOpacity(0.1), darkBackground],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'profile-avatar', // Hero tag para animação
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryAmber, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: cardColor,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (widget.walletData.photoURL != null &&
                                            widget
                                                .walletData
                                                .photoURL!
                                                .isNotEmpty
                                        ? NetworkImage(
                                            widget.walletData.photoURL!,
                                          )
                                        : null)
                                    as ImageProvider?,
                          child:
                              (_selectedImage == null &&
                                  (widget.walletData.photoURL == null ||
                                      widget.walletData.photoURL!.isEmpty))
                              ? const FaIcon(
                                  FontAwesomeIcons.user,
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
                          child: const FaIcon(
                            FontAwesomeIcons.camera,
                            size: 20,
                            color: darkBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
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
            FontAwesomeIcons.wallet,
            primaryAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Ranking',
            '#${wallet.lastEventRank ?? '-'}',
            FontAwesomeIcons.chartSimple,
            Colors.lightBlueAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Vitórias',
            wallet.lastWonEventName != null ? "1" : "0",
            FontAwesomeIcons.trophy,
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 28),
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInfoRow(
              'Nome Completo',
              playerData['name'] ?? '',
              FontAwesomeIcons.idCard,
            ),
            const Divider(height: 32, color: Colors.white10),
            _buildInfoRow(
              'CPF',
              playerData['cpf'] ?? '',
              FontAwesomeIcons.creditCard,
            ),
            const Divider(height: 32, color: Colors.white10),
            _buildInfoRow(
              'Data de Nascimento',
              playerData['birthDate'] ?? '',
              FontAwesomeIcons.calendar,
            ),
            const Divider(height: 32, color: Colors.white10),
            _buildTextFormField(
              controller: _phoneController,
              label: 'Telefone',
              icon: FontAwesomeIcons.mobile,
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
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(icon, color: secondaryTextColor, size: 20),
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
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FaIcon(icon, color: secondaryTextColor, size: 20),
        ),
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const FaIcon(
                FontAwesomeIcons.key,
                color: textColor,
                size: 20,
              ),
            ),
            title: const Text(
              'Redefinir Senha',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            trailing: const FaIcon(
              FontAwesomeIcons.chevronRight,
              color: secondaryTextColor,
              size: 16,
            ),
            onTap: () => _resetPassword(email),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Colors.white.withOpacity(0.1)),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const FaIcon(
                FontAwesomeIcons.rightFromBracket,
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
              await _authService.signOut();
            },
          ),
        ],
      ),
    );
  }
}
