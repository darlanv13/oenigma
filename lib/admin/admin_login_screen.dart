import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final error = await _authService.signInWithEmailAndPassword(
      _emailController.text,
      _passwordController.text,
    );
    if (mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Painel de Admin",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: "Senha"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator(color: primaryAmber)
                      : ElevatedButton(
                          onPressed: _login,
                          child: const Text("Entrar"),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
