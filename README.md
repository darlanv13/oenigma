O ENIGMA
DOCUMENTO MESTRE DE PRODUTO E ENGENHARIA
Product Requirements Document (PRD) — Versão 1.0
Produto: O Enigma
Categoria: Social Gamification / Creator Economy
Mercado inicial: Brasil
Idioma: Português brasileiro
Plataformas: Web responsiva, PWA e aplicativos Android/iOS em etapas posteriores
Modelo de negócio: Compra única de créditos por experiência
Público principal: Microinfluenciadores e criadores de conteúdo
Público secundário: Seguidores e comunidades digitais
Monetização complementar futura: Ferramentas premium e campanhas patrocinadas
Status: Especificação aprovada para início do planejamento técnico

1. VISÃO EXECUTIVA
1.1. Definição do produto
O Enigma é uma plataforma digital que permite que influenciadores criem, publiquem e administrem experiências interativas para seus seguidores.
Os criadores poderão desenvolver:

Caças ao tesouro digitais e presenciais.
Perguntas e desafios de conhecimento.
Missões individuais e coletivas.
Competições de habilidades.
Experiências temáticas.
Atividades para comunidades de fãs.

Os seguidores poderão descobrir experiências, participar, acumular XP, desbloquear conquistas e competir em rankings.
A proposta é transformar seguidores passivos em participantes ativos.
1.2. Problema que O Enigma resolve
Atualmente, influenciadores utilizam Instagram, TikTok e WhatsApp para publicar conteúdos e interagir com suas comunidades.
Entretanto, essas plataformas não oferecem um ambiente próprio e integrado para:

Criar experiências interativas personalizadas.
Organizar missões em etapas.
Acompanhar a participação dos seguidores.
Criar rankings persistentes.
Desenvolver identidade gamificada dos fãs.
Gerar experiências físicas conectadas ao ambiente digital.

O Enigma oferece essa infraestrutura.
1.3. Proposta de valor
Para influenciadores:
Transformar seguidores em uma comunidade participativa, com ferramentas simples para criar experiências e acompanhar resultados.
Para seguidores:
Participar de experiências divertidas, conquistar XP, desenvolver reputação e interagir com seus criadores favoritos.
Para marcas, futuramente:
Patrocinar experiências e mensurar a participação das comunidades.
1.4. Posicionamento
O Enigma não será uma rede social tradicional, um aplicativo exclusivamente de sorteios ou apenas um gerador de QR Codes.
Será uma plataforma de experiências sociais gamificadas.

2. OBJETIVOS E INDICADORES
2.1. Objetivos do negócio

Atrair microinfluenciadores.
Converter influenciadores em criadores ativos.
Estimular a entrada dos seguidores por links compartilháveis.
Criar recorrência de publicação de experiências.
Monetizar por meio de créditos.
Desenvolver efeitos de rede entre criadores e comunidades.

2.2. Metas iniciais
Metas experimentais para os primeiros ciclos de validação:



Indicador
Meta




Usuários cadastrados
10.000


Criadores cadastrados
100


Criadores que publicaram experiências
60


Experiências publicadas
300


Participantes ativos mensais
3.000


Criadores recorrentes
40%


Criadores pagantes
10%



As metas deverão ser revisadas com base nos dados reais do piloto.
2.3. Métrica principal
Experiências publicadas por criador ativo por mês.
Essa métrica demonstra se os influenciadores encontram valor suficiente para continuar utilizando a plataforma.
Indicadores complementares:

Taxa de conversão de visitante em cadastro.
Taxa de conclusão de missões.
Participantes por experiência.
Compartilhamentos por participante.
Retenção de usuários em D7 e D30.
Taxa de recompra de créditos.
Receita média por criador pagante.
Custo de aquisição de criadores.


3. PERFIS DE USUÁRIOS
3.1. Creator — Influenciador
Usuário responsável pela criação e administração de experiências.
Perfil inicial:

Microinfluenciadores.
Criadores entre 5 mil e 100 mil seguidores.
Criadores de conteúdo regional.
Criadores de entretenimento.
Criadores de lifestyle.
Criadores de tecnologia.
Criadores de humor.
Criadores de conteúdo educacional.

Necessidades:

Criar experiências rapidamente.
Compartilhar experiências.
Engajar seguidores.
Visualizar resultados.
Administrar créditos.
Gerenciar suas comunidades.

