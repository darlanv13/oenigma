import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminItemCard extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String statusText;
  final Color statusColor;
  final String subtitle;
  final Widget? tagWidget;
  final List<Widget> actions;
  final VoidCallback? onTap;

  const AdminItemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.statusText,
    required this.statusColor,
    required this.subtitle,
    this.tagWidget,
    this.actions = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.verdeVale.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: AppColors.verdeVale,
                size: 18,
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
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tagWidget != null) ...[
                      const SizedBox(width: 8),
                      tagWidget!,
                    ],
                    const SizedBox(width: 8),
                    if (statusText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: card,
      );
    }

    return card;
  }
}
