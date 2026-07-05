import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/features/auth/screens/auth_wrapper.dart';
import 'package:oenigma/core/utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Parse Server
  const keyApplicationId = '34Q5Q0x8L5Q5Q0x8L5Q5Q0x8L5Q5Q0x8';
  const keyClientKey = '34Q5Q0x8L5Q5Q0x8L5Q5Q0x8L5Q5Q0x8';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, autoSendSessionId: true);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const ProviderScope(child: OEnigmaApp()));
  });
}

class OEnigmaApp extends StatelessWidget {
  const OEnigmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O Enigma',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        primaryColor: primaryAmber,
        cardColor: cardColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryAmber,
          secondary: Colors.orangeAccent,
          surface: cardColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBackground,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAmber,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryAmber),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
