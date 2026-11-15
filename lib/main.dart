import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:oenigma/core/config/env_config.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/screens/portal_hub_screen.dart';

import 'package:oenigma/creator_studio/features/auth/screens/creator_auth_wrapper.dart';
import 'package:oenigma/creator_studio/features/auth/screens/login_screen.dart';
import 'package:oenigma/painel_mestre/features/auth/screens/master_auth_wrapper.dart';
import 'package:oenigma/player/features/auth/screens/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await EnvConfig.initializeParse();
  runApp(const ProviderScope(child: OEnigmaApp()));
}

class OEnigmaApp extends StatelessWidget {
  const OEnigmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O Enigma • Creator Platform & Caça ao Tesouro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.compact,
        primaryColor: AppColors.verdeVale,
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardColor: AppColors.darkCardColor,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.verdeVale,
          secondary: AppColors.amareloVale,
          surface: AppColors.darkCardColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.sidebarBackground,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        var rawName = settings.name ?? '/';

        // 1. No Flutter Web, avalia URLs com fragmentos (#/creator, #/mestre, #/player)
        if (rawName == '/' || rawName.isEmpty) {
          if (Uri.base.fragment.isNotEmpty) {
            rawName = Uri.base.fragment;
          } else {
            final basePath = Uri.base.path;
            if (basePath.contains('/creator') ||
                basePath.contains('/studio') ||
                basePath.contains('/mestre') ||
                basePath.contains('/admin') ||
                basePath.contains('/player')) {
              rawName = basePath;
            }
          }
        }

        // 2. Extrai rota após '#' caso venha formatado como #/creator
        if (rawName.contains('#')) {
          final parts = rawName.split('#');
          if (parts.length > 1 && parts[1].isNotEmpty) {
            rawName = parts[1];
          }
        }

        // 3. Garante que comece com '/'
        if (!rawName.startsWith('/')) {
          rawName = '/$rawName';
        }

        final uri = Uri.parse(rawName);
        var path = uri.path;

        // 4. Remove base-href do GitHub Pages (/oenigma) caso esteja no path
        if (path.startsWith('/oenigma/')) {
          path = path.replaceFirst('/oenigma', '');
        } else if (path == '/oenigma') {
          path = '/';
        }

        // 5. Normaliza barra final
        if (path.length > 1 && path.endsWith('/')) {
          path = path.substring(0, path.length - 1);
        }

        debugPrint('[OEnigma Router] Rota acessada: "$path"');

        // 1. Creator Studio (Web & Mobile Multi-Tenant)
        if (path == '/studio' || path == '/creator' || path.startsWith('/studio/') || path.startsWith('/creator/')) {
          return MaterialPageRoute(
            builder: (_) => const CreatorAuthWrapper(),
            settings: settings,
          );
        }

        // 2. Painel Mestre (Super Admin & Governança de Tenants)
        if (path == '/admin' || path == '/mestre' || path.startsWith('/admin/') || path.startsWith('/mestre/')) {
          return MaterialPageRoute(
            builder: (_) => const MasterAuthWrapper(),
            settings: settings,
          );
        }

        // 3. App Jogador / Caçador
        if (path == '/player' || path == '/cliente' || path.startsWith('/player/') || path.startsWith('/cliente/')) {
          return MaterialPageRoute(
            builder: (_) => const AuthWrapper(),
            settings: settings,
          );
        }

        // 4. Login rápido
        if (path == '/login' || path == '/auth') {
          return MaterialPageRoute(
            builder: (_) => const CreatorLoginScreen(),
            settings: settings,
          );
        }

        // 5. Portal Hub Central (padrão)
        return MaterialPageRoute(
          builder: (_) => const PortalHubScreen(),
          settings: settings,
        );
      },
    );
  }
}
