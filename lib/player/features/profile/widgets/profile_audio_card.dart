import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Cartão de configuração de som ambiente
class ProfileAudioCard extends StatefulWidget {
  const ProfileAudioCard({super.key});

  @override
  State<ProfileAudioCard> createState() => _ProfileAudioCardState();
}

class _ProfileAudioCardState extends State<ProfileAudioCard> {
  @override
  Widget build(BuildContext context) {
    final isMuted = SoundService.isAmbientMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.verdeVale.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.35), width: 1),
                ),
                child: Center(
                  child: FaIcon(
                    isMuted ? FontAwesomeIcons.volumeXmark : FontAwesomeIcons.music,
                    color: AppColors.verdeVale,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOM AMBIENTE',
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMuted ? 'Trilha de mistério silenciada' : 'Música de suspense ativada',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF91A3AE),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: !isMuted,
            activeTrackColor: AppColors.verdeVale.withValues(alpha: 0.6),
            activeThumbColor: AppColors.verdeVale,
            onChanged: (enabled) {
              HapticFeedback.lightImpact();
              setState(() {
                SoundService.toggleAmbientMute();
              });
            },
          ),
        ],
      ),
    );
  }
}
