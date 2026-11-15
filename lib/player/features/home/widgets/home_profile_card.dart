import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeProfileCard extends StatelessWidget {
  final Map<String, dynamic> playerData;
  final UserWalletModel wallet;
  final List<EventModel> events;
  final List<dynamic> allPlayers;

  const HomeProfileCard({
    super.key,
    required this.playerData,
    required this.wallet,
    required this.events,
    required this.allPlayers,
  });

  @override
  Widget build(BuildContext context) {
    final String firstName = wallet.name.split(' ').first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B1115),
                  border: Border.all(
                    color: AppColors.verdeVale.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.verdeVale.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: wallet.photoURL != null && wallet.photoURL!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            wallet.photoURL!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const FaIcon(
                              FontAwesomeIcons.solidUser,
                              color: AppColors.verdeVale,
                              size: 16,
                            ),
                          ),
                        )
                      : const FaIcon(
                          FontAwesomeIcons.solidUser,
                          color: AppColors.verdeVale,
                          size: 16,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CAÇADOR',
                    style: GoogleFonts.cinzel(
                      color: AppColors.cinzaMedio,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    firstName.isNotEmpty ? firstName : 'Visitante!',
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildStatColumn(
                'Saldo',
                'R\$ ${wallet.balance.toStringAsFixed(2).replaceAll('.', ',')}',
                isBalance: true,
              ),
              Container(
                height: 28,
                width: 1,
                color: const Color(0xFF1E3A45),
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              _buildStatColumn(
                'Rank',
                '#${wallet.lastEventRank ?? '-'}',
                isBalance: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value,
      {required bool isBalance}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.cinzel(
            color: AppColors.cinzaMedio,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: isBalance ? AppColors.amareloVale : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
