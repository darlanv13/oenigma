import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oenigma/features/auth/screens/auth_wrapper.dart';

import 'package:oenigma/core/utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  late Animation<double> _fadeAnimation;

  final String _enigmaText = "ENIGMA";

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Cria uma animação de slide para cada letra de "ENIGMA"
    _slideAnimations = List.generate(_enigmaText.length, (index) {
      final startTime = 0.1 * index;
      final endTime = startTime + 0.5;
      return Tween<Offset>(
        begin: const Offset(0, 1.5), // Começa de baixo
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(startTime, endTime, curve: Curves.easeOut),
        ),
      );
    });

    // Animação de fade para a palavra "CITY"
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Inicia a animação
    _animationController.forward();

    // Navega para a próxima tela após a animação
    Timer(const Duration(seconds: 4), _navigateToHome);
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container para a palavra "ENIGMA" animada
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_enigmaText.length, (index) {
                return SlideTransition(
                  position: _slideAnimations[index],
                  child: FadeTransition(
                    opacity: _animationController.drive(
                      CurveTween(curve: Curves.easeOut),
                    ),
                    child: Text(
                      _enigmaText[index],
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                );
              }),
            ),
            // Container para a palavra "CITY" animada
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'CITY',
                style: TextStyle(
                  color: primaryAmber,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
