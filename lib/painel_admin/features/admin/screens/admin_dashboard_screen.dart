import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/painel_admin/core/utils/app_colors.dart';

import '../repositories/admin_repository.dart';

final adminDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) {
    final repo = ref.read(adminRepositoryProvider);
    return repo.getAdminDashboardData();
  },
);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(adminDashboardProvider);

    return dashboardData.when(
      data: (data) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(data),
              const SizedBox(height: 30),
              _buildSectionTitle('Atividade Recente', FontAwesomeIcons.clock),
              _buildRecentActivity(data),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: primaryAmber),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Erro ao carregar dashboard:\n$err',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.5,
      children: [
        _buildStatBox(
          data['totalEvents']?.toString() ?? '0',
          'Eventos',
          FontAwesomeIcons.calendar,
        ),
        _buildStatBox(
          data['totalEnigmas']?.toString() ?? '0',
          'Enigmas',
          FontAwesomeIcons.puzzlePiece,
        ),
        _buildStatBox(
          data['totalBanners']?.toString() ?? '0',
          'Banners',
          FontAwesomeIcons.image,
        ),
        _buildStatBox(
          data['totalHints']?.toString() ?? '0',
          'Dicas',
          FontAwesomeIcons.lightbulb,
        ),
      ],
    );
  }

  Widget _buildStatBox(String number, String label, dynamic icon) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryAmber.withValues(alpha: 0.04),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: GoogleFonts.orbitron(
              color: primaryAmberLight,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                color: primaryAmber,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 14),
      child: Row(
        children: [
          FaIcon(
            icon,
            color: primaryAmber,
            size: 14,
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.orbitron(
              color: primaryAmber,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryAmber.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Map<String, dynamic> data) {
    return Container(
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
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.circleInfo,
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
                Text(
                  'Bem-vindo ao Painel ADM',
                  style: GoogleFonts.inter(
                    color: primaryAmberLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Comece criando seu primeiro evento!',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8A7A5A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
