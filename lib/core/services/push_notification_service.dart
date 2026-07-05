import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class PushNotificationService {
  Future<void> initialize() async {
    // Parse Server Flutter SDK automatically handles device registration
    // internally when initialized, but we can subscribe to channels.
    try {
      final installation = await ParseInstallation.currentInstallation();

      if (!kIsWeb) {
        // Subscreve ao tópico geral para avisos em massa (ex: Novo Evento)
        List<dynamic>? channels = installation.get<List<dynamic>>('channels');
        if (channels == null || !channels.contains('all_players')) {
           installation.subscribeToChannel('all_players');
           await installation.save();
        }
      }

      debugPrint('Push Notifications inicializado com sucesso via Parse');
    } catch (e) {
      debugPrint('Erro ao inicializar Push Notifications: $e');
    }
  }
}
