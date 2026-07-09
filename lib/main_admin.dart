// lib/main_admin.dart

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/admin/screens/admin_auth_wrapper.dart'; // Crie este arquivo a seguir
import 'package:oenigma/core/utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Parse().initialize(
    'ThUDHY1ayK6ah9JFm9YLHTDF9FKMHTU096eqkDKK', // Replace with valid App ID
    'https://parseapi.back4app.com', // Replace with valid Server URL
    clientKey:
        'ZyTU944E8jmtJuDu4lL2mh5tcQR7AErvhL0xNY5d', // Replace with valid Client Key
    autoSendSessionId: true,
  );
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Painel de Gerenciamento - OEnigma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryAmber,
        scaffoldBackgroundColor: darkBackground,
        fontFamily: 'Poppins',
        cardColor: cardColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: cardColor,
          elevation: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryAmber,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAmber,
            foregroundColor: darkBackground,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const AdminAuthWrapper(),
    );
  }
}