3.2. Player — Seguidor
Usuário que participa das experiências.
Necessidades:

Encontrar experiências.
Seguir influenciadores.
Participar gratuitamente das modalidades abertas.
Acumular XP.
Conquistar medalhas.
Consultar seu histórico.
Compartilhar conquistas.

3.3. Administrator — Administrador
Responsável pela operação e segurança da plataforma.
Necessidades:

Gerenciar contas.
Moderar conteúdo.
Investigar denúncias.
Suspender atividades.
Controlar transações.
Consultar indicadores.
Auditar ações administrativas.

3.4. Brand — Marca patrocinadora
Perfil reservado para uma fase futura.
Permissões:

Criar campanhas comerciais.
Contratar experiências.
Selecionar influenciadores.
Acompanhar resultados.
Consultar relatórios.


4. MODALIDADES DE EXPERIÊNCIA
O MVP terá quatro modalidades principais.
4.1. O ENIGMA HUNT
Caça ao tesouro baseada em pistas e localização.
Funcionalidades:

Cadastro de localização de referência.
Criação de pistas.
Liberação progressiva de pistas.
QR Code de validação.
Validação de etapas.
Controle de participantes.
Encerramento da missão.

Requisitos de segurança:

Coordenadas exatas não devem ser expostas antes da etapa apropriada.
QR Codes devem possuir identificadores aleatórios.
Códigos devem poder expirar.
A validação deve ocorrer no servidor.
Deve existir proteção contra repetição de submissões.

A modalidade inicial será baseada em XP, sem distribuição de prêmios aleatórios.
4.2. O ENIGMA QUIZ
Desafios de perguntas e respostas.
Funcionalidades:

Perguntas de múltipla escolha.
Perguntas de resposta objetiva.
Limite de tentativas configurável.
Tempo de resposta opcional.
Pontuação por acerto.
Resultado automático.
Ranking.

O gabarito nunca poderá ser enviado ao cliente antes da resposta.
4.3. O ENIGMA CHALLENGE
Desafios criativos.
Exemplos:

Criar uma foto temática.
Gravar uma coreografia.
Responder a um desafio.
Produzir conteúdo com determinado tema.

Funcionalidades:

Descrição da missão.
Instruções.
Envio de texto ou mídia.
Prazo de participação.
Avaliação manual ou por critérios objetivos.
Aprovação e concessão de XP.

Conteúdo enviado por seguidores ficará sujeito à moderação.
4.4. O ENIGMA MISSION
Missões sequenciais ou independentes.
Exemplos:

Resolver três enigmas.
Completar cinco etapas.
Responder uma sequência de perguntas.
Cumprir atividades em dias diferentes.

Funcionalidades:

Criação de etapas.
Condições de desbloqueio.
Barra de progresso.
Histórico de conclusão.
XP por etapa.
XP por conclusão.


5. EXPERIÊNCIA DO USUÁRIO
5.1. Fluxo do influenciador

Acessa O Enigma.
Cria uma conta.
Seleciona o perfil Creator.
Personaliza seu perfil.
Acessa o painel.
Escolhe o tipo de experiência.
Configura a missão.
Visualiza uma prévia.
Publica.
Compartilha o link.
Acompanha os participantes.
Consulta resultados.

5.2. Fluxo do seguidor

Recebe um link de experiência.
Acessa a página pública.
Visualiza o criador e a missão.
Cria uma conta ou entra na conta existente.
Confirma participação.
Realiza as atividades.
Recebe XP quando cumprir os critérios.
Consulta sua posição no ranking.
Compartilha sua conquista.

O acesso à página pública e à prévia da missão não deve exigir cadastro.
5.3. Fluxo de compra

Creator acessa sua carteira.
Seleciona pacote de créditos.
Escolhe pagamento via Pix.
O backend cria uma cobrança.
O provedor confirma o pagamento por webhook.
O servidor verifica autenticidade e status.
Uma transação é registrada.
Os créditos são disponibilizados.
O histórico é atualizado.

Não liberar créditos com base apenas em uma tela de confirmação apresentada pelo navegador.

6. ESTRUTURA DE TELAS
6.1. Área pública

Página inicial.
Descobrir experiências.
Explorar criadores.
Página pública do influenciador.
Página de experiência.
Termos de uso.
Política de privacidade.
Central de ajuda.

