import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Função para fazer upload de um arquivo e retornar a URL de download
  Future<String> uploadFile(String path, Uint8List fileBytes) async {
    try {
      // Cria uma referência no Storage com o caminho fornecido
      final ref = _storage.ref(path);

      // Faz o upload dos bytes do arquivo
      final uploadTask = ref.putData(fileBytes);

      // Aguarda a conclusão do upload
      final snapshot = await uploadTask.whenComplete(() => {});

      // Pega a URL pública de download
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print("Erro no upload do arquivo: $e");
      rethrow;
    }
  }
}
