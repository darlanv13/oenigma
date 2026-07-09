import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'dart:async';

class AuthRepository {
  // We use a StreamController to broadcast auth state changes manually in Parse
  final StreamController<ParseUser?> _authStateController =
      StreamController<ParseUser?>.broadcast();

  Stream<ParseUser?> get authStateChanges => _authStateController.stream;

  ParseUser? _currentUser;
  ParseUser? get currentUser => _currentUser;

  AuthRepository() {
    _initCurrentUser();
  }

  Future<void> _initCurrentUser() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      final response = await ParseUser.getCurrentUserFromServer(
        user.sessionToken!,
      );
      if (response?.success ?? false) {
        _currentUser = response!.result;
      } else {
        _currentUser = null;
      }
    }
    _authStateController.add(_currentUser);
  }

  Future<String?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = ParseUser(email.trim(), password.trim(), email.trim());
      final response = await user.login();
      if (response.success) {
        _currentUser = response.result;
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
      if (response.success) {
        final ParseUser loggedUser = response.result;
        final isAdmin = loggedUser.get<bool>('isAdmin') ?? false;
        final role = loggedUser.get<String>('role') ?? 'player';

        if (role == 'admin' || isAdmin) {
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
      if (response.success) {
        _currentUser = response.result;
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
    if (_currentUser != null) {
      await _currentUser!.logout();
      _currentUser = null;
      _authStateController.add(null);
    }
  }
}