6.2. Área Creator

Dashboard.
Perfil do criador.
Criar experiência.
Selecionar modalidade.
Configurar missão.
Configurar etapas.
Configurar regras.
Pré-visualização.
Publicar experiência.
Minhas experiências.
Participantes.
Resultados.
Carteira de créditos.
Comprar créditos.
Histórico de transações.
Configurações.

6.3. Área Player

Feed de experiências.
Explorar.
Criadores favoritos.
Minhas missões.
Detalhes da missão.
Tela de participação.
Mapa.
Leitor de QR Code.
Perfil O ENIGMA ID.
Histórico de XP.
Medalhas.
Rankings.
Notificações.
Configurações.

6.4. Área administrativa

Visão geral.
Usuários.
Criadores.
Experiências.
Denúncias.
Moderação.
Transações.
Créditos.
Logs de auditoria.
Configurações globais.


7. REGRAS DE NEGÓCIO
7.1. Contas

Cada usuário deve possuir identificador único.
E-mail ou telefone deverá ser verificado conforme o método de autenticação escolhido.
Usuários podem possuir perfil Player e Creator.
Alterações de permissões devem ser controladas no servidor.
Contas suspensas não podem publicar ou participar enquanto durar a suspensão.

7.2. Experiências
Estados permitidos:

DRAFT.
SCHEDULED.
ACTIVE.
PAUSED.
COMPLETED.
CANCELLED.

Regras:

Uma experiência só poderá ser publicada se todos os campos obrigatórios estiverem preenchidos.
Experiências publicadas terão identificador público.
O criador poderá pausar uma experiência.
O criador não poderá alterar retroativamente regras que afetem participações já registradas.
Experiências encerradas permanecerão disponíveis no histórico.
Experiências denunciadas poderão ser suspensas para análise.

7.3. Participação

O usuário deve estar autenticado para registrar participação.
Cada experiência poderá definir limite de participantes.
Cada missão poderá estabelecer limite de tentativas.
O sistema deve impedir submissões duplicadas indevidas.
Os critérios de conclusão devem ser verificáveis.
O usuário deverá receber feedback sobre sua participação.

7.4. XP
XP significa Experience Points.
Regras:

XP não é dinheiro.
XP não pode ser sacado.
XP não pode ser transferido entre contas.
XP não representa probabilidade de ganhar prêmios.
XP é concedido por atividades válidas.
Cada concessão deve gerar um registro auditável.
Uma mesma atividade não poderá conceder XP duplicado quando não permitido.

Tabela inicial de pontuação:



Atividade
XP




Concluir missão simples
20


Acertar pergunta
10


Completar etapa
5


Concluir desafio criativo aprovado
30


Completar experiência
50


Conquista especial
Configurável



A pontuação poderá ser configurada por modalidade, respeitando limites globais antifraude.
7.5. Níveis
Proposta inicial:

Nível 1: Iniciante.
Nível 2: Explorador.
Nível 3: Desbravador.
Nível 4: Especialista.
Nível 5: Lenda O Enigma.

Os limites de XP deverão ser configuráveis no painel administrativo.
7.6. Créditos
Créditos são unidades de consumo da plataforma, compradas pelos criadores.
Regras:

Créditos não são XP.
Créditos não são moeda eletrônica.
Créditos não são transferíveis.
Créditos não podem ser sacados.
Créditos só podem ser utilizados em funcionalidades autorizadas.
Toda compra e utilização deve gerar movimentação contábil.
O saldo não poderá ficar negativo.
O consumo de crédito deverá ocorrer atomicamente.
Estornos devem ser registrados e auditáveis.


8. MODELO DE MONETIZAÇÃO
8.1. Modelo principal
Venda de créditos por pagamento único.
Tabela comercial inicial:



Pacote
Créditos
Preço




Inicial
1
R$ 5,00


Básico
5
R$ 19,90


Criador
15
R$ 49,90


Avançado
50
R$ 129,90



Preços sujeitos a validação comercial.
8.2. Consumo de créditos
Modelo inicial proposto:

QUIZ: 1 crédito.
CHALLENGE: 1 crédito.
MISSION: 1 crédito.
HUNT: 2 créditos.

