import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'app_gamer/screens/splash_screen.dart'; // <-- 1. IMPORTE A NOVA TELA
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('pt_BR', null);

  runApp(const EnigmaCityApp());
}

class EnigmaCityApp extends StatelessWidget {
  const EnigmaCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enigma City',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFFC107),
        scaffoldBackgroundColor: const Color(0xFF121212),
        // fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
        ),
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: textColor,
          displayColor: textColor,
        ),
      ),
      // --- 2. ALTERE A TELA INICIAL ---
      // A tela inicial agora é a SplashScreen.
      home: const SplashScreen(),
    );
  }
}
