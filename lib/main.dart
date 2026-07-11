import 'package:oenigma/core/services/push_notification_service.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/features/auth/screens/auth_wrapper.dart';
import 'package:oenigma/features/auth/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      theme: ThemeData.dark().copyWith(
        primaryColor: primaryAmber,
        scaffoldBackgroundColor: darkBackground,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: darkBackground,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: primaryAmber,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: primaryAmber.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      home: hasSeenOnboarding ? const AuthWrapper() : const OnboardingScreen(),
    );
  }
}
