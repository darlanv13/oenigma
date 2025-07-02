import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Função de login padrão para os jogadores no app móvel
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

  // --- NOVA FUNÇÃO DE LOGIN APENAS PARA ADMINS ---
  Future<String?> signInAdminWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // 1. Tenta fazer o login normalmente
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        return "Ocorreu um erro inesperado.";
      }

      // 2. Busca o token do usuário para verificar as permissões (claims)
      // O 'true' força a atualização do token para pegar as permissões mais recentes.
      final idTokenResult = await user.getIdTokenResult(true);

      // 3. Verifica se a permissão 'role' é igual a 'admin'
      if (idTokenResult.claims?['role'] == 'admin') {
        // Se for admin, o login é um sucesso.
        return null;
      } else {
        // 4. Se NÃO for admin, desloga o usuário imediatamente e retorna um erro.
        await _auth.signOut();
        return "Acesso negado. Esta conta não possui privilégios de administrador.";
      }
    } on FirebaseAuthException catch (e) {
      // Retorna erros de login padrão (senha errada, usuário não encontrado)
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

  Future<String?> updateUserProfile({
    required String userId,
    File? imageFile,
    required String phone,
    required String birthDate,
  }) async {
    try {
      String? photoURL;
      if (imageFile != null) {
        final ref = _storage
            .ref()
            .child('profile_pictures') // Pasta principal
            .child(userId) // Cria uma sub-pasta com o ID do utilizador
            .child(
              'profile_image.jpg',
            ); // Nome do ficheiro dentro da pasta do utilizador
        await ref.putFile(imageFile);
        photoURL = await ref.getDownloadURL();
      }

      Map<String, dynamic> dataToUpdate = {
        'phone': phone,
        'birthDate': birthDate,
      };
      if (photoURL != null) {
        dataToUpdate['photoURL'] = photoURL;
      }

      await _firestore.collection('players').doc(userId).update(dataToUpdate);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  //Função Recuperar Senha
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      // Retorna uma mensagem de erro mais amigável
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
