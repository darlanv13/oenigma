import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/painel_admin/core/utils/app_colors.dart';

class AdminItemCard extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String statusText;
  final Color statusColor;
  final String subtitle;
  final List<Widget> actions;

  const AdminItemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.statusText,
    required this.statusColor,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryAmber.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryAmber.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryAmber.withValues(alpha: 0.06),
              ),
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: primaryAmber,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: primaryAmberLight,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (statusText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryAmber.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8A7A5A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: actions,
          ),
        ],
      ),
    );
  }
}
