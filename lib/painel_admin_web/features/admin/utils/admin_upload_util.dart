import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';

class AdminUploadUtil {
  static Future<String?> pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return null;

    return _uploadFile(context, pickedFile);
  }

  static Future<String?> takeAndUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile == null) return null;

    return _uploadFile(context, pickedFile);
  }

  static Future<String?> _uploadFile(
    BuildContext context,
    XFile pickedFile,
  ) async {
    bool isShowingDialog = false;

    try {
      if (context.mounted) {
        isShowingDialog = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final originalBytes = await pickedFile.readAsBytes();

      // Compress the image before uploading to save server space and improve load times
      Uint8List compressedBytes;
      try {
        final result = await FlutterImageCompress.compressWithList(
          originalBytes,
          minHeight: 1080,
          minWidth: 1080,
          quality: 70, // Compressa para 70% da qualidade original
        );
        compressedBytes = result;
      } catch (_) {
        // Fallback case compress fails
        compressedBytes = originalBytes;
      }

      final fileName = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'upload_compressed.jpg';

      final parseFile = ParseWebFile(compressedBytes, name: fileName);
      final response = await parseFile.save();

      if (isShowingDialog && context.mounted) {
        isShowingDialog = false;
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.success && parseFile.url != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload realizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return parseFile.url;
      } else {
        throw Exception(response.error?.message ?? 'Falha ao enviar arquivo');
      }
    } catch (e) {
      if (isShowingDialog && context.mounted) {
        isShowingDialog = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no upload: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return null;
    }
  }

  static Future<String?> pickAndUploadAudio(BuildContext context) async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.audio);

    if (result == null || result.files.isEmpty) return null;

    bool isShowingDialog = false;

    try {
      if (context.mounted) {
        isShowingDialog = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final file = result.files.first;
      final bytes = await file.readAsBytes();

      final fileName = file.name.isNotEmpty ? file.name : 'audio_upload.mp3';

      final parseFile = ParseWebFile(bytes, name: fileName);
      final response = await parseFile.save();

      if (isShowingDialog && context.mounted) {
        isShowingDialog = false;
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.success && parseFile.url != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Áudio enviado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return parseFile.url;
      } else {
        throw Exception(
          response.error?.message ?? 'Falha ao enviar arquivo de áudio',
        );
      }
    } catch (e) {
      if (isShowingDialog && context.mounted) {
        isShowingDialog = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no upload de áudio: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return null;
    }
  }
}
