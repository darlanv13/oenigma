import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

/// Grade de métricas do caçador (Saldo, Expedições, Vitórias e XP)
class ProfileMetricsGrid extends StatelessWidget {
  final double balance;
  final int jogados;
  final int vencidos;
  final int xp;

  const ProfileMetricsGrid({
    super.key,
    required this.balance,
    required this.jogados,
    required this.vencidos,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ProfileMetricCard(
                title: 'SALDO ATUAL',
                value: 'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
                icon: FontAwesomeIcons.coins,
                accentColor: const Color(0xFFF3A522),
                bgTint: const Color(0xFFF3A522).withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfileMetricCard(
                title: 'EXPEDIÇÕES',
                value: jogados.toString(),
                icon: FontAwesomeIcons.mapLocationDot,
                accentColor: const Color(0xFF00A4B4),
                bgTint: const Color(0xFF00A4B4).withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ProfileMetricCard(
                title: 'VITÓRIAS',
                value: vencidos.toString(),
                icon: FontAwesomeIcons.trophy,
                accentColor: const Color(0xFFFFB300),
                bgTint: const Color(0xFFFFB300).withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfileMetricCard(
                title: 'EXPERIÊNCIA',
                value: '$xp XP',
                icon: FontAwesomeIcons.medal,
                accentColor: const Color(0xFF4CAF50),
                bgTint: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Cartão individual de métrica tática
class ProfileMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final FaIconData icon;
  final Color accentColor;
  final Color bgTint;

  const ProfileMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.bgTint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
            ),
            child: Center(
              child: FaIcon(icon, color: accentColor, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cinzel(
                    color: const Color(0xFF88A0AD),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
