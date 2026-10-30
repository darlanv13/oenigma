import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/app_cliente/features/event/providers/event_repository_provider.dart';
import 'package:oenigma/app_cliente/features/wallet/screens/wallet_screen.dart';
import 'package:oenigma/app_cliente/features/auth/screens/login_screen.dart'
    as oenigma_login_screen;

import 'event_progress_screen.dart';
import 'lobby_find_and_win_screen.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  final EventModel event;
  final Map<String, dynamic> playerData;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.playerData,
  });

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  Future<Map<String, int>>? _statsFuture;
  bool _isSubscribed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isSubscribed = widget.playerData['events']?[widget.event.id] != null;

    if (widget.event.eventType == 'find_and_win') {
      _statsFuture = _getFindAndWinStats();
    } else {
      _statsFuture = _getClassicEventStats();
    }
  }

  Future<Map<String, int>> _getFindAndWinStats() async {
    final stats = await ref
        .read(eventRepositoryProvider)
        .getFindAndWinStats(widget.event.id);
    return {
      'total': stats['totalEnigmas'] ?? 0,
      'solved': stats['solvedEnigmas'] ?? 0,
    };
  }

  Future<Map<String, int>> _getClassicEventStats() async {
    final count = await ref
        .read(eventRepositoryProvider)
        .getChallengeCountForEvent(widget.event.id);
    return {'total': count, 'solved': 0};
  }

  Future<void> _handleSubscription() async {
    if (widget.playerData.isEmpty || widget.playerData['name'] == null) {
      _showLoginRequiredDialog();
      return;
    }

    final confirmed = await _showSubscriptionConfirmationDialog();
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(eventRepositoryProvider).subscribeToEvent(widget.event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Inscrição realizada com sucesso!"),
            backgroundColor: AppColors.verdeVale,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _isSubscribed = true);
      }
    } on ParseError catch (e) {
      if (mounted) {
        if (e.message.contains('saldo')) {
          _showInsufficientFundsDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showSubscriptionConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Confirmar Inscrição',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Confirma a sua inscrição no evento "${widget.event.name}"?',
          style: GoogleFonts.inter(color: AppColors.cinzaMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cinzaMedio)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'CONFIRMAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.userLock,
              color: AppColors.verdeVale,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Login Necessário',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Você precisa criar uma conta ou fazer login para iniciar a caçada.',
          style: GoogleFonts.inter(color: AppColors.cinzaMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cinzaMedio)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const oenigma_login_screen.LoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'FAZER LOGIN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.wallet, color: AppColors.amareloVale, size: 20),
            const SizedBox(width: 10),
            Text(
              'Saldo Insuficiente',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Você não tem saldo para se inscrever. Deseja adicionar créditos à sua carteira?',
          style: GoogleFonts.inter(color: AppColors.cinzaMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cinzaMedio)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalletScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amareloVale,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'DEPOSITAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onCtaPressed() {
    if (_isLoading) return;
    if (_isSubscribed) {
      if (widget.event.eventType == 'find_and_win') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyFindEndWinScreen(event: widget.event),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventProgressScreen(event: widget.event),
          ),
        );
      }
    } else {
      _handleSubscription();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isObjeto = widget.event.prizeType.toLowerCase() == 'objeto';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1115),
      body: Stack(
        children: [
          // Efeitos de luz ambiental de fundo
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isObjeto
                    ? const Color(0xFF00A4B4).withValues(alpha: 0.12)
                    : const Color(0xFFF3A522).withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isObjeto
                    ? AppColors.verdeVale.withValues(alpha: 0.08)
                    : const Color(0xFF147A40).withValues(alpha: 0.08),
              ),
            ),
          ),

          // Layout em tela única sem overflow e sem necessidade de rolagem
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. Barra Superior Compacta
                          _buildTopBar(isObjeto),

                          const SizedBox(height: 8),

                          // 2. Showcase Vitrine do Prêmio (Objeto ou Dinheiro)
                          isObjeto
                              ? _buildCompactObjectHero()
                              : _buildCompactCashHero(),

                          const SizedBox(height: 8),

                          // 3. Título do Evento & Localização
                          _buildTitleAndLocationRow(isObjeto),

                          const SizedBox(height: 8),

                          // 4. Faixa de Garantias / Vantagens
                          isObjeto
                              ? _buildObjectGuaranteePills()
                              : _buildCashGuaranteePills(),

                          const SizedBox(height: 8),

                          // 5. Barra de Estatísticas Compacta (4 métricas lado a lado)
                          _buildCompactStatsBar(isObjeto),

                          const SizedBox(height: 8),

                          // 6. Resumo "Sobre a Caçada" / Vencedor
                          _buildCompactDescriptionBox(isObjeto),

                          const SizedBox(height: 10),

                          // 7. Botão CTA Principal de Inscrição / Entrada
                          _buildCtaButton(isObjeto),

                          const SizedBox(height: 6),

                          // 8. Selo de Segurança do Rodapé
                          _buildSecurityFooter(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. BARRA SUPERIOR COMPACTA
  // ===========================================================================
  Widget _buildTopBar(bool isObjeto) {
    final isClassic = widget.event.eventType == 'classic';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botão de Voltar Redondo
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF131D24),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.chevronLeft,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ),

        // Título Central
        Text(
          isObjeto ? 'Prêmio Físico' : 'Premiação em Dinheiro',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),

        // Pill da Modalidade
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isObjeto ? const Color(0xFF0C242C) : const Color(0xFF241B08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isObjeto
                  ? const Color(0xFF00A4B4).withValues(alpha: 0.5)
                  : const Color(0xFFF3A522).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                isClassic ? FontAwesomeIcons.trophy : FontAwesomeIcons.boxOpen,
                size: 9.5,
                color: isObjeto ? const Color(0xFF00A4B4) : const Color(0xFFF3A522),
              ),
              const SizedBox(width: 4),
              Text(
                isClassic ? 'CLASSIC' : 'FIND & WIN',
                style: GoogleFonts.poppins(
                  color: isObjeto ? const Color(0xFF00A4B4) : const Color(0xFFF3A522),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. HERO SHOWCASE COMPACTO (OBJETO)
  // ===========================================================================
  Widget _buildCompactObjectHero() {
    final event = widget.event;

    return Container(
      height: 132,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Brilho radial ciano de fundo
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.45, 0),
                    radius: 0.8,
                    colors: [
                      const Color(0xFF00A4B4).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Sparkles decorativos
            const Positioned(
              top: 10,
              right: 14,
              child: _SparkleWidget(color: Color(0xFFF3A522), size: 12),
            ),
            const Positioned(
              bottom: 12,
              right: 22,
              child: _SparkleWidget(color: Color(0xFF00A4B4), size: 9),
            ),

            // Conteúdo Lado a Lado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Lado Esquerdo: Tag + Nome do Objeto + Badge 1º Lugar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C242C),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF00A4B4).withValues(alpha: 0.45),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(FontAwesomeIcons.boxOpen, color: Color(0xFF00A4B4), size: 8.5),
                              const SizedBox(width: 4),
                              Text(
                                'ITEM FÍSICO',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF00A4B4),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event.prize,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(FontAwesomeIcons.trophy, color: Colors.black, size: 8.5),
                              const SizedBox(width: 4),
                              Text(
                                '1º LUGAR LEVA',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Lado Direito: Imagem do Produto com Sombra Elíptica
                  SizedBox(
                    width: 110,
                    height: 105,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 70,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: event.prizeImageUrl != null && event.prizeImageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: event.prizeImageUrl!,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF00A4B4),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Center(
                                    child: FaIcon(
                                      FontAwesomeIcons.gift,
                                      color: Color(0xFFF3A522),
                                      size: 38,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.gift,
                                    color: Color(0xFFF3A522),
                                    size: 38,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. HERO SHOWCASE COMPACTO (DINHEIRO)
  // ===========================================================================
  Widget _buildCompactCashHero() {
    final event = widget.event;

    return Container(
      height: 132,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141C16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF3A522).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Brilho radial dourado
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.5, 0),
                    radius: 0.8,
                    colors: [
                      const Color(0xFFF3A522).withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Sparkles decorativos
            const Positioned(
              top: 10,
              right: 14,
              child: _SparkleWidget(color: Color(0xFFF3A522), size: 12),
            ),
            const Positioned(
              bottom: 12,
              right: 22,
              child: _SparkleWidget(color: Color(0xFFF3A522), size: 9),
            ),

            // Conteúdo Lado a Lado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Ícone de Cofre / Moedas com Halo
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF3A522).withValues(alpha: 0.25),
                          const Color(0xFF141C16),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border.all(
                        color: const Color(0xFFF3A522).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.sackDollar,
                        color: Color(0xFFF3A522),
                        size: 30,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Lado Direito: Tag PIX + Grande Valor + Subtítulo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF281F08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFF3A522).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(FontAwesomeIcons.bolt, color: Color(0xFFF3A522), size: 8.5),
                              const SizedBox(width: 4),
                              Text(
                                'BOUNTY VIA PIX • 1º LUGAR',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFF3A522),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.prize,
                          style: GoogleFonts.poppins(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFF3A522),
                            letterSpacing: -0.4,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFF3A522).withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Transferência imediata sem taxas',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. TÍTULO E LOCALIZAÇÃO (LINHA ÚNICA)
  // ===========================================================================
  Widget _buildTitleAndLocationRow(bool isObjeto) {
    final event = widget.event;
    final isClassic = event.eventType == 'classic';
    final String displayTitle = event.name.isNotEmpty
        ? event.name
        : (isClassic ? 'Modo Clássico' : 'Ache & Ganhe');
    final String displayLocation = event.location.isNotEmpty && event.location != 'Local não definido'
        ? event.location
        : 'Canaã Dos Carajás';
    final Color accentColor = isObjeto ? const Color(0xFF00A4B4) : const Color(0xFFF3A522);

    return Row(
      children: [
        Expanded(
          child: Text(
            displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FaIcon(FontAwesomeIcons.locationDot, color: accentColor, size: 11),
        const SizedBox(width: 4),
        Text(
          displayLocation,
          style: GoogleFonts.inter(
            color: AppColors.cinzaMedio,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. PILLS DE GARANTIAS (OBJETO OU DINHEIRO)
  // ===========================================================================
  Widget _buildObjectGuaranteePills() {
    return Row(
      children: [
        Expanded(child: _buildMiniPill(FontAwesomeIcons.box, 'Lacrado na Caixa', const Color(0xFF00A4B4))),
        const SizedBox(width: 6),
        Expanded(child: _buildMiniPill(FontAwesomeIcons.truckFast, 'Entrega Rápida', const Color(0xFF00A4B4))),
        const SizedBox(width: 6),
        Expanded(child: _buildMiniPill(FontAwesomeIcons.shieldHalved, 'Garantia Oficial', const Color(0xFF00A4B4))),
      ],
    );
  }

  Widget _buildCashGuaranteePills() {
    return Row(
      children: [
        Expanded(child: _buildMiniPill(FontAwesomeIcons.pix, 'PIX Imediato', const Color(0xFF32BCAD))),
        const SizedBox(width: 6),
        Expanded(child: _buildMiniPill(FontAwesomeIcons.shieldHalved, '100% Protegido', const Color(0xFF68D391))),
        const SizedBox(width: 6),
        Expanded(child: _buildMiniPill(FontAwesomeIcons.coins, 'Zero Taxas', const Color(0xFFF3A522))),
      ],
    );
  }

  Widget _buildMiniPill(dynamic icon, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, color: accentColor, size: 9.5),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. BARRA COMPACTA DE ESTATÍSTICAS (4 COLUNAS EM UMA ÚNICA LINHA)
  // ===========================================================================
  Widget _buildCompactStatsBar(bool isObjeto) {
    final event = widget.event;
    final displayDifficulty = event.difficulty.isNotEmpty ? event.difficulty : 'Média';
    final Color accentColor = isObjeto ? const Color(0xFF00A4B4) : const Color(0xFFF3A522);

    // Status
    String statusText = 'Ativo';
    Color statusColor = AppColors.verdeVale;
    dynamic statusIcon = FontAwesomeIcons.circleCheck;

    if (event.status == 'dev') {
      statusText = 'Em breve';
      statusColor = const Color(0xFFF3A522);
      statusIcon = FontAwesomeIcons.clock;
    } else if (event.status == 'closed') {
      statusText = 'Encerrado';
      statusColor = AppColors.danger;
      statusIcon = FontAwesomeIcons.circleXmark;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isObjeto
              ? const Color(0xFF1E3A45)
              : const Color(0xFFF3A522).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: FutureBuilder<Map<String, int>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          String etapasValue;
          if (event.eventType == 'find_and_win') {
            final solved = snapshot.data?['solved'] ?? 0;
            final total = snapshot.data?['total'] ?? 0;
            etapasValue = '$solved/$total';
          } else {
            final total = snapshot.data?['total'] ?? 0;
            etapasValue = total > 0 ? '$total Fases' : 'A definir';
          }

          return Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  'STATUS',
                  statusText,
                  statusColor,
                  statusIcon,
                ),
              ),
              _buildStatDivider(),
              Expanded(
                child: _buildStatColumn(
                  'ETAPAS',
                  etapasValue,
                  Colors.white,
                  FontAwesomeIcons.cubes,
                ),
              ),
              _buildStatDivider(),
              Expanded(
                child: _buildStatColumn(
                  'NÍVEL',
                  displayDifficulty,
                  const Color(0xFFF3A522),
                  FontAwesomeIcons.star,
                ),
              ),
              _buildStatDivider(),
              Expanded(
                child: _buildStatColumn(
                  'JOGADORES',
                  '${event.playerCount}',
                  accentColor,
                  FontAwesomeIcons.users,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color, dynamic icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.cinzaMedio,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 9.5),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 22,
      width: 1,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  // ===========================================================================
  // 7. SOBRE A CAÇADA COMPACTO / VENCEDOR
  // ===========================================================================
  Widget _buildCompactDescriptionBox(bool isObjeto) {
    final event = widget.event;
    final bool isClosed = event.status == 'closed';
    final hasWinner = event.winnerName != null && event.winnerName!.isNotEmpty;
    final Color accentColor = isObjeto ? const Color(0xFF00A4B4) : const Color(0xFFF3A522);

    if (isClosed && hasWinner) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1708),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFF3A522).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.trophy, color: Color(0xFFF3A522), size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Prêmio já conquistado por: ${event.winnerName}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFFF3A522),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Regra da Caçada',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            event.fullDescription.isNotEmpty
                ? event.fullDescription
                : 'Encontre as pistas, escaneie os QR codes e desvende os mistérios. O primeiro a concluir leva o prêmio total.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. BOTÃO CTA PRINCIPAL
  // ===========================================================================
  Widget _buildCtaButton(bool isObjeto) {
    if (widget.event.status == 'closed') {
      return _buildDisabledButton(
        icon: FontAwesomeIcons.flag,
        label: 'Evento Finalizado',
      );
    }
    if (widget.event.status == 'dev') {
      return _buildDisabledButton(
        icon: FontAwesomeIcons.hourglassHalf,
        label: 'Em Breve',
      );
    }

    final bool isFree = widget.event.price == 0;
    final LinearGradient gradient = isObjeto
        ? AppColors.gradienteVerdeVale
        : const LinearGradient(
            colors: [Color(0xFFF3A522), Color(0xFFFFB84D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final Color textColor = isObjeto ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: _onCtaPressed,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2,
                ),
              )
            else ...[
              FaIcon(
                _isSubscribed ? FontAwesomeIcons.play : (isObjeto ? FontAwesomeIcons.ticket : FontAwesomeIcons.coins),
                size: 13,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Text(
                _isSubscribed
                    ? 'ENTRAR NA CAÇADA'
                    : (isFree
                        ? 'INICIAR CAÇADA (GRÁTIS)'
                        : 'INSCRIÇÃO: R\$ ${widget.event.price.toStringAsFixed(2).replaceAll('.', ',')}'),
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledButton({required dynamic icon, required String label}) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              color: AppColors.cinzaMedio,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          FaIcon(icon, size: 12, color: AppColors.cinzaMedio),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FaIcon(
          FontAwesomeIcons.shieldHalved,
          color: AppColors.verdeVale,
          size: 11,
        ),
        const SizedBox(width: 6),
        Text(
          'Caçada segura e prêmio auditado',
          style: GoogleFonts.inter(
            color: AppColors.cinzaMedio,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SPARKLE WIDGET & PAINTER (4-pointed star sparkles)
// =============================================================================
class _SparkleWidget extends StatelessWidget {
  final Color color;
  final double size;

  const _SparkleWidget({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;
    const waist = 0.16;

    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy * (1 - waist), cx + (w / 2) * waist, cy);
    path.quadraticBezierTo(cx + (w / 2) * (1 - waist), cy, w, cy);
    path.quadraticBezierTo(cx + (w / 2) * waist, cy, cx, cy + (h / 2) * waist);
    path.quadraticBezierTo(cx, cy + (h / 2) * (1 - waist), cx, h);
    path.quadraticBezierTo(cx, cy + (h / 2) * waist, cx - (w / 2) * waist, cy);
    path.quadraticBezierTo(cx - (w / 2) * (1 - waist), cy, 0, cy);
    path.quadraticBezierTo(cx - (w / 2) * waist, cy, cx, cy * (1 - waist));
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      color != oldDelegate.color;
}
