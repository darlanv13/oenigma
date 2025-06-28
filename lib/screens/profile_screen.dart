import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();

  // Futuro unificado para carregar todos os dados de uma vez
  late Future<Map<String, dynamic>> _dataFuture;

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadUserData();
  }

  // Lógica de carregamento unificada
  Future<Map<String, dynamic>> _loadUserData() async {
    final userId = _authService.currentUser!.uid;
    // Usamos Future.wait para carregar dados do jogador e da carteira em paralelo
    final results = await Future.wait([
      _firebaseService.getPlayerDetails(userId),
      _firebaseService.getUserWalletData(),
    ]);

    final playerData = results[0] as Map<String, dynamic>?;
    final walletData = results[1] as UserWalletModel;

    if (playerData != null) {
      _phoneController.text = playerData['phone'] ?? '';
      _birthDateController.text = playerData['birthDate'] ?? '';
    }

    return {'playerData': playerData, 'walletData': walletData};
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
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
        birthDate: _birthDateController.text,
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
          // Recarrega os dados para mostrar a nova foto
          setState(() {
            _dataFuture = _loadUserData();
            _selectedImage = null; // Limpa a imagem selecionada
          });
        }
      }
      setState(() => _isLoading = false);
    }
  }

  // Nova função para redefinir senha
  Future<void> _resetPassword(String email) async {
    final error = await _authService.sendPasswordResetEmail(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error == null ? 'Email de recuperação enviado!' : error,
          ),
          backgroundColor: error == null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text("Erro ao carregar dados: ${snapshot.error}"),
            );
          }

          final UserWalletModel wallet = snapshot.data!['walletData'];
          final Map<String, dynamic>? playerData = snapshot.data!['playerData'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(wallet),
                const SizedBox(height: 24),
                _buildStatsSection(wallet),
                const SizedBox(height: 24),
                _buildSectionHeader("DADOS PESSOAIS"),
                _buildEditableInfoCard(playerData),
                const SizedBox(height: 24),
                _buildSectionHeader("CONTA"),
                _buildAccountActions(wallet.email),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS REFEITOS E NOVOS ---

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
                  : (wallet.photoURL != null
                            ? NetworkImage(wallet.photoURL!)
                            : null)
                        as ImageProvider?,
              child: (_selectedImage == null && wallet.photoURL == null)
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoCard(Map<String, dynamic>? playerData) {
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
                Icons.badge_outlined,
                'Nome Completo',
                playerData?['name'] ?? '',
              ),
              const Divider(height: 32),
              _buildInfoRow(Icons.credit_card, 'CPF', playerData?['cpf'] ?? ''),
              const Divider(height: 32),
              _buildTextFormField(
                controller: _phoneController,
                label: 'Telefone (WhatsApp)',
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _birthDateController,
                label: 'Data de Nascimento',
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: const Icon(Icons.save, color: darkBackground),
                  label: const Text('Salvar Alterações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmber,
                    foregroundColor: darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
            onTap: () => _resetPassword(email),
          ),
        ],
      ),
    );
  }
}
