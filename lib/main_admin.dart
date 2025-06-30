import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:oenigma/admin/admin_login_screen.dart';
import 'package:oenigma/admin/dashboard_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OEnigma - Painel de Admin',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFFFC107),
        // outras customizações de tema
      ),
      home: const AuthGate(),
    );
  }
}

// O AuthGate decide qual tela mostrar: Login ou o Dashboard
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AdminLoginScreen();
        }
        // No futuro, você pode adicionar uma verificação de permissão de admin aqui
        return const AdminDashboardScreen();
      },
    );
  }
}
