import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  // A tela recebe os dados pré-carregados
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
  // _birthDateController removido pois o campo agora é apenas leitura

  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Popula os campos com os dados recebidos
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
        // Envia a data de nascimento original, já que não é mais editável nesta tela
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
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(widget.walletData),
            const SizedBox(height: 24),
            _buildSectionHeader("ESTATÍSTICAS"),
            _buildStatsSection(widget.walletData),
            const SizedBox(height: 24),
            _buildSectionHeader("DADOS PESSOAIS"),
            _buildEditableInfoCard(widget.playerData),
            const SizedBox(height: 24),
            _buildSectionHeader("CONTA"),
            _buildAccountActions(widget.walletData.email),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUÇÃO ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserWalletModel wallet) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: cardColor,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (wallet.photoURL != null && wallet.photoURL!.isNotEmpty
                            ? NetworkImage(wallet.photoURL!)
                            : null)
                        as ImageProvider?,
              child:
                  (_selectedImage == null &&
                      (wallet.photoURL == null || wallet.photoURL!.isEmpty))
                  ? const Icon(
                      Icons.person,
                      size: 50,
                      color: secondaryTextColor,
                    )
                  : null,
            ),
            GestureDetector(
              onTap: _pickImage,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: primaryAmber,
                child: Icon(Icons.edit, size: 20, color: darkBackground),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          wallet.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          wallet.email,
          style: const TextStyle(fontSize: 16, color: secondaryTextColor),
        ),
      ],
    );
  }

  // WIDGET DO DASHBOARD / STATS
  Widget _buildStatsSection(UserWalletModel wallet) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Saldo',
          'R\$ ${wallet.balance.toStringAsFixed(2)}',
          Icons.account_balance_wallet_outlined,
          primaryAmber,
        ),
        _buildStatCard(
          'Ranking',
          '#${wallet.lastEventRank ?? '-'}',
          Icons.leaderboard_outlined,
          Colors.lightBlue.shade300,
        ),
        _buildStatCard(
          'Vitórias',
          wallet.lastWonEventName != null ? "1" : "0",
          Icons.emoji_events_outlined,
          Colors.orange.shade300,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
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
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInfoRow(
                'Nome Completo',
                playerData['name'] ?? '',
                Icons.badge_outlined,
              ),
              const Divider(height: 32),
              _buildInfoRow(
                'CPF',
                playerData['cpf'] ?? '',
                Icons.credit_card_outlined,
              ),
              const Divider(height: 32),
              // Data de Nascimento agora é apenas leitura
              _buildInfoRow(
                'Data de Nascimento',
                playerData['birthDate'] ?? '',
                Icons.calendar_today_outlined,
              ),
              const Divider(height: 32),
              _buildTextFormField(
                controller: _phoneController,
                label: 'Telefone (WhatsApp)',
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: const CircularProgressIndicator(
                            color: darkBackground,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined, color: darkBackground),
                  label: const Text('Salvar Alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmber,
                    foregroundColor: darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: secondaryTextColor, size: 20),
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
        fillColor: darkBackground.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryAmber),
        ),
      ),
    );
  }

  Widget _buildAccountActions(String email) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.password_outlined,
              color: secondaryTextColor,
            ),
            title: const Text(
              'Redefinir Senha',
              style: TextStyle(color: textColor),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: secondaryTextColor,
            ),
            onTap: () => _resetPassword(email),
          ),
          // Divisor sutil
          Divider(height: 1, color: Colors.grey[800]),
          // Botão de Sair
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Sair',
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
