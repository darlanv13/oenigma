import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';

class WalletHistoryList extends StatelessWidget {
  final UserWalletModel wallet;

  const WalletHistoryList({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    if (wallet.lastEventRank == null && wallet.lastWonEventName == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'Nenhuma atividade recente.',
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (wallet.lastEventRank != null)
          _HistoryItem(
            icon: FontAwesomeIcons.chartBar,
            title: 'Classificação em Evento',
            subtitle: 'Você ficou em #${wallet.lastEventRank}',
            amountText: '+ Ranking',
            isPositive: true,
          ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final String amountText;
  final bool isPositive;

  const _HistoryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final highlightColor = isPositive
        ? const Color(0xFF10B981) // Pastel Green
        : const Color(0xFFF43F5E); // Pastel Rose

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: highlightColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, color: highlightColor, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: GoogleFonts.orbitron(
              color: highlightColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
