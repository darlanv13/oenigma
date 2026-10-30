import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oenigma/app_cliente/features/auth/screens/auth_wrapper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
    }
  }

  Widget _buildIconBadge(dynamic icon, Color iconColor) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withValues(alpha: 0.15),
        border: Border.all(color: iconColor.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: FaIcon(
          icon,
          size: 60,
          color: iconColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = GoogleFonts.inter(fontSize: 15.0, color: AppColors.cinzaMedio, height: 1.5);
    final pageDecoration = PageDecoration(
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 24.0,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      bodyTextStyle: bodyStyle,
      bodyPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
      pageColor: Colors.transparent,
      imagePadding: const EdgeInsets.only(top: 60, bottom: 20),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IntroductionScreen(
        globalBackgroundColor: Colors.transparent,
        pages: [
          PageViewModel(
            title: "Bem-vindo ao O Enigma!",
            body:
                "A maior caçada ao tesouro digital da sua cidade. Prepare-se para desvendar mistérios e ganhar prêmios reais via Pix.",
            image: Center(
              child: _buildIconBadge(
                FontAwesomeIcons.compass,
                AppColors.verdeVale,
              ),
            ),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Escolha um Evento",
            body:
                "Acesse a tela inicial e entre no evento ativo. Fique de olho na contagem regressiva para largar na frente!",
            image: Center(
              child: _buildIconBadge(
                FontAwesomeIcons.calendarDays,
                AppColors.amareloVale,
              ),
            ),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Siga as Pistas",
            body:
                "Cada enigma te levará a um local diferente. Use as ferramentas de Mapa e Bússola caso precise de uma ajudinha extra.",
            image: Center(
              child: _buildIconBadge(
                FontAwesomeIcons.locationDot,
                AppColors.verdeVale,
              ),
            ),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Escaneie e Ganhe",
            body:
                "Encontrou o local correto? Escaneie o QR Code escondido. O primeiro a completar todas as fases leva a bolada na carteira!",
            image: Center(
              child: _buildIconBadge(
                FontAwesomeIcons.qrcode,
                AppColors.amareloVale,
              ),
            ),
            decoration: pageDecoration,
          ),
        ],
        onDone: () => _onIntroEnd(context),
        onSkip: () => _onIntroEnd(context),
        showSkipButton: true,
        skipOrBackFlex: 0,
        nextFlex: 0,
        showBackButton: false,
        back: const FaIcon(FontAwesomeIcons.arrowLeft, color: AppColors.verdeVale),
        skip: Text(
          'Pular',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.cinzaMedio),
        ),
        next: const FaIcon(FontAwesomeIcons.arrowRight, color: AppColors.verdeVale, size: 18),
        done: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppColors.gradienteVerdeVale,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.verdeVale.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            'Começar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
          ),
        ),
        curve: Curves.fastLinearToSlowEaseIn,
        controlsMargin: const EdgeInsets.all(16),
        dotsDecorator: const DotsDecorator(
          size: Size(8.0, 8.0),
          color: Colors.white24,
          activeSize: Size(22.0, 8.0),
          activeColor: AppColors.verdeVale,
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
        ),
      ),
    );
  }
}
