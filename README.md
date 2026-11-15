# O Enigma — Arquitetura Reestruturada

Ecossistema unificado para jogos de exploração tática urbana e caça ao tesouro, composto por 3 módulos especializados:

---

## 🧭 1. Player (`lib/player/`)
> O aplicativo do jogador / caçador de tesouros (Mobile & Web).
- **Home & Trilhas**: Descoberta de eventos ativos, feed de novidades e ranking.
- **Cockpit do Enigma**: Charadas, mapa com geofencing, scanner de QR Code, detector de proximidade, áudios e bússola tática.
- **Carteira do Caçador**: Saldo, depósitos, saques via PIX e arsenal tático.
- **Perfil & Conquistas**: Certificados de vitória e estatísticas de caçador.

---

## 🎨 2. Creator Studio (`lib/creator_studio/`)
> O estúdio dedicado aos criadores de conteúdo e operadores de jogos (Mobile & Desktop/Web).
- **Eventos**: Criação completa de eventos (modalidade Clássico ou Find & Win, datas, localização, banner, regras).
- **Trilha de Fases**: Estruturação de fases, ordem e regras de desbloqueio.
- **Enigmas**: Criação avançada de enigmas (Charadas, Coordenadas GPS, Raio tático, QR Code físico com gerador e exportação PDF, upload de áudio e pistas visuais).
- **Ferramentas & Arsenal**: Bússola Tática, Radar de Proximidade, Mapa de Raio, Temporizadores e Alvos Falsos (Decoys).
- **Dicas (Hints)**: Dicas progressivas por níveis e regras de desbloqueio.
- **Preços & Economia**: Preço de ingressos, precificação de dicas e ferramentas, premiações e projeção de receita do criador.
- **Dashboard do Criador**: Métricas em tempo real de caçadores inscritos, enigmas jogados e faturamento gerado.

---

## 👑 3. Painel Mestre (`lib/painel_mestre/`)
> A central de governança global, infraestrutura e administração da plataforma (Desktop/Web).
- **Dashboard Mestre**: Visão macro da rede de franquias, faturamento global, volume de saques e alertas de segurança.
- **Controle de Tenancy (Multi-Tenant)**: Gestão de Franquias parceiras, cidades de operação, comissões da plataforma (split) e criadores associados.
- **Usuários & Caçadores**: Gestão global de usuários, filtros por papel (player, creator, operator, admin), ajustes de saldo em carteira e banimentos.
- **Financeiro & Saques**: Aprovação de saques PIX, extratos detalhados de depósitos e conciliação de receitas.
- **Gateways de Pagamento**: Configurações de API (Mercado Pago, Asaas, Stripe).
- **Segurança & Anti-Fraude**: Detecção de spoofing GPS (Mock Location), anomalias de teletransporte e logs de auditoria do sistema.
- **Banners Globais**: Gestão de banners promocionais exibidos no app Player.

---

## 📦 Núcleo Compartilhado (`lib/core/`)
- **`config/`**: Inicialização e variáveis de ambiente (Parse/Back4App).
- **`models/`**: Modelos de dados de Evento, Fase, Enigma, Carteira, Ranking e Banners.
- **`services/`**: Serviços de som ambiente, push notifications, hápticos e Location Shield.
- **`utils/`**: Cores do design system (`AppColors`) e utilitários de upload (`AdminUploadUtil`).
- **`widgets/`**: Componentes visuais compartilhados (Logotipos, Cartões, Modais e Fundos).

---

## 🚀 Como Executar

### Via VS Code (Run & Debug)
- **Player (App)**: Executa o app do caçador no dispositivo móvel.
- **Creator Studio (Mobile/Wi-Fi)** ou **Creator Studio (Desktop/Web)**: Executa o Creator Studio.
- **Painel Mestre (Web)**: Executa o Painel Mestre no Chrome.

### Via Terminal
```bash
# Executar Player
flutter run -t lib/player/main.dart

# Executar Creator Studio
flutter run -t lib/creator_studio/main.dart

# Executar Painel Mestre (Web)
flutter run -d chrome -t lib/painel_mestre/main.dart
```

### Compilar para Web
```powershell
.\scripts\build_web.ps1
```
