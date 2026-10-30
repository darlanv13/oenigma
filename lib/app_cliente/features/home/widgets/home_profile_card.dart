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
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  color: AppColors.verdeVale.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.verdeVale,
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.solidUser,
                    color: AppColors.verdeVale,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Olá,',
                    style: GoogleFonts.inter(
                      color: AppColors.cinzaMedio,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    firstName.isNotEmpty ? firstName : 'Visitante!',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
                color: Colors.white12,
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
          style: GoogleFonts.inter(
            color: AppColors.cinzaMedio,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: isBalance ? AppColors.amareloVale : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
