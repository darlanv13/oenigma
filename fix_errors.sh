#!/bin/bash
# auth_provider.dart
cat << 'AUTH_PROV' > lib/features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/features/auth/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<ParseUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});
AUTH_PROV

# auth_wrapper.dart
cat << 'AUTH_WRAP' > lib/features/auth/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:oenigma/features/home/screens/main_navigation_screen.dart';
import 'package:oenigma/features/auth/screens/login_screen.dart';
import 'package:oenigma/features/admin/screens/admin_auth_wrapper.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final isSuperAdmin = user.get<bool>('super_admin') ?? false;
          final isEditor = user.get<bool>('editor') ?? false;
          final isAdmin = isSuperAdmin || isEditor;

          if (isAdmin) {
            final double screenWidth = MediaQuery.of(context).size.width;
            final bool isDesktop = kIsWeb || screenWidth > 800;

            if (isDesktop) {
              return const AdminAuthWrapper();
            } else {
              return _buildAdminMobileBlockedScreen(context, ref);
            }
          }
          return const MainNavigationScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: primaryAmber)),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: Text('Erro: $error')),
      ),
    );
  }

  Widget _buildAdminMobileBlockedScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.desktop_windows, size: 80, color: primaryAmber),
              const SizedBox(height: 24),
              const Text(
                'Acesso Restrito',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Você é um Administrador. Para gerenciar o O Enigma com eficiência, o Painel Admin deve ser acessado por um computador/Desktop.',
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryTextColor, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final authRepository = ref.read(authRepositoryProvider);
                  await authRepository.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair e Trocar de Conta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
AUTH_WRAP

# admin_auth_wrapper.dart
cat << 'ADMIN_WRAP' > lib/features/admin/screens/admin_auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/features/admin/screens/main_admin_screen.dart';
import 'package:oenigma/features/auth/screens/login_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';

class AdminAuthWrapper extends ConsumerWidget {
  const AdminAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final isSuperAdmin = user.get<bool>('super_admin') ?? false;
          final isEditor = user.get<bool>('editor') ?? false;

          if (isSuperAdmin || isEditor) {
            return const MainAdminScreen();
          }
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: primaryAmber)),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: Text('Erro: $error')),
      ),
    );
  }
}
ADMIN_WRAP

# main_admin_screen.dart
cat << 'MAIN_ADMIN' > lib/features/admin/screens/main_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/features/admin/screens/admin_banners_screen.dart';
import 'package:oenigma/features/admin/screens/admin_dashboard_screen.dart';
import 'package:oenigma/features/admin/screens/admin_events_screen.dart';
import 'package:oenigma/features/admin/screens/admin_finance_screen.dart';
import 'package:oenigma/features/admin/screens/admin_fraud_screen.dart';
import 'package:oenigma/features/admin/screens/admin_tools_screen.dart';
import 'package:oenigma/features/admin/screens/admin_users_screen.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:oenigma/features/auth/screens/login_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class MainAdminScreen extends ConsumerStatefulWidget {
  const MainAdminScreen({super.key});

  @override
  ConsumerState<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends ConsumerState<MainAdminScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminUsersScreen(),
    const AdminEventsScreen(),
    const AdminFinanceScreen(),
    const AdminFraudScreen(),
    const AdminBannersScreen(),
    const AdminToolsScreen(),
  ];

  final List<NavigationRailDestination> _destinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: Text('Usuários'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event),
      label: Text('Eventos'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: Text('Financeiro'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.security_outlined),
      selectedIcon: Icon(Icons.security),
      label: Text('Fraudes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.view_carousel_outlined),
      selectedIcon: Icon(Icons.view_carousel),
      label: Text('Banners'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.build_circle_outlined),
      selectedIcon: Icon(Icons.build_circle),
      label: Text('Ferramentas'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: cardColor,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: primaryAmber),
            unselectedIconTheme: const IconThemeData(color: secondaryTextColor),
            selectedLabelTextStyle: const TextStyle(color: primaryAmber, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: secondaryTextColor),
            destinations: _destinations,
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: 'Sair',
                    onPressed: () async {
                      ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: secondaryTextColor),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
MAIN_ADMIN

sed -i 's/\.uid/\.objectId/' lib/features/event/screens/event_progress_screen.dart
sed -i 's/\.uid/\.objectId/' lib/features/profile/screens/profile_screen.dart
sed -i 's/\.uid/\.objectId/' lib/features/ranking/widgets/ranking_list.dart
