import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CertificateScreen extends StatefulWidget {
  final String eventName;
  final double prize;

  const CertificateScreen({
    super.key,
    required this.eventName,
    required this.prize,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  @override
  void initState() {
    super.initState();
    SoundService.playBadge();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B1115),
      body: Stack(
        children: [
          // Luzes ambientais suaves (Padrão Enigma)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.verdeVale.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amareloVale.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar Customizada Enigma Style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Navigator.canPop(context)
                          ? GestureDetector(
                              onTap: () {
                                SoundService.playClick();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131D24),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.chevronLeft,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox(width: 38),
                      Text(
                        'CERTIFICADO',
                        style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF131D24),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: const Color(0xFF1E3A45),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.verdeVale.withValues(alpha: 0.15),
                                border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.circleCheck,
                                size: 54.0,
                                color: AppColors.verdeVale,
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            Text(
                              'PARABÉNS!',
                              style: GoogleFonts.cinzel(
                                fontSize: 26.0,
                                fontWeight: FontWeight.w900,
                                color: AppColors.amareloVale,
                                letterSpacing: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              'Você desvendou um enigma no evento:',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: AppColors.cinzaMedio,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              widget.eventName,
                              style: GoogleFonts.cinzel(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'E conquistou:',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: AppColors.cinzaMedio,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              currencyFormat.format(widget.prize),
                              style: GoogleFonts.orbitron(
                                fontSize: 28.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.amareloVale,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28.0),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: AppColors.gradienteVerdeVale,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.verdeVale.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'CONTINUAR JOGANDO',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