Uma experiência gratuita de demonstração poderá ser oferecida a cada novo criador, conforme regras de prevenção contra abuso.
8.3. Gratuidade para seguidores
Participação gratuita nas experiências públicas do MVP.
Não cobrar para:

Criar conta Player.
Consultar rankings.
Visualizar perfis públicos.
Acumular XP.
Participar de missões abertas.

8.4. Receitas futuras

Campanhas patrocinadas.
Ferramentas avançadas.
Relatórios de desempenho.
Personalização premium.
Serviços para marcas.

Não implementar divisão de receita com criadores antes de definir contratos, regras fiscais, fluxo financeiro e obrigações legais.

9. ARQUITETURA DE SOFTWARE
9.1. Estratégia arquitetural
Adotar inicialmente um monólito modular.
Não começar com microsserviços.
Justificativa:

Menor complexidade operacional.
Menor custo de infraestrutura.
Desenvolvimento mais rápido.
Facilidade de manutenção.
Separação lógica dos domínios.
Possibilidade de extrair serviços no futuro.

9.2. Stack tecnológica
Frontend:

Next.js.
React.
TypeScript.
Tailwind CSS.
Componentes acessíveis.

Backend:

Next.js Route Handlers ou camada de API dedicada.
TypeScript.
Validação de dados.
Serviços de domínio.
Processamento assíncrono quando necessário.

Banco:

PostgreSQL.
Supabase.

Infraestrutura:

Vercel.
Supabase Storage.
Serviço de e-mail transacional.
Provedor de pagamentos Pix.
Serviço de mapas.
Monitoramento de erros.

9.3. Organização de módulos

Authentication.
Users.
Creators.
Profiles.
Experiences.
Missions.
Participation.
Gamification.
Wallet.
Payments.
Notifications.
Moderation.
Administration.
Analytics.

9.4. Estrutura de diretórios sugerida
o-enigma/
├── apps/
│   ├── web/
│   └── mobile/
├── packages/
│   ├── ui/
│   ├── types/
│   ├── validators/
│   └── config/
├── src/
│   ├── modules/
│   │   ├── auth/
│   │   ├── users/
│   │   ├── creators/
│   │   ├── experiences/
│   │   ├── missions/
│   │   ├── participation/
│   │   ├── gamification/
│   │   ├── wallet/
│   │   ├── payments/
│   │   ├── notifications/
│   │   ├── moderation/
│   │   └── admin/
│   ├── shared/
│   └── infrastructure/
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── seed/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
└── docs/

A estrutura poderá ser adaptada à organização final do repositório.

10. BANCO DE DADOS
Banco principal: PostgreSQL.
Todas as tabelas de negócio devem possuir identificadores UUID, timestamps e índices apropriados.
10.1. Entidades principais
users

id
auth_user_id
email
phone
display_name
avatar_url
birth_date, quando necessário
status
created_at
updated_at

creator_profiles

id
user_id
username
biography
profile_image
banner_image
category
instagram_url
tiktok_url
verification_status
created_at

experiences

id
creator_id
title
slug
description
type
cover_image
status
visibility
starts_at
ends_at
participant_limit
rules
xp_configuration
credit_cost
published_at
created_at
updated_at

missions

id
experience_id
title
description
mission_type
sequence
configuration
xp_reward
max_attempts
status
created_at

mission_steps

id
mission_id
title
description
step_type
sequence
validation_configuration
created_at

participations

id
experience_id
user_id
status
progress
started_at
completed_at
updated_at

Restrição única: experience_id + user_id, quando a modalidade permitir somente uma inscrição por usuário.
mission_submissions

id
mission_id
participation_id
submission_data
validation_status
reviewed_by
submitted_at
reviewed_at

xp_ledger

id
user_id
experience_id
mission_id
transaction_type
amount
description
idempotency_key
created_at

user_levels

user_id
current_level
total_xp
updated_at

badges

id
name
description
image_url
criteria
status

user_badges

id
user_id
badge_id
awarded_at

wallets

id
creator_id
credit_balance
updated_at

O saldo apresentado será uma projeção do livro de movimentações.
credit_transactions

id
wallet_id
type
amount
balance_after
reference_type
reference_id
idempotency_key
created_at

Tipos:

PURCHASE.
CONSUMPTION.
REFUND.
BONUS.
ADJUSTMENT.

payments

