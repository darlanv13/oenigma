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
            .child('profile_pictures')
            .child('$userId.jpg');
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

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
