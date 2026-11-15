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

  /// Cadastro Rápido & Seguro de Criador / Influenciador para o Creator Studio
  Future<String?> signUpCreatorWithEmailAndPassword({
    required String name,
    required String handle,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();
      var cleanHandle = handle.trim();
      if (!cleanHandle.startsWith('@') && cleanHandle.isNotEmpty) {
        cleanHandle = '@$cleanHandle';
      }
      final cleanPhone = phone?.trim() ?? '';

      // 1. Tenta criar via Cloud Code com MasterKey (protegido contra restrições de schema CLP)
      try {
        final cloudFunction = ParseCloudFunction('registerCreator');
        final params = <String, dynamic>{
          'name': name.trim(),
          'email': cleanEmail,
          'password': cleanPassword,
          'channelHandle': cleanHandle,
          if (cleanPhone.isNotEmpty) 'phone': cleanPhone,
        };
        final cfResponse = await cloudFunction.execute(parameters: params);
        if (cfResponse.success && cfResponse.result != null) {
          // Registro concluído no servidor! Efetua login para carregar a sessão no SDK local
          final loginErr = await signInWithEmailAndPassword(cleanEmail, cleanPassword);
          return loginErr;
        } else if (cfResponse.error != null) {
          final errCode = cfResponse.error!.code;
          final errMsg = cfResponse.error!.message;
          // Se a Cloud Function não estiver disponível no servidor ainda (erro 141), faz fallback
          if (errCode != 141) {
            if (errMsg.toLowerCase().contains('already') ||
                errMsg.toLowerCase().contains('existe')) {
              return 'Já existe uma conta cadastrada com este e-mail. Faça login ou recupere sua senha.';
            }
            return errMsg;
          }
        }
      } catch (cfErr) {
        debugPrint('Fallback CloudFunction registerCreator: $cfErr');
      }

      // 2. Fallback direto via ParseUser SDK local
      final user = ParseUser(cleanEmail, cleanPassword, cleanEmail);
      user.set('name', name.trim());
      user.set('email', cleanEmail);
      user.set('username', cleanEmail);
      user.set('channelHandle', cleanHandle);
      user.set('role', 'creator');
      user.set('isCreator', true);
      user.set('balance', 0.0);
      user.set('totalEarned', 0.0);
      if (cleanPhone.isNotEmpty) {
        user.set('phone', cleanPhone);
      }

      final response = await user.signUp();
      if (response.success && response.result is ParseUser) {
        _currentUser = response.result as ParseUser;
        _authStateController.add(_currentUser);
        return null;
      } else {
        final msg = response.error?.message ?? 'Falha ao registrar criador.';
        if (msg.toLowerCase().contains('already exists') ||
            msg.toLowerCase().contains('already taken') ||
            msg.toLowerCase().contains('account already')) {
          return 'Já existe uma conta cadastrada com este e-mail. Faça login ou recupere sua senha.';
        }
        return msg;
      }
    } catch (e) {
      return e.toString();
    }
  }

  /// Login Rápido & Seguro para o Criador (por E-mail ou @canal)
  Future<String?> signInCreator({
    required String identifier,
    required String password,
  }) async {
    try {
      var cleanId = identifier.trim();
      final cleanPass = password.trim();

      // Se informou @handle ou identificador de canal, tenta resolver o e-mail registrado
      if (cleanId.startsWith('@') || (!cleanId.contains('@') && !cleanId.contains('.'))) {
        try {
          final cloudFn = ParseCloudFunction('findCreatorEmail');
          final cfRes = await cloudFn.execute(parameters: {'identifier': cleanId});
          if (cfRes.success && cfRes.result != null && cfRes.result is Map) {
            final emailFound = cfRes.result['email'];
            if (emailFound is String && emailFound.isNotEmpty) {
              cleanId = emailFound;
            }
          }
        } catch (_) {}
      }

      cleanId = cleanId.toLowerCase();
      final user = ParseUser(cleanId, cleanPass, cleanId);
      final response = await user.login();

      if (response.success && response.result is ParseUser) {
        final loggedUser = response.result as ParseUser;

        // Se o usuário era 'player' e logou pelo Creator Studio, assegura permissão de criador
        final currentRole = loggedUser.get<String>('role');
        if (currentRole == null || currentRole == 'player') {
          loggedUser.set('role', 'creator');
          loggedUser.set('isCreator', true);
          try {
            await loggedUser.save();
          } catch (_) {}
        }

        _currentUser = loggedUser;
        _authStateController.add(_currentUser);
        return null;
      } else {
        final msg = response.error?.message ?? 'Erro ao efetuar login.';
        if (msg.toLowerCase().contains('invalid username/password') ||
            msg.toLowerCase().contains('unauthorized')) {
          return 'E-mail/usuário ou senha incorretos. Verifique suas credenciais.';
        }
        return msg;
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
