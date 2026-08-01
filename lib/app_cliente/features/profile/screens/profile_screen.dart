import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/app_cliente/core/models/user_wallet_model.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFC0A060).withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.chevron_left,
            color: Color(0xFFC0A060),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(UserWalletModel walletData, Map<String, dynamic> playerData) {
    final initials = _getInitials(walletData.name);
    final email = playerData['email'] ?? walletData.email;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFC0A060), Color(0xFF8A7A4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC0A060).withValues(alpha: 0.3),
                blurRadius: 24,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF06080B),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          walletData.name,
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF0E6C5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFB0A07A),
          ),
        ),
        const SizedBox(height: 20),
        _buildLeagueBadge(playerData),
      ],
    );
  }

  Widget _buildLeagueBadge(Map<String, dynamic> playerData) {
    int xp = playerData['xp'] ?? 0;
    String league = playerData['league'] ?? 'Bronze';

    // League progress logic
    int currentLeagueMin = 0;
    int currentLeagueMax = 500;
    Color leagueColor = Colors.brown[300]!;

    if (league == 'Lenda') {
      currentLeagueMin = 6001;
      currentLeagueMax = 6001; // Maxed out
      leagueColor = Colors.purpleAccent;
    } else if (league == 'Diamante') {
      currentLeagueMin = 3001;
      currentLeagueMax = 6000;
      leagueColor = Colors.blueAccent;
    } else if (league == 'Ouro') {
      currentLeagueMin = 1501;
      currentLeagueMax = 3000;
      leagueColor = Colors.amber;
    } else if (league == 'Prata') {
      currentLeagueMin = 501;
      currentLeagueMax = 1500;
      leagueColor = Colors.blueGrey[300]!;
    }

    double progress = 1.0;
    if (league != 'Lenda') {
      progress = (xp - currentLeagueMin) / (currentLeagueMax - currentLeagueMin);
      if (progress < 0) progress = 0;
      if (progress > 1) progress = 1;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181C).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: leagueColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield, color: leagueColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Liga $league'.toUpperCase(),
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: leagueColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 8,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: leagueColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(color: leagueColor.withValues(alpha: 0.5), blurRadius: 8),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$xp XP', style: TextStyle(color: leagueColor, fontWeight: FontWeight.bold, fontSize: 12)),
              if (league != 'Lenda')
                Text('Próxima Liga: ${currentLeagueMax + 1} XP', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
              if (league == 'Lenda')
                Text('Nível Máximo', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(UserWalletModel walletData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF16181C).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'SALDO DISPONÍVEL',
            style: TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 10, // ~0.7rem
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'R\$ ${walletData.balance.toStringAsFixed(2).replaceAll('.', ',')}',
            style: GoogleFonts.orbitron(
              fontSize: 30, // ~2.2rem
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF0E6C5),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Depositar',
                  isPrimary: true,
                  onTap: () {}, // Can route to wallet deposit
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  label: 'Sacar',
                  isPrimary: false,
                  onTap: () {}, // Can route to wallet withdraw
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFFC0A060), Color(0xFFA8894A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : Colors.transparent,
          border: isPrimary ? null : Border.all(color: const Color(0xFFC0A060), width: 1.5),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFFC0A060).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.orbitron(
              fontSize: 11, // ~0.75rem
              fontWeight: FontWeight.w700,
              color: isPrimary ? const Color(0xFF06080B) : const Color(0xFFF0E6C5),
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateSection(String title, IconData icon, String message, {String? highlight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          child: Text(
            title,
            style: GoogleFonts.orbitron(
              fontSize: 12, // ~0.8rem
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC0A060),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF16181C).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32, // ~2rem
                color: const Color(0xFF4A4A4A),
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF7A7A7A),
                    fontSize: 13, // ~0.85rem
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(text: message),
                    if (highlight != null) ...[
                      const TextSpan(text: '\n'),
                      TextSpan(
                        text: highlight,
                        style: const TextStyle(
                          color: Color(0xFFC0A060),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER CUSTOMIZADO
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFC0A060).withValues(alpha: 0.10),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBackButton(context),
                    Text(
                      'Perfil',
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF0E6C5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(
                      width: 36,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.more_vert, // fa-ellipsis-v
                          color: Color(0xFFC0A060),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CORPO DA TELA
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
              child: Column(
                children: [
                  _buildProfileSection(widget.walletData, widget.playerData),
                  const SizedBox(height: 24),
                  _buildBalanceCard(widget.walletData),
                  const SizedBox(height: 10),
                  _buildEmptyStateSection(
                    'Meus prêmios',
                    Icons.card_giftcard,
                    'Nenhum prêmio ainda.',
                    highlight: 'Participe de eventos para ganhar!',
                  ),
                  const SizedBox(height: 10),
                  _buildEmptyStateSection(
                    'Histórico recente',
                    Icons.access_time_outlined,
                    'Nenhuma atividade recente.',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
