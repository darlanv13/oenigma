import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class AuthRepository {
  final BehaviorSubject<ParseUser?> _authStateSubject = BehaviorSubject<ParseUser?>();

  AuthRepository() {
    _initAuthState();
  }

  Future<void> _initAuthState() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      final response = await ParseUser.getCurrentUserFromServer(user.sessionToken!);
      if (response?.success ?? false) {
        _authStateSubject.add(response!.result as ParseUser);
      } else {
        await user.logout();
        _authStateSubject.add(null);
      }
    } else {
      _authStateSubject.add(null);
    }
  }

  Stream<ParseUser?> get authStateChanges => _authStateSubject.stream;

  // Synchronous getter returning the latest cached value
  ParseUser? get currentUser => _authStateSubject.valueOrNull;

  Future<String?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = ParseUser(email.trim(), password.trim(), null);
      final response = await user.login();
      if (response.success) {
        _authStateSubject.add(response.result as ParseUser);
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
      final user = ParseUser(email.trim(), password.trim(), null);
      final response = await user.login();
      if (response.success) {
        final loggedInUser = response.result as ParseUser;
        final isSuperAdmin = loggedInUser.get<bool>('super_admin') ?? false;
        final isEditor = loggedInUser.get<bool>('editor') ?? false;

        if (isSuperAdmin || isEditor) {
          _authStateSubject.add(loggedInUser);
          return null;
        } else {
          await loggedInUser.logout();
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
      user.set('photoURL', null);

      final response = await user.signUp(allowWithoutEmail: false);
      if (response.success) {
        final newUser = response.result as ParseUser;
        _authStateSubject.add(newUser);
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
      final user = ParseUser(null, null, email.trim());
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
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      await user.logout();
    }
    _authStateSubject.add(null);
  }
}
