import 'dart:developer' as dev;
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// Configuração Centralizada de Segredos e Chaves de API (SecOps Zero Trust).
///
/// Todas as chaves podem ser injetadas em tempo de build/execução via:
/// `--dart-define=PARSE_APP_ID=seu_app_id`
/// `--dart-define=PARSE_CLIENT_KEY=sua_client_key`
/// `--dart-define=PARSE_SERVER_URL=https://...`
///
/// OU através de arquivo .env com `--dart-define-from-file=.env`.
class EnvConfig {
  EnvConfig._();

  /// Back4App / Parse Application ID
  static const String parseAppId = String.fromEnvironment(
    'PARSE_APP_ID',
    defaultValue: 'ThUDHY1ayK6ah9JFm9YLHTDF9FKMHTU096eqkDKK',
  );

  /// Back4App / Parse Client Key (Chave pública do cliente, NUNCA MasterKey)
  static const String parseClientKey = String.fromEnvironment(
    'PARSE_CLIENT_KEY',
    defaultValue: 'ZyTU944E8jmtJuDu4lL2mh5tcQR7AErvhL0xNY5d',
  );

  /// URL da API Parse Server
  static const String parseServerUrl = String.fromEnvironment(
    'PARSE_SERVER_URL',
    defaultValue: 'https://parseapi.back4app.com',
  );

  /// URL de LiveQuery do Parse Server
  static const String parseLiveQueryUrl = String.fromEnvironment(
    'PARSE_LIVE_QUERY_URL',
    defaultValue: 'https://parseapi.back4app.com',
  );

  /// Chave da API do Google Maps para renderização de mapa/geolocalização
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB2XsDjw1-Bee9RCSfgH_e-aokhRq5Hd80',
  );

  /// Mascara chaves sensíveis para logs seguros (SecOps Zero Trust)
  static String mask(String value) {
    if (value.length <= 8) return '****';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  /// Inicializa o cliente Parse com as chaves protegidas e sanitizadas
  static Future<void> initializeParse() async {
    dev.log(
      'Inicializando Parse com App ID: ${mask(parseAppId)} | Server: $parseServerUrl',
      name: 'EnvConfig',
    );

    await Parse().initialize(
      parseAppId,
      parseServerUrl,
      clientKey: parseClientKey,
      liveQueryUrl: parseLiveQueryUrl.isNotEmpty ? parseLiveQueryUrl : null,
      autoSendSessionId: true,
      debug: false,
    );
  }
}

