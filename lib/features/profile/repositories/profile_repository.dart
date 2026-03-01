import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>?> getPlayerDetails(String userId) async {
    final doc = await _firestore.collection('players').doc(userId).get();
    return doc.data();
  }

  Future<String> uploadFile(String path, Uint8List fileBytes) async {
    try {
      final ref = _storage.ref(path);
      final uploadTask = ref.putData(fileBytes);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('players').doc(userId).update(data);
  }
}
