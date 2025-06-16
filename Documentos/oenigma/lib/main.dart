import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'auth_wrapper.dart'; // Importa o AuthWrapper
import 'utils/app_colors.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa a formatação de data para pt_BR
  await initializeDateFormatting('pt_BR', null);

  // A chamada para signInAnonymously() foi removida.
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
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textColor),
          bodyMedium: TextStyle(color: textColor),
        ),
      ),
      // A tela inicial agora é o AuthWrapper
      home: const AuthWrapper(),
    );
  }
}
