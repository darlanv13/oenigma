import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Ocorreu um erro desconhecido.";
    }
  }

  Future<String?> signInAdminWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = userCredential.user;
      if (user == null) {
        return "Ocorreu um erro inesperado.";
      }
      final idTokenResult = await user.getIdTokenResult(true);
      if (idTokenResult.claims?['role'] == 'admin') {
        return null;
      } else {
        await _auth.signOut();
        return "Acesso negado. Esta conta não possui privilégios de administrador.";
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Ocorreu um erro desconhecido.";
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
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );
      User? newUser = userCredential.user;
      if (newUser != null) {
        await _firestore.collection('players').doc(newUser.uid).set({
          'name': fullName,
          'cpf': cpf,
          'birthDate': birthDate,
          'phone': phone,
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'photoURL': null,
          'balance': 0,
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Ocorreu um erro desconhecido.";
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Nenhum utilizador encontrado para este email.';
      }
      return e.message ?? "Ocorreu um erro desconhecido.";
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
