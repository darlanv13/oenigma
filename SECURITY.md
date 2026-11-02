# Política e Arquitetura de Segurança (SecOps & Zero Trust) - O Enigma

Este documento descreve as diretrizes mandatórias de segurança, arquitetura Zero Trust e proteção de chaves/segredos adotadas no projeto **O Enigma**.

---

## 1. Princípios Fundamentais (Zero Trust)

1. **Nunca Confie no Cliente (Zero Trust Client):**
   - O aplicativo móvel e o painel web rodam em ambientes não controlados pelo servidor.
   - Nenhuma decisão crítica (validação de coordenadas de tesouro, respostas corretas de enigmas, aprovação de saques Pix, manipulação de saldo) é executada ou decidida no cliente.
   - O servidor (Cloud Functions no Back4App) é a única autoridade da verdade.

2. **Ocultação de Payloads e Coordenadas:**
   - As funções de consulta pública (`getSafeEventEnigmas`) limpam os campos `code`, respostas e `compassCoords` antes de responder ao cliente.
   - Pistas bloqueadas (`getEnigmaHints`) têm seus conteúdos ocultados pelo backend até que sejam legitimamente adquiridas pelo jogador.

---

## 2. Gerenciamento de Chaves e Segredos

| Chave / Credencial | Onde é Utilizada | Nível de Acesso | Onde Deve Ser Guardada |
| :--- | :--- | :--- | :--- |
| **Parse App ID** | Flutter (Cliente & Admin) | Público | `.env` / `--dart-define` / `EnvConfig` |
| **Parse Client Key** | Flutter (Cliente & Admin) | Público Restrito | `.env` / `--dart-define` / `EnvConfig` |
| **Parse Master Key** | Back4App Cloud Functions | **Crítico / Confidencial** | **EXCLUSIVO do servidor Back4App**. NUNCA no app cliente. |
| **Google Maps API Key** | Android / Web | Público c/ Restrição | `local.properties` (Android) / `.env` |
| **Tokens Gateways Pix (Asaas / Mercado Pago / EFI)** | Cloud Functions | **Crítico / Confidencial** | Classe `GatewayConfig` no banco de dados via MasterKey / Back4App Environment Variables. NUNCA no app. |

---

## 3. Como Utilizar Variáveis de Ambiente no Flutter

O projeto utiliza a classe centralizada [`EnvConfig`](lib/core/config/env_config.dart).

### 3.1. Usando arquivo `.env` local:
1. Copie o modelo `.env.example` para `.env`:
   ```bash
   cp .env.example .env
   ```
2. Adicione suas chaves reais no `.env`.
3. Execute ou compile o Flutter passando o arquivo:
   ```bash
   flutter run --dart-define-from-file=.env
   # ou
   flutter build web --dart-define-from-file=.env
   flutter build apk --dart-define-from-file=.env
   ```

### 3.2. Usando flags `--dart-define`:
```bash
flutter build apk \
  --dart-define=PARSE_APP_ID=seu_app_id \
  --dart-define=PARSE_CLIENT_KEY=sua_client_key \
  --dart-define=PARSE_SERVER_URL=https://parseapi.back4app.com \
  --dart-define=GOOGLE_MAPS_API_KEY=sua_maps_key
```

---

## 4. Proteção de Chaves no Android

- A chave do Google Maps no `AndroidManifest.xml` não é exposta diretamente no código fonte do repositório; ela é injetada via `${MAPS_API_KEY}` pelo Gradle.
- Para definir uma chave local sem commitá-la, adicione em `android/local.properties`:
  ```properties
  MAPS_API_KEY=AIzaSy...
  ```
  O arquivo `android/local.properties` já é ignorado pelo Git por padrão.

---

## 5. Auditoria de Arquivos Ignorados (.gitignore)

Os seguintes arquivos e padrões são bloqueados pelo `.gitignore` para prevenir vazamento acidental de segredos:
- `.env`, `.env.*`, `*.env`
- `*.keystore`, `*.jks`, `key.properties`
- `b4a-cloud/.parse.local`, `.parse.local`
- `google-services.json`, `GoogleService-Info.plist`
- `functions/serviceAccountKey.json`, `functions/certs/`

