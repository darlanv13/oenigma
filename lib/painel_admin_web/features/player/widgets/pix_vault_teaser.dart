import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class PixVaultTeaser extends StatelessWidget {
  final String prize;
  final String creatorName;
  final int totalPhases;
  final int currentPhase;
  final bool isPlaying;

  const PixVaultTeaser({
    super.key,
    required this.prize,
    required this.creatorName,
    this.totalPhases = 3,
    this.currentPhase = 1,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalPhases > 0 ? (currentPhase / totalPhases).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF131F27), Color(0xFF0D1419)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.amareloVale.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Ícone animado do Cofre
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF182933),
                  border: Border.all(
                    color: AppColors.amareloVale.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amareloVale.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.vault,
                    color: AppColors.amareloVale,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Textos de status do cofre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'COFRE TRANCADO',
                                style: GoogleFonts.orbitron(
                                  color: Colors.redAccent,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'por $creatorName',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.cinzaMedio,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prize,
                      style: GoogleFonts.orbitron(
                        color: AppColors.amareloVale,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isPlaying) ...[
            const SizedBox(height: 12),
            // Barra de Progresso da Quebra do Segredo do Cofre
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DESCRIPTOGRAFIA DO COFRE',
                      style: GoogleFonts.orbitron(
                        color: AppColors.cinzaMedio,
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'FASE $currentPhase DE $totalPhases (${(progress * 100).toInt()}%)',
                      style: GoogleFonts.orbitron(
                        color: Colors.greenAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF0C1318),
                    color: Colors.greenAccent,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
