import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:oenigma/core/config/env_config.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/painel_mestre/features/auth/screens/master_auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await EnvConfig.initializeParse();
  runApp(const ProviderScope(child: MasterPanelApp()));
}

class MasterPanelApp extends StatelessWidget {
  const MasterPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Painel Mestre - O Enigma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.amareloVale,
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardColor: AppColors.darkCardColor,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.amareloVale,
          secondary: AppColors.verdeVale,
          surface: AppColors.darkCardColor,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.sidebarBackground,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.amareloVale,
          foregroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amareloVale,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      home: const MasterAuthWrapper(),
    );
  }
}
