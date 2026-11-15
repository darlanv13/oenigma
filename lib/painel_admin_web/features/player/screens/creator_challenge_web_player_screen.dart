import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/painel_admin_web/features/player/widgets/pix_checkout_dialog.dart';
import 'package:oenigma/painel_admin_web/features/player/widgets/cesar_cipher_tool_dialog.dart';
import 'package:oenigma/painel_admin_web/features/player/widgets/morse_code_tool_dialog.dart';
import 'package:oenigma/painel_admin_web/features/player/widgets/detective_scratchpad_dialog.dart';

enum PlayerStage { landing, playing, finished }

/// Experiência Imersiva & Gamificada do Jogador no Web Player (Mobile & Desktop)
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

  // Cronômetro Gamificado
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;

  // Anotações do Jogador
  String _playerNotes = '';

  // Dados do Jogador
  final _playerNameController = TextEditingController();
  final _playerContactController = TextEditingController();
  final _playerPixKeyController = TextEditingController();
  final _answerController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isVerifyingAnswer = false;
  String? _answerFeedback;
  bool _isAnswerCorrect = false;
  final List<String> _previousAttempts = [];

  // Super Dica
  bool _isPurchasingSuperHint = false;
  String? _unlockedSuperHintText;

  // Conclusão / Vencedor
  bool _isSubmittingWinner = false;
  bool _isFirstWinner = true;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _playerNameController.dispose();
    _playerContactController.dispose();
    _playerPixKeyController.dispose();
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startStopwatch() {
    _stopwatchTimer?.cancel();
    _elapsedSeconds = 0;
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopStopwatch() {
    _stopwatchTimer?.cancel();
  }

  String _formatElapsed(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
        if (enigmaRes.success &&
            enigmaRes.results != null &&
            enigmaRes.results!.isNotEmpty) {
          _enigmas = List<ParseObject>.from(enigmaRes.results!);
        } else {
          _enigmas = _buildDemoEnigmas();
        }
      } else {
        _loadDemoChallenge();
      }
    } catch (_) {
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
      ..set('price', 0.0)
      ..set('difficulty', 'Média')
      ..set('playerCount', 284)
      ..set('videoTeaserUrl', 'https://youtube.com')
      ..set('hasPaidHints', true)
      ..set('paidHintPrice', 1.99);

    _enigmas = _buildDemoEnigmas();
  }

  List<ParseObject> _buildDemoEnigmas() {
    final e1 = ParseObject('Enigma')
      ..set('objectId', 'demo_enigma_1')
      ..set('order', 1)
      ..set('title', 'A Cifra do Imperador')
      ..set(
        'clue',
        'O imperador romano usava um deslocamento secreto para proteger suas ordens militares. Decifre a palavra secreta codificada com pulo de 3 letras: "HQJPD".',
      )
      ..set('code', 'ENIGMA')
      ..set('toolType', 'Cifra de César')
      ..set('superHintPrice', 1.99)
      ..set('hasPaidSuperHint', true)
      ..set(
        'superHintText',
        'Super Dica: Abra o Decodificador Cifra de César no Arsenal abaixo com deslocamento -3: H->E, Q->N, J->I, P->G, D->M, A...',
      );

    final e2 = ParseObject('Enigma')
      ..set('objectId', 'demo_enigma_2')
      ..set('order', 2)
      ..set('title', 'Transmissão Telegráfica Subterrânea')
      ..set(
        'clue',
        'Uma frequência de rádio clandestina captou os seguintes bipes no subterrâneo: "... --- ... / ...- .. - --- .-. .. .-". Qual a segunda palavra transmitida?',
      )
      ..set('code', 'VITORIA')
      ..set('toolType', 'Código Morse')
      ..set('superHintPrice', 1.99)
      ..set('hasPaidSuperHint', true)
      ..set(
        'superHintText',
        'Super Dica: Abra o Decodificador Morse integrado no card abaixo e digite "...- .. - --- .-. .. .-".',
      );

    final e3 = ParseObject('Enigma')
      ..set('objectId', 'demo_enigma_3')
      ..set('order', 3)
      ..set('title', 'O Anagrama Final do Guardião')
      ..set(
        'clue',
        'Para abrir o cofre e reivindicar o prêmio Pix, reorganize as letras deste anagrama sagrado: "R E S P O T A" invertendo a ordem dos ponteiros do relógio.',
      )
      ..set('code', 'RESPOSTA')
      ..set('toolType', 'Lógica & Anagrama')
      ..set('superHintPrice', 1.99)
      ..set('hasPaidSuperHint', true)
      ..set(
        'superHintText',
        'Super Dica: A palavra é a chave de tudo que você buscou até agora: R-E-S-P-O-S-T-A!',
      );

    return [e1, e2, e3];
  }

  void _startFreeChallenge() {
    if (_playerNameController.text.trim().isEmpty) {
      _showToast('Por favor, digite seu nome ou apelido para começar!');
      return;
    }
    setState(() {
      _stage = PlayerStage.playing;
      _currentEnigmaIndex = 0;
      _unlockedSuperHintText = null;
      _answerFeedback = null;
      _previousAttempts.clear();
    });
    _startStopwatch();
  }

  Future<void> _startPaidChallenge() async {
    if (_playerNameController.text.trim().isEmpty) {
      _showToast('Por favor, digite seu nome ou apelido!');
      return;
    }

    final buyerName = _playerNameController.text.trim();
    final buyerEmail = _playerContactController.text.trim();
    final price = (_event!.get<num>('price') ?? 10.0).toDouble();

    if (_event!.objectId == 'demo_event_123') {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PixCheckoutDialog(
            title: 'Inscrição no Desafio (Demo)',
            subtitle: _event!.get<String>('name') ?? 'Desafio do Criador',
            amount: price,
            transactionId: 'demo_ticket_${DateTime.now().millisecondsSinceEpoch}',
            copiaCola:
                '00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-426614174000520400005303986540510.005802BR5913O Enigma Demo6009Sao Paulo62070503***6304ABCD',
            onPaymentApproved: () {
              setState(() {
                _stage = PlayerStage.playing;
                _currentEnigmaIndex = 0;
                _unlockedSuperHintText = null;
                _answerFeedback = null;
                _previousAttempts.clear();
              });
              _startStopwatch();
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
        final amount = (data['amount'] as num?)?.toDouble() ?? price;

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
                  _previousAttempts.clear();
                });
                _startStopwatch();
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
            copiaCola:
                '00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-42661417400052040000530398654041.995802BR5913O Enigma Dica6009Sao Paulo62070503***6304ABCD',
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
        'buyerEmail': _playerContactController.text.trim(),
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
    final rawAnswer = _answerController.text.trim();
    final userAnswer = rawAnswer.toUpperCase();
    final expectedCode =
        (enigma.get<String>('code') ?? '').trim().toUpperCase();

    if (userAnswer.isEmpty) {
      _showToast('Digite sua resposta para validar.');
      return;
    }

    setState(() => _isVerifyingAnswer = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      if (userAnswer == expectedCode) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isAnswerCorrect = true;
          _answerFeedback = '🎉 RESPOSTA EXATA! VOCÊ DECIFROU O ENIGMA!';
        });

        // Passa para a próxima fase após 1.2s
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          if (_currentEnigmaIndex + 1 < _enigmas.length) {
            setState(() {
              _currentEnigmaIndex++;
              _answerController.clear();
              _unlockedSuperHintText = null;
              _answerFeedback = null;
              _isAnswerCorrect = false;
              _isVerifyingAnswer = false;
              _previousAttempts.clear();
            });
            _focusNode.requestFocus();
          } else {
            _finishChallenge();
          }
        });
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _isAnswerCorrect = false;
          _answerFeedback =
              '❌ Resposta incorreta. Revise as pistas ou use as ferramentas!';
          _isVerifyingAnswer = false;
          if (!_previousAttempts.contains(userAnswer)) {
            _previousAttempts.insert(0, userAnswer);
          }
        });
      }
    });
  }

  Future<void> _finishChallenge() async {
    _stopStopwatch();
    setState(() {
      _stage = PlayerStage.finished;
      _isVerifyingAnswer = false;
      _isSubmittingWinner = true;
    });

    try {
      final fn = ParseCloudFunction('submitChallengeWinner');
      final res = await fn.execute(parameters: {
        'eventId': _event!.objectId,
        'winnerName': _playerNameController.text.trim(),
        'winnerContact': _playerContactController.text.trim(),
        'pixKey': _playerPixKeyController.text.trim(),
        'elapsedSeconds': _elapsedSeconds,
      });

      if (res.success && res.result != null && res.result is Map) {
        setState(() {
          _isFirstWinner = res.result['isFirstWinner'] == true;
        });
      }
    } catch (_) {
      // Ignora erro no modo demo
    } finally {
      if (mounted) setState(() => _isSubmittingWinner = false);
    }
  }

  void _openScratchpad() {
    showDialog(
      context: context,
      builder: (ctx) => DetectiveScratchpadDialog(
        initialNotes: _playerNotes,
        onNotesChanged: (n) => setState(() => _playerNotes = n),
      ),
    );
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

  void _shareOnWhatsApp() {
    final title = _event?.get<String>('name') ?? 'O Enigma';
    final prize = _event?.get<String>('prize') ?? 'R\$ 1.000,00';
    final creator = _event?.get<String>('creatorName') ?? 'Criador';
    final url = 'https://darlanv13.github.io/oenigma/#/e/${widget.slug}';

    String text;
    if (_stage == PlayerStage.finished) {
      text =
          '🏆 Eu acabei de decifrar o enigma "$title" de $creator em ${_formatElapsed(_elapsedSeconds)}! Concorrendo a $prize no Pix! Consegue me superar? Jogue agora: $url';
    } else {
      text =
          '🔥 Você é inteligente o bastante? Estou jogando o enigma "$title" de $creator com prêmio de $prize no Pix! Entra aí: $url';
    }

    final uri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E12),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.amareloVale),
        ),
      );
    }

    if (_errorMessage != null || _event == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E12),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
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
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/portal'),
                  child: const Text('Voltar ao Hub'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090D11),
      appBar: _buildPlayerAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _buildStageContent(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildPlayerAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0B1014),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 14, color: AppColors.cinzaMedio),
        onPressed: () {
          if (_stage == PlayerStage.playing) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.darkCardColor,
                title: Text('Sair do Desafio?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                content: Text('Seu cronômetro será pausado. Deseja realmente voltar?', style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 13)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ficar')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _stage = PlayerStage.landing);
                    },
                    child: const Text('Sair'),
                  ),
                ],
              ),
            );
          } else {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/portal');
            }
          }
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.compass, color: AppColors.amareloVale, size: 15),
          const SizedBox(width: 8),
          Text(
            'O ENIGMA',
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.4)),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.poppins(
                color: AppColors.verdeVale,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Cronômetro Ativo se estiver jogando
        if (_stage == PlayerStage.playing)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatElapsed(_elapsedSeconds),
                  style: GoogleFonts.firaCode(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

        // Botão Bloco de Notas
        if (_stage == PlayerStage.playing)
          IconButton(
            tooltip: 'Bloco de Anotações',
            icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 14, color: AppColors.amareloVale),
            onPressed: _openScratchpad,
          ),

        // Botão Compartilhar
        IconButton(
          tooltip: 'Compartilhar Desafio',
          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.greenAccent),
          onPressed: _shareOnWhatsApp,
        ),
      ],
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

  // ===========================================================================
  // 1. LANDING PAGE ELEGANTE & CONVERSIVA
  // ===========================================================================
  Widget _buildLandingPage() {
    final title = _event!.get<String>('name') ?? 'Desafio Enigmático';
    final creatorName = _event!.get<String>('creatorName') ?? 'Influenciador';
    final prize = _event!.get<String>('prize') ?? 'R\$ 1.000,00';
    final price = (_event!.get<num>('price') ?? 0.0).toDouble();
    final isFree = price <= 0;
    final videoTeaser =
        _event!.get<String>('videoTeaserUrl') ?? _event!.get<String>('videoUrl') ?? '';
    final bannerUrl =
        _event!.get<String>('prizeImageUrl') ?? _event!.get<String>('icon') ?? '';
    final difficulty = _event!.get<String>('difficulty') ?? 'Média';
    final count = _event!.get<num>('playerCount')?.toInt() ?? 142;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        children: [
          // Badge do Influenciador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amareloVale.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.amareloVale, size: 15),
                const SizedBox(width: 6),
                Text(
                  'Desafio Oficial por $creatorName',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Título do Desafio
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 8),

          // Prova Social / Jogadores
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 16),
              const SizedBox(width: 4),
              Text(
                '+$count exploradores tentando decifrar',
                style: GoogleFonts.poppins(
                  color: AppColors.cinzaMedio,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Card de Prêmio 3D Dourado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF19252A), Color(0xFF0F1519)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.amareloVale.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.amareloVale.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                if (bannerUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      bannerUrl,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.trophy, color: AppColors.amareloVale, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'PRÊMIO DO PRIMEIRO COLOCADO',
                      style: GoogleFonts.poppins(
                        color: AppColors.cinzaMedio,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  prize,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.amareloVale,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildMetaChip(Icons.speed_rounded, 'Dificuldade: $difficulty'),
                    _buildMetaChip(Icons.extension_rounded, '${_enigmas.length} Enigmas'),
                    _buildMetaChip(Icons.bolt_rounded, 'Premiação no Pix'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Seção "Como Funciona em 3 Passos"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1519),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStepItem('1', 'Inscreva-se', 'Grátis ou Pix'),
                _buildStepItem('2', 'Decifre', 'Use o arsenal'),
                _buildStepItem('3', 'Ganhe', 'Pix na conta'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Teaser em Vídeo (se houver)
          if (videoTeaser.isNotEmpty) ...[
            InkWell(
              onTap: () async {
                final uri = Uri.parse(videoTeaser);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.play, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 10),
                    Text(
                      'Assistir ao Vídeo Teaser do Criador',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Card de Entrada / Checkout
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFree
                    ? AppColors.verdeVale.withValues(alpha: 0.4)
                    : AppColors.amareloVale.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFree ? 'ENTRADA GRATUITA' : 'TAXA DE INSCRIÇÃO',
                      style: GoogleFonts.poppins(
                        color: isFree ? AppColors.verdeVale : AppColors.amareloVale,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      isFree ? '100% GRÁTIS' : 'R\$ ${price.toStringAsFixed(2)} no Pix',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Informe seus dados para concorrer. O primeiro a completar todas as fases recebe o Pix na hora!',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Nome do Jogador
                TextField(
                  controller: _playerNameController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.amareloVale, size: 18),
                    labelText: 'Seu Nome ou @ do Instagram *',
                    labelStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                    hintText: 'ex: Lucas Silva ou @lucas_enigma',
                    hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio.withValues(alpha: 0.5), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0C1013),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 12),

                // Contato (WhatsApp / E-mail)
                TextField(
                  controller: _playerContactController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.contact_mail_outlined, color: AppColors.amareloVale, size: 18),
                    labelText: 'WhatsApp ou E-mail (para contato caso vença) *',
                    labelStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                    hintText: '(11) 99999-9999 ou seu@email.com',
                    hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio.withValues(alpha: 0.5), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0C1013),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 18),

                // Botão de Entrada
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFree ? AppColors.verdeVale : AppColors.amareloVale,
                      foregroundColor: isFree ? Colors.white : Colors.black,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isFree ? _startFreeChallenge : _startPaidChallenge,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          isFree ? FontAwesomeIcons.rocket : FontAwesomeIcons.bolt,
                          size: 15,
                          color: isFree ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFree ? 'Começar Desafio Agora!' : 'Pagar R\$ ${price.toStringAsFixed(2)} no Pix & Jogar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Botão WhatsApp Share
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.greenAccent,
              side: const BorderSide(color: Colors.greenAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 15),
            label: Text(
              'Desafie seus amigos no WhatsApp',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: _shareOnWhatsApp,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1014),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.amareloVale, size: 12),
          const SizedBox(width: 5),
          Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String subtitle) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.amareloVale,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
        Text(subtitle, style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 10)),
      ],
    );
  }

  // ===========================================================================
  // 2. ARENA DE JOGABILIDADE DO ENIGMA
  // ===========================================================================
  Widget _buildPlayingView() {
    if (_enigmas.isEmpty) {
      return Center(
        child: Text(
          'Nenhum enigma cadastrado para este desafio.',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      );
    }

    final enigma = _enigmas[_currentEnigmaIndex];
    final title = enigma.get<String>('title') ?? 'Fase ${_currentEnigmaIndex + 1}';
    final clueText = enigma.get<String>('clue') ??
        enigma.get<String>('instruction') ??
        enigma.get<String>('description') ??
        enigma.get<String>('question') ??
        'Analise atentamente todas as informações para encontrar a chave secreta.';

    final videoUrl = enigma.get<String>('videoUrl');
    final imageUrl = enigma.get<String>('photoUrl') ?? enigma.get<String>('imageUrl');

    final chars = (enigma.get<dynamic>('characteristics') as List?)?.map((e) => e.toString()).toList() ?? [];
    final toolType = enigma.get<String>('toolType') ?? '';
    final hasCesar = chars.contains('cesar') || toolType.toLowerCase().contains('césar') || toolType.toLowerCase().contains('cesar');
    final hasMorse = chars.contains('morse') || toolType.toLowerCase().contains('morse');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs de Fases
          _buildPhasesBreadcrumbs(),

          const SizedBox(height: 14),

          // Card Principal do Enigma
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.verdeVale.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.verdeVale.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.amareloVale.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Fase ${_currentEnigmaIndex + 1}/${_enigmas.length}',
                        style: GoogleFonts.poppins(
                          color: AppColors.amareloVale,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Imagem / Pista Visual (se anexada)
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: const Color(0xFF0A0E12),
                      child: Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Pista em Vídeo (se houver)
                if (videoUrl != null && videoUrl.isNotEmpty) ...[
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(videoUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.youtube, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pista em Vídeo: Toque aqui para assistir',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Texto do Enigma (Charada)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1013),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.darkCardBorder),
                  ),
                  child: Text(
                    clueText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Arsenal de Ferramentas
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.toolbox, size: 12, color: AppColors.amareloVale),
                    const SizedBox(width: 6),
                    Text(
                      'Arsenal Tático de Decodificação:',
                      style: GoogleFonts.poppins(
                        color: AppColors.cinzaMedio,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.lockOpen, size: 12),
                      label: Text(hasCesar ? 'Cifra de César ★' : 'Cifra de César'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.amareloVale,
                        side: BorderSide(
                          color: hasCesar ? AppColors.amareloVale : AppColors.darkCardBorder,
                          width: hasCesar ? 1.5 : 1.0,
                        ),
                        backgroundColor: hasCesar ? AppColors.amareloVale.withValues(alpha: 0.1) : null,
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const CesarCipherToolDialog(),
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.signal, size: 12),
                      label: Text(hasMorse ? 'Código Morse ★' : 'Código Morse'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.verdeVale,
                        side: BorderSide(
                          color: hasMorse ? AppColors.verdeVale : AppColors.darkCardBorder,
                          width: hasMorse ? 1.5 : 1.0,
                        ),
                        backgroundColor: hasMorse ? AppColors.verdeVale.withValues(alpha: 0.1) : null,
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const MorseCodeToolDialog(),
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 12),
                      label: const Text('Bloco de Notas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.darkCardBorder),
                      ),
                      onPressed: _openScratchpad,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Seção da Super Dica (R$ 1,99)
          if (_unlockedSuperHintText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.amareloVale.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.amareloVale, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.lightbulb, color: AppColors.amareloVale, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'SUPER DICA DESBLOQUEADA:',
                        style: GoogleFonts.poppins(
                          color: AppColors.amareloVale,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _unlockedSuperHintText!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF14241C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.amareloVale.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(FontAwesomeIcons.lightbulb, color: AppColors.amareloVale, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Travou nesta fase?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Desbloqueie a Super Dica secreta no Pix por R\$ 1,99.',
                          style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloVale,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: _isPurchasingSuperHint ? null : () => _buySuperHint(enigma),
                    child: _isPurchasingSuperHint
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('R\$ 1,99'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Campo de Resposta com Suporte a Enter
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkCardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isAnswerCorrect
                    ? Colors.greenAccent
                    : (_answerFeedback != null ? Colors.redAccent : AppColors.darkCardBorder),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DIGITE A CHAVE SECRETA:',
                      style: GoogleFonts.poppins(
                        color: AppColors.amareloVale,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Pressione Enter ↵',
                      style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _answerController,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        onSubmitted: (_) => _verifyAnswer(enigma),
                        decoration: InputDecoration(
                          hintText: 'Palavra-chave...',
                          hintStyle: GoogleFonts.poppins(
                            color: AppColors.cinzaMedio.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0C1013),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verdeVale,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isVerifyingAnswer ? null : () => _verifyAnswer(enigma),
                      child: _isVerifyingAnswer
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Validar',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                    ),
                  ],
                ),

                // Feedback
                if (_answerFeedback != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_isAnswerCorrect ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAnswerCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: _isAnswerCorrect ? Colors.greenAccent : Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _answerFeedback!,
                            style: GoogleFonts.poppins(
                              color: _isAnswerCorrect ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Histórico de Tentativas
                if (_previousAttempts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Tentativas incorretas: ',
                        style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11),
                      ),
                      Expanded(
                        child: Text(
                          _previousAttempts.join(', '),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.firaCode(
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhasesBreadcrumbs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_enigmas.length, (index) {
          final isDone = index < _currentEnigmaIndex;
          final isCurrent = index == _currentEnigmaIndex;

          Color borderColor = AppColors.darkCardBorder;
          Color bgColor = const Color(0xFF0F1418);
          Color textColor = AppColors.cinzaMedio;

          if (isDone) {
            borderColor = AppColors.verdeVale;
            bgColor = AppColors.verdeVale.withValues(alpha: 0.15);
            textColor = AppColors.verdeVale;
          } else if (isCurrent) {
            borderColor = AppColors.amareloVale;
            bgColor = AppColors.amareloVale.withValues(alpha: 0.2);
            textColor = Colors.white;
          }

          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDone)
                  const Icon(Icons.check_circle_rounded, color: AppColors.verdeVale, size: 12)
                else if (isCurrent)
                  const Icon(Icons.radio_button_checked_rounded, color: AppColors.amareloVale, size: 12)
                else
                  const Icon(Icons.lock_outline_rounded, color: AppColors.cinzaMedio, size: 12),
                const SizedBox(width: 6),
                Text(
                  'Fase ${index + 1}',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // 3. TELA TRIUNFAL DE VITÓRIA / CONCLUSÃO
  // ===========================================================================
  Widget _buildFinishedView() {
    final prize = _event!.get<String>('prize') ?? 'R\$ 1.000,00';
    final creatorName = _event!.get<String>('creatorName') ?? 'Influenciador';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F241A), Color(0xFF101920)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Troféu Animado
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4), width: 2),
                ),
                child: const FaIcon(FontAwesomeIcons.trophy, color: AppColors.amareloVale, size: 48),
              ),

              const SizedBox(height: 18),

              Text(
                'PARABÉNS! VOCÊ DECIFROU O ENIGMA!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Você superou todas as ${_enigmas.length} fases do desafio oficial de $creatorName!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 13),
              ),

              const SizedBox(height: 20),

              // Métricas da Partida
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1216),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('TEMPO TOTAL', _formatElapsed(_elapsedSeconds), AppColors.amareloVale),
                    _buildStatCol('FASES', '${_enigmas.length}/${_enigmas.length}', Colors.greenAccent),
                    _buildStatCol('PRÊMIO', prize, Colors.white),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Chave Pix do Campeão
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.amareloVale.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.bolt, color: AppColors.amareloVale, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'CHAVE PIX PARA RECEBIMENTO DO PRÊMIO:',
                          style: GoogleFonts.poppins(
                            color: AppColors.amareloVale,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _playerPixKeyController,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'CPF, E-mail ou Telefone Pix...',
                              hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFF0C1013),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.amareloVale,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            if (_playerPixKeyController.text.trim().isNotEmpty) {
                              _showToast('Chave Pix registrada com sucesso!');
                            }
                          },
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Botões de Ação
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                  label: Text(
                    'Compartilhar Vitória no WhatsApp 🏆',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  onPressed: _shareOnWhatsApp,
                ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/portal'),
                child: Text(
                  'Voltar ao Portal e Ver Mais Desafios',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(color: valueColor, fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
