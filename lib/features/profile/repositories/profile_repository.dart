import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'dart:typed_data';

class ProfileRepository {

  Future<Map<String, dynamic>?> getPlayerDetails(String userId) async {
    final query = QueryBuilder<ParseUser>(ParseUser.forQuery())..whereEqualTo('objectId', userId);
    final response = await query.query();
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      final user = response.results!.first as ParseUser;
      // Convert ParseUser data to map or extract needed fields.
      // E.g., user.toJson() could work but typically we want standard fields.
      return {
        'name': user.get<String>('name'),
        'cpf': user.get<String>('cpf'),
        'birthDate': user.get<String>('birthDate'),
        'phone': user.get<String>('phone'),
        'email': user.get<String>('email'),
        'photoURL': user.get<String>('photoURL'),
        'balance': user.get<num>('balance'),
      };
    }
    return null;
  }

  Future<String> uploadFile(String path, Uint8List fileBytes) async {
    try {
      final parseFile = ParseWebFile(fileBytes, name: path.split('/').last);
      final response = await parseFile.save();
      if (response.success) {
        return parseFile.url!;
      } else {
        throw Exception(response.error?.message ?? 'Upload failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final user = ParseUser(null, null, null)..objectId = userId;
    data.forEach((key, value) {
      user.set(key, value);
    });
    final response = await user.save();
    if (!response.success) {
      throw Exception(response.error?.message ?? 'Update failed');
    }
  }
}
