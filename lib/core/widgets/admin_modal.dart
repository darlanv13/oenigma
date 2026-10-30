import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminModal extends StatelessWidget {
  final String title;
  final Widget child;
  final double maxWidth;

  const AdminModal({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.sidebarBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 60,
              offset: const Offset(0, 30),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.verdeVale.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.close,
              color: AppColors.cinzaMedio,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
