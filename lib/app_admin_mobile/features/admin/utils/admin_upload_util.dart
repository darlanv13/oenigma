import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminUploadUtil {
  static Future<String?> pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return null;

    if (!context.mounted) return null;
    return _uploadFile(context, pickedFile);
  }

  static Future<String?> takeAndUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile == null) return null;

    if (!context.mounted) return null;
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
              const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
        );
      }

      final bytes = await pickedFile.readAsBytes();
      final String rawName = pickedFile.name.isNotEmpty ? pickedFile.name : 'upload';
      final bool isPng = rawName.toLowerCase().endsWith('.png') ||
          (bytes.length > 8 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47);

      final String fileName = isPng
          ? (rawName.toLowerCase().endsWith('.png') ? rawName : '$rawName.png')
          : (rawName.isNotEmpty ? rawName : 'upload.jpg');

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
              content: Text('Upload realizado com sucesso!'),
              backgroundColor: AppColors.verdeVale,
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

  static Future<String?> pickAndUploadPng(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (file == null) return null;

      final extension = (file.extension ?? '').toLowerCase();
      final name = file.name.toLowerCase();

      if (extension != 'png' && !name.endsWith('.png')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, selecione apenas arquivos de imagem em formato .PNG com fundo transparente.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return null;
      }

      final bytes = await file.readAsBytes();

      bool isShowingDialog = false;
      if (context.mounted) {
        isShowingDialog = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
        );
      }

      final fileName = file.name.isNotEmpty ? file.name : 'prize_image.png';
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
              content: Text('Foto do prêmio (PNG) enviada com sucesso!'),
              backgroundColor: AppColors.verdeVale,
            ),
          );
        }
        return parseFile.url;
      } else {
        throw Exception(response.error?.message ?? 'Falha ao enviar arquivo PNG');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no upload de PNG: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return null;
    }
  }

  static Future<String?> pickAndUploadAudio(BuildContext context) async {
    final file = await FilePicker.pickFile(type: FileType.audio);

    if (file == null) return null;

    bool isShowingDialog = false;

    try {
      if (context.mounted) {
        isShowingDialog = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
        );
      }

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
              backgroundColor: AppColors.verdeVale,
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
