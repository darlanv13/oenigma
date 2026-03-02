import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Handler para notificações em background (Deve ser top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicialize o Firebase se necessário para operações no background,
  // mas como o plugin já o faz parcialmente, basta lidar com a mensagem.
  print("Mensagem em background recebida: \${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Solicita permissão para iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permissão concedida para Push Notifications');

      // Registra o token no Firestore para o usuário atual
      await _saveDeviceToken();

      // Subscreve ao tópico geral para avisos em massa (ex: Novo Evento)
      await _fcm.subscribeToTopic('all_players');

      // Escuta tokens atualizados
      _fcm.onTokenRefresh.listen((newToken) {
        _updateToken(newToken);
      });

      // Configura handlers de mensagens
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Mensagem recebida em foreground: \${message.notification?.title}');
        // Você pode mostrar um SnackBar ou Dialog aqui, ou usar flutter_local_notifications
        // para exibir o alerta mesmo com o app aberto.
      });

    } else {
      print('Permissão para Push Notifications negada.');
    }
  }

  Future<void> _saveDeviceToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateToken(token);
      }
    } catch (e) {
      print("Erro ao obter token FCM: \$e");
    }
  }

  Future<void> _updateToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('players').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
