import 'package:flutter/material.dart';
import 'package:oenigma/features/admin/screens/admin_auth_wrapper.dart';
import 'package:oenigma/core/utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O Enigma - Admin',
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
          ),
        ),
      ),
      home: const AdminAuthWrapper(),
    );
  }
}