id
creator_id
provider
provider_payment_id
amount
currency
status
external_reference
paid_at
created_at

follows

id
follower_user_id
creator_id
created_at

Restrição única para impedir duplicação.
notifications

id
user_id
type
title
message
read_at
created_at

reports

id
reporter_user_id
target_type
target_id
reason
description
status
reviewed_by
created_at

audit_logs

id
actor_id
action
resource_type
resource_id
metadata
created_at

10.2. Relacionamentos
USERS
 ├── CREATOR_PROFILES
 ├── FOLLOWS
 ├── PARTICIPATIONS
 ├── XP_LEDGER
 ├── USER_LEVELS
 ├── USER_BADGES
 └── NOTIFICATIONS

CREATOR_PROFILES
 ├── EXPERIENCES
 ├── WALLETS
 └── PAYMENTS

EXPERIENCES
 ├── MISSIONS
 └── PARTICIPATIONS

MISSIONS
 ├── MISSION_STEPS
 └── MISSION_SUBMISSIONS

WALLETS
 └── CREDIT_TRANSACTIONS

10.3. Regras de integridade

Usar chaves estrangeiras.
Criar índices para consultas frequentes.
Criar restrições únicas necessárias.
Registrar transações financeiras de forma imutável.
Utilizar transações PostgreSQL para consumo de créditos.
Utilizar idempotência em pagamentos e concessão de XP.
Não permitir exclusões em cascata que eliminem registros financeiros ou de auditoria.


11. SEGURANÇA E PRIVACIDADE
Segurança é requisito obrigatório desde a primeira versão.
11.1. Autenticação

Autenticação segura.
Verificação de e-mail ou telefone.
Recuperação de acesso.
Proteção contra tentativas automatizadas.
Encerramento de sessões.
Controle de sessões administrativas.

11.2. Autorização
Implementar controle de acesso por função e propriedade do recurso.
Um criador só pode editar suas próprias experiências.
Um seguidor só pode alterar seus próprios dados.
Um administrador só pode executar ações administrativas autorizadas.
11.3. Row Level Security
Habilitar RLS nas tabelas expostas pelo Supabase.
Políticas específicas para:

Dados públicos.
Dados privados.
Experiências do próprio criador.
Participações do próprio usuário.
Histórico de créditos.
Dados administrativos.

Nunca utilizar chaves secretas do backend no frontend.
11.4. Proteção contra fraude

Rate limiting.
Captcha quando necessário.
Proteção contra duplicidade.
Validação server-side.
QR Codes com validade.
Logs de atividade.
Detecção de comportamento anormal.
Limites de XP por atividade.
Proteção contra múltiplas contas abusivas.

11.5. LGPD
Implementar:

Política de privacidade.
Termos de uso.
Finalidades de tratamento.
Base legal apropriada.
Consentimentos quando necessários.
Gestão de preferências.
Solicitações de acesso e exclusão.
Política de retenção.
Canal de atendimento ao titular.
Procedimentos para incidentes.

O produto deverá adotar uma política específica de idade mínima e proteção de menores. Recomenda-se restringir o MVP a usuários adultos até a conclusão da análise jurídica e das salvaguardas necessárias.
11.6. Geolocalização
Para experiências presenciais:

Solicitar permissão de localização somente quando necessária.
Não armazenar localização contínua dos participantes.
Proteger coordenadas de locais privados.
Não direcionar usuários a áreas perigosas ou restritas.
Permitir que o criador utilize pontos públicos e seguros.


12. PAGAMENTOS E CARTEIRA
12.1. Fluxo financeiro
O backend será responsável por criar cobranças e confirmar pagamentos.
O webhook deverá:

Receber o evento.
Verificar autenticidade.
Consultar o pagamento no provedor quando necessário.
Validar valor e referência.
Verificar idempotência.
Registrar o pagamento.
Adicionar créditos.
Atualizar o saldo.
Registrar auditoria.

12.2. Regras fundamentais

Não liberar créditos antes da confirmação.
Não aceitar valores informados exclusivamente pelo navegador.
Não confiar em notificações sem validação.
Impedir créditos duplicados.
Registrar estornos.
Conciliar movimentações.
Utilizar valores monetários em centavos inteiros.

12.3. Histórico
O criador deverá visualizar:

Data.
Produto comprado.
Valor.
Forma de pagamento.
Situação.
Créditos recebidos.
Créditos utilizados.


