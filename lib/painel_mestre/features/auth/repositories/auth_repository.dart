import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class MasterAuthRepository {
  final StreamController<ParseUser?> _authStateController =
      StreamController<ParseUser?>.broadcast();

  ParseUser? _currentUser;
  ParseUser? get currentUser => _currentUser;

  Stream<ParseUser?> get authStateChanges async* {
    if (_currentUser != null) {
      yield _currentUser;
    } else {
      try {
        final user = await ParseUser.currentUser() as ParseUser?;
        if (user != null) {
          _currentUser = user;
          yield _currentUser;
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

  MasterAuthRepository() {
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
        debugPrint('Sessão revogada pelo servidor. Efetuando logout do Painel Mestre.');
        await signOut();
      }
    } catch (e) {
      debugPrint('Aviso: Falha temporária na validação de sessão remota: $e');
    }
  }

  Future<String?> signInMasterWithEmailAndPassword(
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

        if (role == 'admin' || isAdmin) {
          _currentUser = loggedUser;
          _authStateController.add(_currentUser);
          return null;
        } else {
          await loggedUser.logout();
          return "Acesso restrito: Apenas Administradores do Painel Mestre têm permissão de acesso.";
        }
      } else {
        return response.error?.message ?? "Credenciais inválidas.";
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
