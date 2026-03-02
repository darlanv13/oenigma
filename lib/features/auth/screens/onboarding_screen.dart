import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oenigma/features/auth/screens/auth_wrapper.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 16.0, color: Colors.white70);
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: primaryAmber),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: darkBackground,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: darkBackground,
      pages: [
        PageViewModel(
          title: "Bem-vindo ao O Enigma!",
          body: "A maior caçada ao tesouro digital da sua cidade. Prepare-se para desvendar mistérios e ganhar prêmios reais via Pix.",
          image: const Center(child: Icon(Icons.explore, size: 140, color: primaryAmber)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Escolha um Evento",
          body: "Acesse a tela inicial e entre no evento ativo. Fique de olho na contagem regressiva!",
          image: const Center(child: Icon(Icons.calendar_month, size: 140, color: Colors.greenAccent)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Siga as Pistas",
          body: "Cada enigma te levará a um local diferente. Use as ferramentas de Mapa e Bússola caso precise de uma ajudinha extra.",
          image: const Center(child: Icon(Icons.location_on, size: 140, color: Colors.blueAccent)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Escaneie e Ganhe",
          body: "Encontrou o local correto? Escaneie o QR Code escondido. O primeiro a completar todas as fases leva a bolada na carteira!",
          image: const Center(child: Icon(Icons.qr_code_scanner, size: 140, color: Colors.purpleAccent)),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      back: const Icon(Icons.arrow_back, color: primaryAmber),
      skip: const Text('Pular', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
      next: const Icon(Icons.arrow_forward, color: primaryAmber),
      done: const Text('Começar', style: TextStyle(fontWeight: FontWeight.w600, color: primaryAmber)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Colors.white24,
        activeSize: Size(22.0, 10.0),
        activeColor: primaryAmber,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