13. SISTEMA DE GAMIFICAÇÃO
13.1. O ENIGMA ID
Todo usuário terá uma identidade gamificada.
Elementos:

Avatar.
Nome público.
Nível.
XP acumulado.
Medalhas.
Histórico.
Criadores favoritos.

13.2. Concessão de XP
O XP será concedido exclusivamente após validação da atividade.
Não conceder XP simplesmente por abrir uma página.
13.3. Rankings
Tipos:

Ranking geral.
Ranking semanal.
Ranking por experiência.
Ranking por criador.

Rankings deverão possuir critérios claros e tratamento contra fraude.
13.4. Medalhas
Exemplos:

Primeiro Enigma.
Explorador.
Mestre dos enigmas.
Participante frequente.
Desbravador.
Campeão de desafios.


14. DESIGN SYSTEM E IDENTIDADE VISUAL
14.1. Posicionamento visual
Identidade:

Moderna.
Jovem.
Digital.
Energética.
Gamificada.
Premium sem parecer complexa.

14.2. Paleta proposta

Fundo principal: #101014.
Superfícies: #1B1B24.
Roxo principal: #8055F5.
Verde de destaque: #A5F05B.
Branco: #FFFFFF.
Texto secundário: #A7A7B5.
Erro: #E45B66.

14.3. Tipografia

Inter.
Alternativa: Manrope.

14.4. Componentes

Botões primários.
Cards de experiência.
Cards de criadores.
Barras de progresso.
Indicadores de XP.
Medalhas.
Badges.
Modais.
Menus inferiores mobile.
Notificações.
Estados vazios.
Estados de erro.

14.5. Responsividade
Prioridade:

Smartphone.
Tablet.
Desktop.

As telas devem funcionar em larguras de 360px ou superiores.

15. NOTIFICAÇÕES E COMPARTILHAMENTO
15.1. Notificações
Eventos:

Nova experiência de criador seguido.
Missão iniciada.
Etapa desbloqueada.
Missão concluída.
XP recebido.
Medalha conquistada.
Experiência encerrada.

Implementar preferências para reduzir notificações excessivas.
15.2. Compartilhamento
Cada experiência terá:

URL pública.
Imagem de compartilhamento.
Título.
Descrição.
Nome do criador.
Metadados Open Graph.

Compartilhamento por:

WhatsApp.
Instagram.
TikTok.
Copiar link.

O Enigma deverá criar cards compartilháveis com a identidade do criador.

16. BACKLOG DE DESENVOLVIMENTO
Prioridades:
P0 = Obrigatório para lançamento.
P1 = Importante para evolução inicial.
P2 = Futuro.
EPIC 01 — Autenticação

[P0] Cadastro.
[P0] Login.
[P0] Recuperação de acesso.
[P0] Verificação.
[P0] Perfis.
[P1] Login social.

EPIC 02 — Creator

[P0] Perfil público.
[P0] Dashboard.
[P0] Edição do perfil.
[P0] Criação de experiência.
[P0] Edição de rascunhos.
[P0] Publicação.
[P0] Compartilhamento.
[P1] Estatísticas avançadas.

EPIC 03 — Experiences

[P0] Estrutura de experiências.
[P0] Estados.
[P0] QUIZ.
[P0] CHALLENGE.
[P0] MISSION.
[P0] HUNT.
[P0] Etapas.
[P0] Prazo.
[P0] Participantes.
[P1] Experiências programadas.

EPIC 04 — Player

[P0] Feed.
[P0] Página de experiência.
[P0] Participação.
[P0] Histórico.
[P0] Perfil.
[P0] Seguir criadores.
[P1] Recomendações.

EPIC 05 — Gamificação

[P0] XP.
[P0] Níveis.
[P0] Histórico de XP.
[P0] Medalhas básicas.
[P0] Ranking por experiência.
[P1] Ranking semanal.
[P1] Ranking geral.

EPIC 06 — HUNT

[P0] Mapa.
[P0] Pistas.
[P0] QR Code.
[P0] Validação.
[P0] Proteção antifraude.
[P1] Etapas geográficas avançadas.

EPIC 07 — Pagamentos

[P0] Carteira.
[P0] Pacotes.
[P0] Pix.
[P0] Webhooks.
[P0] Livro de créditos.
[P0] Consumo de créditos.
[P0] Estornos.
[P0] Histórico.
[P1] Cupons promocionais.

