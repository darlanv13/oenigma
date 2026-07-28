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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.only(bottom: 18),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.solidCircleUser,
                color: Color(0xFFC0A060),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Olá, ',
                style: const TextStyle(
                  color: Color(0xFFB0A07A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                firstName.isNotEmpty ? firstName : 'Visitante!',
                style: const TextStyle(
                  color: Color(0xFFF0E6C5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
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
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7A7A7A),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: isBalance ? const Color(0xFFF0E6C5) : const Color(0xFFC0A060),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
