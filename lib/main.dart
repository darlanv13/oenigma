import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/firebase_options.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/features/auth/screens/auth_wrapper.dart';
import 'package:oenigma/features/auth/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(ProviderScope(child: EnigmaCityApp(hasSeenOnboarding: hasSeenOnboarding)));
}

class EnigmaCityApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const EnigmaCityApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'O Enigma',
      theme: ThemeData.dark().copyWith(
        primaryColor: primaryAmber,
        scaffoldBackgroundColor: darkBackground,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: darkBackground,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: hasSeenOnboarding ? const AuthWrapper() : const OnboardingScreen(),
    );
  }
}
