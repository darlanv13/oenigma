import 'package:mobx/mobx.dart';
import 'package:oenigma/services/auth_service.dart';

part 'forgot_password_store.g.dart';

class ForgotPasswordStore = _ForgotPasswordStore with _$ForgotPasswordStore;

abstract class _ForgotPasswordStore with Store {
  final AuthService _authService = AuthService();

  @observable
  String email = '';
  
  @observable
  bool isLoading = false;
  
  @observable
  String? errorMessage;
  
  @observable
  bool success = false;

  @action
  void setEmail(String value) => email = value;

  @action
  Future<void> resetPassword() async {
    isLoading = true;
    errorMessage = null;
    success = false;

    final error = await _authService.sendPasswordResetEmail(email.trim());

    if (error != null) {
      errorMessage = error;
    } else {
      success = true;
    }
    isLoading = false;
  }
}
