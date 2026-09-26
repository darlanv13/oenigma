import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 16.0, color: Color(0xFF475569));
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: Color(0xFF8B5CF6),
      ),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Color(0xFFF0F4F8),
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: Color(0xFFF0F4F8),
      pages: [
        PageViewModel(
          title: "Bem-vindo ao O Enigma!",
          body:
              "A maior caçada ao tesouro digital da sua cidade. Prepare-se para desvendar mistérios e ganhar prêmios reais via Pix.",
          image: const Center(
            child: FaIcon(
              FontAwesomeIcons.compass,
              size: 140,
              color: Color(0xFF8B5CF6),
            ),
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Escolha um Evento",
          body:
              "Acesse a tela inicial e entre no evento ativo. Fique de olho na contagem regressiva!",
          image: const Center(
            child: FaIcon(
              FontAwesomeIcons.calendarDays,
              size: 140,
              color: Colors.greenAccent,
            ),
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Siga as Pistas",
          body:
              "Cada enigma te levará a um local diferente. Use as ferramentas de Mapa e Bússola caso precise de uma ajudinha extra.",
          image: const Center(
            child: FaIcon(
              FontAwesomeIcons.locationDot,
              size: 140,
              color: Colors.blueAccent,
            ),
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Escaneie e Ganhe",
          body:
              "Encontrou o local correto? Escaneie o QR Code escondido. O primeiro a completar todas as fases leva a bolada na carteira!",
          image: const Center(
            child: FaIcon(
              FontAwesomeIcons.qrcode,
              size: 140,
              color: Colors.purpleAccent,
            ),
          ),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      back: const FaIcon(FontAwesomeIcons.arrowLeft, color: Color(0xFF8B5CF6)),
      skip: const Text(
        'Pular',
        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      ),
      next: const FaIcon(FontAwesomeIcons.arrowRight, color: Color(0xFF8B5CF6)),
      done: const Text(
        'Começar',
        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6)),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFCBD5E1),
        activeSize: Size(22.0, 10.0),
        activeColor: Color(0xFF8B5CF6),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