EPIC 08 — Administração

[P0] Dashboard.
[P0] Gestão de usuários.
[P0] Moderação.
[P0] Denúncias.
[P0] Logs.
[P0] Controle de transações.
[P1] Relatórios.

EPIC 09 — Qualidade

[P0] Testes unitários.
[P0] Testes de integração.
[P0] Testes de segurança.
[P0] Testes E2E.
[P0] Testes mobile.
[P0] Testes de pagamentos.
[P0] Monitoramento.
[P1] Testes de carga.

EPIC 10 — Crescimento

[P0] Links compartilháveis.
[P0] Páginas públicas.
[P1] Programa de indicação.
[P1] Analytics de aquisição.
[P1] Campanhas.
[P2] Área de marcas.


17. CRITÉRIOS DE ACEITAÇÃO
17.1. Cadastro

Usuário consegue criar conta.
Dados obrigatórios são validados.
Conta duplicada é tratada corretamente.
Recuperação de acesso funciona.
Permissões são aplicadas no servidor.

17.2. Criação de experiência

Criador consegue selecionar modalidade.
Criador consegue preencher informações.
Campos obrigatórios são validados.
Experiência pode ser salva como rascunho.
Experiência pode ser publicada.
URL pública é gerada.
Experiência publicada respeita seu estado.

17.3. Participação

Seguidor consegue acessar página pública.
Seguidor consegue se cadastrar.
Seguidor consegue participar.
Tentativas são controladas.
Respostas são validadas.
XP é concedido corretamente.
Duplicidades são impedidas.

17.4. HUNT

Criador consegue cadastrar pistas.
Seguidor consegue visualizar pistas liberadas.
QR Code é validado no backend.
Código expirado é recusado.
Repetição indevida é bloqueada.
Localização não é exposta antes do momento apropriado.

17.5. Pagamento

Criador consegue selecionar pacote.
Cobrança é criada.
Pagamento confirmado gera créditos.
Pagamento pendente não gera créditos.
Webhook duplicado não gera créditos duplicados.
Estorno produz movimentação correspondente.
Saldo nunca fica negativo.

17.6. Gamificação

XP só é concedido após validação.
XP duplicado é impedido.
Histórico é consultável.
Nível é atualizado corretamente.
Ranking reflete pontuação válida.

17.7. Administração

Administrador consegue localizar usuários.
Denúncias podem ser analisadas.
Experiências podem ser suspensas.
Ações administrativas são registradas.
Usuários sem permissão não acessam rotas administrativas.

17.8. Critérios gerais de qualidade

Não existem erros críticos conhecidos.
Aplicação funciona em navegadores modernos.
Layout funciona em dispositivos móveis.
APIs validam entradas.
Dados sensíveis não aparecem em respostas públicas.
Backups e recuperação são testados.
Logs não armazenam senhas ou segredos.
Pagamentos passam por testes de integração.


18. TESTES E QUALIDADE
Tipos de teste obrigatórios:
Unitários
Testar:

Cálculo de XP.
Cálculo de níveis.
Consumo de créditos.
Validação de etapas.
Transições de estados.

Integração
Testar:

Autenticação.
Banco de dados.
Pagamentos.
Webhooks.
Participações.
QR Codes.

E2E
Fluxos completos:

Cadastro de criador.
Compra de créditos.
Criação de QUIZ.
Publicação.
Entrada do seguidor.
Participação.
Concessão de XP.
Atualização do ranking.

Segurança

Testes de autorização.
Testes de RLS.
Testes de injeção.
Testes de rate limiting.
Testes de replay.
Testes de manipulação de pagamentos.


19. ROADMAP
Fase 0 — Preparação

Definir identidade.
Criar protótipo.
Validar público.
Validar preços.
Aprovar arquitetura.

Fase 1 — MVP

Autenticação.
Perfis.
Creator.
Player.
QUIZ.
MISSION.
CHALLENGE.
XP.
Carteira.
Pix.
Administração básica.

Fase 2 — Experiências físicas

HUNT.
QR Codes.
Mapa.
Validação geográfica.
Proteção antifraude.

Fase 3 — Piloto comercial

