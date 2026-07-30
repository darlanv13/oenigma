import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_cliente/core/models/user_wallet_model.dart';

class WalletHistoryList extends StatelessWidget {
  final UserWalletModel wallet;

  const WalletHistoryList({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    if (wallet.lastEventRank == null && wallet.lastWonEventName == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'Nenhuma atividade recente.',
            style: TextStyle(color: Colors.white54),
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
        ? const Color(0xFF4CAF50)
        : const Color(0xFFC76F7A);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Fundo painel escuro
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
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
                  style: const TextStyle(
                    color: Color(0xFFDCD6CC),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
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
