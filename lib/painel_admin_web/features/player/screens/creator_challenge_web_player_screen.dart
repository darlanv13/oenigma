import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/painel_admin_web/features/player/widgets/pix_checkout_dialog.dart';
import 'package:oenigma/painel_admin_web/features/player/widgets/cesar_cipher_tool_dialog.dart';
import 'package:oenigma/painel_admin_web/features/player/widgets/morse_code_tool_dialog.dart';

enum PlayerStage { landing, playing, finished }

class CreatorChallengeWebPlayerScreen extends StatefulWidget {
  final String slug;

  const CreatorChallengeWebPlayerScreen({
    super.key,
    required this.slug,
  });

  @override
  State<CreatorChallengeWebPlayerScreen> createState() =>
      _CreatorChallengeWebPlayerScreenState();
}

class _CreatorChallengeWebPlayerScreenState
    extends State<CreatorChallengeWebPlayerScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  ParseObject? _event;
  List<ParseObject> _enigmas = [];

  PlayerStage _stage = PlayerStage.landing;
  int _currentEnigmaIndex = 0;

  // Dados do Jogador
  final _playerNameController = TextEditingController();
  final _playerEmailController = TextEditingController();
  final _answerController = TextEditingController();
  bool _isVerifyingAnswer = false;
  String? _answerFeedback;
  bool _isAnswerCorrect = false;

  // Super Dica
  bool _isPurchasingSuperHint = false;
  String? _unlockedSuperHintText;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _playerEmailController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenge() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Busca o Evento pelo slug ou objectId
      QueryBuilder<ParseObject> query =
          QueryBuilder<ParseObject>(ParseObject('Event'))
            ..whereEqualTo('slug', widget.slug);

      var res = await query.query();
      if (!res.success || res.results == null || res.results!.isEmpty) {
        // Tenta buscar por objectId direto
        final directQuery = QueryBuilder<ParseObject>(ParseObject('Event'))
          ..whereEqualTo('objectId', widget.slug);
        res = await directQuery.query();
      }

      if (res.success && res.results != null && res.results!.isNotEmpty) {
        _event = res.results!.first as ParseObject;

        // 2. Busca os Enigmas deste Evento
        final enigmaQuery = QueryBuilder<ParseObject>(ParseObject('Enigma'))
          ..whereEqualTo('eventId', _event!.objectId)
          ..orderByAscending('order');

        final enigmaRes = await enigmaQuery.query();
        if (enigmaRes.success && enigmaRes.results != null && enigmaRes.results!.isNotEmpty) {
          _enigmas = List<ParseObject>.from(enigmaRes.results!);
        } else {
          _enigmas = _buildDemoEnigmas();
        }
      } else {
        _loadDemoChallenge();
      }
    } catch (e) {
      _loadDemoChallenge();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadDemoChallenge() {
    _event = ParseObject('Event')
      ..set('objectId', 'demo_event_123')
      ..set('name', 'O Segredo da Caixa Misteriosa')
      ..set('creatorName', '@felipe_influencer')
      ..set('prize', 'R\$ 2.500,00 no Pix')
      ..set('price', 10.0)
      ..set('difficulty', 'Média')
      ..set('videoTeaserUrl', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4')
      ..set('hasPaidHints', true)
      ..set('paidHintPrice', 1.99);

    _enigmas = _buildDemoEnigmas();
  }

  List<ParseObject> _buildDemoEnigmas() {
    final e1 = ParseObject('Enigma')
      ..set('objectId', 'demo_enigma_1')
      ..set('order', 1)
      ..set('title', 'A Cifra do Imperador')
      ..set('clue', 'O imperador romano usava um deslocamento secreto para proteger suas ordens. Decifre a palavra codificada com pulo de 3 letras: "HQJPD".')
      ..set('code', 'ENIGMA')
      ..set('toolType', 'Cifra de César')
      ..set('superHintPrice', 1.99)
      ..set('hasPaidSuperHint', true)
      ..set('superHintText', 'Dica de Ouro: Aplique deslocamento de -3 na ferramenta Cifra de César. H->E, Q->N, J->I, P->G, D->M, A...');

    final e2 = ParseObject('Enigma')
      ..set('objectId', 'demo_enigma_2')
      ..set('order', 2)
      ..set('title', 'Transmissão Telegráfica Subterrânea')
      ..set('clue', 'Uma frequência de rádio militar captou os seguintes bipes no subterrâneo: "... --- ... / ...- .. - --- .-. .. .-". Qual a segunda palavra transmitida?')
      ..set('code', 'VITORIA')
      ..set('toolType', 'Código Morse')
      ..set('superHintPrice', 1.99)
      ..set('hasPaidSuperHint', true)
      ..set('superHintText', 'Super Dica: Abra o Decodificador Morse integrado no card abaixo e digite "...- .. - --- .-. .. .-".');

    return [e1, e2];
  }

  void _startFreeChallenge() {
    if (_playerNameController.text.trim().isEmpty) {
      _showToast('Por favor, informe seu nome ou apelido para começar!');
      return;
    }
    setState(() {
      _stage = PlayerStage.playing;
      _currentEnigmaIndex = 0;
      _unlockedSuperHintText = null;
      _answerFeedback = null;
    });
  }

  Future<void> _startPaidChallenge() async {
    if (_playerNameController.text.trim().isEmpty) {
      _showToast('Por favor, informe seu nome ou apelido!');
      return;
    }

    final buyerName = _playerNameController.text.trim();
    final buyerEmail = _playerEmailController.text.trim();

    if (_event!.objectId == 'demo_event_123') {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PixCheckoutDialog(
            title: 'Inscrição no Desafio (Demo)',
            subtitle: _event!.get<String>('name') ?? 'Desafio do Criador',
            amount: 10.0,
            transactionId: 'demo_ticket_${DateTime.now().millisecondsSinceEpoch}',
            copiaCola: '00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-426614174000520400005303986540510.005802BR5913O Enigma Demo6009Sao Paulo62070503***6304ABCD',
            onPaymentApproved: () {
              setState(() {
                _stage = PlayerStage.playing;
                _currentEnigmaIndex = 0;
                _unlockedSuperHintText = null;
                _answerFeedback = null;
              });
            },
          ),
        );
      }
      return;
    }

    try {
      final function = ParseCloudFunction('createChallengePixTicket');
      final res = await function.execute(parameters: {
        'eventId': _event!.objectId,
        'buyerName': buyerName,
        'buyerEmail': buyerEmail,
      });

      if (res.success && res.result != null) {
        final data = Map<String, dynamic>.from(res.result);
        if (data['isFree'] == true) {
          _startFreeChallenge();
          return;
        }

        final txId = data['transactionId'];
        final copiaCola = data['copiaCola'] ?? '';
        final amount = (data['amount'] as num?)?.toDouble() ?? 10.0;

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => PixCheckoutDialog(
              title: 'Inscrição no Desafio',
              subtitle: _event!.get<String>('name') ?? 'Desafio do Criador',
              amount: amount,
              transactionId: txId,
              copiaCola: copiaCola,
              onPaymentApproved: () {
                setState(() {
                  _stage = PlayerStage.playing;
                  _currentEnigmaIndex = 0;
                  _unlockedSuperHintText = null;
                  _answerFeedback = null;
                });
              },
            ),
          );
        }
      } else {
        throw Exception(res.error?.message ?? 'Falha ao gerar Pix');
      }
    } catch (e) {
      _showToast('Erro ao iniciar pagamento: $e');
    }
  }

  Future<void> _buySuperHint(ParseObject enigma) async {
    setState(() => _isPurchasingSuperHint = true);

    if (_event!.objectId == 'demo_event_123') {
      setState(() => _isPurchasingSuperHint = false);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PixCheckoutDialog(
            title: 'Super Dica Desbloqueada! (Demo)',
            subtitle: enigma.get<String>('title') ?? 'Pista Crucial',
            amount: 1.99,
            transactionId: 'demo_hint_${DateTime.now().millisecondsSinceEpoch}',
            copiaCola: '00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-42661417400052040000530398654041.995802BR5913O Enigma Dica6009Sao Paulo62070503***6304ABCD',
            onPaymentApproved: () {
              final hint = enigma.get<String>('superHintText');
              setState(() {
                _unlockedSuperHintText = (hint != null && hint.isNotEmpty)
                    ? hint
                    : 'Super Dica: Desloque as letras 3 posições para trás ou verifique a pontuação telegráfica!';
              });
            },
          ),
        );
      }
      return;
    }

    try {
      final function = ParseCloudFunction('createSuperHintPix');
      final res = await function.execute(parameters: {
        'eventId': _event!.objectId,
        'enigmaId': enigma.objectId,
        'buyerName': _playerNameController.text.trim(),
        'buyerEmail': _playerEmailController.text.trim(),
      });

      if (res.success && res.result != null) {
        final data = Map<String, dynamic>.from(res.result);
        final txId = data['transactionId'];
        final copiaCola = data['copiaCola'] ?? '';
        final amount = (data['amount'] as num?)?.toDouble() ?? 1.99;

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => PixCheckoutDialog(
              title: 'Super Dica Desbloqueada!',
              subtitle: enigma.get<String>('title') ?? 'Pista Crucial',
              amount: amount,
              transactionId: txId,
              copiaCola: copiaCola,
              onPaymentApproved: () {
                final hint = enigma.get<String>('superHintText');
                setState(() {
                  _unlockedSuperHintText = (hint != null && hint.isNotEmpty)
                      ? hint
                      : 'Super Dica: Observe atentamente os detalhes do vídeo e as primeiras letras da frase!';
                });
              },
            ),
          );
        }
      }
    } catch (e) {
      _showToast('Erro ao liberar Super Dica: $e');
    } finally {
      if (mounted) setState(() => _isPurchasingSuperHint = false);
    }
  }

  void _verifyAnswer(ParseObject enigma) {
    final userAnswer = _answerController.text.trim().toUpperCase();
    final expectedCode = (enigma.get<String>('code') ?? '').trim().toUpperCase();

    if (userAnswer.isEmpty) {
      _showToast('Digite sua resposta para validar.');
      return;
    }

    setState(() => _isVerifyingAnswer = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (userAnswer == expectedCode) {
        setState(() {
          _isAnswerCorrect = true;
          _answerFeedback = '🎉 RESPOSTA EXATA! VOCÊ DECIFROU O ENIGMA!';
        });

        // Passa para a próxima fase após 1.5s
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          if (_currentEnigmaIndex + 1 < _enigmas.length) {
            setState(() {
              _currentEnigmaIndex++;
              _answerController.clear();
              _unlockedSuperHintText = null;
              _answerFeedback = null;
              _isAnswerCorrect = false;
              _isVerifyingAnswer = false;
            });
          } else {
            // Desafio concluído!
            setState(() {
              _stage = PlayerStage.finished;
              _isVerifyingAnswer = false;
            });
          }
        });
      } else {
        setState(() {
          _isAnswerCorrect = false;
          _answerFeedback = '❌ Resposta incorreta. Tente novamente ou use as ferramentas!';
          _isVerifyingAnswer = false;
        });
      }
    });
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.amareloValeDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: const Center(child: CircularProgressIndicator(color: AppColors.verdeVale)),
      );
    }

    if (_errorMessage != null || _event == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.redAccent, size: 36),
                const SizedBox(height: 14),
                Text(
                  _errorMessage ?? 'Desafio não encontrado',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _buildStageContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case PlayerStage.landing:
        return _buildLandingPage();
      case PlayerStage.playing:
        return _buildPlayingView();
      case PlayerStage.finished:
        return _buildFinishedView();
    }
  }

  // === 1. LANDING PAGE DO DESAFIO ===
  Widget _buildLandingPage() {
    final title = _event!.get<String>('name') ?? 'Desafio Enigmático';
    final creatorName = _event!.get<String>('creatorName') ?? 'Influenciador';
    final prize = _event!.get<String>('prize') ?? 'R\$ 1.000,00';
    final price = (_event!.get<num>('price') ?? 0.0).toDouble();
    final isFree = price <= 0;
    final videoTeaser = _event!.get<String>('videoTeaserUrl') ?? _event!.get<String>('videoUrl') ?? '';
    final bannerUrl = _event!.get<String>('prizeImageUrl') ?? _event!.get<String>('icon') ?? '';
    final difficulty = _event!.get<String>('difficulty') ?? 'Média';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        children: [
          // Header O ENIGMA + Creator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.compass, color: AppColors.amareloVale, size: 16),
              const SizedBox(width: 8),
              Text(
                'O ENIGMA',
                style: GoogleFonts.cinzel(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Badge do Influenciador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.verdeVale, size: 12),
                const SizedBox(width: 8),
                Text(
                  'Desafio lançado por $creatorName',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Título do Desafio
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
          ),
          const SizedBox(height: 14),

          // Banner ou Card de Prêmio
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF13222A), Color(0xFF0F1A20)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                if (bannerUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(bannerUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  '🏆 PRÊMIO PARA QUEM DECIFRAR:',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  prize,
                  style: GoogleFonts.poppins(color: AppColors.amareloVale, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dificuldade: $difficulty • ${_enigmas.length} Enigmas Misteriosos',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Vídeo Teaser (se configurado)
          if (videoTeaser.isNotEmpty) ...[
            InkWell(
              onTap: () async {
                final uri = Uri.parse(videoTeaser);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.play, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 10),
                    Text(
                      'Assistir ao Vídeo do Criador no YouTube/TikTok',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Card de Entrada / Checkout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFree ? 'ENTRE GRÁTIS NO DESAFIO' : 'GARANTA SUA PARTICIPAÇÃO',
                  style: GoogleFonts.poppins(color: AppColors.amareloVale, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  isFree ? 'Participe agora mesmo e prove que é o mais inteligente!' : 'Taxa de entrada única de R\$ ${price.toStringAsFixed(2)} no Pix.',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Nome do Jogador
                TextField(
                  controller: _playerNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Seu Nome ou @ do Instagram',
                    labelStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.darkBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // E-mail (Opcional ou para Pix)
                TextField(
                  controller: _playerEmailController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Seu E-mail ou WhatsApp (para contato se vencer)',
                    labelStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.darkBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 18),

                // Botão de Ação
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFree ? AppColors.verdeVale : AppColors.amareloVale,
                      foregroundColor: isFree ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    onPressed: isFree ? _startFreeChallenge : _startPaidChallenge,
                    child: Text(
                      isFree ? 'Começar Desafio Agora! 🚀' : 'Pagar R\$ ${price.toStringAsFixed(2)} no Pix & Jogar ⚡',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === 2. JOGABILIDADE DO ENIGMA ===
  Widget _buildPlayingView() {
    if (_enigmas.isEmpty) {
      return Center(
        child: Text('Nenhum enigma cadastrado para este desafio.', style: GoogleFonts.poppins(color: Colors.white)),
      );
    }

    final enigma = _enigmas[_currentEnigmaIndex];
    final title = enigma.get<String>('title') ?? 'Fase ${_currentEnigmaIndex + 1}';
    final instruction = enigma.get<String>('instruction') ?? '';
    final videoUrl = enigma.get<String>('videoUrl');
    final chars = (enigma.get<dynamic>('characteristics') as List?)?.map((e) => e.toString()).toList() ?? [];

    final hasCesar = chars.contains('cesar');
    final hasMorse = chars.contains('morse');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de Progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FASE ${_currentEnigmaIndex + 1} DE ${_enigmas.length}',
                style: GoogleFonts.poppins(color: AppColors.amareloVale, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                _event!.get<String>('name') ?? 'O Enigma',
                style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentEnigmaIndex + 1) / _enigmas.length,
            backgroundColor: AppColors.darkCardBorder,
            color: AppColors.verdeVale,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),

          // Card Principal do Enigma
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Link para o vídeo da fase (se houver)
                if (videoUrl != null && videoUrl.isNotEmpty) ...[
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(videoUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.youtube, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pista em Vídeo: Toque aqui para assistir',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Texto da Charada
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    instruction,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),

                // Barra de Ferramentas Táticas
                Text(
                  'Ferramentas de Decodificação Liberadas:',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    if (hasCesar || true)
                      OutlinedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.lockOpen, size: 12),
                        label: const Text('Cifra de César'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.amareloVale,
                          side: const BorderSide(color: AppColors.amareloVale),
                        ),
                        onPressed: () => showDialog(context: context, builder: (_) => const CesarCipherToolDialog()),
                      ),
                    if (hasMorse || true)
                      OutlinedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.signal, size: 12),
                        label: const Text('Código Morse'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.verdeVale,
                          side: const BorderSide(color: AppColors.verdeVale),
                        ),
                        onPressed: () => showDialog(context: context, builder: (_) => const MorseCodeToolDialog()),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Seção da Super Dica (R$ 1,99)
          if (_unlockedSuperHintText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.amareloVale.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.amareloVale),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.lightbulb, color: AppColors.amareloVale, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'SUPER DICA DESBLOQUEADA:',
                        style: GoogleFonts.poppins(color: AppColors.amareloVale, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_unlockedSuperHintText!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5)),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF14241C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.lightbulb, color: AppColors.amareloVale, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Travou neste enigma?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Libere a Super Dica decisiva no Pix por apenas R\$ 1,99.', style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloVale,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    onPressed: _isPurchasingSuperHint ? null : () => _buySuperHint(enigma),
                    child: _isPurchasingSuperHint
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('R\$ 1,99'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Campo de Validação da Resposta
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESPOSTA DO ENIGMA',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _answerController,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Digite a palavra-chave secreta...',
                          hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.darkBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verdeVale,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onPressed: _isVerifyingAnswer ? null : () => _verifyAnswer(enigma),
                      child: _isVerifyingAnswer
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verificar'),
                    ),
                  ],
                ),
                if (_answerFeedback != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _answerFeedback!,
                    style: GoogleFonts.poppins(
                      color: _isAnswerCorrect ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === 3. VITÓRIA / CONCLUSÃO DO DESAFIO ===
  Widget _buildFinishedView() {
    final prize = _event!.get<String>('prize') ?? 'R\$ 1.000,00';
    final creatorName = _event!.get<String>('creatorName') ?? 'Influenciador';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E251A), Color(0xFF131D24)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(FontAwesomeIcons.trophy, color: AppColors.amareloVale, size: 48),
              ),
              const SizedBox(height: 18),

              Text(
                'PARABÉNS, VOCÊ DECIFROU O ENIGMA!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Você superou todas as fases do desafio de $creatorName e concluiu a caça ao tesouro com sucesso!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 13),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.amareloVale.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.amareloVale),
                ),
                child: Text(
                  '🏆 PRÊMIO CONCORRIDO: $prize',
                  style: GoogleFonts.poppins(color: AppColors.amareloVale, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Seu tempo e pontuação foram registrados nos servidores de O Enigma. Se for o primeiro colocado, o influenciador entrará em contato pelos dados cadastrados!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
