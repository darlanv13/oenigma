import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_gamer/screens/login_screen.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  // Parâmetros opcionais para garantir que a navegação nunca quebre
  final Map<String, dynamic>? playerData;
  final UserWalletModel? walletData;

  const ProfileScreen({super.key, this.playerData, this.walletData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  Map<String, dynamic>? _playerData;
  UserWalletModel? _walletData;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 1. Usa dados recebidos (Cache Instantâneo)
    if (widget.playerData != null) {
      _playerData = widget.playerData;
    }
    if (widget.walletData != null) {
      _walletData = widget.walletData;
    }

    // 2. Se faltar algo, busca no servidor
    if (_playerData == null || _walletData == null) {
      _fetchMissingData();
    }
  }

  Future<void> _fetchMissingData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      // Busca paralela para eficiência
      final results = await Future.wait([
        if (_playerData == null) _firebaseService.getPlayerDetails(userId),
        if (_walletData == null) _firebaseService.getUserWalletData(),
      ]);

      if (mounted) {
        setState(() {
          // Atualiza apenas o que estava faltando
          if (_playerData == null)
            _playerData = results[0] as Map<String, dynamic>?;
          // Se player data foi buscado, wallet é o segundo resultado (índice 1), senão é o primeiro (índice 0)
          if (_walletData == null) {
            final walletIndex = _playerData == null ? 1 : 0;
            // Ajuste seguro de índice dependendo do que foi buscado
            final dynamic walletResult = results.length > walletIndex
                ? results[walletIndex]
                : results[0];
            if (walletResult is UserWalletModel) _walletData = walletResult;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao atualizar perfil: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dados de exibição com Fallback seguro
    final name = _playerData?['name'] ?? 'Agente';
    final email = _authService.currentUser?.email ?? '';
    final photoUrl = _playerData?['photoURL'];
    final balance =
        _walletData?.balance ?? 0.0; // Campo 'balance' do seu modelo

    if (_isLoading && _playerData == null) {
      return const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: primaryAmber)),
      );
    }

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "PERFIL",
          style: GoogleFonts.orbitron(color: Colors.white, letterSpacing: 2),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- HEADER DO PERFIL ---
            Hero(
              tag: 'profile_avatar',
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryAmber, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAmber.withOpacity(0.3),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: cardColor,
                  backgroundImage:
                      (photoUrl != null && photoUrl.startsWith('http'))
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: (photoUrl == null)
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: secondaryTextColor,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(email, style: const TextStyle(color: secondaryTextColor)),

            const SizedBox(height: 32),

            // --- CARD DE STATUS ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Nível", "1", Icons.star), // Exemplo estático
                  Container(width: 1, height: 40, color: Colors.white10),
                  _buildStatItem(
                    "Saldo",
                    "R\$ ${balance.toStringAsFixed(2)}",
                    FontAwesomeIcons.wallet,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- MENU DE AÇÕES ---
            _buildMenuOption(
              icon: Icons.edit,
              title: "Editar Dados",
              onTap: () {},
            ),
            _buildMenuOption(
              icon: Icons.lock,
              title: "Alterar Senha",
              onTap: () {},
            ),
            _buildMenuOption(
              icon: Icons.help_outline,
              title: "Suporte",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: primaryAmber, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: secondaryTextColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white24,
        ),
        onTap: onTap,
      ),
    );
  }
}
