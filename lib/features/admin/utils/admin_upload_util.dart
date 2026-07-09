import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class AdminUploadUtil {
  static Future<String?> pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return null;

    bool isShowingDialog = false;

    try {
      if (context.mounted) {
        isShowingDialog = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name.isNotEmpty ? pickedFile.name : 'upload.jpg';

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
}
