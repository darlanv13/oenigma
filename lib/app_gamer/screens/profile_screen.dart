import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_gamer/screens/login_screen.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../stores/profile_store.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? playerData;
  final UserWalletModel? walletData;

  const ProfileScreen({super.key, this.playerData, this.walletData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileStore _store = ProfileStore();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _store.setInitialData(player: widget.playerData, wallet: widget.walletData);
    _store.fetchMissingData();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Observer(
        builder: (_) {
          final name = _store.playerData?['name'] ?? 'Agente';
          final email = _authService.currentUser?.email ?? '';
          final photoUrl = _store.playerData?['photoURL'];
          final balance =
              _store.walletData?.balance ?? 0.0;

          if (_store.isLoading && _store.playerData == null) {
             return const Center(child: CircularProgressIndicator(color: primaryAmber));
          }

          return SingleChildScrollView(
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
          );
        },
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
