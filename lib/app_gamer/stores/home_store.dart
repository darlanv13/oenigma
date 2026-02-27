import 'package:mobx/mobx.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/services/auth_service.dart';

part 'home_store.g.dart';

class HomeStore = _HomeStore with _$HomeStore;

abstract class _HomeStore with Store {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @observable
  Map<String, dynamic>? data;

  @observable
  bool isGuest = false;

  @action
  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    try {
      final role = await _authService.getUserRole();
      isGuest = role == 'guest';
      data = await _firebaseService.getHomeScreenData();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }
}
