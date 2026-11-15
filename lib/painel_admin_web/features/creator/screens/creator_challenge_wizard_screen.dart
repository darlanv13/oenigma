import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/config/env_config.dart';

class EnigmaDraft {
  String title;
  String instruction;
  String? videoUrl;
  String code; // Resposta secreta
  bool hasPaidSuperHint;
  String superHintText;
  bool toolCesar;
  bool toolMorse;
  bool toolCompass;
  bool toolQr;

  EnigmaDraft({
    this.title = 'Fase 1: O Primeiro Segredo',
    this.instruction = '',
    this.videoUrl,
    this.code = '',
    this.hasPaidSuperHint = true,
    this.superHintText = '',
    this.toolCesar = true,
    this.toolMorse = false,
    this.toolCompass = false,
    this.toolQr = false,
  });
}

class CreatorChallengeWizardScreen extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String eventId)? onChallengeCreated;

  const CreatorChallengeWizardScreen({
    super.key,
    required this.onCancel,
    this.onChallengeCreated,
  });

  @override
  State<CreatorChallengeWizardScreen> createState() =>
      _CreatorChallengeWizardScreenState();
}

class _CreatorChallengeWizardScreenState
    extends State<CreatorChallengeWizardScreen> {
  int _currentStep = 0;
  bool _isSaving = false;

  // Passo 1: Identidade
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _videoTeaserController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  String _difficulty = 'Média';

  // Passo 2: Monetização
  bool _isPaidEntry = true;
  double _ticketPrice = 10.0;
  String _prizeType = 'dinheiro'; // 'dinheiro' ou 'objeto'
  final _prizeAmountController = TextEditingController(text: '1000,00');
  final _prizeNameController = TextEditingController();
  bool _enableSuperHints = true;

  // Passo 3: Fases & Enigmas
  final List<EnigmaDraft> _enigmas = [
    EnigmaDraft(
      title: 'Fase 1: A Pista Inicial',
      instruction: 'Assista ao vídeo e descubra a palavra-chave oculta.',
      code: '',
      superHintText: 'A primeira letra é a mesma do nome do canal.',
    ),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _videoTeaserController.dispose();
    _bannerUrlController.dispose();
    _prizeAmountController.dispose();
    _prizeNameController.dispose();
    super.dispose();
  }

  void _generateSlugFromTitle(String title) {
    final clean = title
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    _slugController.text = clean;
  }

  Future<void> _publishChallenge() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Por favor, informe o título do desafio.');
      setState(() => _currentStep = 0);
      return;
    }

    if (_enigmas.isEmpty || _enigmas.any((e) => e.code.trim().isEmpty)) {
      _showError('Todas as fases devem ter uma Resposta Secreta definida.');
      setState(() => _currentStep = 2);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await ParseUser.currentUser() as ParseUser?;
      final creatorId = user?.objectId ?? '';
      final creatorName = user?.get<String>('name') ??
          user?.get<String>('username') ??
          'Criador';
      final creatorAvatar = user?.get<String>('photoURL') ?? '';

      final slug = _slugController.text.trim().isNotEmpty
          ? _slugController.text.trim()
          : 'desafio-${DateTime.now().millisecondsSinceEpoch}';

      final finalPrice = _isPaidEntry ? _ticketPrice : 0.0;
      final prizeValue = _prizeType == 'dinheiro'
          ? (_prizeAmountController.text.trim().startsWith('R\$')
              ? _prizeAmountController.text.trim()
              : 'R\$ ${_prizeAmountController.text.trim()}')
          : (_prizeNameController.text.trim().isNotEmpty
              ? _prizeNameController.text.trim()
              : 'Prêmio Especial');

      final eventData = <String, dynamic>{
        'name': _titleController.text.trim(),
        'title': _titleController.text.trim(),
        'slug': slug,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'creatorAvatar': creatorAvatar,
        'videoTeaserUrl': _videoTeaserController.text.trim(),
        'videoUrl': _videoTeaserController.text.trim(),
        'difficulty': _difficulty,
        'status': 'open',
        'eventType': 'classic',
        'playerCount': 0,
        'price': finalPrice,
        'platformFeePercent': 15.0,
        'hasPaidHints': _enableSuperHints,
        'paidHintPrice': 1.99,
        'prizeType': _prizeType,
        'prize': prizeValue,
      };

      if (_bannerUrlController.text.trim().isNotEmpty) {
        eventData['prizeImageUrl'] = _bannerUrlController.text.trim();
        eventData['icon'] = _bannerUrlController.text.trim();
      }

      final enigmasData = _enigmas.map((draft) {
        final chars = <String>[];
        if (draft.toolCesar) chars.add('cesar');
        if (draft.toolMorse) chars.add('morse');
        if (draft.toolCompass) chars.add('compass');
        if (draft.toolQr) chars.add('qrcode');

        return <String, dynamic>{
          'title': draft.title,
          'instruction': draft.instruction,
          'code': draft.code.trim().toUpperCase(),
          'videoUrl': draft.videoUrl?.trim(),
          'hasPaidSuperHint': draft.hasPaidSuperHint,
          'superHintPrice': 1.99,
          'superHintText': draft.superHintText.trim(),
          'characteristics': chars,
        };
      }).toList();

      String? createdEventId;

      // 1. Salva via Cloud Function dedicada publishCreatorChallenge (usa MasterKey no servidor para contornar qualquer restrição de CLP)
      try {
        final cloudFunc = ParseCloudFunction('publishCreatorChallenge');
        final res = await cloudFunc.execute(parameters: {
          ...eventData,
          'enigmas': enigmasData,
        });

        if (res.success && res.result != null) {
          final data = Map<String, dynamic>.from(res.result);
          if (data['success'] == true && data['eventId'] != null) {
            createdEventId = data['eventId'];
          } else if (data['error'] != null) {
            throw Exception(data['error']);
          }
        } else {
          throw Exception(res.error?.message ?? 'Falha ao salvar evento no servidor.');
        }
      } catch (e) {
        debugPrint('[publishCreatorChallenge Error]: $e');
        rethrow;
      }

      // Sucesso! Mostra modal de compartilhamento
      if (createdEventId != null && mounted) {
        _showSuccessDialog(createdEventId, slug);
      }
    } catch (e) {
      _showError('Erro ao publicar desafio: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(String eventId, String slug) {
    final publicLink = EnvConfig.buildChallengeUrl(slug);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.verdeVale),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.greenAccent,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Desafio Publicado com Sucesso!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seu desafio já está online e pronto para receber seus seguidores!',
                style: GoogleFonts.poppins(
                  color: AppColors.cinzaMedio,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),

              // QR Code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: publicLink,
                  version: QrVersions.auto,
                  size: 160.0,
                ),
              ),
              const SizedBox(height: 16),

              // Campo de Link
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        publicLink,
                        style: GoogleFonts.poppins(
                          color: AppColors.amareloVale,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: publicLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copiado com sucesso!'),
                            backgroundColor: AppColors.verdeVale,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onChallengeCreated != null) {
                widget.onChallengeCreated!(eventId);
              } else {
                widget.onCancel();
              }
            },
            child: const Text('Concluir & Ir para o Studio'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com Botão Voltar e Passos
          _buildWizardHeader(),
          const SizedBox(height: 16),

          // Conteúdo do Passo Ativo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildCurrentStepContent(),
            ),
          ),

          // Rodapé com Botões de Navegação
          _buildWizardFooter(),
        ],
      ),
    );
  }

  Widget _buildWizardHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 18),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    onPressed: widget.onCancel,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMobile ? 'Novo Desafio' : 'Criar Novo Desafio para seus Seguidores',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isMobile ? 15 : 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Passo ${_currentStep + 1} de 4: ${_getStepTitle(_currentStep)}',
                          style: GoogleFonts.poppins(
                            color: AppColors.amareloVale,
                            fontSize: isMobile ? 11 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) _buildStepPills(),
                ],
              ),
              const SizedBox(height: 10),

              // Barra de Progresso Mobile em 4 Segmentos
              Row(
                children: List.generate(4, (index) {
                  final isPassed = index < _currentStep;
                  final isCurrent = index == _currentStep;
                  Color barColor = AppColors.darkCardBorder;
                  if (isCurrent) barColor = AppColors.verdeVale;
                  if (isPassed) barColor = AppColors.amareloVale;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      height: 4,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Identidade & Vídeo Teaser';
      case 1:
        return 'Monetização & Prêmio';
      case 2:
        return 'Fases, Pistas & Super Dicas';
      case 3:
        return 'Revisão & Lançamento';
      default:
        return '';
    }
  }

  Widget _buildStepPills() {
    return Row(
      children: List.generate(4, (index) {
        final isPassed = index < _currentStep;
        final isCurrent = index == _currentStep;

        Color bg = AppColors.darkBackground;
        Color text = AppColors.cinzaMedio;
        if (isCurrent) {
          bg = AppColors.verdeVale;
          text = Colors.white;
        } else if (isPassed) {
          bg = AppColors.amareloVale.withValues(alpha: 0.2);
          text = AppColors.amareloVale;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? AppColors.verdeVale : AppColors.darkCardBorder,
            ),
          ),
          child: Center(
            child: isPassed
                ? const Icon(Icons.check_rounded, size: 14, color: AppColors.amareloVale)
                : Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      color: text,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Identity();
      case 1:
        return _buildStep2Monetization();
      case 2:
        return _buildStep3Enigmas();
      case 3:
        return _buildStep4Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // === PASSO 1: IDENTIDADE ===
  Widget _buildStep1Identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('1. Título & Link de Divulgação'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _titleController,
          label: 'Nome do Desafio',
          hint: 'Ex: O Mistério da Caixa Secreta de Natal',
          onChanged: (val) => _generateSlugFromTitle(val),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _slugController,
          label: 'Link Personalizado (Slug)',
          hint: 'ex: misterio-caixa-secreta',
          prefixText: EnvConfig.webPlayerDisplayPrefix,
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('2. Vídeo de Apresentação (Teaser)'),
        const SizedBox(height: 4),
        Text(
          'Cole o link do seu vídeo no YouTube, Shorts, TikTok ou Reels explicando as regras e provocando o público.',
          style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _videoTeaserController,
          label: 'URL do Vídeo (YouTube / Shorts / TikTok)',
          hint: 'https://www.youtube.com/watch?v=... ou https://tiktok.com/@...',
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('3. Imagem de Capa & Dificuldade'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _bannerUrlController,
          label: 'URL da Imagem de Capa (Banner 16:9)',
          hint: 'https://exemplo.com/banner.png',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Dificuldade Geral: ', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
            ...['Fácil', 'Média', 'Difícil', 'Lendária'].map((diff) {
              final isSelected = _difficulty == diff;
              return ChoiceChip(
                label: Text(diff),
                selected: isSelected,
                selectedColor: AppColors.verdeVale,
                backgroundColor: AppColors.darkCardColor,
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : AppColors.cinzaMedio,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (_) => setState(() => _difficulty = diff),
              );
            }),
          ],
        ),
      ],
    );
  }

  // === PASSO 2: MONETIZAÇÃO ===
  Widget _buildStep2Monetization() {
    final simulatedParticipants = 1000;
    final grossSimulation = _isPaidEntry ? (simulatedParticipants * _ticketPrice) : 0.0;
    final platformFee = grossSimulation * 0.15;
    final netSimulation = grossSimulation - platformFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('1. Como os seguidores entram no desafio?'),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            final cardGratuito = _buildChoiceCard(
              title: 'Desafio Gratuito',
              subtitle: 'Qualquer seguidor pode jogar sem pagar. Excelente para viralizar.',
              isSelected: !_isPaidEntry,
              icon: Icons.card_giftcard_rounded,
              onTap: () => setState(() => _isPaidEntry = false),
            );
            final cardPago = _buildChoiceCard(
              title: 'Pay-to-Play (R\$ 5 a R\$ 20)',
              subtitle: 'Seguidores pagam uma taxa simbólica no Pix para concorrer ao prêmio.',
              isSelected: _isPaidEntry,
              icon: Icons.confirmation_number_rounded,
              badge: 'MAIS LUCRATIVO',
              onTap: () => setState(() => _isPaidEntry = true),
            );

            if (isMobile) {
              return Column(
                children: [
                  cardGratuito,
                  const SizedBox(height: 12),
                  cardPago,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: cardGratuito),
                const SizedBox(width: 14),
                Expanded(child: cardPago),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        if (_isPaidEntry) ...[
          _buildSectionTitle('2. Valor do Ingresso Pix (R\$ 5 a R\$ 20)'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [5.0, 10.0, 15.0, 20.0].map((val) {
              final isSel = _ticketPrice == val;
              return InkWell(
                onTap: () => setState(() => _ticketPrice = val),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.amareloVale : AppColors.darkCardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel ? AppColors.amareloVale : AppColors.darkCardBorder,
                    ),
                  ),
                  child: Text(
                    'R\$ ${val.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: isSel ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Card de Simulação de Receita
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.verdeVale.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined, color: AppColors.amareloVale, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Simulação: Com $simulatedParticipants participantes a R\$ ${_ticketPrice.toStringAsFixed(2)}, você recebe R\$ ${netSimulation.toStringAsFixed(2)} líquido no Pix (15% taxa da plataforma inclusa).',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        _buildSectionTitle('3. O Prêmio do Vencedor'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ChoiceChip(
              label: const Text('Dinheiro no Pix'),
              selected: _prizeType == 'dinheiro',
              selectedColor: AppColors.verdeVale,
              backgroundColor: AppColors.darkCardColor,
              onSelected: (_) => setState(() => _prizeType = 'dinheiro'),
            ),
            ChoiceChip(
              label: const Text('Item / Objeto Especial (ex: iPhone, PS5, Troféu)'),
              selected: _prizeType == 'objeto',
              selectedColor: AppColors.verdeVale,
              backgroundColor: AppColors.darkCardColor,
              onSelected: (_) => setState(() => _prizeType = 'objeto'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_prizeType == 'dinheiro')
          _buildTextField(
            controller: _prizeAmountController,
            label: 'Valor Total do Prêmio (R\$)',
            hint: 'Ex: 1000,00',
            prefixText: 'R\$ ',
          )
        else
          _buildTextField(
            controller: _prizeNameController,
            label: 'Nome do Objeto / Prêmio',
            hint: 'Ex: PlayStation 5 Edição Especial autografado',
          ),
        const SizedBox(height: 20),

        _buildSectionTitle('4. Super Dicas Pagas (R\$ 1,99)'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Habilitar Super Dicas de R\$ 1,99 no Pix',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            'Se um seguidor travar em um enigma, ele pode pagar R\$ 1,99 para liberar a dica decisiva. A receita é dividida entre você e a plataforma!',
            style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
          ),
          value: _enableSuperHints,
          activeColor: AppColors.amareloVale,
          onChanged: (val) => setState(() => _enableSuperHints = val),
        ),
      ],
    );
  }

  // === PASSO 3: FASES & ENIGMAS ===
  Widget _buildStep3Enigmas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            final infoText = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Fases do Desafio (${_enigmas.length})'),
                Text(
                  'Cada fase deve ter uma resposta secreta que o seguidor precisa desvendar.',
                  style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                ),
              ],
            );

            final addButton = ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Adicionar Próxima Fase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeVale,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: () {
                setState(() {
                  final nextNum = _enigmas.length + 1;
                  _enigmas.add(
                    EnigmaDraft(
                      title: 'Fase $nextNum: Novo Mistério',
                      instruction: 'Decifre a charada para avançar.',
                      code: '',
                      superHintText: '',
                    ),
                  );
                });
              },
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  infoText,
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: addButton,
                  ),
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: infoText),
                const SizedBox(width: 12),
                addButton,
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _enigmas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, index) {
            final draft = _enigmas[index];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.darkCardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FASE ${index + 1}',
                        style: GoogleFonts.poppins(
                          color: AppColors.amareloVale,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (_enigmas.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            setState(() => _enigmas.removeAt(index));
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Título da Fase
                  TextFormField(
                    initialValue: draft.title,
                    decoration: _inputDecoration('Título da Fase', 'Ex: O Criptograma Misterioso'),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (val) => draft.title = val,
                  ),
                  const SizedBox(height: 12),

                  // Vídeo da Fase (Opcional)
                  TextFormField(
                    initialValue: draft.videoUrl ?? '',
                    decoration: _inputDecoration('Vídeo da Fase (Link YouTube / Shorts / TikTok)', 'Cole o link do vídeo desta pista'),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (val) => draft.videoUrl = val,
                  ),
                  const SizedBox(height: 12),

                  // Instrução / Enigma
                  TextFormField(
                    initialValue: draft.instruction,
                    maxLines: 2,
                    decoration: _inputDecoration('Instrução / Texto da Charada', 'Texto do enigma que aparece na tela do seguidor'),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (val) => draft.instruction = val,
                  ),
                  const SizedBox(height: 12),

                  // Ferramentas Táticas Ativadas
                  Text(
                    'Ferramentas que o jogador pode usar nesta fase:',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Cifra de César'),
                        selected: draft.toolCesar,
                        selectedColor: AppColors.verdeVale,
                        onSelected: (val) => setState(() => draft.toolCesar = val),
                      ),
                      FilterChip(
                        label: const Text('Código Morse'),
                        selected: draft.toolMorse,
                        selectedColor: AppColors.verdeVale,
                        onSelected: (val) => setState(() => draft.toolMorse = val),
                      ),
                      FilterChip(
                        label: const Text('Bússola / GPS'),
                        selected: draft.toolCompass,
                        selectedColor: AppColors.verdeVale,
                        onSelected: (val) => setState(() => draft.toolCompass = val),
                      ),
                      FilterChip(
                        label: const Text('Scanner QR Code'),
                        selected: draft.toolQr,
                        selectedColor: AppColors.verdeVale,
                        onSelected: (val) => setState(() => draft.toolQr = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Resposta Secreta & Super Dica
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: draft.code,
                          decoration: _inputDecoration(
                            'Resposta Secreta (Chave de Validação)',
                            'Palavra exata que o seguidor deve digitar',
                          ),
                          style: GoogleFonts.poppins(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          onChanged: (val) => draft.code = val,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          initialValue: draft.superHintText,
                          decoration: _inputDecoration(
                            'Super Dica Secreta (R\$ 1,99)',
                            'Liberada imediatamente quando ele pagar o Pix de R\$ 1,99',
                          ),
                          style: GoogleFonts.poppins(
                            color: AppColors.amareloVale,
                            fontSize: 13,
                          ),
                          onChanged: (val) => draft.superHintText = val,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // === PASSO 4: REVISÃO & LANÇAMENTO ===
  Widget _buildStep4Review() {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Desafio sem título';
    final slug = _slugController.text.trim();
    final prize = _prizeType == 'dinheiro'
        ? 'R\$ ${_prizeAmountController.text.trim()}'
        : (_prizeNameController.text.trim().isNotEmpty ? _prizeNameController.text.trim() : 'Prêmio Especial');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Resumo do Desafio Pronto para Publicação'),
        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.verdeVale.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, color: AppColors.amareloVale, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Link público: ${EnvConfig.webPlayerDisplayPrefix}$slug',
                          style: GoogleFonts.poppins(color: AppColors.amareloVale, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.darkCardBorder, height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 580;
                  if (isMobile) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildReviewMetric('Inscrição', _isPaidEntry ? 'R\$ ${_ticketPrice.toStringAsFixed(2)}' : 'Gratuito')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildReviewMetric('Prêmio', prize)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildReviewMetric('Fases', '${_enigmas.length} Enigmas')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildReviewMetric('Super Dicas', _enableSuperHints ? 'Ativadas (R\$ 1,99)' : 'Desativadas')),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildReviewMetric('Inscrição', _isPaidEntry ? 'R\$ ${_ticketPrice.toStringAsFixed(2)}' : 'Gratuito'),
                      _buildReviewMetric('Prêmio', prize),
                      _buildReviewMetric('Fases', '${_enigmas.length} Enigmas'),
                      _buildReviewMetric('Super Dicas', _enableSuperHints ? 'Ativadas (R\$ 1,99)' : 'Desativadas'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.verdeVale.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.amareloVale, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Ao clicar em "Publicar Desafio Agora", o link será ativado imediatamente e o QR Code será gerado para você postar nos seus Stories e redes sociais.',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewMetric(String label, String value) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildWizardFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: _isSaving ? null : () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.cinzaMedio),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Voltar'),
            )
          else
            const SizedBox.shrink(),

          if (_currentStep < 3)
            ElevatedButton(
              onPressed: () {
                if (_currentStep == 0 && _titleController.text.trim().isEmpty) {
                  _showError('Informe o título do desafio para continuar.');
                  return;
                }
                setState(() => _currentStep++);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeVale,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              ),
              child: const Text('Avançar'),
            )
          else
            ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.rocket_launch_rounded, size: 16),
              label: Text(_isSaving ? 'Publicando...' : 'Publicar Desafio Agora!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloVale,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              onPressed: _isSaving ? null : _publishChallenge,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefixText,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: _inputDecoration(label, hint, prefixText: prefixText),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.poppins(color: AppColors.amareloVale, fontWeight: FontWeight.bold),
      labelStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
      hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio.withValues(alpha: 0.5), fontSize: 12),
      filled: true,
      fillColor: AppColors.darkCardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.darkCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.darkCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.verdeVale),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required dynamic icon,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.verdeVale.withValues(alpha: 0.15) : AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.verdeVale : AppColors.darkCardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                icon is IconData
                    ? Icon(icon as IconData, color: isSelected ? AppColors.amareloVale : AppColors.cinzaMedio, size: 22)
                    : FaIcon(icon, color: isSelected ? AppColors.amareloVale : AppColors.cinzaMedio, size: 20),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amareloVale,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 9),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
