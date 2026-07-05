import 'dart:typed_data';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class ProfileRepository {
  Future<Map<String, dynamic>?> getPlayerDetails(String userId) async {
    final query = QueryBuilder<ParseUser>(ParseUser.forQuery())
      ..whereEqualTo('objectId', userId);

    final response = await query.query();

    if (response.success && response.results != null && response.results!.isNotEmpty) {
      final user = response.results!.first as ParseUser;

      final Map<String, dynamic> map = {
        'name': user.get<String>('name'),
        'cpf': user.get<String>('cpf'),
        'birthDate': user.get<String>('birthDate'),
        'phone': user.get<String>('phone'),
        'email': user.get<String>('email'),
        'photoURL': user.get<String>('photoURL'),
        'balance': user.get<num>('balance'),
      };
      return map;
    }
    return null;
  }

  Future<String> uploadFile(String path, Uint8List fileBytes) async {
    try {
      final parseFile = ParseWebFile(fileBytes, name: 'profile_image.jpg');
      final response = await parseFile.save();

      if (response.success && response.result != null) {
        final savedFile = response.result as ParseFileBase;
        return savedFile.url ?? '';
      } else {
        throw Exception(response.error?.message ?? 'Failed to upload file');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) throw Exception('Nenhum usuário logado');

    data.forEach((key, value) {
      user.set(key, value);
    });

    final response = await user.save();
    if (!response.success) {
      throw Exception(response.error?.message ?? 'Falha ao atualizar o perfil');
    }
  }
}
