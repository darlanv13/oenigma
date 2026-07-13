import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/features/event/providers/event_repository_provider.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:oenigma/core/models/event_model.dart';
import '../screens/event_progress_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'find_and_win_progress_screen.dart';
import 'package:oenigma/features/wallet/screens/wallet_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

    // Lógica de carregamento condicional
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

  String _formatDate(String dateStr) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateStr);
      return DateFormat("d 'de' MMM", 'pt_BR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _handleSubscription() async {
    final confirmed = await _showSubscriptionConfirmationDialog();
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(eventRepositoryProvider).subscribeToEvent(widget.event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inscrição realizada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isSubscribed = true);
      }
    } on ParseError catch (e) {
      if (mounted) {
        if (e.message?.contains('saldo') == true) {
          _showInsufficientFundsDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? "Ocorreu um erro."),
              backgroundColor: Colors.redAccent,
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

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmar Inscrição',
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Confirma a sua inscrição no evento "${widget.event.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: Colors.black,
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

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.wallet, color: Color(0xFFFFD54F), size: 20),
            SizedBox(width: 10),
            Text(
              'Saldo Insuficiente',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Você não tem saldo para se inscrever. Deseja adicionar créditos à sua carteira?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Depois', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (!mounted) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
                ),
              );

              try {
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WalletScreen(),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro ao carregar carteira: $e"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'RECARREGAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFindAndWin = widget.event.eventType == 'find_and_win';
    final eventTitle = isFindAndWin ? "Ache & Ganhe" : "Modo Clássico";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // HEADER IMERSIVO COM A MESMA IMAGEM DO CARD
              SliverAppBar(
                expandedHeight: 350.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: _buildBackButton(context),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Imagem de Fundo (Mesma lógica do EventCard)
                      widget.event.icon.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.event.icon,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFFD54F),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: FaIcon(
                                      FontAwesomeIcons.image,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                            )
                          : Container(color: Colors.grey.shade900),

                      // Gradiente escurecedor
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF121212),
                              const Color(0xFF121212).withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            stops: const [0.0, 0.3, 1.0],
                          ),
                        ),
                      ),

                      // Badge Principal de Prêmio
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        right: 20,
                        child: _buildMainBadge(),
                      ),
                    ],
                  ),
                ),
              ),

              // CORPO DA TELA (Painel Escuro)
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 50),
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        60,
                        24,
                        120,
                      ), // Espaço extra p/ botão fixo
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, -10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  eventTitle,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFD54F),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.event.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildInfoGrid(),
                          const SizedBox(height: 32),
                          _buildDescriptionSection(),
                        ],
                      ),
                    ),

                    // ÍCONE 3D CENTRALIZADO E FLUTUANTE
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.sackDollar,
                              size: 70,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // BOTÃO FIXO (NEON) NO RODAPÉ
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF121212).withValues(alpha: 0.0),
                    const Color(0xFF121212).withValues(alpha: 0.9),
                    const Color(0xFF121212),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _buildBottomCtaButton(context),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES DO NOVO DESIGN ---

  Widget _buildMainBadge() {
    return SizedBox(
      width: 75,
      height: 95,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 55,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF6B1A2C),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
          ),
          Positioned(
            top: 10,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF8B233C), Color(0xFF4A101C)],
                ),
                border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.event.prize.replaceAll('R\$', 'R\$\n'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.6,
      children: [
        _buildInfoPill(
          FontAwesomeIcons.locationDot,
          'Local',
          widget.event.location.isNotEmpty
              ? widget.event.location
              : 'Não definido',
        ),
        _buildInfoPill(
          FontAwesomeIcons.calendarDay,
          'Data',
          _formatDate(widget.event.startDate),
        ),
        FutureBuilder<Map<String, int>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (widget.event.eventType == 'find_and_win') {
              final solved = snapshot.data?['solved'] ?? 0;
              final total = snapshot.data?['total'] ?? 0;
              return _buildInfoPill(
                FontAwesomeIcons.bullseye,
                'Progresso',
                '$solved / $total',
                isHighlight: true,
              );
            } else {
              final total = snapshot.data?['total'] ?? 0;
              return _buildInfoPill(
                FontAwesomeIcons.filter,
                'Fases',
                total.toString(),
                isHighlight: true,
              );
            }
          },
        ),
        _buildInfoPill(
          FontAwesomeIcons.users,
          'Jogadores',
          widget.event.playerCount.toString(),
        ),
      ],
    );
  }

  Widget _buildInfoPill(
    dynamic icon,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlight
                  ? const Color(0xFFFFD54F).withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
              icon,
              color: isHighlight ? const Color(0xFFFFD54F) : Colors.grey,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isHighlight ? const Color(0xFFFFD54F) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SOBRE A CAÇADA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.event.fullDescription.isNotEmpty
              ? widget.event.fullDescription
              : 'Prepare-se para uma jornada épica. Siga as pistas, desvende os enigmas e encontre o tesouro antes dos outros jogadores.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Padding(
                padding: EdgeInsets.only(right: 2.0),
                child: FaIcon(
                  FontAwesomeIcons.angleLeft,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCtaButton(BuildContext context) {
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

    // Determina o gradiente do botão com base no status de inscrição e preço
    List<Color> buttonGradient;
    Color shadowColor;

    if (_isSubscribed) {
      buttonGradient = [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
      shadowColor = Colors.green;
    } else if (isFree) {
      buttonGradient = [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
      shadowColor = Colors.green;
    } else {
      buttonGradient = [const Color(0xFFFFD54F), const Color(0xFFF57F17)];
      shadowColor = const Color(0xFFFFD54F);
    }

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              if (_isSubscribed) {
                if (widget.event.eventType == 'find_and_win') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FindAndWinProgressScreen(event: widget.event),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EventProgressScreen(event: widget.event),
                    ),
                  );
                }
              } else {
                _handleSubscription();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: buttonGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: shadowColor.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            else ...[
              Text(
                _isSubscribed
                    ? 'ENTRAR NA CAÇADA'
                    : (isFree
                          ? 'INICIAR CAÇADA (GRÁTIS)'
                          : "INSCRIÇÃO: R\$ ${widget.event.price.toStringAsFixed(2).replaceAll('.', ',')}"),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              FaIcon(
                _isSubscribed
                    ? FontAwesomeIcons.play
                    : (isFree
                          ? FontAwesomeIcons.lockOpen
                          : FontAwesomeIcons.lock),
                size: 16,
                color: Colors.black,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledButton({required dynamic icon, required String label}) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 10),
          FaIcon(icon, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
