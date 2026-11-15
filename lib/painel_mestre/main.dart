import 'package:flutter/material.dart';
import 'package:oenigma/core/config/env_config.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/painel_mestre/features/admin/screens/main_admin_screen.dart';
import 'package:oenigma/creator_studio/features/creator/screens/main_creator_screen.dart';
import 'package:oenigma/painel_mestre/features/auth/screens/admin_auth_wrapper.dart';
import 'package:oenigma/painel_mestre/features/portal/screens/portal_hub_screen.dart';
import 'package:oenigma/painel_mestre/features/player/screens/creator_challenge_web_player_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.initializeParse();
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O Enigma • Creator Platform',
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
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.verdeVale,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verdeVale,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        var rawName = settings.name ?? '/';

        // 1. No Flutter Web, se a rota inicial for raiz ('/' ou vazio),
        // mas a URL da barra de endereços do navegador tiver fragmento (#/e/slug) ou path:
        if (rawName == '/' || rawName.isEmpty) {
          if (Uri.base.fragment.isNotEmpty) {
            rawName = Uri.base.fragment;
          } else {
            final basePath = Uri.base.path;
            if (basePath.contains('/e/') || basePath.contains('/desafio/')) {
              rawName = basePath;
            }
          }
        }

        // 2. Extrai rota após '#' caso venha formatado como #/e/slug ou /#/e/slug
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

        // 5. Remove barra no final (exceto raiz)
        if (path.length > 1 && path.endsWith('/')) {
          path = path.substring(0, path.length - 1);
        }

        debugPrint('[Router] Rota avaliada: "$path" (raw: "$rawName", Uri.base: "${Uri.base}")');

        // 1. Suporte a rotas de Desafios Públicos: /e/:slug, /desafio/:slug, /player ou /webplayer
        if (path.startsWith('/e/') ||
            path == '/e' ||
            path.startsWith('/desafio/') ||
            path == '/desafio' ||
            path == '/player' ||
            path == '/webplayer') {
          String slug = 'desafio-demo';
          if (path.startsWith('/e/')) {
            slug = path.replaceFirst('/e/', '').split('/').first;
          } else if (path.startsWith('/desafio/')) {
            slug = path.replaceFirst('/desafio/', '').split('/').first;
          } else if (uri.queryParameters.containsKey('slug')) {
            slug = uri.queryParameters['slug']!;
          }

          if (slug.isEmpty || slug == 'e' || slug == 'desafio') {
            slug = 'desafio-demo';
          }

          return MaterialPageRoute(
            builder: (_) => CreatorChallengeWebPlayerScreen(slug: slug),
            settings: settings,
          );
        }

        // 2. Rota explícita para o Creator Studio
        if (path == '/studio' || path == '/creator' || path.startsWith('/studio/')) {
          return MaterialPageRoute(
            builder: (_) => const MainCreatorScreen(),
            settings: settings,
          );
        }

        // 3. Rota explícita para o Super Admin Master
        if (path == '/admin') {
          return MaterialPageRoute(
            builder: (_) => const MainAdminScreen(),
            settings: settings,
          );
        }

        // 4. Rota para Login Administrativo
        if (path == '/login' || path == '/auth') {
          return MaterialPageRoute(
            builder: (_) => const AdminAuthWrapper(),
            settings: settings,
          );
        }

        // 5. Rota Portal Hub Central (raiz / ou /portal)
        return MaterialPageRoute(
          builder: (_) => const PortalHubScreen(),
          settings: settings,
        );
      },
    );
  }
}
