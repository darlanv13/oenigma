import 'package:flutter/material.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/models/event_model.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFFFFFFF),
            blurRadius: 16,
            offset: Offset(-8, -8),
          ),
          BoxShadow(
            color: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(8, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.solidCircleUser,
                color: Color(0xFF3B82F6),
                size: 24,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Olá, ',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    firstName.isNotEmpty ? firstName : 'Visitante!',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B),
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
              const SizedBox(width: 16),
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
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: isBalance ? const Color(0xFF1E293B) : const Color(0xFF3B82F6),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