10 a 30 criadores.
Primeiras campanhas orgânicas.
Teste de compra de créditos.
Métricas de retenção.
Correções de UX.

Fase 4 — Escala

Android e iOS.
Programa de indicação.
Analytics avançado.
Patrocínios.
Área de marcas.

Fase 5 — Expansão

Novas categorias.
Novos formatos.
Parcerias comerciais.
Internacionalização.

As durações de cada fase serão definidas após estimativa de engenharia e capacidade da equipe.

20. ESTRATÉGIA DE LANÇAMENTO
20.1. Piloto
Selecionar 10 microinfluenciadores de nichos diferentes.
Critérios:

Comunidade ativa.
Boa frequência de publicação.
Interesse em interagir.
Capacidade de divulgar links.
Disposição para testar produto novo.

20.2. Programa Creator Founders
Criar um programa de pioneiros.
Benefícios:

Selo Creator Founders.
Créditos de lançamento.
Acesso antecipado.
Participação no desenvolvimento.
Divulgação dos criadores selecionados.

20.3. Aquisição
Canais:

Instagram.
TikTok.
YouTube Shorts.
WhatsApp.
Comunidades.
Parcerias com criadores.

20.4. Viralização
Criar cards de conquistas e resultados que possam ser compartilhados fora da plataforma.
Cada criador deverá possuir URL personalizada.
20.5. Meta de expansão

10 criadores pioneiros.
30 criadores ativos.
60 criadores ativos.
100 criadores cadastrados e ativados.
10 mil usuários acumulados.


21. REGRAS JURÍDICAS E OPERACIONAIS
Antes do lançamento público:

Elaborar Termos de Uso.
Elaborar Política de Privacidade.
Implementar LGPD.
Definir política de conteúdo.
Definir política de propriedade intelectual.
Definir procedimento de denúncia.
Definir política de suspensão.
Revisar a política de menores.
Revisar os modelos de pagamento.
Obter parecer jurídico sobre experiências que envolvam prêmios.

A versão inicial deverá priorizar XP, medalhas, rankings e reconhecimento, sem sorteios ou distribuição de prêmios.
Campanhas promocionais futuras devem passar por análise jurídica específica, inclusive quanto à eventual autorização da Secretaria de Prêmios e Apostas do Ministério da Fazenda.

22. DEFINIÇÃO DE PRONTO
Uma funcionalidade somente será considerada pronta quando:

Requisitos funcionais atendidos.
Interface aprovada.
Validação de dados implementada.
Autorização verificada.
Testes automatizados aprovados.
Testes manuais realizados.
Erros críticos resolvidos.
Documentação atualizada.
Logs implementados quando necessários.
Aprovação do responsável pelo produto.

Uma entrega visual sem integração real não será considerada funcionalidade concluída.

23. PRINCÍPIOS INEGOCIÁVEIS DO O ENIGMA

Mobile first.
Experiência simples.
Compartilhamento fácil.
Seguidores gratuitos nas modalidades públicas.
Criadores no centro do produto.
Gamificação justa.
XP sem valor monetário.
Créditos com movimentação auditável.
Segurança desde a arquitetura.
Privacidade por padrão.
Crescimento orientado por métricas.
Desenvolvimento modular.
Sem funcionalidades fictícias ou botões sem ação.
Nenhuma promessa de prêmio sem regras e conformidade legal.


24. DEFINIÇÃO FINAL DO PRODUTO
O Enigma será uma plataforma de experiências interativas em que influenciadores criam missões e desafios para suas comunidades.
O negócio será sustentado inicialmente por créditos adquiridos pelos criadores.
Os seguidores terão acesso gratuito às experiências públicas e construirão sua identidade por meio de XP, níveis, rankings e medalhas.
O MVP será uma aplicação web responsiva e instalável, com arquitetura preparada para aplicativos nativos.
O lançamento será realizado no Brasil, começando por microinfluenciadores e expandindo progressivamente para comunidades maiores e marcas patrocinadoras.
MISSÃO DO O ENIGMA
Transformar seguidores em participantes e influenciadores em criadores de experiências.
VISÃO
Ser uma das principais plataformas brasileiras de experiências sociais gamificadas para comunidades digitais.
POSICIONAMENTO
O Enigma — Não fique só assistindo. Entre no jogo.

FIM DO DOCUMENTO MESTRE — O ENIGMA PRD V1.0
