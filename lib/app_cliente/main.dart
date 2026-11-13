import 'package:oenigma/core/config/env_config.dart';
import 'package:oenigma/core/services/push_notification_service.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_cliente/features/auth/screens/auth_wrapper.dart';
import 'package:oenigma/app_cliente/features/auth/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oenigma/core/widgets/app_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await EnvConfig.initializeParse();

  await PushNotificationService().initialize();

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    ProviderScope(child: EnigmaCityApp(hasSeenOnboarding: hasSeenOnboarding)),
  );
}

class EnigmaCityApp extends StatefulWidget {
  final bool hasSeenOnboarding;
  const EnigmaCityApp({super.key, required this.hasSeenOnboarding});

  @override
  State<EnigmaCityApp> createState() => _EnigmaCityAppState();
}

class _EnigmaCityAppState extends State<EnigmaCityApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicia a música ambiente de mistério contínua
    SoundService.startAmbient();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SoundService.resumeAmbient();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      SoundService.pauseAmbient();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SoundService.stopAmbient();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'O Enigma',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.verdeVale,
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCardColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.verdeVale,
          brightness: Brightness.dark,
          primary: AppColors.verdeVale,
          secondary: AppColors.amareloVale,
          surface: AppColors.darkCardColor,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verdeVale,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.cinzel(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return AppBackground(
          opacity: 0.05,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: widget.hasSeenOnboarding ? const AuthWrapper() : const OnboardingScreen(),
    );
  }
}
