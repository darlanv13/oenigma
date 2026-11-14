# O Enigma — Plataforma de Desafios para Influenciadores 🚀

**O Enigma** é uma plataforma SaaS para a Creator Economy onde influenciadores e criadores de conteúdo criam caças ao tesouro e desafios misteriosos para seu público, engajam sua audiência e monetizam através de ingressos Pix e microtransações de dicas.

---

## 🌟 Pilares da Plataforma

```
Influenciador (Studio Web) ──> Cria Desafio & Gera Link ──> Posta nos Stories/Bio
                                                                    │
                                                                    ▼
Seguidores (Web Player)    <── Resolve Enigmas & Pistas <── Abre Link no Navegador
```

1. **Creator Studio Web**: Aplicação fácil e intuitiva para o influenciador lançar desafios em menos de 5 minutos, anexar vídeos de teaser e pistas (YouTube, Shorts, TikTok, Reels), habilitar ferramentas táticas (Cifra de César, Morse, QR Code) e acompanhar métricas em tempo real.
2. **Web Player do Seguidor (Zero Atrito)**: O fã clica no link compartilhado nos Stories (`oenigma.com.br/e/:slug`), visualiza a Landing Page do desafio e joga diretamente no navegador do smartphone (sem precisar baixar aplicativo de 60MB).
3. **Split Financeiro Automático**: A plataforma processa os pagamentos Pix via Gateways integrados (Mercado Pago, Asaas, AbacatePay, Bacen BRCode) e divide a receita automaticamente entre o influenciador e a plataforma.

---

## 💰 Modelo de Monetização Aprovado

### 1. Desafios Pagos (Pay-to-Play):
* O influenciador define uma taxa simbólica de inscrição de **R$ 5,00 a R$ 20,00** para os seguidores concorrerem ao super prêmio (dinheiro ou item).
* A plataforma processa o Pix e retém uma **taxa de serviço de 15%**.
* O influenciador recebe **85% líquido** diretamente na sua carteira da plataforma para saque via Pix.

### 2. Super Dicas (R$ 1,99 no Pix):
* O jogo pode ser gratuito ou pago; se um seguidor travar em um enigma e quiser a dica decisiva, ele pode pagar **R$ 1,99 no Pix instantâneo**.
* A dica secreta é liberada na hora na tela do jogador, e o valor é dividido automaticamente.

---

## 🏗️ Estrutura de Pastas

```
lib/
├── core/
│   ├── models/
│   │   ├── event_model.dart            # Multi-tenancy (creatorId, slug, videoTeaserUrl, price, split)
│   │   ├── enigma_model.dart           # Fases, vídeo da pista, superHintText (R$ 1,99), ferramentas
│   │   ├── creator_transaction_model.dart # Registro contábil de splits e vendas de ingressos/dicas
│   │   └── creator_profile_model.dart  # Perfil do influencer, chave Pix e saldo
│   └── utils/
│       └── app_colors.dart             # Identidade visual oficial
│
├── painel_admin_web/
│   ├── features/
│   │   ├── creator/screens/            # O NOVO CREATOR STUDIO
│   │   │   ├── creator_dashboard_screen.dart       # KPIs de faturamento, participantes e desafios
│   │   │   ├── creator_challenge_wizard_screen.dart # Assistente em 4 passos para criar desafios
│   │   │   ├── creator_finance_screen.dart         # Extrato detalhado de Pix e botão de saque
│   │   │   └── creator_links_screen.dart           # Gerador de links, QR Code e prévia de Stories
│   │   ├── player/screens/             # O WEB PLAYER DO SEGUIDOR
│   │   │   ├── creator_challenge_web_player_screen.dart # Landing page, Checkout Pix e Enigmas
│   │   │   └── widgets/
│   │   │       ├── pix_checkout_dialog.dart        # Modal Pix com timer e detecção em tempo real
│   │   │       ├── cesar_cipher_tool_dialog.dart   # Decodificador interativo de Cifra de César
│   │   │       └── morse_code_tool_dialog.dart     # Tradutor de Código Morse
│   │   └── admin/screens/
│   │       └── main_admin_screen.dart  # Seletor de Modo: [🚀 Studio] vs [⚙️ Super Admin]
│   └── main.dart                       # Roteamento inteligente (/e/:slug e /)
│
b4a-cloud/cloud/
├── main.js                             # Cloud Functions: createChallengePixTicket, createSuperHintPix, split
└── financial_service.js                # Integrações Pix (Asaas, Mercado Pago, AbacatePay, Bacen)
```

---

## 🌐 Rotas & Acesso Online (GitHub Pages)

A aplicação está configurada para deploy automático no GitHub Pages:
* **Portal Hub Central**: `https://darlanv13.github.io/oenigma/`
* **Painel Super Admin**: `https://darlanv13.github.io/oenigma/#/admin`
* **Creator Studio (Influenciador)**: `https://darlanv13.github.io/oenigma/#/studio`
* **Web Player Público (Page Player Demo)**: `https://darlanv13.github.io/oenigma/#/player`
* **Desafio do Influenciador**: `https://darlanv13.github.io/oenigma/#/e/:slug`

---

## 🚀 Como Executar Localmente

### Creator Studio, Web Player & Admin:
```bash
flutter run -d chrome -t lib/painel_admin_web/main.dart
```

* **Portal Hub**: `http://localhost:PORT/`
* **Super Admin**: `http://localhost:PORT/#/admin`
* **Creator Studio**: `http://localhost:PORT/#/studio`
* **Web Player Demo**: `http://localhost:PORT/#/player`
* **Acesso do Seguidor / Desafio Específico**: `http://localhost:PORT/#/e/:slug-do-desafio`
