import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'dart:developer' as dev;

class PushNotificationService {
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      final installation = await ParseInstallation.currentInstallation();

      final List<dynamic> channels = installation.get<List<dynamic>>('channels') ?? [];
      if (!channels.contains('all_players')) {
        installation.setAddUnique('channels', 'all_players');
        await installation.save();
        dev.log('Inscrito no canal all_players', name: 'PushNotificationService');
      }

      final user = await ParseUser.currentUser() as ParseUser?;
      if (user != null) {
        installation.set('user', user);
        await installation.save();
        dev.log('Instalação vinculada ao usuário', name: 'PushNotificationService');
      }

    } catch (e, stack) {
      dev.log('Erro ao inicializar ParseInstallation', name: 'PushNotificationService', error: e, stackTrace: stack);
    }
  }
}
