import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/utils/app_colors.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      // 1. Autenticação Padrão (Gera o token de segurança para as Functions)
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passController.text.trim(),
          );

      final user = userCredential.user;

      if (user != null) {
        // 2. SEGURANÇA: Força a atualização do token para baixar as 'claims' mais recentes
        // Isso garante que se você acabou de dar 'admin' no banco, o app saiba imediatamente.
        final idTokenResult = await user.getIdTokenResult(true);

        // 3. Verifica se o usuário tem a permissão 'admin' definida nas suas Functions
        final isAdmin = idTokenResult.claims?['role'] == 'admin';

        if (!isAdmin) {
          // Se não for admin, desloga imediatamente e mostra erro
          await FirebaseAuth.instance.signOut();
          throw FirebaseAuthException(
            code: 'access-denied',
            message: 'Este usuário não tem permissão de Administrador.',
          );
        }

        // Se for admin, o AuthWrapper (no main_admin.dart) vai redirecionar automaticamente para o Dashboard
      }
    } on FirebaseAuthException catch (e) {
      String message = "Erro desconhecido";
      if (e.code == 'user-not-found') message = "Usuário não encontrado.";
      if (e.code == 'wrong-password') message = "Senha incorreta.";
      if (e.code == 'invalid-email') message = "Email inválido.";
      if (e.code == 'access-denied') message = e.message ?? "Acesso negado.";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 64,
                color: primaryAmber,
              ),
              const SizedBox(height: 20),
              const Text(
                "Painel Admin",
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: textColor),
                decoration: const InputDecoration(
                  labelText: "Email Admin",
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.email, color: primaryAmber),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryAmber),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: textColor),
                decoration: const InputDecoration(
                  labelText: "Senha",
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.lock, color: primaryAmber),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryAmber),
                  ),
                ),
                onSubmitted: (_) => _isLoading ? null : _login(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmber,
                    foregroundColor: darkBackground,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: darkBackground,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "ENTRAR",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
