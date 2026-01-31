import 'package:mobx/mobx.dart';
import 'package:oenigma/services/auth_service.dart';

part 'signup_store.g.dart';

class SignUpStore = _SignUpStore with _$SignUpStore;

abstract class _SignUpStore with Store {
  final AuthService _authService = AuthService();

  @observable
  String name = '';

  @observable
  String email = '';

  @observable
  String password = '';

  @observable
  String confirmPassword = '';

  @observable
  bool isLoading = false;

  @observable
  bool isPasswordVisible = false;

  @observable
  bool isConfirmPasswordVisible = false;

  @observable
  String? errorMessage;

  @observable
  bool success = false;

  @action
  void setName(String value) => name = value;

  @action
  void setEmail(String value) => email = value;

  @action
  void setPassword(String value) => password = value;

  @action
  void setConfirmPassword(String value) => confirmPassword = value;

  @action
  void togglePasswordVisibility() => isPasswordVisible = !isPasswordVisible;

  @action
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible = !isConfirmPasswordVisible;

  @action
  Future<void> signUp() async {
    isLoading = true;
    errorMessage = null;
    success = false;

    if (password != confirmPassword) {
      errorMessage = "Senhas não conferem";
      isLoading = false;
      return;
    }

    final error = await _authService.signUpWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
      fullName: name.trim(),
      cpf: '',
      birthDate: '',
      phone: '',
    );

    if (error != null) {
      errorMessage = error;
    } else {
      success = true;
    }
    isLoading = false;
  }
}
