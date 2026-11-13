import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class AuthRepository {
  // Controller de transmissão para mudanças manuais de estado de autenticação
  final StreamController<ParseUser?> _authStateController =
      StreamController<ParseUser?>.broadcast();

  ParseUser? _currentUser;
  ParseUser? get currentUser => _currentUser;

  /// Stream reativo com garantia de replay do estado atual:
  /// Qualquer novo ouvinte recebe imediatamente o usuário em cache / persistido no localStorage,
  /// garantindo que ao recarregar a página (F5) o estado não fique perdido.
  Stream<ParseUser?> get authStateChanges async* {
    if (_currentUser != null) {
      yield _currentUser;
    } else {
      try {
        final user = await ParseUser.currentUser() as ParseUser?;
        if (user != null) {
          _currentUser = user;
          yield _currentUser;
          // Validação remota de token em segundo plano sem bloquear a inicialização da UI
          _validateSessionInBackground(user);
        } else {
          yield null;
        }
      } catch (e) {
        debugPrint('Erro ao obter usuário persistido: $e');
        yield null;
      }
    }
    yield* _authStateController.stream;
  }

  AuthRepository() {
    _initCurrentUser();
  }

  Future<void> _initCurrentUser() async {
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user != null) {
        _currentUser = user;
        _authStateController.add(_currentUser);
        await _validateSessionInBackground(user);
      } else {
        _currentUser = null;
        _authStateController.add(null);
      }
    } catch (e) {
      debugPrint('Erro ao inicializar sessão Parse: $e');
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  /// Valida o token de sessão com o servidor Back4App em segundo plano.
  /// Se a conexão falhar ou o servidor demorar, o admin continua trabalhando
  /// com os dados em cache no localStorage.
  /// O logout só ocorre se o servidor responder explicitamente com código 209
  /// (Token Inválido ou Sessão Expirada).
  Future<void> _validateSessionInBackground(ParseUser user) async {
    try {
      final token = user.sessionToken;
      if (token == null || token.isEmpty) {
        await signOut();
        return;
      }

      final response = await ParseUser.getCurrentUserFromServer(token);
      if (response != null && response.success && response.result is ParseUser) {
        _currentUser = response.result as ParseUser;
        _authStateController.add(_currentUser);
      } else if (response?.error?.code == 209) {
        // Código 209: Session token is invalid or expired
        debugPrint('Sessão revogada pelo servidor. Efetuando logout do admin.');
        await signOut();
      }
    } catch (e) {
      debugPrint('Aviso: Falha temporária na validação de sessão remota: $e');
    }
  }

  Future<String?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = ParseUser(email.trim(), password.trim(), email.trim());
      final response = await user.login();
      if (response.success && response.result is ParseUser) {
        _currentUser = response.result as ParseUser;
        _authStateController.add(_currentUser);
        return null;
      } else {
        return response.error?.message ?? "Ocorreu um erro desconhecido.";
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInAdminWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = ParseUser(email.trim(), password.trim(), email.trim());
      final response = await user.login();
      if (response.success && response.result is ParseUser) {
        final ParseUser loggedUser = response.result as ParseUser;
        final isAdmin = loggedUser.get<bool>('isAdmin') ?? false;
        final role = loggedUser.get<String>('role') ?? 'player';

        if (role == 'admin' || role == 'creator' || isAdmin) {
          _currentUser = loggedUser;
          _authStateController.add(_currentUser);
          return null;
        } else {
          await loggedUser.logout();
          return "Acesso negado. Esta conta não possui privilégios de administrador.";
        }
      } else {
        return response.error?.message ?? "Ocorreu um erro desconhecido.";
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String cpf,
    required String birthDate,
    required String phone,
  }) async {
    try {
      final user = ParseUser(email.trim(), password.trim(), email.trim());
      user.set('name', fullName);
      user.set('cpf', cpf);
      user.set('birthDate', birthDate);
      user.set('phone', phone);
      user.set('balance', 0);
      user.set('role', 'player');

      final response = await user.signUp();
      if (response.success && response.result is ParseUser) {
        _currentUser = response.result as ParseUser;
        _authStateController.add(_currentUser);
        return null;
      } else {
        return response.error?.message ?? "Ocorreu um erro desconhecido.";
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      final ParseUser user = ParseUser(null, null, email.trim());
      final response = await user.requestPasswordReset();
      if (response.success) {
        return null;
      } else {
        return response.error?.message ?? "Ocorreu um erro desconhecido.";
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user != null) {
        await user.logout();
      } else if (_currentUser != null) {
        await _currentUser!.logout();
      }
    } catch (e) {
      debugPrint('Aviso ao efetuar logout: $e');
    }
    _currentUser = null;
    _authStateController.add(null);
  }
}
