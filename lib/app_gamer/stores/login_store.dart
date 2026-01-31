import 'package:mobx/mobx.dart';
import 'package:oenigma/services/auth_service.dart';

part 'login_store.g.dart';

class LoginStore = _LoginStore with _$LoginStore;

abstract class _LoginStore with Store {
  final AuthService _authService = AuthService();

  @observable
  String email = '';

  @observable
  String password = '';

  @observable
  bool isLoading = false;

  @observable
  bool isPasswordVisible = false;

  @observable
  String? errorMessage;

  @action
  void setEmail(String value) => email = value;

  @action
  void setPassword(String value) => password = value;

  @action
  void togglePasswordVisibility() => isPasswordVisible = !isPasswordVisible;

  @action
  Future<bool> login() async {
    isLoading = true;
    errorMessage = null;
    try {
      final error = await _authService.signInWithEmailAndPassword(email.trim(), password.trim());
      if (error != null) {
        errorMessage = error;
        return false;
      }
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }
}
