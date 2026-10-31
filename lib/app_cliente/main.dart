import 'package:oenigma/core/services/push_notification_service.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
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
  await Parse().initialize(
    'ThUDHY1ayK6ah9JFm9YLHTDF9FKMHTU096eqkDKK', // Replace with valid App ID
    'https://parseapi.back4app.com', // Replace with valid Server URLrsrs
    clientKey:
        'ZyTU944E8jmtJuDu4lL2mh5tcQR7AErvhL0xNY5d', // Replace with valid Client Key
    autoSendSessionId: true,
  );

  await PushNotificationService().initialize();

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    ProviderScope(child: EnigmaCityApp(hasSeenOnboarding: hasSeenOnboarding)),
  );
}

class EnigmaCityApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const EnigmaCityApp({super.key, required this.hasSeenOnboarding});

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
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
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
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
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
      home: hasSeenOnboarding ? const AuthWrapper() : const OnboardingScreen(),
    );
  }
}
